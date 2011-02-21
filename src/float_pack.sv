package float_pack;
   
   parameter [4:0] Nm = 23; // Nm [1,23]
   parameter [3:0] Ne = 8;  // Ne [2,8]
   parameter [6:0] De = 2**(Ne-1)-1;

   typedef struct packed { logic unsigned s;
			   logic unsigned [Ne-1:0] e;
			   logic unsigned [Nm-1:0] m;
			   } float; 

   typedef struct packed { logic unsigned s;
			   logic unsigned [7:0] e;
			   logic unsigned [22:0] m;
			   } float_ieee;


/***********************************************************
 *                    TESTBENCH
 ***********************************************************/

// synthesis translate off
function float_ieee real2float_ieee(input shortreal nb);
   
   real2float_ieee=$shortrealtobits(nb);
   
endfunction // float_ieee


function shortreal float_ieee2real(input float_ieee nb);
   
   float_ieee2real=$bitstoshortreal(nb);
   
endfunction // shortreal

// synthesis translate on


function float float_ieee2float(input float_ieee nb);
   
   float_ieee2float.s=nb.s;
   
   if((nb.e+De-127)>2**Ne-2) // Max reached
     begin
	float_ieee2float.e=2**Ne-2;
	float_ieee2float.m=2**Nm-1;
     end
   else
     begin
	if(nb.e+De<=127)// Min reached
	  begin
	     float_ieee2float.e=0;
	     float_ieee2float.m=0;
	  end
	else // Normal case
	  begin
	     float_ieee2float.e=nb.e+De-127;
	     float_ieee2float.m=nb.m[22:23-Nm];
	  end
     end
   
endfunction // float


function float_ieee float2float_ieee(input float nb);
   
   float2float_ieee.s=nb.s;
   float2float_ieee.e=nb.e-De+127;
   float2float_ieee.m=nb.m<<23-Nm;

endfunction // float_ieee


// synthesis translate off

function float real2float(input shortreal nb);
   
   real2float=float_ieee2float(real2float_ieee(nb));
   
endfunction // float


function shortreal float2real(input float nb);
   
   float2real=float_ieee2real(float2float_ieee(nb));
   
endfunction // float

// synthesis translate on


/***********************************************************
 *                    MULT
 ***********************************************************/

function float float_mul(input float a, input float b);

   logic signed [Ne+1:0] sum_exp;
   logic [2*Nm+1:0] 	 mult_sig;
   logic [5:0] 		 first_one;

   first_one = 2*Nm + 2;
   float_mul.s=a.s^b.s;
   sum_exp=a.e + b.e - De;   
   mult_sig = {a.e!=0,a.m}*{b.e!=0,b.m};
   
   while(~mult_sig[first_one - 1] && first_one > 0)
     first_one = first_one - 1;

   sum_exp =  sum_exp + first_one - (2*Nm + 2) + 1;

   if(sum_exp > 0 && sum_exp < (2**Ne-1) && first_one>0)
     begin
	float_mul.e = sum_exp;
	float_mul.m = mult_sig>>(first_one-1 - Nm);
     end   
   else
     begin
	if(first_one==0 || sum_exp <=0)
	  begin
	     float_mul.e = 0;
	     float_mul.m = 0;
	  end
	else
	  begin
	     float_mul.e = 2**Ne-2;
	     float_mul.m = 2**Nm-1;
	  end
     end
   
endfunction // float


/**********************************************************
 *                    DIVISION
 **********************************************************/

