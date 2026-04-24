module alu (
  input  logic [31:0] a,
  input  logic [31:0] b,
  input  logic [3:0]  alu_control,
  output logic [31:0] result,
  output logic        zero
);
  import riscv_defs::*;

  always_comb begin
    case (alu_control)
      ALU_ADD: result = a + b;
      ALU_SUB: result = a - b;
      ALU_AND: result = a & b;
      ALU_OR:  result = a | b;
      default: result = 32'b0;
    endcase
  end

  assign zero = (result == 32'b0);
endmodule
