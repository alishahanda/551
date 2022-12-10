module Segway_tb();

import tb_tasks::*;
			
//// Interconnects to DUT/support defined as type wire /////
wire SS_n,SCLK,MOSI,MISO,INT;				// to inertial sensor
wire A2D_SS_n,A2D_SCLK,A2D_MOSI,A2D_MISO;	// to A2D converter
wire RX_TX;
wire PWM1_rght, PWM2_rght, PWM1_lft, PWM2_lft;
wire piezo,piezo_n;
wire cmd_sent;
wire rst_n;					// synchronized global reset

////// Stimulus is declared as type reg ///////
logic clk, RST_n;
reg [7:0] cmd;				// command host is sending to DUT
reg send_cmd;				// asserted to initiate sending of command
reg signed [15:0] rider_lean;
reg [11:0] ld_cell_lft, ld_cell_rght,steerPot,batt;	// A2D values
reg OVR_I_lft, OVR_I_rght;

///// Internal registers for testing purposes??? /////////
logic [39:0] spd_mem; 

////////////////////////////////////////////////////////////////
// Instantiate Physical Model of Segway with Inertial sensor //
//////////////////////////////////////////////////////////////	
SegwayModel iPHYS(.clk(clk),.RST_n(RST_n),.SS_n(SS_n),.SCLK(SCLK),
                  .MISO(MISO),.MOSI(MOSI),.INT(INT),.PWM1_lft(PWM1_lft),
				  .PWM2_lft(PWM2_lft),.PWM1_rght(PWM1_rght),
				  .PWM2_rght(PWM2_rght),.rider_lean(rider_lean));				  

/////////////////////////////////////////////////////////
// Instantiate Model of A2D for load cell and battery //
///////////////////////////////////////////////////////
ADC128S_FC iA2D(.clk(clk),.rst_n(RST_n),.SS_n(A2D_SS_n),.SCLK(A2D_SCLK),
             .MISO(A2D_MISO),.MOSI(A2D_MOSI),.ld_cell_lft(ld_cell_lft),.ld_cell_rght(ld_cell_rght),
			 .steerPot(steerPot),.batt(batt));			
	 
////// Instantiate DUT ////////
Segway iDUT(.clk(clk),.RST_n(RST_n),.INERT_SS_n(SS_n),.INERT_MOSI(MOSI),
            .INERT_SCLK(SCLK),.INERT_MISO(MISO),.INERT_INT(INT),.A2D_SS_n(A2D_SS_n),
			.A2D_MOSI(A2D_MOSI),.A2D_SCLK(A2D_SCLK),.A2D_MISO(A2D_MISO),
			.PWM1_lft(PWM1_lft),.PWM2_lft(PWM2_lft),.PWM1_rght(PWM1_rght),
			.PWM2_rght(PWM2_rght),.OVR_I_lft(OVR_I_lft),.OVR_I_rght(OVR_I_rght),
			.piezo_n(piezo_n),.piezo(piezo),.RX(RX_TX));

//// Instantiate UART_tx (mimics command from BLE module) //////
UART_tx iTX(.clk(clk),.rst_n(rst_n),.TX(RX_TX),.trmt(send_cmd),.tx_data(cmd),.tx_done(cmd_sent));

/////////////////////////////////////
// Instantiate reset synchronizer //
///////////////////////////////////
rst_synch iRST(.clk(clk),.RST_n(RST_n),.rst_n(rst_n));

localparam g = 8'h67; //go command
localparam s = 8'h73; //stop command