function float float_div(input float a, input float b);
   
   logic signed   [Ne+1:0]   expo;
   logic unsigned [2*Nm+1:0] sig;
   logic unsigned [5:0]      first_one;

   first_one = 2*Nm + 2;   
   float_div.s=a.s^b.s;
  
   if(b.e==0)//NAN      XXX
     begin
	float_div.e=2**Ne-1;
	float_div.m=0;	
     end
   else
     begin
	expo =  signed'({1'b0,a.e}) - signed'({1'b0,b.e}) + De;
	sig = {a.e!=0,a.m,{Nm{1'b0}}}/{{Nm{1'b0}},b.e!=0,b.m};

	while(~sig[first_one - 1] && first_one > 0)
	  first_one = first_one - 1;

	expo =  expo -Nm+ first_one-1;
	
	if(expo > 0 && expo < (2**Ne-1) && first_one>0)
	  begin
	     float_div.e = expo;
	     if(first_one-1 > Nm)
	       float_div.m = sig>>(first_one-1 - Nm);
	     else
	       float_div.m = sig<<-(first_one-1 - Nm);
	  end   
	else
	  begin
	     if(first_one==0 || expo <=0)
	       begin
		  float_div.e = 0;
		  float_div.m = 0;
	       end
	     else
	       begin
		  float_div.e = 2**Ne-2;
		  float_div.m = 2**Nm-1;
	       end 
	  end
     end
   
endfunction // float


/**********************************************************
 *                    ADD_SUB
 **********************************************************/

//choice : 0 ----> add      1 ----> sub
function float float_add_sub(input bit choice, input float a, input float b);
  
   logic unsigned [Ne-1:0]   expo_min, expo_max;
   logic unsigned [2*Nm:0]   sig_min, sig_max;
   logic unsigned 	     b_sign, sign_min, sign_max;
   logic unsigned [Nm+1:0]   sum_sig;
   logic unsigned [2*Nm+1:0] sum_sig_aux;

   logic unsigned [5:0]      first_one;
   logic unsigned [2*Nm:0]     sub_sig;
   
   b_sign = choice ^ b.s;   //add or sub

   if(a.e<b.e || (a.e==b.e && a.m<b.m) )
     begin
	expo_min=a.e;
	expo_max=b.e;
	sig_min={a.e!=0,a.m,{Nm{1'b0}}};
	sig_max={b.e!=0,b.m,{Nm{1'b0}}};
	sign_min=a.s;
	sign_max=b_sign;
     end
   else 
     begin
	expo_min=b.e;
	expo_max=a.e;
	sig_min={b.e!=0,b.m,{Nm{1'b0}}};
	sig_max={a.e!=0,a.m,{Nm{1'b0}}};
	sign_min=b_sign;
	sign_max=a.s;
     end
   
   sig_min = sig_min >> (expo_max - expo_min);  // we compensate the significand
   
   if(sign_max==sign_min)
     begin
	float_add_sub.s = sign_max;
	sum_sig_aux=sig_max+sig_min;
	sum_sig=sum_sig_aux[2*Nm+1:Nm];
	
	if(sum_sig[Nm + 1])
	  begin
	     if(expo_max == 2**Ne - 2) //max reached
	       begin
		  float_add_sub.m = 2**Nm-1;
		  float_add_sub.e=2**Ne-2;
	       end
	     else 
	       begin
		  float_add_sub.e = expo_max + 1'b1;
		  float_add_sub.m = sum_sig[Nm:1];
	       end
	  end
	else
	  begin
	     float_add_sub.e = expo_max;
	     float_add_sub.m = sum_sig[Nm-1:0];
	  end	
     end
   else
     begin
	first_one = 2*Nm+1;
	sub_sig = (sig_max - sig_min);

	while(~sub_sig[first_one - 1] && first_one > 0)
	  first_one = first_one - 1;

	if((expo_max > (2*Nm - (first_one-1))) && first_one!=0)
	  begin
	     float_add_sub.e = expo_max - (2*Nm - (first_one-1));
	     if(first_one-1<Nm-1)
	       float_add_sub.m = sub_sig << -(first_one-1-Nm);
	     else
	       float_add_sub.m = sub_sig >> (first_one-1-Nm);
	  end
	else
	  begin
	     float_add_sub.e = 0;
	     float_add_sub.m = 0;
	  end

	float_add_sub.s=sign_max;
     end
   
endfunction // float


function float float_add(input float a, input float b);
   
   float_add = float_add_sub(1'b0, a, b);
   
endfunction // float

function float float_sub(input float a, input float b);
   
   float_sub = float_add_sub(1'b1, a, b);
   
endfunction // float

endpackage // float_pack

