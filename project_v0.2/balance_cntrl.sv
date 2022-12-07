module balance_cntrl #(parameter fast_sim = 1) (clk, rst_n, vld, ptch, ptch_rt, pwr_up, rider_off, steer_pot, en_steer, lft_spd, rght_spd, too_fast);

input clk, rst_n, vld;
input [15:0] ptch;
input [15:0] ptch_rt;
input pwr_up;
input rider_off; 
input [11:0] steer_pot;
input en_steer;
output signed [11:0] lft_spd, rght_spd;
output signed too_fast;

logic signed [11:0] PID_cntrl;
logic signed [7:0] ss_tmr;

//Instantiate PID and SegwayMath
PID #(.fast_sim(fast_sim)) iPID (.clk(clk), .rst_n(rst_n), .vld(vld), .rider_off(rider_off), .ptch(ptch), .ptch_rt(ptch_rt), .pwr_up(pwr_up), .PID_cntrl(PID_cntrl), .ss_tmr(ss_tmr));
SegwayMath iSegMath (.PID_cntrl(PID_cntrl), .ss_tmr(ss_tmr), .steer_pot(steer_pot), .en_steer(en_steer), .pwr_up(pwr_up), .lft_spd(lft_spd), .rght_spd(rght_spd), .too_fast(too_fast));

endmodule