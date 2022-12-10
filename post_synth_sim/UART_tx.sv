module UART_tx(clk, rst_n, trmt, tx_data, tx_done, TX);

input clk, rst_n, trmt;
input [7:0] tx_data;
output TX;
output logic tx_done;

logic load, shift, transmitting;
logic [3:0] bit_cnt;
logic [11:0] baud_cnt;
logic [8:0] tx_shift_reg;
logic set_done, clr_done;

typedef enum logic {IDLE, TRANSMIT} state_t;
state_t state, nxt_state;

//keep track of how many bits we've shifted
always_ff@(posedge clk) begin
	if (load)
		bit_cnt <= 'b0;
	else if (shift)
		bit_cnt <= bit_cnt + 1;
end

//count to 2604 to generate baud rate of 19200
always_ff@(posedge clk) begin	
	if (load || shift)
		baud_cnt <= 'b0;
	else if (transmitting)
		baud_cnt <= baud_cnt + 1;
end

//start shifting when baud cnt has reached 2604
assign shift = (baud_cnt === 12'd2604) ? 1'b1 : 1'b0;

//shift register
always_ff@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		tx_shift_reg <= 9'h1FF;
	else if(load)
		tx_shift_reg <= {tx_data, 1'b0};
	else if (shift)
		tx_shift_reg <= {1'b1, tx_shift_reg[8:1]};
end

//transmitted bit 
assign TX = tx_shift_reg[0];

//SR flop indicating if tx is done
always_ff@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		tx_done <= 'b0;
	else if (clr_done) //resetting flop has priority
		tx_done <= 1'b0;
	else if (set_done)
		tx_done <= 1'b1;
end

//FSM to generate load, transmitting, set_done and clr_done signals
always_ff@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		state <= IDLE;
	else 
		state <= nxt_state;
end

always_comb begin
	load = 1'b0;
	transmitting = 1'b0;
	set_done = 1'b0;
	clr_done = 1'b0;
	nxt_state = IDLE;

	case(state)
		//when trmt asserted, initiate transmission
		IDLE: if(trmt) begin 
			nxt_state = TRANSMIT;
			load = 1'b1;
			clr_done = 1'b1;
		end
		
		TRANSMIT: begin 
			if(bit_cnt === 4'd10) begin	//done transmitting when bit_cnt reaches 10
				nxt_state = IDLE;
				set_done = 1'b1;
				clr_done = 1'b0;
			end
			else begin
				nxt_state = TRANSMIT;
				transmitting = 1'b1;
			end			
		end
		
		default: nxt_state = IDLE;
	endcase
end

endmodule