initial begin
  
  //////////////////////////////////
  // Initialize all inputs
  //////////////////////////////////
  initialize(clk, RST_n, send_cmd, cmd, rider_lean, ld_cell_lft, ld_cell_rght, steerPot, batt, OVR_I_lft, OVR_I_rght); //initialize inputs, assert and de-assert RST_n

 ///////////////////////////////////////////
  // Testing of auth blk
  ///////////////////////////////////////////

   @(negedge clk);
  sendCmd(g, cmd, send_cmd, clk); //sending go signal

  applyInputs(12'h400, 12'h400, 12'h800, 12'hFFF, 16'h0000, 'b0, 'b0, clk, ld_cell_lft, ld_cell_rght, steerPot, batt, rider_lean, OVR_I_lft, OVR_I_rght); //rider on	
  check_pwr_up(iDUT.iAuth.pwr_up, clk, cmd, iDUT.iAuth.rider_off, iDUT.iAuth.rx_rdy);
  /*sendCmd(s, cmd, send_cmd, clk); //sending stop signal
  //however rider is still on.. shouldn't be powering off...
  check_pwr_up(iDUT.iAuth.pwr_up, clk, cmd, iDUT.iAuth.rider_off, iDUT.iAuth.rx_rdy);
  //Now rider steps off
  applyInputs(12'h000, 12'h000, 12'h800, 12'hFFF, 16'h0000, 'b0, 'b0, clk, ld_cell_lft, ld_cell_rght, steerPot, batt, rider_lean, OVR_I_lft, OVR_I_rght); //rider off
  check_pwr_up(iDUT.iAuth.pwr_up, clk, cmd, iDUT.iAuth.rider_off, iDUT.iAuth.rx_rdy);*/




  ////////////////////////////////////////////
  // Testing of theta platform
  ///////////////////////////////////////////
  @(negedge clk);
  sendCmd(g, cmd, send_cmd, clk); //sending go signal
  repeat (800000) @(posedge clk); //need to wait couple hundred thousand clock cycles between sending go signal and applying rider lean
  applyInputs(12'h400, 12'h400, 12'h800, 12'hFFF, 16'h0FFF, 'b0, 'b0, clk, ld_cell_lft, ld_cell_rght, steerPot, batt, rider_lean, OVR_I_lft, OVR_I_rght); //step function on rider_lean, rider_lean initially 0, now applying FFF
  check_theta_plat(iPHYS.theta_platform, clk);
  applyInputs(12'h400, 12'h400, 12'h800, 12'hFFF, 16'h0000, 'b0, 'b0, clk, ld_cell_lft, ld_cell_rght, steerPot, batt, rider_lean, OVR_I_lft, OVR_I_rght); //rider_lean abruptly changes to 000
  check_theta_plat(iPHYS.theta_platform, clk);

 /* ///////////////////////////////////////////
  // Testing of auth blk
  ///////////////////////////////////////////
  applyInputs(12'h400, 12'h400, 12'h800, 12'hFFF, 16'h0000, 'b0, 'b0, clk, ld_cell_lft, ld_cell_rght, steerPot, batt, rider_lean, OVR_I_lft, OVR_I_rght); //rider on	
  check_pwr_up(iDUT.iAuth.pwr_up, clk, cmd, iDUT.iAuth.rider_off, iDUT.iAuth.rx_rdy);
  sendCmd(s, cmd, send_cmd, clk); //sending stop signal
  //however rider is still on.. shouldn't be powering off...
  check_pwr_up(iDUT.iAuth.pwr_up, clk, cmd, iDUT.iAuth.rider_off, iDUT.iAuth.rx_rdy);
  //Now rider steps off
  applyInputs(12'h000, 12'h000, 12'h800, 12'hFFF, 16'h0000, 'b0, 'b0, clk, ld_cell_lft, ld_cell_rght, steerPot, batt, rider_lean, OVR_I_lft, OVR_I_rght); //rider off
  check_pwr_up(iDUT.iAuth.pwr_up, clk, cmd, iDUT.iAuth.rider_off, iDUT.iAuth.rx_rdy);*/

  ////////////////////////////////////////////
  // Testing to see if lft_spd, rght_spd 
  // varies with changes in steer_pot
  ///////////////////////////////////////////
  applyInputs(12'h400, 12'h400, 12'h800, 12'hFFF, 16'h0000, 'b0, 'b0, clk, ld_cell_lft, ld_cell_rght, steerPot, batt, rider_lean, OVR_I_lft, OVR_I_rght); //apply steerPot val of 800
  repeat(40000) @(posedge clk);
  check_steer_pot_lft_spd_rght_spd(iDUT.iBAL.lft_spd, iDUT.iBAL.rght_spd, steerPot, clk); 
  //repeat(40000) @(posedge clk);
  applyInputs(12'h400, 12'h400, 12'hFFF, 12'hFFF, 16'h0000, 'b0, 'b0, clk, ld_cell_lft, ld_cell_rght, steerPot, batt, rider_lean, OVR_I_lft, OVR_I_rght); //apply steerPot val of FFF
  repeat(40000) @(posedge clk);
  check_steer_pot_lft_spd_rght_spd(iDUT.iBAL.lft_spd, iDUT.iBAL.rght_spd, steerPot, clk); 
  //repeat(8000000) @(posedge clk);
  applyInputs(12'h400, 12'h400, 12'h200, 12'hFFF, 16'h0000, 'b0, 'b0, clk, ld_cell_lft, ld_cell_rght, steerPot, batt, rider_lean, OVR_I_lft, OVR_I_rght); //apply steerPot val of 200
  repeat(40000) @(posedge clk);
  check_steer_pot_lft_spd_rght_spd(iDUT.iBAL.lft_spd, iDUT.iBAL.rght_spd, steerPot, clk); 
  //repeat(8000000) @(posedge clk);
  
   
  /////////////////////////////////////////
  // Testing of steer_en and steer_en SM
  /////////////////////////////////////////
  
  
  applyInputs(12'd1024, 12'd1024, 12'h800, 12'hFFF, 16'h0FFF, 'b0, 'b0, clk, ld_cell_lft, ld_cell_rght, steerPot, batt, rider_lean, OVR_I_lft, OVR_I_rght);
  repeat (40000) @(posedge clk);
  check_en_steer(RST_n,iDUT.en_steer,iDUT.rider_off);
  applyInputs(12'd600, 12'd16, 12'h800, 12'hFFF, 16'h0FFF, 'b0, 'b0, clk, ld_cell_lft, ld_cell_rght, steerPot, batt, rider_lean, OVR_I_lft, OVR_I_rght);
  repeat (40000) @(posedge clk);
  check_en_steer(RST_n,iDUT.en_steer,iDUT.rider_off);
  repeat (40000) @(posedge clk);
  applyInputs(12'd128, 12'd128, 12'h800, 12'hFFF, 16'h0000, 'b0, 'b0, clk, ld_cell_lft, ld_cell_rght, steerPot, batt, rider_lean, OVR_I_lft, OVR_I_rght);
  repeat (40000) @(posedge clk);
  check_en_steer(RST_n,iDUT.en_steer,iDUT.rider_off);
  applyInputs(12'd1024, 12'd1024, 12'h800, 12'hFFF, 16'h0FFF, 'b0, 'b0, clk, ld_cell_lft, ld_cell_rght, steerPot, batt, rider_lean, OVR_I_lft, OVR_I_rght);
  repeat (80000) @(posedge clk);
  check_en_steer(RST_n,iDUT.en_steer,iDUT.rider_off);
  applyInputs(12'd128, 12'd128, 12'h400, 12'hFFF, 16'h0FFF, 'b0, 'b0, clk, ld_cell_lft, ld_cell_rght, steerPot, batt, rider_lean, OVR_I_lft, OVR_I_rght);
  repeat (80000) @(posedge clk);
  check_en_steer(RST_n,iDUT.en_steer,iDUT.rider_off);
  /*applyInputs(12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 16'h0FFF, 'b0, 'b0, clk, ld_cell_lft, ld_cell_rght, steerPot, batt, rider_lean, OVR_I_lft, OVR_I_rght);
  repeat (40000) @(posedge clk);
  check_en_steer(RST_n,iDUT.en_steer,iDUT.rider_off);*/

  ////////////////////////////////////////
  // Testing of lft_spd, rght_spd with 
  // change in rider_lean 
  ////////////////////////////////////////
  applyInputs(12'd1024, 12'd1024, 12'h800, 12'hFFF, 16'h0000, 'b0, 'b0, clk, ld_cell_lft, ld_cell_rght, steerPot, batt, rider_lean, OVR_I_lft, OVR_I_rght);
  repeat (40000) @(posedge clk);
  store_lft_rght_spd_mem(spd_mem,iDUT.iBAL.lft_spd,iDUT.iBAL.rght_spd,rider_lean);
  applyInputs(12'd1024, 12'd1024, 12'h800, 12'hFFF, 16'h0A00, 'b0, 'b0, clk, ld_cell_lft, ld_cell_rght, steerPot, batt, rider_lean, OVR_I_lft, OVR_I_rght);
  repeat (40000) @(posedge clk);
  check_speed_change(iDUT.iBAL.lft_spd,iDUT.iBAL.rght_spd,rider_lean,spd_mem); 
  store_lft_rght_spd_mem(spd_mem,iDUT.iBAL.lft_spd,iDUT.iBAL.rght_spd,rider_lean);
  applyInputs(12'd1024, 12'd1024, 12'h800, 12'hFFF, 16'h0FFF, 'b0, 'b0, clk, ld_cell_lft, ld_cell_rght, steerPot, batt, rider_lean, OVR_I_lft, OVR_I_rght);
  repeat (40000) @(posedge clk);
  check_speed_change(iDUT.iBAL.lft_spd,iDUT.iBAL.rght_spd,rider_lean,spd_mem); 
  store_lft_rght_spd_mem(spd_mem,iDUT.iBAL.lft_spd,iDUT.iBAL.rght_spd,rider_lean);
  applyInputs(12'd1024, 12'd1024, 12'h800, 12'hFFF, 16'hEAAA, 'b0, 'b0, clk, ld_cell_lft, ld_cell_rght, steerPot, batt, rider_lean, OVR_I_lft, OVR_I_rght);
  repeat (40000) @(posedge clk);
  check_speed_change(iDUT.iBAL.lft_spd,iDUT.iBAL.rght_spd,rider_lean,spd_mem); 


  sendCmd(s, cmd, send_cmd, clk); //sending stop signal
  check_pwr_up(iDUT.iAuth.pwr_up, clk, cmd, iDUT.iAuth.rider_off, iDUT.iAuth.rx_rdy);

  
 


  $stop();
end

always
  #10 clk = ~clk;

endmodule	
