module FPDiv(
input n_reset,
input clk,
input clk_en,
input [31:0] dividend,
input [31:0] divisor,
output [31:0] quotient,
output ready_out,
output division_by_zero
);

reg [31:0] q;
reg [1:0] div_en;
reg div_en_final,div_by_zero;
wire g_clk, ready;
wire [4:0] msb_number;
wire [23:0] q_part;
assign g_clk = clk_en? clk : 1'b0;
assign mant_ready = (~div_en_final) & div_en[1] & div_en[0];
assign quotient = q;
assign division_by_zero = div_by_zero;
assign ready_out = ready;

always @(ready or clk_en or n_reset)
	if(!n_reset) begin
		div_en <= 1'b0;
		div_by_zero <= 1'b0;
	end
	else if(clk_en)
	begin
		div_by_zero <= 1'b0;
		div_en <= !ready? {div_en[1], 1'b1} : {div_en[0], div_en[0]}; 
	end
	else if (!clk_en) begin
		div_by_zero <= divisor[30:0] == 31'b0;
		div_en <= 2'b0;
	end

always @(negedge g_clk or negedge n_reset)
	if(!n_reset)
		div_en_final <= 1'b0;
	else
		div_en_final <= !div_en[1] | !div_en[0];

MSBSeek msb_seeker(
	.in_data(q_part),
	.out_data(msb_number)
	);
	
Goldsmith_div divider(
	.n_reset(n_reset),
	.clk(g_clk),
	.clk_en(div_en_final),
	.dividend({1'b1, dividend[22:0]}),
	.divisor({1'b1, divisor[22:0]}),
	.quotient(q_part),
	.res_ready(ready)
);


always @(negedge n_reset or posedge g_clk)
	if(!n_reset)
	begin
		q <= 32'b0;
	end 
	else 
	begin
		q[31] <= dividend[31] ^ divisor[31];
		if ((divisor[30:23] > 8'h7F) && ((divisor[30:23] - 8'h7F) > dividend[30:23]))
			q[30:23] <= 8'b0;
		else 
		if (divisor[30:0] == 31'b0)
		begin
			q[30:23] <= q[30:23];
		end
		else
		begin
			if(msb_number < 5'd23)
				q[30:23] <= ({1'b0, (dividend[30:23] + 8'h7F - divisor[30:23] - (5'd23 - msb_number))} > {1'b0, 8'hFF})? 8'hFF :
								dividend[30:23] + 8'h7F - divisor[30:23] - (5'd23 - msb_number);
			else
				q[30:23] <= ({1'b0,(dividend[30:23] + 8'h7F - divisor[30:23])} > {1'b0, 8'hFF})? 8'hFF : 
								dividend[30:23] + 8'h7F - divisor[30:23];
		end

		if(mant_ready) q[22:0] <= q_part[22:0] << (5'd23 - msb_number);
		else q[22:0] <= q[22:0];
	end

endmodule	