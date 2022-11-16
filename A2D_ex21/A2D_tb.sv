module A2D_tb();

logic clk, rst_n;
logic nxt;
logic [11:0] lft_ld, rght_ld, batt, steer_pot;
logic MISO, SS_n, SCLK, MOSI;

//Instantiate DUT
A2D_Intf iDUT(.clk(clk), .rst_n(rst_n), .nxt(nxt), .lft_ld(lft_ld), .rght_ld(rght_ld), .batt(batt), .steer_pot(steer_pot), .MISO(MISO), .MOSI(MOSI), .SCLK(SCLK), .SS_n(SS_n));
ADC128S iADC128S(.clk(clk), .rst_n(rst_n), .SS_n(SS_n), .SCLK(SCLK), .MISO(MISO), .MOSI(MOSI));

initial begin
	clk = 0;
	rst_n = 0;
	nxt = 0;
	
	@(posedge clk);
	@(negedge clk);
	rst_n = 1;
	
	nxt = 1;
	@(posedge iDUT.done);
	if(iDUT.state !== 2'b10) begin
		$display("Error: Should be in IDLE_CYCLE state");
		$stop();
	end
	@(posedge iDUT.done);
	if(lft_ld !== 12'hC00) begin
		$display("Error: lft_ld value (%h) is incorrect.. should be 0xC00");
		$stop();
	end

end 

always 
	#2 clk <= ~clk;

endmodule