import float_pack::*;

module float_copro(
    input logic clk,
    input logic copro_valid,
    input logic [10:0] copro_opcode,
    input logic [31:0] copro_op0,
    input logic [31:0] copro_op1,
    output logic       copro_complete, 
    output logic [31:0] copro_result) ;


   enum 		{waiting_and_processing, waiting_copro_not_valid} state;

   always_ff @(posedge clk)
     begin

	case(state)
	  
	  waiting_and_processing : 
	    begin
	       if(copro_valid)
		 begin

		    case(copro_opcode[1:0])
		      2'b00 : copro_result <= float2float_ieee(float_add(float_ieee2float(copro_op0[Nm+Ne+1:0]), 
									 float_ieee2float(copro_op1[Nm+Ne+1])));
		      2'b01 : copro_result <= float2float_ieee(float_sub(float_ieee2float(copro_op0[Nm+Ne+1:0]), 
									 float_ieee2float(copro_op1[Nm+Ne+1])));
		      2'b10 : copro_result <= float2float_ieee(float_div(float_ieee2float(copro_op0[Nm+Ne+1:0]), 
									 float_ieee2float(copro_op1[Nm+Ne+1])));
		      2'b11 : copro_result <= float2float_ieee(float_mul(float_ieee2float(copro_op0[Nm+Ne+1:0]),
                                                                         float_ieee2float(copro_op1[Nm+Ne+1])));
		    endcase

		    copro_complete <= 1;
		    state <= waiting_copro_not_valid;

		 end
	    end

	  waiting_copro_not_valid :
	    begin
	       if(~copro_valid)
		 begin
		    copro_complete <= 0;
		    state <= waiting_and_processing;
		 end
	    end		

	endcase

     end

endmodule // float_copro


