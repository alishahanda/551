package tb_tasks;

task automatic initialize;
ref clk, RST_n, send_cmd;
ref [7:0] cmd; 
ref signed [15:0] rider_lean;
ref [11:0] ld_cell_lft, ld_cell_rght, steerPot, batt;
ref OVR_I_lft, OVR_I_rght;
begin
	RST_n = 0;
	clk = 0;
	send_cmd = 0;
	cmd = 'b0;
	rider_lean = 'b0;
	ld_cell_lft = 'b0;
	ld_cell_rght = 'b0;
	steerPot = 12'h800;
	batt = 'b0;
	OVR_I_lft = 0;
	OVR_I_rght = 0;
	@(posedge clk);
	@(negedge clk);
	RST_n = 1;
end
endtask

task automatic sendCmd;
input [7:0] desired_cmd;
ref [7:0] cmd;
ref send_cmd, clk;
begin
	cmd = desired_cmd;
	@(negedge clk);
	send_cmd = 1;
	repeat (2) @(negedge clk);
	send_cmd = 0;
end
endtask

task automatic applyInputs; 
input [11:0] lft_ld_val, rght_ld_val, steer_pot_val, batt_val;
input signed [15:0] rider_lean_val;
input ovr_i_lft_val, ovr_i_rght_val;
ref clk;
ref [11:0] ld_cell_lft;
ref [11:0] ld_cell_rght;
ref [11:0] steerPot;
ref [11:0] batt;
ref signed [15:0] rider_lean;
ref OVR_I_lft;
ref OVR_I_rght;

begin
	@(negedge clk);
	ld_cell_lft = lft_ld_val; 
	ld_cell_rght = rght_ld_val; 
	steerPot = steer_pot_val; 
	batt = batt_val;
	rider_lean = rider_lean_val;
	OVR_I_lft = ovr_i_lft_val;
	OVR_I_rght = ovr_i_rght_val;
end 
endtask

endpackage