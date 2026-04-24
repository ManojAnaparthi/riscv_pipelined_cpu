`timescale 1ns/1ps

module components_tb;
  import riscv_defs::*;

  logic [31:0] alu_a, alu_b, alu_result;
  logic [3:0] alu_control;
  logic alu_zero;
  alu alu_dut (
    .a(alu_a), .b(alu_b), .alu_control(alu_control),
    .result(alu_result), .zero(alu_zero)
  );

  logic clk = 1'b0;
  logic reset;
  logic [4:0] read_addr_1, read_addr_2, write_addr;
  logic [31:0] read_data_1, read_data_2, write_data;
  logic write_enable;
  register_file register_file_dut (
    .clk, .reset, .read_addr_1, .read_addr_2, .read_data_1, .read_data_2,
    .write_enable, .write_addr, .write_data
  );
  always #5 clk = ~clk;

  logic [31:0] instruction, immediate;
  immediate_generator immediate_dut (.instruction, .immediate);

  logic reg_write, mem_read, mem_write, mem_to_reg, alu_src, branch;
  logic [3:0] control_alu;
  logic illegal_instruction;
  control_unit control_dut (
    .instruction, .reg_write, .mem_read, .mem_write, .mem_to_reg,
    .alu_src, .branch, .alu_control(control_alu), .illegal_instruction
  );

  task automatic check(input logic condition, input string message);
    if (!condition) $fatal(1, "FAIL: %s", message);
  endtask

  function automatic [31:0] encode_i(
    input integer imm, input integer rs1, input integer funct3,
    input integer rd, input logic [6:0] opcode
  );
    encode_i = {imm[11:0], rs1[4:0], funct3[2:0], rd[4:0], opcode};
  endfunction

  function automatic [31:0] encode_s(
    input integer imm, input integer rs1, input integer rs2,
    input integer funct3, input logic [6:0] opcode
  );
    encode_s = {imm[11:5], rs2[4:0], rs1[4:0], funct3[2:0],
                imm[4:0], opcode};
  endfunction

  function automatic [31:0] encode_b(
    input integer imm, input integer rs1, input integer rs2,
    input integer funct3, input logic [6:0] opcode
  );
    encode_b = {imm[12], imm[10:5], rs2[4:0], rs1[4:0], funct3[2:0],
                imm[4:1], imm[11], opcode};
  endfunction

  initial begin
    alu_a = 32'd12; alu_b = 32'd5;
    alu_control = ALU_ADD; #1;
    check(alu_result == 32'd17 && !alu_zero, "ALU ADD");
    alu_control = ALU_SUB; #1;
    check(alu_result == 32'd7, "ALU SUB");
    alu_control = ALU_AND; #1;
    check(alu_result == (32'd12 & 32'd5), "ALU AND");
    alu_control = ALU_OR; #1;
    check(alu_result == (32'd12 | 32'd5), "ALU OR");
    alu_a = 32'd7; alu_b = 32'd7; alu_control = ALU_SUB; #1;
    check(alu_result == 0 && alu_zero, "ALU zero flag");

    reset = 1'b1;
    write_enable = 1'b0;
    write_addr = 0;
    write_data = 0;
    read_addr_1 = 0;
    read_addr_2 = 0;
    repeat (2) @(posedge clk);
    reset = 1'b0;
    write_enable = 1'b1;
    write_addr = 5'd5;
    write_data = 32'h1234_5678;
    @(posedge clk);
    #1;
    read_addr_1 = 5'd5;
    read_addr_2 = 5'd0;
    #1;
    check(read_data_1 == 32'h1234_5678, "register file write/read");
    check(read_data_2 == 32'b0, "register x0 read");
    write_addr = 5'd0;
    write_data = 32'hffff_ffff;
    @(posedge clk);
    #1;
    check(read_data_2 == 32'b0, "register x0 write protection");

    instruction = encode_i(-4, 1, 3'b000, 2, OPCODE_I_TYPE);
    #1;
    check(immediate == 32'hffff_fffc, "I-type immediate");
    instruction = encode_i(16, 1, 3'b010, 2, OPCODE_LOAD);
    #1;
    check(immediate == 32'd16, "load immediate");
    instruction = encode_s(-8, 1, 2, 3'b010, OPCODE_STORE);
    #1;
    check(immediate == 32'hffff_fff8, "S-type immediate");
    instruction = encode_b(12, 1, 2, 3'b000, OPCODE_BRANCH);
    #1;
    check(immediate == 32'd12, "B-type immediate");

    instruction = {7'b0, 5'd3, 5'd2, 3'b000, 5'd1, OPCODE_R_TYPE};
    #1;
    check(reg_write && !alu_src && control_alu == ALU_ADD &&
          !illegal_instruction, "ADD control");
    instruction = {7'b0100000, 5'd3, 5'd2, 3'b000, 5'd1, OPCODE_R_TYPE};
    #1;
    check(reg_write && control_alu == ALU_SUB && !illegal_instruction,
          "SUB control");
    instruction = {7'b0, 5'd3, 5'd2, 3'b111, 5'd1, OPCODE_R_TYPE};
    #1;
    check(reg_write && control_alu == ALU_AND && !illegal_instruction,
          "AND control");
    instruction = {7'b0, 5'd3, 5'd2, 3'b110, 5'd1, OPCODE_R_TYPE};
    #1;
    check(reg_write && control_alu == ALU_OR && !illegal_instruction,
          "OR control");
    instruction = encode_i(1, 1, 3'b000, 2, OPCODE_I_TYPE);
    #1;
    check(reg_write && alu_src && control_alu == ALU_ADD &&
          !illegal_instruction, "ADDI control");
    instruction = encode_s(0, 1, 2, 3'b010, OPCODE_STORE);
    #1;
    check(mem_write && alu_src && !reg_write && !illegal_instruction,
          "SW control");
    instruction = encode_i(0, 1, 3'b010, 2, OPCODE_LOAD);
    #1;
    check(reg_write && mem_read && mem_to_reg && alu_src &&
          !mem_write && !illegal_instruction, "LW control");
    instruction = encode_b(8, 1, 2, 3'b000, OPCODE_BRANCH);
    #1;
    check(branch && control_alu == ALU_SUB && !illegal_instruction,
          "BEQ control");
    instruction = 32'hffff_ffff;
    #1;
    check(illegal_instruction && !reg_write && !mem_write,
          "illegal instruction control");

    $display("PASS: component tests");
    $finish;
  end
endmodule
