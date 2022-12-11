module piezo_drv #(parameter fast_sim = 1) (clk, rst_n, en_steer, too_fast, batt_low, piezo, piezo_n);
input clk, rst_n, en_steer, too_fast, batt_low;
output logic piezo, piezo_n;

logic [25:0] note_duration_cnt;
logic [27:0] timer_3s_cnt;
logic [14:0] freq_cnt;

logic clr_freq_cnt, clr_timer_3s, clr_duration_cnt;
logic en_freq_cnt, en_tmr_3s, en_dur_cnt;
logic timer_3s_full;

logic [27:0] time3s;
logic [14:0] G6_freq_cnt, C7_freq_cnt, E7_freq_cnt, G7_freq_cnt;
logic [25:0] G6_dur, C7_dur, E7_dur, G7_dur, E7_2_dur, G7_2_dur;
logic [6:0] incr_val;

logic [14:0] toggle_freq_cnt;

typedef enum logic [2:0] {IDLE, NOTE_G6, NOTE_C7, NOTE_E7, NOTE_G7, NOTE_E7_2, NOTE_G7_2} state_t;
state_t state, nxt_state;

localparam G6_freq_cnt_norm = 15'd31888; //1568
localparam C7_freq_cnt_norm = 15'd23889; //2093
localparam E7_freq_cnt_norm = 15'd18961; //2637
localparam G7_freq_cnt_norm = 15'd15944; //3136

localparam G6_freq_cnt_fast_sim = 15'd384;//15'd498;
localparam C7_freq_cnt_fast_sim = 15'd384;//15'd373;
localparam E7_freq_cnt_fast_sim = 15'd256;//15'd296;
localparam G7_freq_cnt_fast_sim = 15'd256;//15'd249;

localparam G6_dur_norm = 26'h0800000; //2^23 clocks
localparam C7_dur_norm = 26'h0800000; //2^23 clocks
localparam E7_dur_norm = 26'h0800000; //2^23 clocks
localparam G7_dur_norm = (26'h0800000 + 26'h400000); //2^23 + 2^22 clocks
localparam E7_2_dur_norm = 26'h400000; //2^22 clocks
localparam G7_2_dur_norm = 26'h2000000; //2^25 clocks

localparam G6_dur_fast_sim = 26'h20000;
localparam C7_dur_fast_sim = 26'h20000;
localparam E7_dur_fast_sim = 26'h20000;
localparam G7_dur_fast_sim = (26'h20000 + 26'h10000);
localparam E7_2_dur_fast_sim = 26'h10000;
localparam G7_2_dur_fast_sim = 26'h80000;

//Duration timer to keep track of duration of clock cycles for which note should be played
always_ff@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		note_duration_cnt <= 'b0;
	else if(clr_duration_cnt)
		note_duration_cnt <= 'b0;
	else if(en_dur_cnt)
		note_duration_cnt <= note_duration_cnt + incr_val;
end

//Repeat timer to maintain 3 seconds
always_ff@(posedge clk, negedge rst_n) begin
	if (!rst_n)
		timer_3s_cnt <= time3s;
	else if(clr_timer_3s)
		timer_3s_cnt <= 'b0;
	else if(en_tmr_3s)
		timer_3s_cnt <= timer_3s_cnt + incr_val;
end

assign timer_3s_full = (timer_3s_cnt == time3s); //3 sec

//Counter to generate note frequency 
always_ff@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		freq_cnt <= 'b0;
	else if (clr_freq_cnt)
		freq_cnt <= 'b0;
	else if (en_freq_cnt)
		freq_cnt <= freq_cnt + incr_val;
end

//FSM
always_ff@(posedge clk, negedge rst_n) begin 
	if (!rst_n)
		state <= IDLE;
	else 
		state <= nxt_state;
end

