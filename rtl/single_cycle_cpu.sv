module single_cycle_cpu #(
  parameter INSTRUCTION_FILE = ""
) (
  input  logic        clk,
  input  logic        reset,
  output logic [31:0] pc
);
  import riscv_defs::*;

  logic [31:0] next_pc;
  logic [31:0] instruction;
  logic [31:0] immediate;
  logic [31:0] rs1_data;
  logic [31:0] rs2_data;
  logic [31:0] alu_operand_b;
  logic [31:0] alu_result;
  logic [31:0] memory_read_data;
  logic [31:0] writeback_data;
  logic        alu_zero;
  logic        reg_write;
  logic        mem_read;
  logic        mem_write;
  logic        mem_to_reg;
  logic        alu_src;
  logic        branch;
  logic        illegal_instruction;
  logic [3:0]  alu_control;

  instruction_memory #(.INIT_FILE(INSTRUCTION_FILE)) imem (
    .address(pc),
    .instruction(instruction)
  );

  register_file regs (
    .clk(clk),
    .reset(reset),
    .read_addr_1(instruction[19:15]),
    .read_addr_2(instruction[24:20]),
    .read_data_1(rs1_data),
    .read_data_2(rs2_data),
    .write_enable(reg_write),
    .write_addr(instruction[11:7]),
    .write_data(writeback_data)
  );

  immediate_generator immediate_gen (
    .instruction(instruction),
    .immediate(immediate)
  );

  control_unit control (
    .instruction(instruction),
    .reg_write(reg_write),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_to_reg(mem_to_reg),
    .alu_src(alu_src),
    .branch(branch),
    .alu_control(alu_control),
    .illegal_instruction(illegal_instruction)
  );

  assign alu_operand_b = alu_src ? immediate : rs2_data;

  alu execute_alu (
    .a(rs1_data),
    .b(alu_operand_b),
    .alu_control(alu_control),
    .result(alu_result),
    .zero(alu_zero)
  );

  data_memory dmem (
    .clk(clk),
    .reset(reset),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .address(alu_result),
    .write_data(rs2_data),
    .read_data(memory_read_data)
  );

  assign writeback_data = mem_to_reg ? memory_read_data : alu_result;
  assign next_pc = (branch && alu_zero) ? pc + immediate : pc + 32'd4;

  always_ff @(posedge clk) begin
    if (reset)
      pc <= 32'b0;
    else
      pc <= next_pc;
  end
endmodule
