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
//// task to check steer_pot functionality //////////////////
task automatic self_check_steer_pot 
input logic [11:0] steer_pot_val;
ref [12:0] lft_spd;
ref [12:0] rght_spd;

	begin 
		steer_pot = steer_pot_val; 
		repeat (5); 
		
		if (steer_pot_val < 12'h800 && lft_spd < rght_spd) $display("check passed...turning left");
		else $display("ERROR..... not turning left"); 
		
		if (steer_pot_val > 12'h800 && lft_spd > rght_spd) $display("check passed......turning right");
		else $display("ERROR..... not turning right"); 
		
		if (steer_pot_val == 12'h800 && lft_spd == rght_spd) $display("check passed.......going straight");
		else $display("ERROR..... going straight"); 
	end 
	endtask 
	
//////task to check theta platform ///////
task automatic self_check_theta_plat
input logic [13:0] rider_lean_val; 
ref [13:0] rider_lean; 
ref [15:0] theta_platform; 

	rider_lean = rider_lean_val;
	
	fork 
		begin: timeout
			repeat (1000000) @(negedge clk); 
			$display("ERROR... theta platform doesnt become zero"); 
		end
		begin 
			@(negedge theta_platform); 
			disable timeout; 
			$display("YAY, theta platform works"); 
		end
	join
endtask

endpackage
