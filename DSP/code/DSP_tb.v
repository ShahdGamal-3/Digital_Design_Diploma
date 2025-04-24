`timescale 1ns/1ps

module DSP48A1_tb();

// ------------------------------
// Parameter Definitions
// ------------------------------
parameter A0REG = 0 ;
parameter A1REG = 1 ;
parameter B0REG = 0 ;
parameter B1REG = 1 ;
parameter CREG = 1; 
parameter DREG = 1 ; 
parameter MREG = 1 ; 
parameter PREG = 1 ; 
parameter CARRYINREG = 1 ; 
parameter CARRYOUTREG = 1 ; 
parameter OPMODEREG = 1;
parameter CARRYINSEL = "OPMODE5";  // Determines carry input selection
parameter B_INPUT = "DIRECT";  // Specifies whether B input is direct or cascaded
parameter RSTTYPE = "SYNC";  // Specifies whether resets are synchronous or asynchronous

// ------------------------------
// Signal Declarations
// ------------------------------
reg [17:0] A, B, D;
reg [47:0] C, PCIN;
reg [17:0] BCIN;
reg CLK, CARRYIN;
reg [7:0] OPMODE;
reg RSTA, RSTB, RSTM, RSTP, RSTC, RSTD, RSTCARRYIN, RSTOPMODE;
reg CEA, CEB, CEM, CEP, CEC, CED, CECARRYIN, CEOPMODE;

wire [17:0] BCOUT;
wire [47:0] PCOUT, P;
wire [35:0] M;
wire CARRYOUT, CARRYOUTF;

// ------------------------------
// Device Under Test (DUT) Instantiation
// ------------------------------
DSP48A1 #(
    .A0REG(A0REG), .A1REG(A1REG), .B0REG(B0REG), .B1REG(B1REG),
    .CREG(CREG), .DREG(DREG), .MREG(MREG), .PREG(PREG),
    .CARRYINREG(CARRYINREG), .CARRYOUTREG(CARRYOUTREG),
    .OPMODEREG(OPMODEREG), .CARRYINSEL(CARRYINSEL), .B_INPUT(B_INPUT), .RSTTYPE(RSTTYPE)
) DUT (
    .A(A), .B(B), .D(D), .C(C), .CLK(CLK), .CARRYIN(CARRYIN), .OPMODE(OPMODE),
    .BCIN(BCIN), .RSTA(RSTA), .RSTB(RSTB), .RSTM(RSTM), .RSTP(RSTP),
    .RSTC(RSTC), .RSTD(RSTD), .RSTCARRYIN(RSTCARRYIN), .RSTOPMODE(RSTOPMODE),
    .CEA(CEA), .CEB(CEB), .CEM(CEM), .CEP(CEP), .CEC(CEC), .CED(CED),
    .CECARRYIN(CECARRYIN), .CEOPMODE(CEOPMODE), .PCIN(PCIN),
    .BCOUT(BCOUT), .PCOUT(PCOUT), .P(P), .M(M), .CARRYOUT(CARRYOUT), .CARRYOUTF(CARRYOUTF)
);

// ------------------------------
// Clock Generation
// ------------------------------
initial begin
    CLK = 0;
    forever #1 CLK = ~CLK;  // Generates a clock signal with a period of 2 ns
end

// ------------------------------
// Test Stimulus Generator
// ------------------------------
initial begin
    // Initialize and assert reset signals
    RSTA = 1; RSTB = 1; RSTM = 1;       RSTP = 1; 
    RSTC = 1; RSTD = 1; RSTCARRYIN = 1; RSTOPMODE = 1;
    CEA = 1;  CEB = 1;  CEM = 1;        CEP = 1;
    CEC = 1;  CED = 1;  CECARRYIN = 1;  CEOPMODE = 1;
    A = 0;    B = 0;    C = 0;          D = 0;
    CARRYIN = 0;        BCIN = 0;       PCIN = 0;
    OPMODE = 8'b00000000;

    repeat(5) @(negedge CLK);

    // Release resets
    RSTA = 0; RSTB = 0; RSTM = 0;       RSTP = 0; 
    RSTC = 0; RSTD = 0; RSTCARRYIN = 0; RSTOPMODE = 0;

    // ------------------------------ 
    // Test Cases
    // ------------------------------

    // Test Case 1: Basic addition
    A = 20; B = 50; C = 10; D = 100; CARRYIN = 0; BCIN = 5; PCIN = 40;
    OPMODE = 8'b01101111; // A + B + D + C
    repeat(5) @(negedge CLK);

    // Test Case 2: Basic subtraction
    A = 80; B = 10; C = 10; D = 10; CARRYIN = 0;
    OPMODE = 8'b01010100; // A - B - D - C
    repeat(5) @(negedge CLK);

    // Test Case 3: Multiplication with addition
    A = 15; B = 10; C = 100; D = 5; CARRYIN = 0;
    OPMODE = 8'b00101010; // A * B + D + C
    repeat(5) @(negedge CLK);

    // Test Case 4: Accumulation with CARRYIN
    A = 10; B = 20; C = 50; D = 10; CARRYIN = 1;
    OPMODE = 8'b10001101; // A + B + D + CARRYIN
    repeat(5) @(negedge CLK);

    // Test Case 5: Chained operations with different OPMODE values
    A = 50; B = 25; C = 200; D = 10; CARRYIN = 0;
    OPMODE = 8'b01111111; // Complex operation
    repeat(5) @(negedge CLK);

    // Test Case 6: Cascade input (BCIN) handling
    A = 60; B = 30; C = 100; D = 10; CARRYIN = 0; BCIN = 10;
    OPMODE = 8'b11000010; // Perform operation using BCIN
    repeat(5) @(negedge CLK);

    // Test Case 7: Complex operation using all inputs
    A = 70; B = 40; C = 150; D = 20; CARRYIN = 1;
    OPMODE = 8'b10101010; // Another complex operation
    repeat(5) @(negedge CLK);

    // Test Case 8: Another OPMODE setting with all inputs
    A = 80; B = 50; C = 175; D = 25; CARRYIN = 0;
    OPMODE = 8'b00011000; // Another operation mode
    repeat(5) @(negedge CLK);

    // Test Case 9: Overflow scenario (max values)
    A = 18'h3FFFF; B = 18'h3FFFF; C = 48'hFFFFFFFFFFFF; D = 18'h3FFFF;
    CARRYIN = 1;
    OPMODE = 8'b10000000; // Checking max value addition
    repeat(5) @(negedge CLK);

    // Test Case 10: Zero Inputs (A, B, C, D all zero)
    A = 0; B = 0; C = 0; D = 0; CARRYIN = 0;
    OPMODE = 8'b00001111; // Testing zero addition
    repeat(5) @(negedge CLK);

    // Test Case 11: Negative values (2's complement simulation)
    A = -10; B = -5; C = -50; D = -20; CARRYIN = 1;
    OPMODE = 8'b11100001; // Negative accumulation
    repeat(5) @(negedge CLK);

    // Test Case 12: Carry propagation
    A = 50; B = 25; C = 200; D = 10; CARRYIN = 1;
    OPMODE = 8'b10001101; // Carry should propagate
    repeat(5) @(negedge CLK);

    // Test Case 13: Cascade input (BCIN) handling
    A = 60; B = 30; C = 100; D = 10; CARRYIN = 0; BCIN = 10;
    OPMODE = 8'b11000010; // Perform operation using BCIN
    repeat(5) @(negedge CLK);

    // Test Case 14: Different shift and accumulation
    A = 12; B = 5; C = 60; D = 4; CARRYIN = 0;
    OPMODE = 8'b10101010; // Shift-accumulate
    repeat(5) @(negedge CLK);

    // ------------------------------
    // Reset and Finish Simulation
    // ------------------------------
    RSTA = 1; RSTB = 1; RSTM = 1;       RSTP = 1;
    RSTC = 1; RSTD = 1; RSTCARRYIN = 1; RSTOPMODE = 1;
    CEA = 0;  CEB = 0;  CEM = 0;        CEP = 0;
    CEC = 0;  CED = 0;  CECARRYIN = 0;  CEOPMODE = 0;
    A = 0;    B = 0;    C = 0;          D = 0;
    CARRYIN = 0;        BCIN = 0;       PCIN = 0;
    OPMODE = 8'b00000000;

    repeat(10) @(negedge CLK);
    $stop;  // Stop simulation
end

// ------------------------------
// Test Monitor and Debugging
// ------------------------------
initial begin
    $monitor("Time=%t | A=%d, B=%d, C=%d, D=%d, CARRYIN=%d, PCIN=%d, OPMODE=%b, P=%d, BCOUT=%d, M=%d, CARRYOUT=%d", 
             $time, A, B, C, D, CARRYIN, PCIN, OPMODE, P, BCOUT, M, CARRYOUT);
end

endmodule
