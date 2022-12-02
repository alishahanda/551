/*TEAM : UARTists 
MEMBERS :-  Deepa Sivaram
			Alisha Handa
			Rohit Kolapalli
			Yashwardhan Singh*/

module mtr_drv_tb();
	logic clk,rst_n;
	logic [11:0] lft_spd,rght_spd;
	logic OVR_I_lft,OVR_I_rght;
	logic PWM1_lft,PWM1_rght,PWM2_lft,PWM2_rght;
	logic [7:0] LED;
	
	// instantiate DUT
	
	mtr_drv iDUT(.clk(clk), .rst_n(rst_n), .lft_spd(lft_spd), .rght_spd(rght_spd),
					.OVR_I_lft(OVR_I_lft), .OVR_I_rght(OVR_I_rght), .PWM1_lft(PWM1_lft), 
					.PWM2_lft(PWM2_lft), .PWM2_rght(PWM2_rght), .LED(LED));
									
	initial begin
		clk = 0;
		rst_n = 0;
		OVR_I_lft = 0;
		OVR_I_rght = 0;
		@(negedge clk);
		rst_n = 1;
		
		// Generating 128 or more OVR_I_lft pulses in blanking period
		$display("Generating 128 or more OVR_I_lft pulses WITHIN blanking period over 140 PWM periods.");
		repeat(140)	begin	
			repeat(50)@(posedge clk);
			OVR_I_lft = 1'b1;
			repeat(2)@(posedge clk);
			OVR_I_lft = 1'b0;
			@(posedge iDUT.PWM_synch);
		end
		// Checking if shutdown signal is not asserted. Expected outcome is for shutdown to not assert
		if(iDUT.OVR_I_shtdwn) begin
			$display("ERROR: SHUTDOWN signal should be low. It is asserted. Over Current signal occured 128 or more times");
			$display("====> inside BLANKING PERIOD. SEGWAY shouldn't shutdown because of this. Please check your verilog\n");
			$stop();
		end else
			$display("TEST 1 : PASS . When Over Current occurs 128 or more times in BLANKING PERIOD, SHUTDOWN is not asserted\n");
		
		// Generating 128 or more OVR_I_lft pulses outside the blanking region over 140 PWM periods
		$display("Generating 128 or more OVR_I_lft pulses OUTSIDE the blanking region over 140 PWM periods.");
		repeat(140) begin
			@(posedge iDUT.OVR_I_blank_n);
			repeat(5)@(negedge clk);
			OVR_I_lft = 1'b1;
			repeat(2)@(posedge clk);
			OVR_I_lft = 1'b0;
		end
		// Checking if shutdown signal is asserted because of consecutive 128 or more OVR_I_* pulses
		if(!iDUT.OVR_I_shtdwn) begin
			$display("ERROR: SHUTDOWN signal should be ASSERTED. It is low. Over Current signal occured 128 or more times");
			$display("====> outside BLANKING PERIOD. SEGWAY should SHUTDOWN because of this. Please check your verilog\n");
			$stop();
		end
		else
			$display("TEST 2 : PASS . When Over Current occurs 128 or more times outside BLANKING PERIOD, SHUTDOWN is asserted\n");
		
		/*reset the circuit to test for other conditions because 
		shutdown is high. SHUTDOWN goes low only on reset*/
		$display("Asserting rst_n as shutdown is high now and we want to make to low to test other conditions\n");
		rst_n = 0;
		repeat(2)@(negedge clk);
		rst_n = 1;
		
		/*Generating 70 (<128 ofc :p) pulses of OVR_I_rght
		   OUTSIDE blanking period over a period of 140 PWM periods*/
		$display("Generating 70 pulses OVR_I_rght pulses OUTSIDE the blanking region over 140 PWM periods.");
		OVR_I_lft = 0;
		repeat(70) begin
			@(posedge iDUT.OVR_I_blank_n);
			repeat(5)@(negedge clk);
			OVR_I_rght = 1'b1;
			repeat(2)@(posedge clk);
			OVR_I_rght = 1'b0;
		end
		repeat(70)@(posedge iDUT.OVR_I_blank_n);
		repeat(5)@(negedge clk);
		
		/*Checking if SHUTDOWN signal is asserted. Expected outcome is for it to be de-asserted.*/
		if(iDUT.OVR_I_shtdwn) begin
			$display("ERROR: SHUTDOWN signal should be low. It is asserted. Over Current signal occured 128 or less times");
			$display("====> OUTSIDE BLANKING PERIOD. SEGWAY shouldn't shutdown because of this. Please check your verilog\n");
			$stop();
		end else
			$display("TEST 3 : PASS . When Over Current occurs 128 or less times OUTSIDE BLANKING PERIOD, SHUTDOWN should be low\n");
		
		/* Generating 70 pulses of OVR_I_lft followed by 70 pulses of OVR_I_rght
		OUTSIDE BLANKING period over a time of 140 PWM periods. Expected Outcome is
		SHUTDOWN is asserted */
		$display("Generating 70 pulses OVR_I_lft pulses followed by 70 pulses of OVR_I_rght OUTSIDE the blanking region over 140 PWM periods.");
		// 70 pulses of OVR_I_lft 
		repeat(70) begin
			@(posedge iDUT.OVR_I_blank_n);
			repeat(5)@(negedge clk);
			OVR_I_lft = 1'b1;
			repeat(2)@(posedge clk);
			OVR_I_lft = 1'b0;
		end
		// 70 pulses of OVR_I_rght
		repeat(70) begin
			@(posedge iDUT.OVR_I_blank_n);
			repeat(5)@(negedge clk);
			OVR_I_rght = 1'b1;
			repeat(2)@(posedge clk);
			OVR_I_rght = 1'b0;
		end
		// Checking if SHUTDOWN signal is asserted. Expected outcome is it should be asserted.
		if(!iDUT.OVR_I_shtdwn) begin
			$display("ERROR: SHUTDOWN signal should be ASSERTED. It is low. Over Current signal occured 128 or more times");
			$display("====> outside BLANKING PERIOD. SEGWAY should SHUTDOWN because of this. Please check your verilog\n");
			$stop();
		end
		else begin
			$display("TEST 4 : PASS . When Over Current occurs 128 or more times outside BLANKING PERIOD, SHUTDOWN is asserted\n");
			$stop();
		end
		
	end
	
	always 
	#5 clk = ~clk;
	
	endmodule
		