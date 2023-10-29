module Goldsmith_div(
input n_reset,
input clk,
input clk_en,
input [23:0] dividend,
input [23:0] divisor,
output [23:0] quotient,
output res_ready
);

reg [48:0] n, d, f;
reg ready;
wire g_clk;

assign res_ready = ready;
assign g_clk = clk_en? clk : 1'b0;
assign quotient = n[23:0];

always @(posedge g_clk or negedge n_reset)
	if(!n_reset)
	begin
		n <= 49'b0;
		d <= 49'b0;
		f <= 49'b0;
		ready <= 1'b1;
	end
	else begin
	if(!ready)
		begin
			f[24:0] <= {1'b1, 24'b0} - ((d * f) >> 23);
			d[23:0] <= (d * f) >> 23;
			n[23:0] <= (n * f) >> 23;
		end
	else
		begin 
			f[24:0] <= {1'b1, 24'b0} - {1'b0, divisor[23:0]};
			d[23:0] <= divisor[23:0] >> 1;
			n[23:0] <= dividend[23:0] >> 1;
		end
		ready <= (d[48:0] > {25'b0, 1'b1, 23'b0})? (d[48:0] - {25'b0, 1'b1, 23'b0}) < 49'd2 : ({25'b0, 1'b1, 23'b0} - d[48:0]) < 49'd2;
	end
	

endmodule
