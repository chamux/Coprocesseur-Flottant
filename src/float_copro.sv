import float_pack::*;

module float_copro(
    input logic clk,
    input logic copro_valid,
    input logic [10:0] copro_opcode,
    input logic [31:0] copro_op0,
    input logic [31:0] copro_op1,
    output logic       copro_complete, 
    output logic [31:0] copro_result) ;

   float 	a,b;
   logic [31:0] 	res_as, res_m, res_d;
   logic 		choice;
   
   logic [5:0] 		count;


   assign copro_result =(!copro_opcode[1])?res_as:(copro_opcode[0]?res_d:res_m);
      
   enum 		logic [1:0] {data_in,processing,waiting} state;
   

   /*
    add 23.66
    mul 27.42
    div 2.52
    */   
   
   always_ff @(posedge clk)
     begin
	if(copro_valid)
	  begin

	     case(state)
	       data_in:
		 begin
		    a<=copro_op1;
		    b<=copro_op0;

		    case(copro_opcode[1:0])
		      2'b00 :
			begin
			   count<= 5;
			   choice<=0;
			end
		      2'b01 : 
			begin
			   count<= 5;
			   choice<=1;
			end
		      2'b10 :
			count<= 4;
		      2'b11 : 
			count<= 40;
		      
		    endcase

		    state<=processing;
		    
		 end // case: data_in
	       
	       processing:
		 begin
		    count<=count-1;
		    if(count==1)
		      begin
			 res_as <= float_add_sub(choice,a,b); 
			 res_m  <= float_mul(a,b);
			 res_d  <= float_div(a,b);
			
			 copro_complete<=1;
			 state<=waiting;
		      end
		 end
	     endcase
	     
	  end // if (copro_valid)
	
	else //initialisation
	  begin
	     state<=data_in;
	     copro_complete<=0;
	  end
	
     end // always_ff @ (posedge clk)
   
endmodule // float_copro


