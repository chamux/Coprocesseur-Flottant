import float_pack::*;

module float_copro(
		   input logic clk,
		   input logic copro_valid,
		   input logic [10:0] copro_opcode,
		   input logic [31:0] copro_op0,
		   input logic [31:0] copro_op1,
		   output logic       copro_complete, 
		   output logic [31:0] copro_result) ;

   float 	copro_reg_op0,copro_reg_op1;
   logic [31:0] 		       res_as, res_m, copro_res_div;
   logic 			       choice;
   
   logic [7:0] 			       count;
   
   enum 			       logic [1:0] {data_in,processing,complete,waiting} state;

   // synthesis translate off  
   
   shortreal 			       f_copro_op0;
   shortreal 			       f_copro_op1;
   shortreal 			       f_copro_result;
   always @(*)
     begin
	f_copro_op0      = $bitstoshortreal( copro_op0 );
	f_copro_op1      = $bitstoshortreal( copro_op1 );
	f_copro_result   = $bitstoshortreal( copro_result );
     end

   // synthesis translate on

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
		    copro_reg_op1<=copro_op1;
		    copro_reg_op0<=copro_op0;

		    case(copro_opcode[1:0])
		      2'b00 : begin
			 count<= 3;
			 choice<=0;
		      end
		      2'b01 : begin
			 count<= 3;
			 choice<=1;
		      end
		      2'b10 : count<= 2;
		      2'b11 : count<= 20;
		    endcase

		    state<=processing;
		    
		 end // case: data_in
	       
	       processing:
		 begin
		    count<=count-1;
		    if(count==1)
		      begin
			 res_as <= float_add_sub(choice,copro_reg_op0,copro_reg_op1); 
			 res_m  <= float_mul(copro_reg_op0,copro_reg_op1);
			 copro_res_div  <= float_div(copro_reg_op0,copro_reg_op1);
			 
			 state<=complete;
		      end
		 end
	       complete:begin
		  copro_result <=(!copro_opcode[1])?res_as:(copro_opcode[0]?copro_res_div:res_m);
		  copro_complete<=1;
		  state<=waiting;
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


