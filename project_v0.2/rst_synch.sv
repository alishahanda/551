module rst_synch(RST_n, clk, rst_n);
input RST_n, clk;
output logic rst_n;
logic q;

always_ff@(negedge clk, negedge RST_n) begin
	if(!RST_n) begin	
		q <= 1'b0;
		rst_n <= 1'b0;
	end
	else begin
		q <= 1'b1;
		rst_n <= q;
	end
end

endmodule