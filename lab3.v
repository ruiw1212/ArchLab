// Northwestern - CompEng 361 - Lab2
// Groupname: SmartArch
// NetIDs: tht5102, dsn9734 

// Definition of ISA Encoding
`define OPCODE_COMPUTE    7'b0110011
`define OPCODE_BRANCH     7'b1100011
`define OPCODE_LOAD       7'b0000011
`define OPCODE_STORE      7'b0100011 
`define OPCODE_COMPUTE_I  7'b0010011
`define OPCODE_LUI        7'b0110111
`define OPCODE_AUIPC      7'b0010111
`define OPCODE_JUMP       7'b1101111
`define OPCODE_JUMPR      7'b1100111

// R-type FUNCT3
`define FUNC_ADD      3'b000
`define FUNC_SUB      3'b000
`define FUNC_SLL      3'b001
`define FUNC_SLT      3'b010
`define FUNC_SLTU     3'b011
`define FUNC_XOR      3'b100
`define FUNC_SRL      3'b101
`define FUNC_SRA      3'b101
`define FUNC_OR       3'b110
`define FUNC_AND      3'b111

// R-type FUNCT7
`define AUX_FUNC_ADD  7'b0000000
`define AUX_FUNC_SUB  7'b0100000
`define AUX_FUNC_SLL  7'b0000000
`define AUX_FUNC_SLT  7'b0000000
`define AUX_FUNC_SLTU 7'b0000000
`define AUX_FUNC_XOR  7'b0000000
`define AUX_FUNC_SRL  7'b0000000
`define AUX_FUNC_SRA  7'b0100000
`define AUX_FUNC_OR   7'b0000000
`define AUX_FUNC_AND  7'b0000000

// I-type FUNCT3
`define FUNC_ADDI     3'b000
`define FUNC_SLLI     3'b001
`define FUNC_SLTI     3'b010
`define FUNC_SLTIU    3'b011
`define FUNC_XORI     3'b100
`define FUNC_SRLI     3'b101
`define FUNC_SRAI     3'b101
`define FUNC_ORI      3'b110
`define FUNC_ANDI     3'b111

// I-type FUNCT7
`define AUX_FUNC_SLLI 7'b0000000
`define AUX_FUNC_SRLI 7'b0000000
`define AUX_FUNC_SRAI 7'b0100000

// S-type FUNCT3
`define FUNC_SB       3'b000
`define FUNC_SH       3'b001
`define FUNC_SW       3'b010

// L-type FUNCT3
`define FUNC_LB       3'b000
`define FUNC_LH       3'b001
`define FUNC_LW       3'b010
`define FUNC_LBU      3'b100
`define FUNC_LHU      3'b101

// B-type FUNCT3
`define FUNC_BEQ      3'b000
`define FUNC_BNE      3'b001
`define FUNC_BLT      3'b100
`define FUNC_BGE      3'b101
`define FUNC_BLTU     3'b110
`define FUNC_BGEU     3'b111

// J-type FUNCT3
`define FUNC_JALR      3'b000

