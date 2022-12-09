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
task automatic self_check_steer_pot;
//input logic [11:0] steer_pot_val;
ref signed [11:0] lft_spd;
ref signed [11:0] rght_spd;
ref [11:0] steerPot;
ref clk; 

	begin 
		//steerPot = steer_pot_val; 
		//repeat (5); 
		repeat (100) @(negedge clk);
		if (steerPot < 12'h800)
			begin 
				if(lft_spd < rght_spd) $display("YAY...check passed...turning left");
				else $display("ERROR..... not turning left"); 
			end
		
		if (steerPot > 12'h800) 
			begin
				if(lft_spd > rght_spd) $display("YAY...check passed......turning right");
				else $display("ERROR..... not turning right"); 
			end
		if (steerPot == 12'h800)
			begin 
				if (lft_spd == rght_spd) $display("YAY...check passed.......going straight");
				else $display("ERROR..... going straight"); 
			end
			
	end 
	endtask 
	
//////task to check theta platform ///////
task automatic self_check_theta_plat;
//input logic signed [15:0] rider_lean_val; 
ref signed [15:0] rider_lean; 
ref signed[15:0] theta_platform; 
ref clk; 
//	rider_lean = rider_lean_val;
	
	fork 
		begin: timeout
			repeat (1000000) @(negedge clk); 
			$display("ERROR... theta platform doesnt behave as intended");
			$stop();
		end
		begin 
			if (theta_platform >16'hff01  || theta_platform < 16'h00ff ) begin
				disable timeout; 
				$display("YAY, theta platform works"); 
			end
		end
	join
endtask
// Adding task for Auth blk test
task automatic check_pwr_up;

ref pwr_up;
ref clk;
ref RST_n;
ref [7:0] cmd;
ref rider_off;
ref rx_rdy;

begin
	@(posedge rx_rdy);
	if(cmd == g) begin
		repeat(2)@(negedge clk);
		if(pwr_up == 1)
			$display("The Segway has received a GO signal and is pwred up\n");
		else begin
			$display("The Segway is not yet pwred up\n");
			$stop();
		end
	end
	else if(cmd == s) begin
		repeat(2)@(negedge clk);
		if(rider_off == 1) begin
			if(pwr_up == 0)
				$display("The Segway has powered off\n");
			else begin
				$display("The Segway should have powered down\n");
				$stop();
			end
		end
	end
	else
		$display("Wrong cmd sent \n");
end
endtask
endpackage
 
