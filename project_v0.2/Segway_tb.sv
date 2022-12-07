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
logic signed [15:0] rider_lean;
logic [11:0] ld_cell_lft, ld_cell_rght,steerPot,batt;	// A2D values
reg OVR_I_lft, OVR_I_rght;

///// Internal registers for testing purposes??? /////////


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

localparam g = 8'h67;

initial begin
  /// Your magic goes here ///
  initialize(clk, RST_n, send_cmd, cmd, rider_lean, ld_cell_lft, ld_cell_rght, steerPot, batt, OVR_I_lft, OVR_I_rght); //initialize inputs, assert and de-assert RST_n
  @(negedge clk);
  sendCmd(g, cmd, send_cmd, clk);
  repeat (1000000) @(posedge clk); 
  applyInputs(12'h400, 12'h400, 12'h800, 12'hFFF, 16'h0FFF, 'b0, 'b0, clk, ld_cell_lft, ld_cell_rght, steerPot, batt, rider_lean, OVR_I_lft, OVR_I_rght);
  repeat (800000) @(posedge clk);
  self_check_theta_plat (rider_lean,iPHYS.theta_platform,clk);
  applyInputs(12'h400, 12'h400, 12'h800, 12'hFFF, 16'h0000, 'b0, 'b0, clk, ld_cell_lft, ld_cell_rght, steerPot, batt, rider_lean, OVR_I_lft, OVR_I_rght);
  repeat (800000) @(posedge clk);
  self_check_theta_plat (rider_lean,iPHYS.theta_platform,clk);
  applyInputs(12'hFFF, 12'hFFF, 12'h800, 12'hFFF, 16'h0FFF, 'b0, 'b0, clk, ld_cell_lft, ld_cell_rght, steerPot, batt, rider_lean, OVR_I_lft, OVR_I_rght);
  repeat (800000) @(posedge clk);
  applyInputs(12'h400, 12'h400, 12'h400, 12'hFFF, 16'h0FFF, 'b0, 'b0, clk, ld_cell_lft, ld_cell_rght, steerPot, batt, rider_lean, OVR_I_lft, OVR_I_rght);
  repeat (800000) @(posedge clk);
  self_check_steer_pot (iDUT.lft_spd,iDUT.rght_spd,steerPot,clk);
  applyInputs(12'h400, 12'h400, 12'hE00, 12'hFFF, 16'h0FFF, 'b0, 'b0, clk, ld_cell_lft, ld_cell_rght, steerPot, batt, rider_lean, OVR_I_lft, OVR_I_rght);
  repeat (800000) @(posedge clk);
  self_check_steer_pot (iDUT.lft_spd,iDUT.rght_spd,steerPot,clk);

  //repeat (1000000000) @(posedge clk);
  self_check_theta_plat (rider_lean,iPHYS.theta_platform,clk);
  
  $stop();
  
end

always
  #10 clk = ~clk;

endmodule	
