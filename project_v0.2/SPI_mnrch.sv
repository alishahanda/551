module SPI_mnrch(clk, rst_n, wrt, wt_data, done, rd_data, SS_n, SCLK, MOSI, MISO);
input clk, rst_n;
input wrt;
input MISO;
input [15:0] wt_data;
output logic SS_n;
output SCLK, MOSI;
output logic done;
output [15:0] rd_data;

logic [3:0] bit_cnt;
logic [3:0] SCLK_div;
logic ld_SCLK;
logic done15, set_done;
logic init, shft, smpl;
logic MISO_smpl;
logic [15:0] shft_reg;
logic shft_im;

typedef enum logic [1:0] {IDLE, FRNT_PRCH, TRANSFER, BACK_PRCH} state_t;
state_t state, nxt_state;

//bit counter to keep track of number of bits transmitted
always_ff@(posedge clk) begin
	if (init)
		bit_cnt <= 4'b0000;
	else if (shft)
		bit_cnt <= bit_cnt + 1;
end 

//Done shifting 15 times when bit counter is full (that is all 1's )
assign done15 = &bit_cnt;

//Generate SCLK from clk
always_ff@(posedge clk) begin
	if (ld_SCLK)
		SCLK_div <= 4'b1011; //If ld_SCLK, load SCLK_div with 1011 so that SCLK is held high
	else 
		SCLK_div <= SCLK_div + 1;
end 

assign SCLK = SCLK_div[3]; //SCLK is MSB of SCLK_div

//assign sample and shft_im signals
assign smpl = (SCLK_div == 4'b0111) ? 1'b1 : 1'b0; //sample on rising edge of SCLK
assign shft_im = (SCLK_div == 4'b1111) ? 1'b1 : 1'b0; //shift on falling edge of SCLK

//16-bit shift reg
always_ff@(posedge clk) begin
	if(smpl)
		MISO_smpl <= MISO;
end

always @(posedge clk) begin
	if (init)
		shft_reg <= wt_data[15:0];
	else if (shft)
		shft_reg <= {shft_reg[14:0], MISO_smpl};
end

assign MOSI = shft_reg[15]; //MOSI is MSB of shft_reg
assign rd_data = shft_reg; //rd_data is essentially the data stored in the shift register

//FSM to generate set_done, shft, ld_SCLK, init signals
always_ff@(posedge clk, negedge rst_n) begin	
	if(!rst_n)
		state <= IDLE;
	else	
		state <= nxt_state;
end

always_comb begin
	//initialize SM outputs and nxt_state value
	shft = 0;
	ld_SCLK = 1;
	init = 0;
	set_done = 0;
	nxt_state = IDLE;
	
	case (state)
		IDLE: if (wrt) begin //if we receive a wrt signal, transition to FRNT_PRCH state
				nxt_state = FRNT_PRCH;
				init = 1;
				ld_SCLK = 0;
			end
		
		FRNT_PRCH: if (SCLK_div == 4'b1111) begin
				nxt_state = TRANSFER;
				ld_SCLK = 0;
			end else begin
				nxt_state = FRNT_PRCH; //in FRNT_PRCH state, we do not shift so shft = 0 (default initialized value)
				ld_SCLK = 0;
			end
		
		TRANSFER: if(done15) begin
				nxt_state = BACK_PRCH; //when we have finished shifting 15 times we transition to BACK_PRCH
				ld_SCLK = 0;
			end else begin
				nxt_state = TRANSFER;
				shft = shft_im; //In TRANSFER state, shft_im determines when we shift (i.e. at every falling edge of SCLK)
				ld_SCLK = 0;
			end
		
		BACK_PRCH: if (SCLK_div == 4'b1111) begin //when SCLK_div = 1111, falling edge is imminent (i.e. SCLK will have a falling edge in the next cycle)
				//Need to prevent negedge of SCLK and need to shift here one final time
				nxt_state = IDLE;   
				ld_SCLK = 1; //Assert ld_SCLK = 1 to hold SCLK high and prevent negedege of SCLK from occurring
				set_done = 1; //Assert set_done signal
				shft = 1; //Perform one last shift where the falling edge of SCLK was supposed to occur
			end else begin
				nxt_state = BACK_PRCH;
				ld_SCLK = 0;
			end
		
		default: nxt_state = IDLE;
	endcase

end

//Flop SS_n signal to prevent glitches
always_ff@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		SS_n <= 1'b1; //preset
	else if (init)
		SS_n <= 1'b0;
	else if (set_done) 
		SS_n <= 1'b1;		
end

//Flop done signal to prevent glitches
always_ff@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		done <= 1'b0;
	else if (init)
		done <= 1'b0;
	else if (set_done)
		done <= 1'b1;		
end

endmodule
