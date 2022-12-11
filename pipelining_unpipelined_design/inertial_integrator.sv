module inertial_integrator (
	input clk, rst_n,
	input vld,						// integrator integrates only when vld is high
	input signed [15:0] ptch_rt,	// signed ptch_rt input that we are integrating
	input [15:0] AZ,				// input to calculate accelerometer ptch to fuse 
	output signed [15:0] ptch);		// output integrated and fused ptch 
	
	/////////////////////////////////////////////
	/////////// TEAM : UARTists /////////////////
	/////////////////////////////////////////////
	
	/* Members :-
		1. Deepa Sivaram
		2. Alisha Handa
		3. Rohit Kolapalli
		4. Yashwardhan Singh */
	
	/////////////////////////////////////////////

	// OFFSET values that change the initial reference from 0
	localparam PTCH_RT_OFFSET = 16'h0050;
	localparam AZ_OFFSET = 16'h00A0;
	
	/*ptch_int				=	ptch_rt integrating reg 
	  ptch_rt_comp			=	compensated ptch_rt value 
	  AZ_comp				= 	compensated Z axis acceleration
	  ptch_acc				=	accelerometer pitch value 
	  fusion_ptch_offset	=	leak term to make gryo angular measurement agree with accelerometer measurement
	  */
	
	logic [26:0] ptch_int;
	logic signed [15:0] ptch_rt_comp, AZ_comp;
	logic signed [25:0] ptch_acc_product;
	logic signed [15:0] ptch_acc;
	logic signed [11:0] fusion_ptch_offset;
	
	// compensating ptch_rt and AZ to bring them to reference 0
	assign ptch_rt_comp = ptch_rt - $signed(PTCH_RT_OFFSET) ;
	assign AZ_comp = AZ - AZ_OFFSET ;
	
	// calculation of accelerometer pitch measurement 
	assign ptch_acc_product = AZ_comp * $signed(327) ;
	// pitch angle calculation from accelerometer
	assign ptch_acc = {{3{ptch_acc_product[25]}}, ptch_acc_product[25:13]} ;
	
	assign fusion_ptch_offset = (ptch_acc > ptch) ? 12'h400 : 12'hC00;
	
	assign ptch = ptch_int[26:11];
	
	// integrator should integrate whenever vld goes high so add it in event list 
	always_ff @ (posedge clk, negedge rst_n) begin
		if (!rst_n)
			ptch_int <= 0;
		else if (vld)
			ptch_int <= ptch_int - { {11{ptch_rt_comp[15]}}, ptch_rt_comp} + { {15{fusion_ptch_offset[11]}}, fusion_ptch_offset} ;
	end	
	
	
endmodule