always_comb begin
	//Initialize output of FSM
	nxt_state = IDLE;
	clr_freq_cnt = 0;
	clr_duration_cnt = 0;
	clr_timer_3s = 0;
	en_dur_cnt = 0;
	en_freq_cnt = 0;
	en_tmr_3s = 0;
	toggle_freq_cnt = 1;
	
	case(state)
		IDLE: if(too_fast) begin
				nxt_state = NOTE_G6;
				clr_timer_3s = 1;
			end else if (batt_low && timer_3s_full) begin
				nxt_state = NOTE_G7_2;
				clr_timer_3s = 1;
			end else if (en_steer && timer_3s_full) begin
				nxt_state = NOTE_G6;
				clr_timer_3s = 1;
			end else begin
				en_tmr_3s = 1;
				clr_freq_cnt = 1;
				clr_duration_cnt = 1;
			end
		
		NOTE_G6: if(note_duration_cnt == G6_dur) begin
				if (too_fast)
					nxt_state = NOTE_C7;
				else if (batt_low)
					nxt_state = IDLE;
				else if (en_steer)
					nxt_state = NOTE_C7;
				clr_duration_cnt = 1;
			end else begin
				clr_freq_cnt = (freq_cnt == G6_freq_cnt) ? 1'b1 : 1'b0;
				toggle_freq_cnt = {1'b0, G6_freq_cnt[14:1]};
				nxt_state = NOTE_G6;
				en_freq_cnt = 1;
				en_dur_cnt = 1;
				if (!too_fast) en_tmr_3s = 1;
			end
		
		NOTE_C7: if(note_duration_cnt == C7_dur) begin
				if (too_fast)
					nxt_state = NOTE_E7;
				else if (batt_low)
					nxt_state = NOTE_G6;
				else if (en_steer)
					nxt_state = NOTE_E7;
				clr_duration_cnt = 1;
			end else begin
				clr_freq_cnt = (freq_cnt == C7_freq_cnt) ? 1'b1 : 1'b0;
				toggle_freq_cnt = {1'b0, C7_freq_cnt[14:1]};
				nxt_state = NOTE_C7;
				en_freq_cnt = 1;
				en_dur_cnt = 1;
				if (!too_fast) en_tmr_3s = 1;
			end
		
		NOTE_E7: if (note_duration_cnt == E7_dur && too_fast) begin
				nxt_state = NOTE_G6;
				clr_duration_cnt = 1;
				clr_timer_3s = 1;
			end else if(note_duration_cnt == E7_dur && !too_fast) begin
				if (batt_low)
					nxt_state = NOTE_C7;
				else if (en_steer)
					nxt_state = NOTE_G7;
				clr_duration_cnt = 1;
			end else begin
				clr_freq_cnt = (freq_cnt == E7_freq_cnt) ? 1'b1 : 1'b0;
				toggle_freq_cnt = {1'b0, E7_freq_cnt[14:1]};
				nxt_state = NOTE_E7;
				en_freq_cnt = 1;
				en_dur_cnt = 1;
				if (!too_fast) en_tmr_3s = 1;
			end
		
		NOTE_G7: if (too_fast) begin
				nxt_state = NOTE_G6;
				clr_duration_cnt = 1;
				clr_timer_3s = 1;
			end else if (note_duration_cnt == G7_dur) begin
				if (batt_low)
					nxt_state = NOTE_E7;
				else if (en_steer)
					nxt_state = NOTE_E7_2;
				clr_duration_cnt = 1;
			end else begin
				clr_freq_cnt = (freq_cnt == G7_freq_cnt) ? 1'b1 : 1'b0;
				toggle_freq_cnt = {1'b0, G7_freq_cnt[14:1]};
				nxt_state = NOTE_G7;
				en_freq_cnt = 1;
				en_dur_cnt = 1;
				en_tmr_3s = 1;
			end
		
		NOTE_E7_2: if (too_fast) begin
				nxt_state = NOTE_G6;
				clr_duration_cnt = 1;
				clr_timer_3s = 1;
			end else if (note_duration_cnt == E7_2_dur) begin
				if (batt_low)
					nxt_state = NOTE_G7;
				else if (en_steer)
					nxt_state = NOTE_G7_2;
				clr_duration_cnt = 1;
			end else begin
				clr_freq_cnt = (freq_cnt == E7_freq_cnt) ? 1'b1 : 1'b0;
				toggle_freq_cnt = {1'b0, E7_freq_cnt[14:1]};
				nxt_state = NOTE_E7_2;
				en_freq_cnt = 1;
				en_dur_cnt = 1;
				en_tmr_3s = 1;
			end
		
		NOTE_G7_2: if (too_fast) begin
				nxt_state = NOTE_G6;
				clr_duration_cnt = 1;
				clr_timer_3s = 1;
			end else if (note_duration_cnt == G7_2_dur) begin
				if (batt_low)
					nxt_state = NOTE_E7_2;
				else if (en_steer)
					nxt_state = IDLE;
				clr_duration_cnt = 1;
			end else begin
				clr_freq_cnt = (freq_cnt == G7_freq_cnt) ? 1'b1 : 1'b0;
				toggle_freq_cnt = {1'b0, G7_freq_cnt[14:1]};
				nxt_state = NOTE_G7_2;
				en_freq_cnt = 1;
				en_dur_cnt = 1;
				en_tmr_3s = 1;
			end
				
		default: nxt_state = IDLE;
	
	endcase	
end

//generate conditional
generate if (fast_sim) begin
		assign incr_val = 7'd64;
		assign G6_freq_cnt = G6_freq_cnt_fast_sim;
		assign C7_freq_cnt = C7_freq_cnt_fast_sim;
		assign E7_freq_cnt = E7_freq_cnt_fast_sim;
		assign G7_freq_cnt = G7_freq_cnt_fast_sim;
		assign G6_dur = G6_dur_fast_sim;
		assign C7_dur = C7_dur_fast_sim;
		assign E7_dur = E7_dur_fast_sim;
		assign G7_dur = G7_dur_fast_sim;
		assign E7_2_dur = E7_2_dur_fast_sim;
		assign G7_2_dur = G7_2_dur_fast_sim;
		assign time3s = 28'd2343744;//28'h23C346;
	end else begin
		assign incr_val = 7'd1;
		assign G6_freq_cnt = G6_freq_cnt_norm;
		assign C7_freq_cnt = C7_freq_cnt_norm;
		assign E7_freq_cnt = E7_freq_cnt_norm;
		assign G7_freq_cnt = G7_freq_cnt_norm;
		assign G6_dur = G6_dur_norm;
		assign C7_dur = C7_dur_norm;
		assign E7_dur = E7_dur_norm;
		assign G7_dur = G7_dur_norm;
		assign E7_2_dur = E7_2_dur_norm;
		assign G7_2_dur = G7_2_dur_norm;
		assign time3s = 28'h8F0D180;
	end
endgenerate

always_ff@(posedge clk, negedge rst_n) begin
	if (!rst_n)
		piezo <= 1'b0;
	else if (freq_cnt == toggle_freq_cnt)
		piezo <= ~piezo;
end

assign piezo_n = ~piezo;

endmodule
