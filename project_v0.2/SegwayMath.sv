module SegwayMath(PID_cntrl, ss_tmr, steer_pot, en_steer, pwr_up, lft_spd, rght_spd, too_fast);
input signed [11:0] PID_cntrl;
input [7:0] ss_tmr; //unsigned 
input [11:0] steer_pot; //unsigned
input en_steer;
input pwr_up;
output signed [11:0] lft_spd, rght_spd;
output signed too_fast;

//internal signals
logic signed [19:0] PID_cntrl_scaled;
logic signed [11:0] PID_ss;
logic [11:0] steer_pot_sat;
logic signed [11:0] steer_pot_signed;
logic signed [12:0] steer_pot_signed_3_16;
logic signed [12:0] lft_torque, rght_torque;
logic signed [12:0] lft_torque_abs, rght_torque_abs;
logic signed [12:0] lft_torque_comp, rght_torque_comp;
logic signed [12:0] lft_shaped, rght_shaped;

//scaling with soft start
assign PID_cntrl_scaled = PID_cntrl * $signed({1'b0, ss_tmr});
assign PID_ss = PID_cntrl_scaled[19:8]; //divide by 256 is right shift by 8

//steering input
//limiting steer_pot between 0x200 and 0xE00
assign steer_pot_sat = (steer_pot < 12'h200) ? 12'h200 : 
                       ((steer_pot > 12'hE00) ? 12'hE00 : steer_pot); //unsigned

//Converting limited steer_pot value to a signed number
assign steer_pot_signed = steer_pot_sat - 12'h7FF;

//Multiplying steer_pot_signed by 3/16
assign steer_pot_signed_3_16 = {{5{steer_pot_signed[11]}}, steer_pot_signed[11:4]} + {{4{steer_pot_signed[11]}}, steer_pot_signed[11:3]}; // 3/16 = 1/16 + 2/16 which is right shift by 4 + right shift by 3

assign lft_torque = en_steer ? ({PID_ss[11],PID_ss} + steer_pot_signed_3_16) : {PID_ss[11], PID_ss};
assign rght_torque = en_steer ? ({PID_ss[11],PID_ss} - steer_pot_signed_3_16) : {PID_ss[11], PID_ss};

//deadzone shaping
localparam MIN_DUTY = 13'h3C0;
localparam LOW_TORQUE_BAND = 8'h3C;
localparam GAIN_MULT = 6'h10;

assign lft_torque_comp = lft_torque[12] ? (lft_torque - MIN_DUTY) : (lft_torque + MIN_DUTY);
assign lft_torque_abs = lft_torque[12] ? (-lft_torque): lft_torque;
assign lft_shaped = pwr_up ? ((lft_torque_abs > $signed(LOW_TORQUE_BAND)) ? lft_torque_comp : (lft_torque * $signed(GAIN_MULT))) : 13'h0000;

assign rght_torque_comp = rght_torque[12] ? (rght_torque - MIN_DUTY) : (rght_torque + MIN_DUTY);
assign rght_torque_abs = rght_torque[12] ? (-rght_torque): rght_torque;
assign rght_shaped = pwr_up ? ((rght_torque_abs > $signed(LOW_TORQUE_BAND)) ? rght_torque_comp : (rght_torque * $signed(GAIN_MULT))) : 13'h0000;

//final saturation and over speed detect
//12-bit signed saturation
assign lft_spd = (~lft_shaped[12] && |lft_shaped[12:11]) ? 12'h7FF : 
				((lft_shaped[12] && ~(&lft_shaped[12:11])) ? 12'h800 : 
				lft_shaped[11:0]);
assign rght_spd = (~rght_shaped[12] && |rght_shaped[12:11]) ? 12'h7FF : 
				((rght_shaped[12] && ~(&rght_shaped[12:11])) ? 12'h800 : 
				rght_shaped[11:0]);

assign too_fast = (lft_spd > $signed(12'd1792)) || (rght_spd > $signed(12'd1792));

endmodule
