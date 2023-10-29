module FPMul(
	input n_reset,
	input clk,
	input clk_en,
	input [31:0] mult1,
	input [31:0] mult2,
	output [31:0] product
);

reg [47:0] p;
wire g_clk;

assign g_clk = clk_en? clk : 1'b0;
assign product = p[31:0];

always @(negedge n_reset or posedge g_clk)
	if(!n_reset)
		p <= 32'b0;
	else	
		begin
			p[31] <= mult1[31] ^ mult2[31];
			if((mult1[30:23] + mult2[30:23]) < {1'b0, 8'h7F})
				p[30:23] <= 8'b0;
			else if ({mult1[30:23] + mult2[30:23] - 8'h7F} > {1'b0, 8'hFF})
				p[30:23] <= 8'hFF;
			else
				p[30:23] <= (({24'b0, 1'b1, mult1[22:0]} * {24'b0, 1'b1, mult2[22:0]}) & 48'h800000000000)?
								mult1[30:23] + mult2[30:23] - 8'h7E :
								mult1[30:23] + mult2[30:23] - 8'h7F;								
				
			p[22:0] <= (({24'b0, 1'b1, mult1[22:0]} * {24'b0, 1'b1, mult2[22:0]}) & 48'h800000000000)? 
							({24'b0, 1'b1, mult1[22:0]} * {24'b0, 1'b1, mult2[22:0]}) >> 24 :
							({24'b0, 1'b1, mult1[22:0]} * {24'b0, 1'b1, mult2[22:0]}) >> 23;
		end

endmodule 