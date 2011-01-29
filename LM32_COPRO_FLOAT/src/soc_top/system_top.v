//---------------------------------------------------------------------------
// LatticeMico32 System On A Chip
//
// Top Level Design 
//---------------------------------------------------------------------------

`include "system_conf.v"

module system
  #(
    parameter   bootram_file     = "soft.vm",
    parameter   clk_freq         = `CLK_FREQUENCY,
    parameter   uart_baud_rate   = `uartBAUD_RATE,
    parameter   b_ram_adddr_w    = `B_RAM_ADD_W 
    ) (
       input                   clk, 
       input                   clk_locked, 
       input                   rst,
       // UART
       input                   uart_rxd, 
       output                  uart_txd,
       // SRAM
        output           [17:0] sram_adr,
        inout            [15:0] sram_dat,
        output            [1:0] sram_be_n,    // Byte   Enable
        output                  sram_ce_n,    // Chip   Enable
        output                  sram_oe_n,    // Output Enable
        output                  sram_we_n,     // Write  Enable
       // SDRAM
//       inout   [15:0]  dram_dq,   //      Sdram Data bus 16 Bits
//       output  [11:0]  dram_addr, //      Sdram Address bus 12 Bits
//       output  dram_ldqm,         //      Sdram Low-byte Data Mask 
//       output  dram_udqm,         //      Sdram High-byte Data Mask
//       output  dram_we_n,         //      Sdram Write Enable
//       output  dram_cas_n,        //      Sdram Column Address Strobe
//       output  dram_ras_n,        //      Sdram Row Address Strobe
//       output  dram_cs_n,         //      Sdram Chip Select
//       output  dram_ba_0,         //      Sdram Bank Address 0
//       output  dram_ba_1,         //      Sdram Bank Address 0
//       output  dram_clk,          //      Sdram Clock
//       output  dram_cke,          //      Sdram Clock Enable
//       // SDRAM secondary  ACCESS
//       input sdr_rd            ,      // initiate read operation
//       input sdr_wr            ,      // initiate write operation
//       output sdr_earlyOpBegun ,      // read/write op has begun (async)
//       output sdr_opBegun      ,      // read/write op has begun (clocked)
//       output sdr_rdPending    ,      // true if read operation(s) are still in the pipeline
//       output sdr_done         ,      // read or write operation is done
//       output sdr_rdDone       ,      // read operation is done and data is available
//       input [21:0] sdr_hAddr  ,  // address from host to SDRAM
//       input [15:0] sdr_hDIn ,     // data from host to SDRAM
//       output [15:0] sdr_hDOut ,   // data from SDRAM to host
//       output [3:0] sdr_status,   // diagnostic status of the SDRAM controller FSM         
       // COPROCESSOR ACCESS
       input [31:0] copro_result,
       input copro_complete,
       output copro_valid,
       output [31:0] copro_op0,
       output [31:0] copro_op1,
       output [10:0] copro_opcode
       );
   
	//reset wire

 
   //------------------------------------------------------------------
   // Whishbone Wires
   //------------------------------------------------------------------
   wire 		       gnd   =  1'b0;
   wire [3:0] 		       gnd4  =  4'h0;
   wire [31:0] 		       gnd32 = 32'h00000000;

   
   wire [31:0] 		       lm32i_adr,
			       lm32d_adr,
			       uart0_adr,
			       timer0_adr,
			       bram0_adr,
			       sram0_adr;
//                               sdram0_adr;


   wire [31:0] 		       lm32i_dat_r,
			       lm32i_dat_w,
			       lm32d_dat_r,
			       lm32d_dat_w,
			       uart0_dat_r,
			       uart0_dat_w,
			       timer0_dat_r,
			       timer0_dat_w,
			       bram0_dat_r,
			       bram0_dat_w,
			       sram0_dat_w,
			       sram0_dat_r;
//			       sdram0_dat_w,
//			       sdram0_dat_r;
                  

   wire [3:0] 		       lm32i_sel,
			       lm32d_sel,
			       uart0_sel,
			       timer0_sel,
			       bram0_sel,
			       sram0_sel;
//			       sdram0_sel;

   wire 		       lm32i_we,
			       lm32d_we,
			       uart0_we,
			       timer0_we,
			       bram0_we,
			       sram0_we;
//			       sdram0_we;

   wire 		       lm32i_cyc,
			       lm32d_cyc,
			       uart0_cyc,
			       timer0_cyc,
			       bram0_cyc,
			       sram0_cyc;
