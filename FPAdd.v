module FPAdd(
input n_reset,
input clk,
input clk_en,
input [31:0] term1,
input [31:0] term2,
output [31:0] sum,
output overflow1,
output mant_added1
);

reg [31:0] pre_sum;
reg mant_added;
reg overflow;
wire g_clk;
wire [4:0] msb_number;

assign sum = pre_sum;
assign mant_added1 = mant_added;
assign overflow1 = overflow;
assign g_clk = clk_en? clk : 1'b0; 

MSBSeek seek(
    .in_data(pre_sum[22:0]),
    .out_data(msb_number));


always @(posedge g_clk or negedge n_reset)
	if(!n_reset) begin
		pre_sum <= 32'b0;
		mant_added <= 1'b0;
		overflow <= 1'b0;
	end
	else
		if(term1[31] == term2[31]) begin
			if(term1[30:23] >= term2[30:23])
				begin
					if(!mant_added) 
							begin
								if({{1'b1, term1[22:0]} + ({1'b1,term2[22:0]} >> (term1[30:23] - term2[30:23]))} > 24'hFFFFFF) begin
										 pre_sum[24:0] <= {{1'b1, term1[22:0]} + ({1'b1,term2[22:0]} >> (term1[30:23] - term2[30:23]))} >> 1;
										 overflow <= 1'b1;
								end
								else begin
										 pre_sum[24:0] <=	 {{1'b1, term1[22:0]} + ({1'b1,term2[22:0]} >> (term1[30:23] - term2[30:23]))};
										 overflow <= 1'b0;
								end									
								pre_sum[30:25] <= term1[30:25];
								pre_sum[31] <= term1[31];
								mant_added <= 1'b1;
							end
					else
							begin
								pre_sum[22:0] <= pre_sum[22:0];
								pre_sum[30:23] <= overflow? term1[30:23] + 1 : term1[30:23];
								pre_sum[31] <= term1[31];
								mant_added <= 1'b0;
						   end
				end 
			else if (term1[30:23] < term2[30:23])
				begin
					if(!mant_added) 
							begin
								if({{1'b1, term2[22:0]} + ({1'b1,term1[22:0]} >> (term2[30:23] - term1[30:23]))} > 24'hFFFFFF) begin
										 pre_sum[24:0] <= {{1'b1, term2[22:0]} + ({1'b1,term1[22:0]} >> (term2[30:23] - term1[30:23]))} >> 1;
										 overflow <= 1'b1;
								end
								else begin
										 pre_sum[24:0] <=	 {{1'b1, term2[22:0]} + ({1'b1,term1[22:0]} >> (term2[30:23] - term1[30:23]))};
										 overflow <= 1'b0;
								end									
								pre_sum[30:25] <= term2[30:25];
								pre_sum[31] <= term2[31];
								mant_added <= 1'b1;
							end
					else
							begin
								pre_sum[22:0] <= pre_sum[22:0];
								pre_sum[30:23] <= overflow? term2[30:23] + 1 : term2[30:23];
								pre_sum[31] <= term2[31];
								mant_added <= 1'b0;
								overflow <= 1'b0;
						   end				
				end
		end
		else if(term1[31] != term2[31]) begin
			if(term1[30:23] > term2[30:23])
				begin
					if(!mant_added) begin
						pre_sum[23:0] <= {1'b1, term1[22:0]} - ({1'b1, term2[22:0]} >> (term1[30:23] - term2[30:23]));
						pre_sum[30:24] <= term1[30:24];
						pre_sum[31] <= term1[30:24];
						overflow <= ({1'b1, term1[22:0]} - ({1'b1, term2[22:0]} >> (term1[30:23] - term2[30:23])) < 32'h800000)? 1'b1 : 1'b0;
						mant_added <=1'b1;
					end 
					else begin
						pre_sum[22:0] <= overflow? pre_sum[22:0] << (5'd22 - msb_number) : pre_sum[22:0];
						pre_sum[30:23] <= overflow? term1[30:23] + msb_number - 5'd22 : term1[30:23];
						pre_sum[31] <= term1[31];
						overflow <= 1'b0;
						mant_added <=1'b0;
					end	
				end
			else if(term1[30:23] < term2[30:23])
			   begin
					if(!mant_added) begin
						pre_sum[23:0] <= {1'b1, term2[22:0]} - ({1'b1, term1[22:0]} >> (term2[30:23] - term1[30:23]));
						pre_sum[30:24] <= term2[30:24];
						pre_sum[31] <= term2[31];
						overflow <= ({1'b1, term2[22:0]} - ({1'b1, term1[22:0]} >> (term2[30:23] - term1[30:23])) < 32'h800000)? 1'b1 : 1'b0;
						mant_added <=1'b1;
					end 
					else begin
						pre_sum[22:0] <= overflow? pre_sum[22:0] << (5'd22 - msb_number) : pre_sum[22:0];
						pre_sum[30:23] <= overflow? term2[30:23] + msb_number - 5'd22 : term2[30:23];
						pre_sum[31] <= term2[31];
						overflow <= 1'b0;
						mant_added <=1'b0;
					end	
				end 
			else if(term1[22:0] > term2[22:0])
				begin
					if(!mant_added) begin
						pre_sum[22:0] <= term1[22:0] - term2[22:0];
						pre_sum[30:23] <= term1[30:23];
						pre_sum[31] <= term1[31];
						overflow <= 1'b0;
						mant_added <=1'b1;
					end 
					else begin
						pre_sum[22:0] <= pre_sum[22:0] << (5'd22 - msb_number);
						pre_sum[30:23] <= term1[30:23] + msb_number - 5'd22;
						pre_sum[31] <= term1[31];
						overflow <= 1'b0;
						mant_added <=1'b0;
					end	
				end 
			else if(term1[22:0] < term2[22:0])
				begin
					if(!mant_added) begin
						pre_sum[22:0] <= term2[22:0] - term1[22:0];
						pre_sum[30:23] <= term2[30:23];
						pre_sum[31] <= term2[31];
						overflow <= 1'b0;
						mant_added <=1'b1;
					end 
					else begin
						pre_sum[22:0] <= pre_sum[22:0] << (5'd22 - msb_number);
						pre_sum[30:23] <= term2[30:23] + msb_number - 5'd22;
						pre_sum[31] <= term2[31];
						overflow <= 1'b0;
						mant_added <=1'b0;
					end	
				end 
			else if(term1[30:0] == term2[30:0]) begin
					pre_sum <= 32'b0;
					mant_added <= 1'b0;
					overflow <= 1'b0;
			end 
		end
endmodule 