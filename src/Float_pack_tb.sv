module Float_pack_tb;

   import float_pack::*;
   
      
   initial
     begin
	
	shortreal a ;
	float_ieee b ;
	shortreal c;
	

	a = 1.236;
	$display("a =%d",a);
	
	b = real2float_ieee(a) ;
	$display("a =%d",a," b.s=%d", b.s," b.e=%d",b.e," b.m=%d", b.m);
	b.e = b.e+1 ; 
	$display("a =%d",a," b.s=%d", b.s," b.e=%d",b.e," b.m=%d", b.m);
	a = float_ieee2real(b) ;
	$display("a =%d",a," b.s=%d", b.s," b.e=%d",b.e," b.m=%d", b.m);

	c=float2real(b);
	$display("c =%b",c);
	
	
     end // initial begin
   

endmodule // Float_pack_tb
