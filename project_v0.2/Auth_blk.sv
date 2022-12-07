module Auth_blk(clk, rst_n, RX, rider_off, pwr_up);
input clk, rst_n;
input RX, rider_off;
output logic pwr_up;

logic clr_rx_rdy, rx_rdy;
logic [7:0] rx_data;

typedef enum logic [1:0] {OFF, PWR1, PWR2} state_t;
state_t state, nxt_state;

localparam g = 8'h67; //go 
localparam s = 8'h73; //stop

//instantiate UART_rx
UART_rx iUART_rx(.clk(clk), .rst_n(rst_n), .RX(RX), .clr_rdy(clr_rx_rdy), .rx_data(rx_data), .rdy(rx_rdy));

//auth_SM
always_ff@(posedge clk, negedge rst_n) begin
	if (!rst_n)
		state <= OFF;
	else
		state <= nxt_state;
end

always_comb begin
	//initialize outputs and next state
	pwr_up = 0;
	clr_rx_rdy = 0;
	nxt_state = OFF;
	
	case(state)
		OFF: if (rx_data == g && rx_rdy) begin //if we receive go then transition to PWR1 state
				nxt_state = PWR1;
				pwr_up = 1; //Segway powers up
				clr_rx_rdy = 1;
			end
		
		PWR1: if(rx_data == s && rx_rdy && !rider_off) begin  //If Segway powered up and receives a stop signal but rider is not off, need to enter PWR2 state
				nxt_state = PWR2; 
				pwr_up = 1;
				clr_rx_rdy = 1;
			end else if (rx_data == s && rx_rdy && rider_off) begin //If Segway powered up and receives a stop signal and rider is off, transition to OFF state
				nxt_state = OFF;
				clr_rx_rdy = 1;
			end else begin
				nxt_state = PWR1;
				pwr_up = 1; //Powered up while in PWR1 state
			end
			
		PWR2: if (rx_data == g && rx_rdy) begin //When powered on and waiting for rider to step off if 'go' is received, re-enter the primary powered state (PWR1)
				nxt_state = PWR1;
				pwr_up = 1;
				clr_rx_rdy = 1;
			end else if (rider_off) begin //If rider steps off, transition to OFF state	
				nxt_state = OFF;
			end else begin
				nxt_state = PWR2; //In PWR2 state we remain powered on and wait for rider_off to be asserted
				pwr_up = 1;
			end
			
		default: nxt_state = OFF; //default to OFF state
	endcase
end

endmodule