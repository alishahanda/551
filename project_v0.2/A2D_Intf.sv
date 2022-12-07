module A2D_Intf(
input logic clk, rst_n,
input logic nxt,
output logic [11:0] lft_ld, 
output logic [11:0] rght_ld, 
output logic [11:0] batt,
output logic [11:0] steer_pot,
input logic MISO, 
output logic SS_n, 
output logic SCLK, 
output logic MOSI
); 

//Internal SPI signals
logic [15:0] rd_data; 
logic wrt;
logic [15:0] cmd;
logic done;

logic [1:0] rnd_robin_cnt;
logic update;
logic [2:0] channel;

typedef enum logic [1:0] {IDLE,CMD,ID_CYCLE,RECIEVE_DATA} state_t;
state_t state, nxt_state;

//Round robin counter - 2 bit 
always_ff@(posedge clk, negedge rst_n) begin
	if (!rst_n) 
		rnd_robin_cnt <= 'b0;
	else if (update)
		rnd_robin_cnt <= rnd_robin_cnt + 1;
end

//Holding registers for lft_ld, rght_ld, steer_pot and batt
always_ff@(posedge clk, negedge rst_n) begin //lft_ld holding register
	if (!rst_n)
		lft_ld <= 'b0;
	else if (rnd_robin_cnt == 2'b00)
		lft_ld <= rd_data[11:0];
end

always_ff@(posedge clk, negedge rst_n) begin //rght_ld holding register
	if (!rst_n)
		rght_ld <= 'b0;
	else if (rnd_robin_cnt == 2'b01)
		rght_ld <= rd_data[11:0];
end

always_ff@(posedge clk, negedge rst_n) begin //steer_pot holding register
	if (!rst_n)
		steer_pot <= 'b0;
	else if (rnd_robin_cnt == 2'b10)
		steer_pot <= rd_data[11:0];
end

always_ff@(posedge clk, negedge rst_n) begin //batt holding register
	if (!rst_n)
		batt <= 'b0;
	else if (rnd_robin_cnt == 2'b11)
		batt <= rd_data[11:0];
end

//Instantiate SPI_mnrch interface
SPI_mnrch iSPI_mnrch(.clk(clk), .rst_n(rst_n), .wrt(wrt), .wt_data(cmd), .done(done), .rd_data(rd_data), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO));

assign channel = (rnd_robin_cnt == 2'b00) ? 3'b000 :
				 (rnd_robin_cnt == 2'b01) ? 3'b100 :
				 (rnd_robin_cnt == 2'b10) ? 3'b101 : 3'b110;
assign cmd = {2'b00, channel[2:0], 11'h000};

//State machine to generate wrt, update signals
always_ff@(posedge clk, negedge rst_n) begin
	if (!rst_n)	
		state <= IDLE;
	else
		state <= nxt_state;
end

always_comb begin
wrt = 0 ; 
update = 0; 
nxt_state = state;

case(state)
	IDLE:if (nxt) begin 
		nxt_state = CMD; 
		wrt = 1 ; 
	end 
	
	CMD: if (done) nxt_state = ID_CYCLE;

	ID_CYCLE: begin 
		nxt_state = RECIEVE_DATA; 
		wrt = 1;
	end
	
	RECIEVE_DATA: if(done) begin 
		nxt_state = IDLE; 
		update = 1; 
	end

	default: nxt_state = state;
endcase
end

endmodule
