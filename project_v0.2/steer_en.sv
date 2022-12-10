module steer_en #(parameter fast_sim = 1) (clk, rst_n, lft_ld, rght_ld, en_steer, rider_off);
input clk, rst_n;
input [11:0] lft_ld, rght_ld;
output logic en_steer;
output logic rider_off;

logic clr_tmr, tmr_full;
logic sum_gt_min;			
logic sum_lt_min;
logic diff_gt_15_16;
logic diff_gt_1_4;

logic [12:0] sum_lft_rght_ld;
logic [12:0] sum_lft_rght_ld_1_4;
logic [12:0] sum_lft_rght_ld_15_16;
logic signed [11:0] diff_lft_rght_ld;
logic signed [11:0] diff_lft_rght_ld_abs;
logic [25:0] timer_1p34s;
logic [25:0] tmr_full_val;

localparam MIN_RIDER_WT = 12'h200;
localparam WT_HYSTERESIS = 8'h40;
localparam tmr_full_val_norm = 26'h3FE56C0;
localparam tmr_full_val_fast_sim = 15'h7FFF;

//instantiate steer_en_SM
steer_en_SM iSM(.clk(clk), .rst_n(rst_n), .tmr_full(tmr_full), .clr_tmr(clr_tmr), 
				.sum_gt_min(sum_gt_min), .sum_lt_min(sum_lt_min), .diff_gt_1_4(diff_gt_1_4),
				.diff_gt_15_16(diff_gt_15_16), .en_steer(en_steer), .rider_off(rider_off));

assign sum_lft_rght_ld = lft_ld + rght_ld;
assign sum_lft_rght_ld_1_4 = {{2{sum_lft_rght_ld[12]}}, sum_lft_rght_ld[12:2]};
assign sum_lft_rght_ld_15_16 = sum_lft_rght_ld - {{4{sum_lft_rght_ld[12]}}, sum_lft_rght_ld[12:4]};

assign sum_lt_min = sum_lft_rght_ld < ($signed(MIN_RIDER_WT) - $signed(WT_HYSTERESIS));
assign sum_gt_min = sum_lft_rght_ld > ($signed(MIN_RIDER_WT) + $signed(WT_HYSTERESIS));

assign diff_lft_rght_ld = lft_ld - rght_ld;
assign diff_lft_rght_ld_abs =  diff_lft_rght_ld[11] ? (-diff_lft_rght_ld): diff_lft_rght_ld; 

assign diff_gt_1_4 = diff_lft_rght_ld_abs > sum_lft_rght_ld_1_4; 
assign diff_gt_15_16 = diff_lft_rght_ld_abs > sum_lft_rght_ld_15_16;

//1.34 sec timer 
always_ff@(posedge clk, negedge rst_n) begin
	if (!rst_n)
		timer_1p34s <= 'b0;
	else if (clr_tmr)
		timer_1p34s <= 'b0;
	else 
		timer_1p34s <= timer_1p34s + 1;
end

assign tmr_full = (timer_1p34s == tmr_full_val) ? 1'b1 : 1'b0;

generate if (fast_sim) begin
		assign tmr_full_val = tmr_full_val_fast_sim;
	end else begin
		assign tmr_full_val = tmr_full_val_norm;
	end 
endgenerate

endmodule


