module ampl(
	input n_reset,
	input clk,
	input start,
	input [31:0] x,
	input [31:0] y,
	output [31:0] ampli,
	output done
);

wire [31:0] x_x, y_y, sum, sqrt_k;
wire done_a;
reg done_idle;
reg sum_was;
reg [1:0] clk_en;
reg [1:0] state;
reg [1:0] start_strb;

assign done = done_idle;
assign ampli = sqrt_k;

FPMul x_sqr(
	.n_reset(n_reset),
	.clk(clk),
	.clk_en(clk_en[0]),
	.mult1(x),
	.mult2(x),
	.product(x_x)
);

FPMul y_sqr(
	.n_reset(n_reset),
	.clk(clk),
	.clk_en(clk_en[0]),
	.mult1(y),
	.mult2(y),
	.product(y_y)
);

FPAdd add_sub(
	.n_reset(n_reset),
	.clk(clk),
	.clk_en(clk_en[1]),
	.term1(x_x),
	.term2(y_y),
	.sum(sum)
);

sqrt_4 sqrt_ent(
	.n_reset(n_reset),
	.clk(clk),
	.start(start_strb[0]),
	.argument(sum),
	.result(sqrt_k),
	.done(done_a)
);

always @(n_reset or clk)
	if(!n_reset) begin
		state <= 2'b0;
		start_strb <= 2'b0;
		done_idle <= 1'b1;
		clk_en <= 2'b0;
	end
	else
		begin
			case(state)
				2'b0: begin clk_en <= 2'b00; if(start) state <= 2'b01; start_strb <= 2'b0;done_idle <= 1'b1; end
				2'b01: begin clk_en <= 2'b01; if(clk) state <= 2'b10; start_strb <= 2'b0; end
				2'b10: begin start_strb <= 2'b0; if(clk) clk_en <= {!sum_was, 1'b0}; if(clk) sum_was <= clk_en[1]; 
																									  if(sum_was) state <= 2'b11; end
				2'b11: begin start_strb[0] <= !start_strb[1]; start_strb[1] <= 1'b1;
												  done_idle <= done_a; clk_en <= 2'b0; 
											if(start_strb[1] & done_a) state <= 2'b0; end
			endcase 
		end

endmodule 