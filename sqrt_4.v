module sqrt_4(
 input n_reset,
 input clk,
 input start,
 input [31:0] argument,
 output [31:0] result,
 output done
);

assign done = calc_done;
assign result = x;

reg [31:0] x;
reg [1:0] state;
reg [1:0] div_sync;
reg [1:0] clk_en;
reg calc_done;
reg [2:0] iter;
reg ready_was;
reg sum_done;
wire [31:0] quotient;
wire [31:0] sum;
wire div_done;


FPDiv div_module(
	.n_reset(n_reset),
	.clk(clk),
	.clk_en(clk_en[0]),
	.dividend(argument),
	.divisor(x),
	.quotient(quotient),
	.ready_out(div_done)
);

FPAdd add_sub(
	.n_reset(n_reset),
	.clk(clk),
	.clk_en(clk_en[1]),
	.term1(quotient),
	.term2(x),
	.sum(sum)
);

always @(n_reset or clk)
	if(!n_reset) begin
		x <= {8'h3F, 24'b0};
		state <= 2'b0;
		div_sync <= 2'b0;
		clk_en <= 2'b0;
		iter <= 3'b0;
		ready_was <= 1'b0;
		calc_done <= 1'b0;
		sum_done <= 1'b0;
	end
	else begin
	case (state)
		2'b0 : begin x <= x; clk_en <= 2'b0; div_sync <= 2'b0; iter <= 3'b0; sum_done <=1'b0;
												if (start) state <= 2'b01; ready_was <= 1'b0; calc_done <= 1'b1; end
		2'b01: begin x <= x; div_sync <= {div_sync[0], !div_done}; clk_en <= 2'b01; sum_done <= 1'b0;
															  if (clk) ready_was <= div_sync[1]; 
															 if(clk & ready_was) state <= 2'b10;
															 calc_done <=1'b0; end
	   2'b10: begin if(!sum_done & clk) clk_en <= 2'b10; else clk_en <= 2'b0; 
				 if(clk & clk_en[1]) sum_done <= 1'b1;
				 if(sum_done) begin x <= {sum[31], sum[30:23] - 1, sum[22:0]}; iter <= iter + 3'b01; end
				 if(sum_done) begin 
						if(iter == 3'b100) state <= 2'b0; else state <= 2'b01; 
								  end
					calc_done <= 1'b0;
				end
 	endcase
	end

endmodule 