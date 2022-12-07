module UART_rx(clk, rst_n, RX, clr_rdy, rx_data, rdy);

input clk, rst_n, clr_rdy;
input RX;
output [7:0] rx_data;
output logic rdy;

logic start, shift, receiving;
logic [3:0] bit_cnt;
logic [12:0] baud_cnt;
logic [8:0] rx_shift_reg;
logic set_rdy;
logic RX_flop1, RX_meta_free;

typedef enum logic {IDLE, RECEIVE} state_t;
state_t state, nxt_state;

//keep track of how many bits we've shifted
always_ff@(posedge clk) begin
	if (start)
		bit_cnt <= 'b0;
	else if (shift)
		bit_cnt <= bit_cnt + 1;
end

//count down from 1302 (for first bit) or 2604 (for subsequent bits)
always_ff@(posedge clk) begin	
	if (start || shift)
		baud_cnt <= (start) ? 12'd1302 : 12'd2604;
	else if (receiving)
		baud_cnt <= baud_cnt - 1;
end

//start shifting when baud cnt has reached 0
assign shift = (baud_cnt === 12'd0) ? 1'b1 : 1'b0;

//make RX meta-stability free
always_ff@(posedge clk) begin
	RX_flop1 <= RX;
	RX_meta_free <= RX_flop1;
end

//shift register
always_ff@(posedge clk) begin
	if (shift)
		rx_shift_reg <= {RX_meta_free, rx_shift_reg[8:1]};
end

//received data  
assign rx_data = rx_shift_reg[7:0];

//SR flop indicating if data is ready
always_ff@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		rdy <= 'b0;
	else if (start || clr_rdy) //resetting flop has priority -- rdy signal stays high until start bit of next byte or until clr_rdy asserted
		rdy <= 1'b0;
	else if (set_rdy)
		rdy <= 1'b1;
end

//FSM to generate start, receiving, set_rdy signals
always_ff@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		state <= IDLE;
	else 
		state <= nxt_state;
end

always_comb begin
	start = 1'b0;
	receiving = 1'b0;
	set_rdy = 1'b0;
	nxt_state = IDLE;

	case(state)
		IDLE: if(~RX_meta_free) begin
			nxt_state = RECEIVE;
			start = 1'b1;
		end
		
		RECEIVE: begin 
			if(bit_cnt === 4'd10) begin	//received all bits when bit_cnt reaches 10
				nxt_state = IDLE;
				set_rdy = 1'b1;
			end
			else begin
				nxt_state = RECEIVE;
				receiving = 1'b1;
			end
		end
		
		default: nxt_state = IDLE;
	endcase
end

endmodule
