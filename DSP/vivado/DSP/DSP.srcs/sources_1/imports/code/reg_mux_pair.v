module REG_MUX_pair (BLOCK_IN, SEL, CLK, RST, CE, BLOCK_OUT);
parameter RSTTYPE = "SYNC";
parameter WIDTH = 18;
input SEL,CLK,RST,CE;
input   [WIDTH-1:0] BLOCK_IN;
output  [WIDTH-1:0] BLOCK_OUT;
reg     [WIDTH-1:0] REG_OUT;

generate
	if (RSTTYPE == "SYNC") begin
		always @(posedge CLK) begin
			if (RST) begin
				REG_OUT <= 0;
			end
			else if (CE) begin
				REG_OUT <= BLOCK_IN;
			end
		end
	end	
	else if (RSTTYPE == "ASYNC") begin
		always @(posedge CLK or posedge RST) begin
			if (RST) begin
				REG_OUT <= 0;
			end
			else if (CE) begin
				REG_OUT<=BLOCK_IN;
			end
		end
	end
endgenerate

assign BLOCK_OUT = (SEL)? REG_OUT : BLOCK_IN ;
endmodule