//			       sdram0_cyc;

   wire 		       lm32i_stb,
			       lm32d_stb,
			       uart0_stb,
			       timer0_stb,
			       bram0_stb,
			       sram0_stb;
//			       sdram0_stb;

   wire 		       lm32i_ack,
			       lm32d_ack,
			       uart0_ack,
			       timer0_ack,
			       bram0_ack,
			       sram0_ack;
//			       sdram0_ack;

   wire 		       lm32i_rty,
			       lm32d_rty;

   wire 		       lm32i_err,
			       lm32d_err;

   wire 		       lm32i_lock,
			       lm32d_lock;

   wire [2:0] 		       lm32i_cti,
			       lm32d_cti;

   wire [1:0] 		       lm32i_bte,
			       lm32d_bte;

   //---------------------------------------------------------------------------
   // Interrupts
   //---------------------------------------------------------------------------
   wire [31:0] 		       intr_n;
   wire 		       uart0_intr = 0;
   wire [1:0] 		       timer0_intr;

   assign 		       intr_n = { 29'hFFFFFFF, ~timer0_intr[1], ~timer0_intr[0], ~uart0_intr };

   //---------------------------------------------------------------------------
   // Wishbone Interconnect
   //---------------------------------------------------------------------------
   wb_conbus_top #(
		   .s0_addr_w ( 11 ),           // Should be 12 but bit 31 is ignored
		   .s0_addr   ( 11'h001 ),      // sram0 0010_0000->0017_ffff = 512K
		   .s1_addr_w ( 7 ),           // Should be 8 but bit 31 is ignored           
		   .s1_addr   ( 7'h01 ),       // sdram 0100_0000->017F_FFFF = 8M  
		   .s27_addr_w( 15 ),          // Should be 16 but bit 31 is ignored
		   .s2_addr   ( 15'h0000 ),    // bram0  0000_0000->0000_0fff = 4K
		   .s3_addr   ( 15'hf000 ),    // uart0  f000_0000
		   .s4_addr   ( 15'hf001 ),    // timer0 f001_0000
		   .s5_addr   ( 15'hf002 ),    
		   .s6_addr   ( 15'hf003 ),
		   .s7_addr   ( 15'hf004 )
		   ) conmax0 (
			      .clk_i( clk ),
			      .rst_i( rst ),
			      // Master0
			      .m0_dat_i(  lm32i_dat_w  ),
			      .m0_dat_o(  lm32i_dat_r  ),
			      .m0_adr_i(  lm32i_adr    ),
			      .m0_we_i (  lm32i_we     ),
			      .m0_sel_i(  lm32i_sel    ),
			      .m0_cyc_i(  lm32i_cyc    ),
			      .m0_stb_i(  lm32i_stb    ),
			      .m0_ack_o(  lm32i_ack    ),
			      .m0_rty_o(  lm32i_rty    ),
			      .m0_err_o(  lm32i_err    ),
			      // Master1
			      .m1_dat_i(  lm32d_dat_w  ),
			      .m1_dat_o(  lm32d_dat_r  ),
			      .m1_adr_i(  lm32d_adr    ),
			      .m1_we_i (  lm32d_we     ),
			      .m1_sel_i(  lm32d_sel    ),
			      .m1_cyc_i(  lm32d_cyc    ),
			      .m1_stb_i(  lm32d_stb    ),
			      .m1_ack_o(  lm32d_ack    ),
			      .m1_rty_o(  lm32d_rty    ),
			      .m1_err_o(  lm32d_err    ),
			      // Master2
			      .m2_dat_i(  gnd32  ),
			      .m2_adr_i(  gnd32  ),
			      .m2_we_i (  gnd  ),
			      .m2_sel_i(  gnd4   ),
			      .m2_cyc_i(  gnd    ),
			      .m2_stb_i(  gnd    ),
			      // Master3
			      .m3_dat_i(  gnd32  ),
			      .m3_adr_i(  gnd32  ),
			      .m3_we_i (  gnd  ),
			      .m3_sel_i(  gnd4   ),
			      .m3_cyc_i(  gnd    ),
			      .m3_stb_i(  gnd    ),
			      // Master4
			      .m4_dat_i(  gnd32  ),
			      .m4_adr_i(  gnd32  ),
			      .m4_we_i (  gnd  ),
			      .m4_sel_i(  gnd4   ),
			      .m4_cyc_i(  gnd    ),
			      .m4_stb_i(  gnd    ),
			      // Master5
			      .m5_dat_i(  gnd32  ),
			      .m5_adr_i(  gnd32  ),
			      .m5_we_i (  gnd  ),
			      .m5_sel_i(  gnd4   ),
			      .m5_cyc_i(  gnd    ),
			      .m5_stb_i(  gnd    ),
			      // Master6
			      .m6_dat_i(  gnd32  ),
			      .m6_adr_i(  gnd32  ),
			      .m6_we_i (  gnd  ),
			      .m6_sel_i(  gnd4   ),
			      .m6_cyc_i(  gnd    ),
			      .m6_stb_i(  gnd    ),
			      // Master7
			      .m7_dat_i(  gnd32  ),
			      .m7_adr_i(  gnd32  ),
			      .m7_we_i (  gnd ),
			      .m7_sel_i(  gnd4   ),
			      .m7_cyc_i(  gnd    ),
			      .m7_stb_i(  gnd    ),

			      // Slave0
			      .s0_dat_i( sram0_dat_r ),
			      .s0_dat_o( sram0_dat_w ),
			      .s0_adr_o( sram0_adr ),
			      .s0_sel_o( sram0_sel ),
			      .s0_we_o( sram0_we ),
			      .s0_cyc_o( sram0_cyc ),
			      .s0_stb_o( sram0_stb ),
			      .s0_ack_i( sram0_ack ),
			      .s0_err_i( gnd  ),
			      .s0_rty_i( gnd  ),
			      // Slave1
//			      .s1_dat_i( sdram0_dat_r ),
//			      .s1_dat_o( sdram0_dat_w ),
//			      .s1_adr_o( sdram0_adr ),
//			      .s1_sel_o( sdram0_sel ),
//			      .s1_we_o( sdram0_we ),
//			      .s1_cyc_o( sdram0_cyc ),
//			      .s1_stb_o( sdram0_stb ),
//			      .s1_ack_i( sdram0_ack ),
//			      .s1_err_i( gnd  ),
//			      .s1_rty_i( gnd  ),
			      .s1_dat_i(  gnd32  ),
			      .s1_ack_i(  gnd    ),
			      .s1_err_i(  gnd    ),
			      .s1_rty_i(  gnd    ),
			      // Slave2
			      .s2_dat_i(  bram0_dat_r ),
			      .s2_dat_o(  bram0_dat_w ),
			      .s2_adr_o(  bram0_adr   ),
			      .s2_sel_o(  bram0_sel   ),
			      .s2_we_o(   bram0_we    ),
			      .s2_cyc_o(  bram0_cyc   ),
			      .s2_stb_o(  bram0_stb   ),
			      .s2_ack_i(  bram0_ack   ),
			      .s2_err_i(  gnd         ),
			      .s2_rty_i(  gnd         ),
			      // Slave3
			      .s3_dat_i(  uart0_dat_r ),
			      .s3_dat_o(  uart0_dat_w ),
			      .s3_adr_o(  uart0_adr   ),
			      .s3_sel_o(  uart0_sel   ),
			      .s3_we_o(   uart0_we    ),
			      .s3_cyc_o(  uart0_cyc   ),
			      .s3_stb_o(  uart0_stb   ),
			      .s3_ack_i(  uart0_ack   ),
			      .s3_err_i(  gnd         ),
			      .s3_rty_i(  gnd         ),
			      // Slave4
			      .s4_dat_i(  timer0_dat_r ),
			      .s4_dat_o(  timer0_dat_w ),
			      .s4_adr_o(  timer0_adr   ),
			      .s4_sel_o(  timer0_sel   ),
			      .s4_we_o(   timer0_we    ),
			      .s4_cyc_o(  timer0_cyc   ),
			      .s4_stb_o(  timer0_stb   ),
			      .s4_ack_i(  timer0_ack   ),
			      .s4_err_i(  gnd          ),
			      .s4_rty_i(  gnd          ),
			      // Slave5
			      .s5_dat_i(  gnd32  ),
			      .s5_ack_i(  gnd    ),
			      .s5_err_i(  gnd    ),
			      .s5_rty_i(  gnd    ),
			      // Slave6
			      .s6_dat_i(  gnd32  ),
			      .s6_ack_i(  gnd    ),
			      .s6_err_i(  gnd    ),
			      .s6_rty_i(  gnd    ),
			      // Slave7
			      .s7_dat_i(  gnd32  ),
			      .s7_ack_i(  gnd    ),
			      .s7_err_i(  gnd    ),
			      .s7_rty_i(  gnd    )
			      );


   //---------------------------------------------------------------------------
   // LM32 CPU 
   //---------------------------------------------------------------------------
   lm32_cpu lm32_cpu0 (
		 .clk_i(  clk  ),
		 .rst_i(  rst  ),
		 .interrupt_n(  intr_n  ),
                 .user_valid(copro_valid),
                 .user_opcode(copro_opcode),
                 .user_operand_0(copro_op0),
                 .user_operand_1(copro_op1),
                 .user_result(copro_result),
                 .user_complete(copro_complete),
		 //
		 .I_ADR_O(  lm32i_adr    ),
		 .I_DAT_I(  lm32i_dat_r  ),
		 .I_DAT_O(  lm32i_dat_w  ),
		 .I_SEL_O(  lm32i_sel    ),
		 .I_CYC_O(  lm32i_cyc    ),
		 .I_STB_O(  lm32i_stb    ),
		 .I_ACK_I(  lm32i_ack    ),
		 .I_WE_O (  lm32i_we     ),
		 .I_CTI_O(  lm32i_cti    ),
		 .I_LOCK_O( lm32i_lock   ),
		 .I_BTE_O(  lm32i_bte    ),
		 .I_ERR_I(  lm32i_err    ),
		 .I_RTY_I(  lm32i_rty    ),
		 //
		 .D_ADR_O(  lm32d_adr    ),
		 .D_DAT_I(  lm32d_dat_r  ),
		 .D_DAT_O(  lm32d_dat_w  ),
		 .D_SEL_O(  lm32d_sel    ),
		 .D_CYC_O(  lm32d_cyc    ),
		 .D_STB_O(  lm32d_stb    ),
		 .D_ACK_I(  lm32d_ack    ),
		 .D_WE_O (  lm32d_we     ),
		 .D_CTI_O(  lm32d_cti    ),
		 .D_LOCK_O( lm32d_lock   ),
		 .D_BTE_O(  lm32d_bte    ),
		 .D_ERR_I(  lm32d_err    ),
		 .D_RTY_I(  lm32d_rty    )
		 );
   
   //---------------------------------------------------------------------------
   // Block RAM
   //---------------------------------------------------------------------------
   wb_bram #(
	     .adr_width( b_ram_adddr_w ),
	     .mem_file_name( bootram_file )
	     ) bram0 (
		      .clk_i(  clk  ),
		      .rst_i(  rst  ),
		      //
		      .wb_adr_i(  bram0_adr    ),
		      .wb_dat_o(  bram0_dat_r  ),
		      .wb_dat_i(  bram0_dat_w  ),
		      .wb_sel_i(  bram0_sel    ),
		      .wb_stb_i(  bram0_stb    ),
		      .wb_cyc_i(  bram0_cyc    ),
		      .wb_ack_o(  bram0_ack    ),
		      .wb_we_i(   bram0_we     )
		      );

   //---------------------------------------------------------------------------
   // sram0
   //---------------------------------------------------------------------------
    wb_sram16 #(
                .adr_width(  18  ),
                .latency(    `sramLATENCY   ),
                .read_latency(    `sramREAD_LATENCY  ),
                .write_latency(    `sramWRITE_LATENCY   )
                ) sram0 (
         		.clk(         clk           ),
         		.reset(       rst           ),
         		// Wishbone
         		.wb_cyc_i(    sram0_cyc     ),
         		.wb_stb_i(    sram0_stb     ),
         		.wb_we_i(     sram0_we      ),
         		.wb_adr_i(    sram0_adr     ),
         		.wb_dat_o(    sram0_dat_r   ),
         		.wb_dat_i(    sram0_dat_w   ),
         		.wb_sel_i(    sram0_sel     ),
         		.wb_ack_o(    sram0_ack     ),
         		// SRAM
         		.sram_adr(    sram_adr      ),
         		.sram_dat(    sram_dat      ),
         		.sram_be_n(   sram_be_n     ),
         		.sram_ce_n(   sram_ce_n  ),
         		.sram_oe_n(   sram_oe_n     ),
         		.sram_we_n(   sram_we_n     )
         		);

    //assign 		       sram_ce_n[1] = sram_ce_n[0];

   //---------------------------------------------------------------------------
   // sdram0
   //---------------------------------------------------------------------------
//    wb_sdram16 #(
//                .adr_width(  22  )
//                ) sdram0 (
//         		.clk(         clk           ),
//         		.clk_locked(         clk_locked           ),
//         		.reset(       rst           ),
//         		// Wishbone
//         		.wb_cyc_i(    sdram0_cyc     ),
//         		.wb_stb_i(    sdram0_stb     ),
//         		.wb_we_i(     sdram0_we      ),
//         		.wb_adr_i(    sdram0_adr     ),
//         		.wb_dat_o(    sdram0_dat_r   ),
//         		.wb_dat_i(    sdram0_dat_w   ),
//         		.wb_sel_i(    sdram0_sel     ),
//         		.wb_ack_o(    sdram0_ack     ),
//         		// SDRAM
//                        .dram_dq(     dram_dq        ),   //      Sdram Data bus 16 Bits
//                        .dram_addr(   dram_addr      ),   //      Sdram Address bus 12 Bits
//                        .dram_ldqm(   dram_ldqm      ),   //      Sdram Low-byte Data Mask 
//                        .dram_udqm(   dram_udqm      ),   //      Sdram High-byte Data Mask
//                        .dram_we_n(   dram_we_n      ),   //      Sdram Write Enable
//                        .dram_cas_n(  dram_cas_n     ),   //      Sdram Column Address Strobe
//                        .dram_ras_n(  dram_ras_n     ),   //      Sdram Row Address Strobe
//                        .dram_cs_n(   dram_cs_n      ),   //      Sdram Chip Select
//                        .dram_ba_0(   dram_ba_0      ),   //      Sdram Bank Address 0
//                        .dram_ba_1(   dram_ba_1      ),   //      Sdram Bank Address 0
//                        .dram_clk(    dram_clk       ),   //      Sdram Clock
//                        .dram_cke(    dram_cke       ),   //      Sdram Clock Enable
//                        // SDRAM secondary  ACCESS
//                        .sdr_rd(      sdr_rd         ),   // initiate read operation
//                        .sdr_wr(      sdr_wr         ),   // initiate write operation
//                        .sdr_earlyOpBegun( sdr_earlyOpBegun), // read/write op has begun (async)
//                        .sdr_opBegun( sdr_opBegun    ),   // read/write op has begun (clocked)
//                        .sdr_rdPending(sdr_rdPending ),   // true if read operation(s) are still in the pipeline
//                        .sdr_done(    sdr_done       ),   // read or write operation is done
//                        .sdr_rdDone(  sdr_rdDone     ),   // read operation is done and data is available
//                        .sdr_hAddr(   sdr_hAddr      ),   // address from host to SDRAM
//                        .sdr_hDIn(    sdr_hDIn       ),   // data from host to SDRAM
//                        .sdr_hDOut(   sdr_hDOut      ),   // data from SDRAM to host
//                        .sdr_status(  sdr_status     )    // diagnostic status of the SDRAM controller FSM         
//         		);
//
   

   //---------------------------------------------------------------------------
   // uart0
   //---------------------------------------------------------------------------

   wb_uart #(
	     .clk_freq( clk_freq        ),
	     .baud(     uart_baud_rate  )
	     ) uart0 (
		      .clk( clk ),
		      .reset( rst ),
		      //
		      .wb_adr_i( uart0_adr ),
		      .wb_dat_i( uart0_dat_w ),
		      .wb_dat_o( uart0_dat_r ),
		      .wb_stb_i( uart0_stb ),
		      .wb_cyc_i( uart0_cyc ),
		      .wb_we_i(  uart0_we ),
		      .wb_sel_i( uart0_sel ),
		      .wb_ack_o( uart0_ack ), 
		      //	.intr(       uart0_intr ),
		      .uart_rxd( uart_rxd ),
		      .uart_txd( uart_txd )
		      );

   //---------------------------------------------------------------------------
   // timer0
   //---------------------------------------------------------------------------
   wb_timer #(
	      .clk_freq(   clk_freq  )
	      ) timer0 (
			.clk(      clk          ),
			.reset(    rst          ),
			//
			.wb_adr_i( timer0_adr   ),
			.wb_dat_i( timer0_dat_w ),
			.wb_dat_o( timer0_dat_r ),
			.wb_stb_i( timer0_stb   ),
			.wb_cyc_i( timer0_cyc   ),
			.wb_we_i(  timer0_we    ),
			.wb_sel_i( timer0_sel   ),
			.wb_ack_o( timer0_ack   ), 
			.intr(     timer0_intr  )
			);



endmodule 


