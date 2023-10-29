module DFT(
	input n_reset,
	input clk,
	input start_in,
	input [31:0] time_data_in,
	input [31:0] cos_in [16],
	input [31:0] sin_in [16],
	input [6:0] ampl_number,
	input [6:0] harm_number,
	output [31:0] cos_out,
	output [31:0] sin_out,
	output [31:0] ampl_out,
	output [31:0] time_data_out,
	output [31:0] math_og_out,
	output done
);

reg [31:0] time_data [128];
reg [31:0] cos_data [128];
reg [31:0] sin_data [128];
reg [31:0] ampl_data [128];
reg [31:0] math_og;
wire [31:0] prod_cos [16];
wire [31:0] prod_sin [16];
wire [31:0] cos_sum [16];
wire [31:0] sin_sum [16];
wire [31:0] ampl_in;
wire [31:0] math_ogid;
wire ampl_done; 
wire mant_math;
reg [31:0] ampl;
reg [6:0] time_index;
reg [6:0] amp_index; 
reg [6:0] amp_numberik;
reg [1:0] state;
reg [1:0] state_global;
reg sum_was, sum_was1;
reg [1:0] start_strb;
reg [1:0] clk_en;
reg [4:0] latency;
reg done_reg;
reg math_en;
integer incr;

assign time_data_out = time_data[0];
assign cos_out = cos_data[harm_number];
assign sin_out = sin_data[harm_number];
assign ampl_out = ampl_data[ampl_number];
assign math_og_out = math_og;
assign done = done_reg;

always @(negedge n_reset or posedge clk)
	if(!n_reset) begin
		state_global <= 2'b0;
		latency <= 5'b0;
		done_reg <= 1'b1;
	end
	else 
		case(state_global)
			2'b0: begin if(start_in) state_global <= 2'b01; done_reg <= 1'b1; end
			2'b01: begin if((amp_index == 3'd7) && (time_index == 7'd127) && sum_was) state_global <= 2'b10; done_reg <= 1'b0;end
			2'b10: begin if(amp_numberik == 7'd127) latency[0] <= 1'b1; latency[4:1] <= latency[3:0]; 
					 if(latency[4]) state_global <= 2'b0; end
		endcase
			

ampl amplik (
	.n_reset(n_reset),
	.clk(clk),
	.start(start_strb[0]),
	.x(cos_data[amp_numberik]),
	.y(sin_data[amp_numberik]),
	.ampli(ampl_in),
	.done(ampl_done)
);			
			
FPAdd math_ogi(
	.n_reset(n_reset),
	.clk(clk),
	.clk_en(math_en),
	.term1(math_og),
	.term2(ampl_in),
	.sum(math_ogid),
	.mant_added1(mant_math)
);
	
always @(negedge n_reset or posedge clk)
	if(!n_reset) begin
		start_strb <= 2'b0;
		amp_numberik <= 7'd0;
	end
	else 
		if(state_global == 2'b10) begin
			if(start_strb == 2'b0) begin
				start_strb[0] <= !start_strb[1];
				start_strb[1] <= 1'b1;
			end
			else
			begin 
				if(ampl_done) begin
					start_strb <= (amp_numberik < 7'd127)? 2'b0 : start_strb;
					amp_numberik <= (amp_numberik == 7'd127)? 7'd127 : amp_numberik + 7'd1;
				end
			end
		end
		else	
			begin 
				start_strb <= 2'b0;
				amp_numberik <= 7'd0;
			end
		
always @(clk)
	begin
		if(start_strb & ampl_done & clk) math_en <= 1'b1; else
		if (!mant_math & !clk) begin 
				math_en <= 1'b0; 
				math_og <= (amp_numberik == 7'd127)? {math_ogid[31], math_ogid[30:23]-8'd7, 23'd0} : math_ogid; 
		end
	end 
	
always @(negedge n_reset or posedge clk)
	if(!n_reset) begin
		amp_index <= 7'd0;
		state <= 2'b0;
		sum_was <= 1'b0;
		sum_was1 <= 1'b0;
	end
	else begin 
		case(state)
			2'b0: begin if(state_global == 2'b01) state <= 2'b01; sum_was <= 1'b0; time_index <= 7'd0; 
					sum_was1 <= 1'b0; amp_index <= 7'd0; end
			2'b01: begin state <= 2'b10; sum_was <= 1'b0; sum_was1 <= 1'b0; end
			2'b10: begin sum_was <= sum_was1; sum_was1 <= 1'b1; 
					if((amp_index == 7'd7) && (time_index == 7'd127)) state <= sum_was? 2'b00 : 2'b10; else
									state <= sum_was? 2'b01 : 2'b10;
					if(sum_was) begin
						time_index <= (time_index < 7'd127)? time_index + 7'd1 : 7'd0;
						amp_index <= (time_index < 7'd127)? amp_index + 7'd1 : 3'd0;
					end
					end
		endcase
		end
					
always @(clk)
	case(state)
		2'b0: clk_en <= 2'b0;
		2'b01: if(clk) clk_en <= 2'b01;
		2'b10: if(clk) clk_en <= 2'b10; else if (sum_was) clk_en <= 2'b0;
	endcase

	always @(posedge clk)
		for(incr = 0; incr < 16; incr = incr + 1)
			if(sum_was) begin 
					cos_data[({4'b0,amp_index}<<4) + incr] <= cos_sum[incr];
					sin_data[({4'b0,amp_index}<<4) + incr] <= sin_sum[incr];
			end
	
genvar i, j;
generate

		for(i = 0; i < 16; i = i + 1) begin : i1
			FPMul cos_mul1 (
				.n_reset(n_reset),
				.clk(clk),
				.clk_en(clk_en[0]),
				.mult1(cos_in[i]),
				.mult2(time_data[time_index]),
				.product(prod_cos[i])
			);
	
			FPMul sin_mul1 (
				.n_reset(n_reset),
				.clk(clk),
				.clk_en(clk_en[0]),
				.mult1(cos_in[i]),
				.mult2(time_data[time_index]),
				.product(prod_sin[i])
			);
		
			FPAdd cos_sumka(
				.n_reset(n_reset),
				.clk(clk),
				.clk_en(clk_en[1]),
				.term1(prod_cos[i]),
				.term2((time_index == 0)? 32'b0: cos_data[k<<4 + i]),
				.sum(cos_sum[i])
			);
		
			FPAdd sin_sumka(
				.n_reset(n_reset),
				.clk(clk),
				.clk_en(clk_en[1]),
				.term1(prod_sin[i]),
				.term2((time_index == 0)? 32'b0: sin_data[k<<4 + i]),
				.sum(sin_sum[i])
			);
		
	end
		
	for(j = 127; j >= 0; j = j - 1) begin : ji1
		always @(posedge clk) 
			time_data[j] = (j == 127)? time_data_in : time_data[j+1];
			
	end
	
endgenerate

endmodule 