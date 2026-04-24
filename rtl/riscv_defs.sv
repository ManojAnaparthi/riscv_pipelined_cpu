package riscv_defs;
  localparam logic [6:0] OPCODE_R_TYPE = 7'b0110011;
  localparam logic [6:0] OPCODE_I_TYPE = 7'b0010011;
  localparam logic [6:0] OPCODE_LOAD   = 7'b0000011;
  localparam logic [6:0] OPCODE_STORE  = 7'b0100011;
  localparam logic [6:0] OPCODE_BRANCH = 7'b1100011;

  localparam logic [3:0] ALU_ADD = 4'b0000;
  localparam logic [3:0] ALU_SUB = 4'b0001;
  localparam logic [3:0] ALU_AND = 4'b0010;
  localparam logic [3:0] ALU_OR  = 4'b0011;
endpackage
