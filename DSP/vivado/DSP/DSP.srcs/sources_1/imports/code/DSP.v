`timescale 1ns/1ps

module DSP48A1 #(
    // Parameterized pipeline register enables (1 = register enabled, 0 = bypassed)
    parameter A0REG = 0,
    parameter A1REG = 1,
    parameter B0REG = 0,
    parameter B1REG = 1,
    parameter CREG = 1,
    parameter DREG = 1,
    parameter MREG = 1,
    parameter PREG = 1,
    parameter CARRYINREG = 1,
    parameter CARRYOUTREG = 1, 
    parameter OPMODEREG = 1,

    // Functional parameters controlling carry selection and input mode
    parameter CARRYINSEL = "OPMODE5",  // Controls carry input selection
    parameter B_INPUT = "DIRECT",  // Selects direct B input or cascade from BCIN
    parameter RSTTYPE = "SYNC"  // Determines reset type (SYNC/ASYNC)
)(
    // Data inputs
    input  [17:0] A, B, D,
    input  [47:0] C,
    input  [47:0] PCIN,
    input  [17:0] BCIN,
    input  [7:0] OPMODE,

    // Data outputs
    output [35:0] M,
    output [47:0] P,
    output [17:0] BCOUT,
    output [47:0] PCOUT,

    // Clock, carry input, and control signals
    input  CLK,
    input  CARRYIN,
    input  CEA, CEB, CEC, CECARRYIN, CED, CEM, CEOPMODE, CEP,
    input  RSTA, RSTB, RSTC, RSTCARRYIN, RSTD, RSTM, RSTOPMODE, RSTP,

    // Carry outputs
    output CARRYOUT, CARRYOUTF
);

// --------------------------------------
// Stage 1: Input Registers and Muxing
// --------------------------------------
wire [17:0] D_BLOCK_OUT, B0_MUX_OUT, B0_BLOCK_OUT, A0_BLOCK_OUT;
wire [47:0] C_BLOCK_OUT;

// Select B input source (direct or cascade)
assign B0_MUX_OUT = (B_INPUT == "DIRECT") ? B : (B_INPUT == "CASCADE") ? BCIN : 18'b0;

// Register inputs if pipeline is enabled
REG_MUX_pair #(.WIDTH(18), .RSTTYPE(RSTTYPE)) D_BLOCK (.BLOCK_IN(D), .SEL(DREG), .CLK(CLK), .RST(RSTD), .CE(CED), .BLOCK_OUT(D_BLOCK_OUT));
REG_MUX_pair #(.WIDTH(18), .RSTTYPE(RSTTYPE)) B0_BLOCK (.BLOCK_IN(B0_MUX_OUT), .SEL(B0REG), .CLK(CLK), .RST(RSTB), .CE(CEB), .BLOCK_OUT(B0_BLOCK_OUT));
REG_MUX_pair #(.WIDTH(18), .RSTTYPE(RSTTYPE)) A0_BLOCK (.BLOCK_IN(A), .SEL(A0REG), .CLK(CLK), .RST(RSTA), .CE(CEA), .BLOCK_OUT(A0_BLOCK_OUT));
REG_MUX_pair #(.WIDTH(48), .RSTTYPE(RSTTYPE)) C_BLOCK (.BLOCK_IN(C), .SEL(CREG), .CLK(CLK), .RST(RSTC), .CE(CEC), .BLOCK_OUT(C_BLOCK_OUT));

// --------------------------------------
// Stage 2: OPMODE Register and Pre-Adder
// --------------------------------------
wire [7:0] OPMODE_BLOCK_OUT;
wire [17:0] PREADDER_OUT, PREADDER_MUX_OUT;

// Register OPMODE control signals
REG_MUX_pair #(.WIDTH(8), .RSTTYPE(RSTTYPE)) OPMODE_BLOCK (.BLOCK_IN(OPMODE), .SEL(OPMODEREG), .CLK(CLK), .RST(RSTOPMODE), .CE(CEOPMODE), .BLOCK_OUT(OPMODE_BLOCK_OUT));

// Pre-Adder operation based on OPMODE[6]
assign PREADDER_OUT = (OPMODE_BLOCK_OUT[6]) ? (D_BLOCK_OUT - B0_BLOCK_OUT) : (D_BLOCK_OUT + B0_BLOCK_OUT);

// Select whether to use the pre-adder output or bypass it
assign PREADDER_MUX_OUT = (OPMODE_BLOCK_OUT[4]) ? PREADDER_OUT : B0_BLOCK_OUT;

// --------------------------------------
// Stage 3: Registering Pre-Adder Outputs
// --------------------------------------
wire [17:0] B1_BLOCK_OUT, A1_BLOCK_OUT;

REG_MUX_pair #(.WIDTH(18), .RSTTYPE(RSTTYPE)) B1_BLOCK (.BLOCK_IN(PREADDER_MUX_OUT), .SEL(B1REG), .CLK(CLK), .RST(RSTB), .CE(CEB), .BLOCK_OUT(B1_BLOCK_OUT));
REG_MUX_pair #(.WIDTH(18), .RSTTYPE(RSTTYPE)) A1_BLOCK (.BLOCK_IN(A0_BLOCK_OUT), .SEL(A1REG), .CLK(CLK), .RST(RSTA), .CE(CEA), .BLOCK_OUT(A1_BLOCK_OUT));

// --------------------------------------
// Stage 4: Multiplication and Carry Handling
// --------------------------------------
wire [35:0] MUL_OUT, MUL_BLOCK_OUT;
wire CARRY_MUX_OUT, CIN;

// Cascade output assignment
assign BCOUT = B1_BLOCK_OUT;

// Perform 18-bit x 18-bit multiplication
assign MUL_OUT = B1_BLOCK_OUT * A1_BLOCK_OUT;

// Select carry input source
assign CARRY_MUX_OUT = (CARRYINSEL == "OPMODE5") ? OPMODE_BLOCK_OUT[5] : (CARRYINSEL == "CARRYIN") ? CARRYIN : 1'b0;

// Generate Block: Buffering Multiplication Output
generate
	genvar i;
	for(i = 0;i<36;i=i+1)
		buf(M[i],MUL_BLOCK_OUT[i]); 
endgenerate
//assign M = MUL_BLOCK_OUT;

// Register multiplication output and carry input
REG_MUX_pair #(.WIDTH(36), .RSTTYPE(RSTTYPE)) MUL_BLOCK (.BLOCK_IN(MUL_OUT), .SEL(MREG), .CLK(CLK), .RST(RSTM), .CE(CEM), .BLOCK_OUT(MUL_BLOCK_OUT));
REG_MUX_pair #(.WIDTH(1), .RSTTYPE(RSTTYPE)) CYI_BLOCK (.BLOCK_IN(CARRY_MUX_OUT), .SEL(CARRYINREG), .CLK(CLK), .RST(RSTCARRYIN), .CE(CECARRYIN), .BLOCK_OUT(CIN));

// --------------------------------------
// Stage 5: Post-Adder and Final Output
// --------------------------------------
wire [47:0] MUXX_OUT, D_A_B_CONCAT, MUXZ_OUT, POSTADDER_SUM;
wire POSTADDER_COUT;

// Assign output control signals
assign CARRYOUTF = CARRYOUT;
assign PCOUT = P;

// Concatenation of inputs for post-adder
assign D_A_B_CONCAT = {D[11:0], A[17:0], B[17:0]};

// Select input to post-adder
assign MUXX_OUT = (OPMODE_BLOCK_OUT[1:0] == 2'b00) ? 48'b0 :
                  (OPMODE_BLOCK_OUT[1:0] == 2'b01) ? MUL_BLOCK_OUT :
                  (OPMODE_BLOCK_OUT[1:0] == 2'b10) ? P : D_A_B_CONCAT;

assign MUXZ_OUT = (OPMODE_BLOCK_OUT[3:2] == 2'b00) ? 48'b0 :
                  (OPMODE_BLOCK_OUT[3:2] == 2'b01) ? PCIN :
                  (OPMODE_BLOCK_OUT[3:2] == 2'b10) ? P : C_BLOCK_OUT;

// Final addition/subtraction with carry-in
assign {POSTADDERCOUT, POSTADDER_SUM} = (OPMODE_BLOCK_OUT[7]) ? 
        (MUXZ_OUT - (MUXX_OUT + CIN)) : (MUXZ_OUT + MUXX_OUT + CIN);

// Registering final outputs
REG_MUX_pair #(.WIDTH(1), .RSTTYPE(RSTTYPE)) CYO_BLOCK (.BLOCK_IN(POSTADDERCOUT), .SEL(CARRYOUTREG), .CLK(CLK), .RST(RSTCARRYIN), .CE(CECARRYIN), .BLOCK_OUT(CARRYOUT));
REG_MUX_pair #(.WIDTH(48), .RSTTYPE(RSTTYPE)) P_BLOCK (.BLOCK_IN(POSTADDER_SUM), .SEL(PREG), .CLK(CLK), .RST(RSTP), .CE(CEP), .BLOCK_OUT(P));

endmodule
