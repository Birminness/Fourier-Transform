module pulse_gen15(
	input n_reset,
	input clk,
	input clk_en,
	output out,
	output done_pulse
);
assign out = gate;
assign done_pulse = ~anti_glitch;
reg counter1, counter2;
reg anti_glitch1, anti_glitch2;
wire anti_glitch = anti_glitch1 ^ anti_glitch2;
wire g_clk = anti_glitch? clk : 1'b0;
wire gate = counter1 | counter2;

always @(negedge n_reset or posedge clk_en)
	if(!n_reset)
		anti_glitch1 <= 1'b0;
	else anti_glitch1 <= ~anti_glitch2;
	
always @(negedge n_reset or negedge gate)
	if(!n_reset)
		anti_glitch2 <= 1'b0;
	else anti_glitch2 <= anti_glitch1;

always @(negedge n_reset or posedge g_clk)
	if(!n_reset) begin
			counter1 <= 1'd0;
		end
	else
		begin
			counter1 <= ~counter1;
		end
		
always @(negedge n_reset or negedge g_clk)		
	if(!n_reset)
			counter2 <= 1'd0;
	else
			counter2 <= ~counter2;

endmodule 