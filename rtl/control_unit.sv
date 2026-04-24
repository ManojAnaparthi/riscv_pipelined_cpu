module control_unit (
  input  logic [31:0] instruction,
  output logic        reg_write,
  output logic        mem_read,
  output logic        mem_write,
  output logic        mem_to_reg,
  output logic        alu_src,
  output logic        branch,
  output logic [3:0]  alu_control,
  output logic        illegal_instruction
);
  import riscv_defs::*;

  always_comb begin
    reg_write         = 1'b0;
    mem_read          = 1'b0;
    mem_write         = 1'b0;
    mem_to_reg        = 1'b0;
    alu_src           = 1'b0;
    branch            = 1'b0;
    alu_control       = ALU_ADD;
    illegal_instruction = 1'b0;

    case (instruction[6:0])
      OPCODE_R_TYPE: begin
        reg_write = 1'b1;
        case ({instruction[30], instruction[14:12]})
          4'b0000: alu_control = ALU_ADD;
          4'b1000: alu_control = ALU_SUB;
          4'b0111: alu_control = ALU_AND;
          4'b0110: alu_control = ALU_OR;
          default: begin
            reg_write = 1'b0;
            illegal_instruction = 1'b1;
          end
        endcase
      end

      OPCODE_I_TYPE: begin
        if (instruction[14:12] == 3'b000) begin
          reg_write = 1'b1;
          alu_src = 1'b1;
          alu_control = ALU_ADD;
        end else begin
          illegal_instruction = 1'b1;
        end
      end

      OPCODE_LOAD: begin
        if (instruction[14:12] == 3'b010) begin
          reg_write = 1'b1;
          mem_read = 1'b1;
          mem_to_reg = 1'b1;
          alu_src = 1'b1;
          alu_control = ALU_ADD;
        end else begin
          illegal_instruction = 1'b1;
        end
      end

      OPCODE_STORE: begin
        if (instruction[14:12] == 3'b010) begin
          mem_write = 1'b1;
          alu_src = 1'b1;
          alu_control = ALU_ADD;
        end else begin
          illegal_instruction = 1'b1;
        end
      end

      OPCODE_BRANCH: begin
        if (instruction[14:12] == 3'b000) begin
          branch = 1'b1;
          alu_control = ALU_SUB;
        end else begin
          illegal_instruction = 1'b1;
        end
      end

      default:
        illegal_instruction = 1'b1;
    endcase
  end
endmodule
