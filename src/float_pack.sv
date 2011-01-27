package float_pack;
   
   parameter [4:0] Nm = `TB_MANT_SIZE; // Nm [1,23]
   parameter [3:0] Ne = `TB_EXP_SIZE;  // Ne [2,8]
   parameter [6:0] De = 2**(Ne-1)-1;

   typedef struct packed { logic unsigned s;
			   logic unsigned [Ne-1:0] e;
			   logic unsigned [Nm-1:0] m;
			   } float; 

typedef struct packed { logic unsigned s;
			logic unsigned [7:0] e;
			logic unsigned [22:0] m;
			} float_ieee;


//*******************************************************//


function float_ieee real2float_ieee(input shortreal nb);
   real2float_ieee=$shortrealtobits(nb);
   
endfunction // float_ieee

function shortreal float_ieee2real(input float_ieee nb);
   float_ieee2real=$bitstoshortreal(nb);
   
endfunction; // shortreal

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
     end // else: !if(nb.e[22:Ne])
   
endfunction; // float


function float_ieee float2float_ieee(input float nb);
   float2float_ieee.s=nb.s;
   float2float_ieee.e=nb.e-De+127;
   float2float_ieee.m=nb.m<<23-Nm;

endfunction; // float_ieee

function float real2float(input shortreal nb);
   real2float=float_ieee2float(real2float_ieee(nb));
endfunction; // float

function shortreal float2real(input float nb);
   float2real=float_ieee2real(float2float_ieee(nb));
endfunction; // float

//*********************************************************//

function float float_mul(input float a, input float b);
endfunction; // float

function float float_div(input float a, input float b);
endfunction; // float

function float float_add_sub(input bit choice, input float a, input float b);   //choice : 0 ----> add      1 ----> sub
   logic unsigned [Ne-1:0] expo_min, expo_max;
   logic unsigned [Nm:0]   sig_min, sig_max;
   logic unsigned 	  b_sign, sign_min, sign_max;
   logic unsigned [Nm+1:0] sum_sig;
   
   
   b_sign = choice ^ b.s;   //add or sub


   if(a.e<b.e || (a.e==b.e && a.m<b.m) )
     begin
	$display("a min");
	
	expo_min=a.e;
	expo_max=b.e;
	sig_min={1'b1,a.m};
	sig_max={1'b1,b.m};
	sign_min=a.s;
	sign_max=b_sign;
     end
   else 
     begin
	$display("b min");
	
	expo_min=b.e;
	expo_max=a.e;
	sig_min={1'b1,b.m};
	sig_max={1'b1,a.m};
	sign_min=b_sign;
	sign_max=a.s;
     end // else: !if(a.e<b.e || (a.e==b.e && a.m<b.m) )
      
   sig_min = sig_min >> (expo_max - expo_min);  // we compensate the significand

   if(sign_max==sign_min)
     begin
	$display("same sign");
	
	float_add_sub.s = sign_max;
	
	sum_sig=sign_max+sign_min;
	if(sum_sig[Nm + 1])
	  begin
	     $display("shift sign");
	     
	     if(expo_min == 2**Ne - 2) //max reached
	       begin
		  $display("max reached");
		  
		  float_add_sub.m = 2**Nm-1;
		  float_add_sub.e=2**Ne-2;
	       end
	     else 
	       begin
		  float_add_sub.e = expo_max + 1'b1;
		  float_add_sub.m = sum_sig[Nm:1];
	       end
	  end // if (sum_sig[Nm + 1])
	else
	  begin
	     float_add_sub.e = expo_max;
	     float_add_sub.m = sum_sig[Nm-1:0];
	  end // else: !if(sum_sig[Nm + 1])
	
     end
   else
     begin
	if(sign_min==0)
	  begin
	     $display("neg");

	     $display("%b %b %b %b",sig_max, expo_max, sig_min, expo_min);
	     
	     float_add_sub = sub_aux(sig_max, expo_max, sig_min, expo_min);

	     

	     
	     float_add_sub.s = 1;
	  end
	else
	  begin
	     $display("pos");
	     
	     float_add_sub = sub_aux(sig_max, expo_max, sig_min, expo_min);
	     float_add_sub.s = 0;
	  end
     end
endfunction; // float

function float float_add(input float a, input float b);
   float_add = float_add_sub(1'b0, a, b);
endfunction; // float

function float float_sub(input float a, input float b);
   float_sub = float_add_sub(1'b1, a, b);
endfunction; // float


function float sub_aux(
    input logic unsigned [Nm:0] sa, 
    input logic unsigned [Ne-1:0] ea,
    input logic unsigned [Nm:0] 	 sb, 
    input logic unsigned [Ne-1:0] eb);
   
   
   logic unsigned [4:0] 		 first_one;
   logic unsigned [Nm:0] 	 sub_sig;
   

   first_one = Nm+1;
   sub_sig = sa - sb;

   $display("%b",sub_sig);
   
   while(~sub_sig[first_one - 1] && first_one > 0)
     first_one = first_one - 1;

   $display(first_one);   

   if(ea + (Nm - first_one) >0)
     begin
	sub_aux.e = ea - (Nm - first_one);
	sub_aux.m = sub_sig << Nm - first_one;
     end
   else
     begin
	$display("min reached");
	
	sub_aux.e = 0;
	sub_aux.m = 0;
     end

endfunction; // float



endpackage // float_pack