// Memory Size
`define SIZE_BYTE  2'b00
`define SIZE_HWORD 2'b01
`define SIZE_WORD  2'b10

module PipelinedCPU(halt, clk, rst);
  output halt;
  input clk, rst;


  /**************************IF Stage Begin*************************************/
  // pipeline registers
  reg[31:0] IF_ID_InstWord;

  // define module instances
  wire [31:0] PC , NPC, PC_Plus_4; // PC and NPC
  wire [31:0] InstWord ; 

  // updating the module intsances
  assign PC_Plus_4 = PC + 4; // PC + 4
  assign NPC = PC_Plus_4; // NPC = PC + 4
  Reg PC_REG(.Din(NPC), .Qout(PC), .WEN(1'b0), .CLK(clk), .RST(rst));
  InstMem IMEM(.Addr(PC), .Size(`SIZE_WORD), .DataOut(InstWord), .CLK(clk));

  // updating pipeline registers
  always @(negedge clk) begin
    IF_ID_InstWord <= InstWord;
  end
  /**************************IF Stage End *************************************/




  /**************************ID Stage Begin*************************************/
  // pipeline registers
  reg [31:0] ID_EX_OpA, ID_EX_OpB; 
  reg [2:0]  ID_EX_Func3;
  reg [6:0]  ID_EX_Func7;
  reg [4:0]  ID_EX_Rdst; 

  // define module instances
  wire [6:0]  opcode;
  wire [6:0]  funct7;
  wire [2:0]  funct3;
  wire known_type ;
  wire IsRtype ; 
  wire [4:0]  Rsrc1_ID, Rsrc2_ID, Rdst_ID, Rdst_actual;
  wire [31:0] Rdata1_ID, Rdata2_ID, RWrdata_ID;
  wire        RWrEn_ID;
  
  // updating the module intsances
  assign opcode = IF_ID_InstWord[6:0];
  assign funct7 = IF_ID_InstWord[31:25];
  assign funct3 = IF_ID_InstWord[14:12];
  assign Rsrc1_ID = IF_ID_InstWord[19:15];
  assign Rsrc2_ID = IF_ID_InstWord[24:20];
  assign Rdst_ID = IF_ID_InstWord[11:7];
  assign RWrEn_ID = 1'b0; // not enable in ID stage
  assign Rdst_actual = WB_Rdst; // get the actual Rdst from WB stage
  assign RWrdata_ID = WB_ForwardedData; // get the forwarded data from WB stage

  assign IsRtype = (opcode == `OPCODE_COMPUTE) && 
  ( (funct3 == `FUNC_ADD) || (funct3 == `FUNC_SUB) || (funct3 == `FUNC_SLL) || (funct3 == `FUNC_SLT) || (funct3 == `FUNC_SLTU) || (funct3 == `FUNC_XOR) || (funct3 == `FUNC_SRL) || (funct3 == `FUNC_SRA) || (funct3 == `FUNC_OR) || (funct3 == `FUNC_AND) )&& 
  ( (funct7 == `AUX_FUNC_ADD) || (funct7 == `AUX_FUNC_SUB) || (funct7 == `AUX_FUNC_SLL) || (funct7 == `AUX_FUNC_SLT) || (funct7 == `AUX_FUNC_SLTU) || (funct7 == `AUX_FUNC_XOR) || (funct7 == `AUX_FUNC_SRL) || (funct7 == `AUX_FUNC_SRA) || (funct7 == `AUX_FUNC_OR) || (funct7 == `AUX_FUNC_AND));

  assign known_type = IsRtype ;
  assign halt = !(known_type) ;

  RegFile RF(.AddrA(Rsrc1_ID), .DataOutA(Rdata1_ID), 
      .AddrB(Rsrc2_ID), .DataOutB(Rdata2_ID), 
      .AddrW(Rdst_actual), .DataInW(RWrdata_ID), .WenW(RWrEn_ID), .CLK(clk));

  // updating pipeline registers
  always @(negedge clk) begin
    ID_EX_OpA <= Rdata1_ID;
    ID_EX_OpB <= Rdata2_ID;
    ID_EX_Func3 <= funct3;
    ID_EX_Func7 <= funct7;
    ID_EX_Rdst <= Rdst_ID;
  end
  /**************************ID Stage End *************************************/




  /**************************EX Stage Begin*************************************/
  // pipeline registers
  reg [31:0] EX_MEM_ALUresult;
  reg [4:0]  EX_MEM_Rdst;

  // define module instances
  wire [31:0] ALUresult;
  wire [4:0] Rdst_EX;
  wire [31:0] OpA, OpB;
  wire [2:0]  func_EX;
  wire [6:0]  auxFunc_EX;
  wire IsRtype_EX;

  // updating the module intsances
  assign OpA = ID_EX_OpA;
  assign OpB = ID_EX_OpB;
  assign func_EX = ID_EX_Func3;
  assign auxFunc_EX = ID_EX_Func7;
  assign IsRtype_EX = 1'b1;
  assign Rdst_EX = ID_EX_Rdst;
  ExecutionUnit EU(.out(ALUresult), .opA(OpA), .opB(OpB), .func(ID_EX_Func3), .auxFunc(ID_EX_Func7), .IsRtype(IsRtype), .IsItype(1'b0), .IsIshift(1'b0));

  // updating pipeline registers
  always @(negedge clk) begin
    EX_MEM_ALUresult <= ALUresult;
    EX_MEM_Rdst <= Rdst_EX;
  end
  /**************************EX Stage End**************************************/


  /*************************MEM Stage Begin*************************************/
  // pipeline registers
  reg [31:0] MEM_WB_ALUresult;
  reg [4:0]  MEM_WB_Rdst;

  // define module instances
  wire [31:0] ALUresult_MEM;
  wire [4:0] Rdst_MEM;

  // updating the module intsances
  assign ALUresult_MEM = EX_MEM_ALUresult;
  assign Rdst_MEM = EX_MEM_Rdst;

  // updating pipeline registers
  always @(negedge clk) begin
    MEM_WB_ALUresult <= ALUresult_MEM;
    MEM_WB_Rdst <= Rdst_MEM;
  end
  /*************************MEM Stage End***************************************/


  /*************************WB Stage Begin**************************************/
  // pipeline registers
  reg [31:0] WB_ForwardedData;
  reg [4:0]  WB_Rdst;

  // define module instances
  wire [31:0] ALUresult_WB;
  wire [4:0]  Rdst_WB;
  wire RWrEn_WB;

  // updating the module intsances
  assign ALUresult_WB = MEM_WB_ALUresult;
  assign Rdst_WB = MEM_WB_Rdst;
  assign RWrEn_WB = 1'b0; // enable in WB stage

  // forward the data to the ID state in order to write back 
  always @(negedge clk) begin
    WB_ForwardedData <= ALUresult_WB;
    WB_Rdst <= Rdst_WB;
  end
  /*************************WB Stage End****************************************/
endmodule // PipelinedCPU


// EU provide ALU result for R and I type instructions
module ExecutionUnit(out, opA, opB, func, auxFunc, IsRtype, IsItype, IsIshift);
   output [31:0] out;
   input [31:0]  opA, opB;
   input [2:0] 	 func;
   input [6:0] 	 auxFunc;
   input IsRtype;
   input IsItype;
   input IsIshift;

  reg [31:0] result;
  
  always @(*) begin
    if (IsRtype) begin
      case({func, auxFunc})
        // artithmetic operations
        10'b000_0000000: result <= opA + opB; // ADD, assume no overflow bit
        10'b000_0100000: result <= opA - opB; // SUB
        // logic operations
        10'b111_0000000: result <= opA & opB; // AND
        10'b110_0000000: result <= opA | opB; // OR
        10'b100_0000000: result <= opA ^ opB; // XOR
        // shift operations
        10'b001_0000000: result <= $unsigned(opA) << opB; // SLL
        10'b101_0000000: result <= $unsigned(opA) >> opB; // SRL
        10'b010_0000000: result <= ($signed(opA) < $signed(opB)) ? 32'b1 : 32'b0; // SLT
        10'b011_0000000: result <= ($unsigned(opA) < $unsigned(opB))? 32'b1 : 32'b0; // SLTU
        10'b101_0100000: result <= ($signed(opA) >>> $unsigned(opB)); // SRA
      endcase
    end
    else if (IsItype) begin
      case (func)
      // addi
      3'b000: result <= opA + opB;
      // slti
      3'b010: result <= ($signed(opA) < $signed(opB)) ? 32'b1 : 32'b0;
      // sltiu
      3'b011: result <= ($unsigned(opA) < $unsigned(opB)) ? 32'b1 : 32'b0;
      // xori
      3'b100: result <= opA ^ opB;
      // ori
      3'b110: result <= opA | opB;
      // andi
      3'b111: result <= opA & opB;
      endcase
    end 
    else if (IsIshift) begin
      case({func, auxFunc})
      // slli 
      10'b001_0000000: result <= $unsigned(opA) << $unsigned(opB);
      // srli
      10'b101_0000000: result <= $unsigned(opA) >> $unsigned(opB);
      // srai
      10'b101_0100000: result <= ($signed(opA) >>> $unsigned(opB));
      endcase
    end
    else begin
      result <= 32'b0;
    end
  end

  assign out = result;

   
endmodule // ExecutionUnit