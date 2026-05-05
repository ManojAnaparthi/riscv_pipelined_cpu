module pipelined_cpu #(
  parameter INSTRUCTION_FILE = ""
) (
  input  logic        clk,
  input  logic        reset,
  output logic [31:0] pc
);
  import riscv_defs::*;

  logic [31:0] instruction;
  logic [31:0] next_pc;
  logic [31:0] rs1_data;
  logic [31:0] rs2_data;
  logic [31:0] immediate;
  logic [31:0] writeback_data;
  logic [31:0] memory_read_data;
  logic [31:0] alu_operand_b;
  logic [31:0] alu_result;
  logic        alu_zero;
  logic        reg_write;
  logic        mem_read;
  logic        mem_write;
  logic        mem_to_reg;
  logic        alu_src;
  logic        branch;
  logic        illegal_instruction;
  logic [3:0]  alu_control;

  logic [31:0] if_id_pc;
  logic [31:0] if_id_instruction;
  logic        if_id_valid;

  logic [31:0] id_ex_pc;
  logic [31:0] id_ex_rs1_data;
  logic [31:0] id_ex_rs2_data;
  logic [31:0] id_ex_immediate;
  logic [4:0]  id_ex_rs1;
  logic [4:0]  id_ex_rs2;
  logic [4:0]  id_ex_rd;
  logic        id_ex_reg_write;
  logic        id_ex_mem_read;
  logic        id_ex_mem_write;
  logic        id_ex_mem_to_reg;
  logic        id_ex_alu_src;
  logic        id_ex_branch;
  logic [3:0]  id_ex_alu_control;
  logic        id_ex_valid;

  logic [31:0] ex_mem_alu_result;
  logic [31:0] ex_mem_store_data;
  logic [4:0]  ex_mem_rd;
  logic        ex_mem_reg_write;
  logic        ex_mem_mem_read;
  logic        ex_mem_mem_write;
  logic        ex_mem_mem_to_reg;
  logic        ex_mem_valid;

  logic [31:0] mem_wb_alu_result;
  logic [31:0] mem_wb_memory_data;
  logic [4:0]  mem_wb_rd;
  logic        mem_wb_reg_write;
  logic        mem_wb_mem_to_reg;
  logic        mem_wb_valid;

  logic branch_taken;
  logic [31:0] branch_target;

  instruction_memory #(.INIT_FILE(INSTRUCTION_FILE)) imem (
    .address(pc),
    .instruction(instruction)
  );

  register_file regs (
    .clk(clk),
    .reset(reset),
    .read_addr_1(if_id_instruction[19:15]),
    .read_addr_2(if_id_instruction[24:20]),
    .read_data_1(rs1_data),
    .read_data_2(rs2_data),
    .write_enable(mem_wb_reg_write && mem_wb_valid),
    .write_addr(mem_wb_rd),
    .write_data(writeback_data)
  );

  immediate_generator immediate_gen (
    .instruction(if_id_instruction),
    .immediate(immediate)
  );

  control_unit control (
    .instruction(if_id_instruction),
    .reg_write(reg_write),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_to_reg(mem_to_reg),
    .alu_src(alu_src),
    .branch(branch),
    .alu_control(alu_control),
    .illegal_instruction(illegal_instruction)
  );

  assign alu_operand_b = id_ex_alu_src ? id_ex_immediate : id_ex_rs2_data;

  alu execute_alu (
    .a(id_ex_rs1_data),
    .b(alu_operand_b),
    .alu_control(id_ex_alu_control),
    .result(alu_result),
    .zero(alu_zero)
  );

  assign branch_taken = id_ex_valid && id_ex_branch && alu_zero;
  assign branch_target = id_ex_pc + id_ex_immediate;
  assign next_pc = branch_taken ? branch_target : pc + 32'd4;
  assign writeback_data = mem_wb_mem_to_reg ? mem_wb_memory_data : mem_wb_alu_result;

  data_memory dmem (
    .clk(clk),
    .reset(reset),
    .mem_read(ex_mem_mem_read && ex_mem_valid),
    .mem_write(ex_mem_mem_write && ex_mem_valid),
    .address(ex_mem_alu_result),
    .write_data(ex_mem_store_data),
    .read_data(memory_read_data)
  );

  pipeline_if_id if_id (
    .clk(clk),
    .reset(reset),
    .flush(branch_taken),
    .pc_in(pc),
    .instruction_in(instruction),
    .valid_in(1'b1),
    .pc_out(if_id_pc),
    .instruction_out(if_id_instruction),
    .valid_out(if_id_valid)
  );

  pipeline_id_ex id_ex (
    .clk(clk),
    .reset(reset),
    .flush(branch_taken),
    .pc_in(if_id_pc),
    .rs1_data_in(rs1_data),
    .rs2_data_in(rs2_data),
    .immediate_in(immediate),
    .rs1_in(if_id_instruction[19:15]),
    .rs2_in(if_id_instruction[24:20]),
    .rd_in(if_id_instruction[11:7]),
    .reg_write_in(reg_write && if_id_valid && !illegal_instruction),
    .mem_read_in(mem_read && if_id_valid && !illegal_instruction),
    .mem_write_in(mem_write && if_id_valid && !illegal_instruction),
    .mem_to_reg_in(mem_to_reg && if_id_valid && !illegal_instruction),
    .alu_src_in(alu_src),
    .branch_in(branch && if_id_valid && !illegal_instruction),
    .alu_control_in(alu_control),
    .valid_in(if_id_valid && !illegal_instruction),
    .pc_out(id_ex_pc),
    .rs1_data_out(id_ex_rs1_data),
    .rs2_data_out(id_ex_rs2_data),
    .immediate_out(id_ex_immediate),
    .rs1_out(id_ex_rs1),
    .rs2_out(id_ex_rs2),
    .rd_out(id_ex_rd),
    .reg_write_out(id_ex_reg_write),
    .mem_read_out(id_ex_mem_read),
    .mem_write_out(id_ex_mem_write),
    .mem_to_reg_out(id_ex_mem_to_reg),
    .alu_src_out(id_ex_alu_src),
    .branch_out(id_ex_branch),
    .alu_control_out(id_ex_alu_control),
    .valid_out(id_ex_valid)
  );

  pipeline_ex_mem ex_mem (
    .clk(clk),
    .reset(reset),
    .alu_result_in(alu_result),
    .store_data_in(id_ex_rs2_data),
    .rd_in(id_ex_rd),
    .reg_write_in(id_ex_reg_write),
    .mem_read_in(id_ex_mem_read),
    .mem_write_in(id_ex_mem_write),
    .mem_to_reg_in(id_ex_mem_to_reg),
    .valid_in(id_ex_valid),
    .alu_result_out(ex_mem_alu_result),
    .store_data_out(ex_mem_store_data),
    .rd_out(ex_mem_rd),
    .reg_write_out(ex_mem_reg_write),
    .mem_read_out(ex_mem_mem_read),
    .mem_write_out(ex_mem_mem_write),
    .mem_to_reg_out(ex_mem_mem_to_reg),
    .valid_out(ex_mem_valid)
  );

  pipeline_mem_wb mem_wb (
    .clk(clk),
    .reset(reset),
    .alu_result_in(ex_mem_alu_result),
    .memory_data_in(memory_read_data),
    .rd_in(ex_mem_rd),
    .reg_write_in(ex_mem_reg_write),
    .mem_to_reg_in(ex_mem_mem_to_reg),
    .valid_in(ex_mem_valid),
    .alu_result_out(mem_wb_alu_result),
    .memory_data_out(mem_wb_memory_data),
    .rd_out(mem_wb_rd),
    .reg_write_out(mem_wb_reg_write),
    .mem_to_reg_out(mem_wb_mem_to_reg),
    .valid_out(mem_wb_valid)
  );

  always_ff @(posedge clk) begin
    if (reset)
      pc <= 32'b0;
    else
      pc <= next_pc;
  end
endmodule
