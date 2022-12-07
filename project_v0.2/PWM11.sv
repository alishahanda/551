module PWM11(clk, rst_n, duty, PWM_sig, PWM_synch, OVR_I_blank_n);

input clk, rst_n;
input [10:0] duty;
output logic PWM_sig, PWM_synch, OVR_I_blank_n;

logic [10:0] cnt;
logic set, reset;

//11-bit counter
always_ff@(posedge clk, negedge rst_n) begin
	if (!rst_n)
		cnt <= 'b0;
	else
		cnt <= cnt + 11'h001;
end

assign set = (cnt === 'b0) ? 1'b1 : 1'b0; //set if cnt equal to all zeros
assign reset = (cnt >= duty) ? 1'b1 : 1'b0; //reset if cnt >= duty

always_ff@(posedge clk, negedge rst_n) begin
	if (!rst_n)
		PWM_sig <= 1'b0;
	else if (reset) //reset has priority
		PWM_sig <= 1'b0;
	else if (set)
		PWM_sig <= 1'b1;
end

assign PWM_synch = &cnt;
assign OVR_I_blank_n = (cnt > 255) ? 1'b1 : 1'b0; //generate blanking signal

endmodule