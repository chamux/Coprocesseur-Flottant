package float_pack;
   
   parameter [4:0] Nm = 23; // Nm [1,23]
   parameter [3:0] Ne = 8;  // Ne [2,8]

   typedef struct packed { logic unsigned s;
                   logic unsigned [Ne-1:0] e;
		   logic unsigned [Nm-1:0] m;
                 } float; 
   
   typedef struct packed { logic unsigned s;
                   logic unsigned [7:0] e;
		   logic unsigned [22:0] m;
                 } float_ieee;

function float_ieee real2float_ieee(input shortreal nb);
   real2float_ieee=$shortrealtobits(nb);
   
endfunction // float_ieee

function shortreal float_ieee2real(input float_ieee nb);
   float_ieee2real=$bitstoshortreal(nb);
   
endfunction; // shortreal

function float float_ieee2float(input float_ieee nb);
   float_ieee2float.s=nb.s;
   if(nb.e[22:Ne])
     begin
	float_ieee2float.e=2**Ne-2;
	float_ieee2float.m=2**Nm-1;
     end
   else
     begin
	float_ieee2float.e=nb.e[Ne-1:0];
	float_ieee2float.m=nb.m[22:23-Nm];
     end
endfunction; // float


function float_ieee float2float_ieee(input float nb);
   float2float_ieee.s=nb.s;
   float2float_ieee.e=nb.e;
   float2float_ieee.m=nb.m<<23-Nm;
endfunction; // float_ieee

function float real2float(input shortreal nb);
   real2float=float_ieee2float(real2float_ieee(nb));
endfunction; // float

function shortreal float2real(input float nb);
   float2real=float_ieee2real(float2float_ieee(nb));
endfunction; // float



endpackage // float_pack
