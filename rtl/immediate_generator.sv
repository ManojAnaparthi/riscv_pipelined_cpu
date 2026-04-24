module immediate_generator (
  input  logic [31:0] instruction,
  output logic [31:0] immediate
);
  import riscv_defs::*;

  always_comb begin
    case (instruction[6:0])
      OPCODE_I_TYPE, OPCODE_LOAD:
        immediate = {{20{instruction[31]}}, instruction[31:20]};
      OPCODE_STORE:
        immediate = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
      OPCODE_BRANCH:
        immediate = {{19{instruction[31]}}, instruction[31], instruction[7],
                     instruction[30:25], instruction[11:8], 1'b0};
      default:
        immediate = 32'b0;
    endcase
  end
endmodule
