package tb_tasks;

///////////////////////////////////////////////////////
// Task to initialize all signals to known default value
//////////////////////////////////////////////////////
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

///////////////////////////////////
// Task to send 'g' or 's' command 
///////////////////////////////////
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

//////////////////////////////
// Task to apply Segway inputs
//////////////////////////////
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

//////////////////////////////////////////////////////////
// Task to test auth_blk and to check if Segway powers up
//////////////////////////////////////////////////////////
task automatic check_pwr_up;

ref pwr_up;
ref clk;
ref [7:0] cmd;
ref rider_off;
ref rx_rdy;

begin
	@(posedge rx_rdy);
	if(cmd === 8'h67) begin
		repeat(2)@(negedge clk);
		if(pwr_up)
			$display("Test_AuthBlk: The Segway has received a GO signal and is powered up\n");
		else begin
			$display("ERROR: Segway should be powered up by now...\n");
			$stop();
		end
	end
	else if(cmd === 8'h73) begin
		repeat(2)@(negedge clk);
		$display("Stop cmd is sent");
		if(rider_off) begin
			if(~pwr_up)
				$display("Test_AuthBlk: The Segway has powered off\n");
			else begin
				$display("ERROR: The Segway should have powered down...\n");
				$stop();
			end
		end else begin
			if(~pwr_up) begin
				$display("ERROR: The Segway should not have powered down...\n");
				$display("ERROR: Need to wait for rider to step off..");
				$stop();
			end

			else $display("Segway not powered down, behaving as intended YAY");

		end
	end else
		$display("ERROR: Incorrect cmd sent! \n");
end
endtask

/////////////////////////////////////
// Task to check theta platform
/////////////////////////////////////
task automatic check_theta_plat;
ref signed [15:0] theta_platform; 
ref clk; 
	fork 
		begin: timeout
			repeat (10000000) @(negedge clk); 
			$display("ERROR: theta platform should converge to zero..");
			$stop();
		end
		begin 
			if (theta_platform > $signed(16'hff01) && theta_platform < 16'd512 ) begin
				disable timeout; 
				$display("Test_ThetaPlatform: YAY, theta platform works"); 
			end
		end
	join
endtask


//////////////////////////
// Task to check steer_en
//////////////////////////
task automatic check_en_steer; // checking for all state transitions of en_steer block based on en_steer and rider off signals. 

ref RST_n;
ref en_steer;
ref rider_off;

begin
	if (!en_steer && rider_off) begin
		$display("en_steer = %b \t \& rider_off = %b", en_steer, rider_off);
		$display("STEERING ENABLE system should be in INIT state..  Waiting for the rider to step on the Segway\n");
	end else if (!en_steer && !rider_off) begin
		$display("en_steer = %b \t \& rider_off = %b", en_steer, rider_off);
		$display("STEERING ENABLE system should be in RIDER_WAIT_1p3s. Waiting for the rider to be on the Segway for more than 1.3 sec\n");
	end else if (en_steer && !rider_off) begin
		$display("en_steer = %b \t \& rider_off = %b", en_steer, rider_off);
		$display("STEERING ENABLE system should be in EN_STEER. Rider was on the segway for more than 1.3 sec. Hence the Segway can start\n");
	end else if (!RST_n) begin
		$display("en_steer = %b \t \& rider_off = %b", en_steer, rider_off);
		$display("STEERING ENABLE system has been reset and should be in INIT state");
	end
end
endtask

//////////////////////////////////////////////
// Task to check changes in lft_spd, rght_spd
// on varying steer_pot
/////////////////////////////////////////////
task automatic check_steer_pot_lft_spd_rght_spd;
ref signed [11:0] lft_spd;
ref signed [11:0] rght_spd;
ref [11:0] steerPot;
ref clk; 

begin 
	repeat (100) @(negedge clk);
	if (steerPot < 12'h800) begin
		if(lft_spd < rght_spd) $display("YAY...check passed...turning left");
		else $display("ERROR..... not turning left"); 
	end
	
	if (steerPot > 12'h800) begin
		if(lft_spd > rght_spd) $display("YAY...check passed......turning right");
		else $display("ERROR..... not turning right"); 
	end

	if (steerPot === 12'h800) begin 
		if (lft_spd === rght_spd) $display("YAY...check passed.......going straight");
		else $display("ERROR... not going straight"); 
	end
end 
endtask 


  ////////////////////////////////////////
  // Testing of lft_spd, rght_spd with 
  // change in rider_lean 
  ////////////////////////////////////////

 task automatic check_speed_change;

	ref signed [11:0] lft_spd;
	ref signed [11:0] rght_spd;
	ref signed [15:0] rider_lean;
	ref [39:0] spd_mem;
	begin
		$display("Rider lean = %d earlier_rider_lean = %d",rider_lean, $signed(spd_mem[39:24]));
		if(rider_lean > $signed(spd_mem[39:24])) begin
			$display("The lft spd value = %d rght_spd = %d earlier_lft_spd = %d earlier_rght_spd = %d",lft_spd,rght_spd, $signed(spd_mem[11:0]), $signed(spd_mem[23:12]));
			if(lft_spd > $signed(spd_mem[11:0]) && rght_spd > $signed(spd_mem[23:12]))
				$display("Segway speed increases with increase in rider lean \n");
			else
				$display("Segway speed is not increasing with increase in rider lean\n");
		end
		else if(rider_lean < $signed(spd_mem[39:24])) begin
			$display("The lft spd value = %d rght_spd = %d earlier_lft_spd = %d earlier_rght_spd = %d",lft_spd,rght_spd, $signed(spd_mem[11:0]), $signed(spd_mem[23:12]));
			if(lft_spd < $signed(spd_mem[11:0]) && rght_spd < $signed(spd_mem[23:12]))
				$display("Segway speed decreases with decrease in rider lean \n");
			else
				$display("Segway speed is not decreasing with decrease in rider lean\n");

		end

	end
	endtask
/////////////////////////////////////////////////
////////Store task for the spd test//////////////	
/////////////////////////////////////////////////	
	
task automatic store_lft_rght_spd_mem;
   ref [39:0] spd_mem;
    ref signed [11:0] lft_spd;
	ref signed [11:0] rght_spd;
    ref signed [15:0] rider_lean;
    begin
        spd_mem = {rider_lean,rght_spd,lft_spd};
    end
endtask



endpackage
