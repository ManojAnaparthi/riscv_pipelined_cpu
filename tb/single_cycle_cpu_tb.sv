`timescale 1ns/1ps

module single_cycle_cpu_tb;
  import riscv_defs::*;

  logic clk = 1'b0;
  logic reset;
  logic [31:0] pc;
  single_cycle_cpu dut (.clk(clk), .reset(reset), .pc(pc));
  always #5 clk = ~clk;

  function automatic [31:0] encode_r(
    input integer funct7, input integer rs2, input integer rs1,
    input integer funct3, input integer rd
  );
    encode_r = {funct7[6:0], rs2[4:0], rs1[4:0], funct3[2:0],
                rd[4:0], OPCODE_R_TYPE};
  endfunction

  function automatic [31:0] encode_i(
    input integer imm, input integer rs1, input integer rd
  );
    encode_i = {imm[11:0], rs1[4:0], 3'b000, rd[4:0], OPCODE_I_TYPE};
  endfunction

  function automatic [31:0] encode_lw(
    input integer imm, input integer rs1, input integer rd
  );
    encode_lw = {imm[11:0], rs1[4:0], 3'b010, rd[4:0], OPCODE_LOAD};
  endfunction

  function automatic [31:0] encode_s(
    input integer imm, input integer rs1, input integer rs2
  );
    encode_s = {imm[11:5], rs2[4:0], rs1[4:0], 3'b010,
                imm[4:0], OPCODE_STORE};
  endfunction

  function automatic [31:0] encode_b(
    input integer imm, input integer rs1, input integer rs2
  );
    encode_b = {imm[12], imm[10:5], rs2[4:0], rs1[4:0], 3'b000,
                imm[4:1], imm[11], OPCODE_BRANCH};
  endfunction

  task automatic check_register(input integer register_number, input logic [31:0] expected);
    if (dut.regs.registers[register_number] !== expected)
      $fatal(1, "Register x%0d expected %h, got %h",
             register_number, expected, dut.regs.registers[register_number]);
  endtask

  integer index;
  initial begin
    for (index = 0; index < 256; index = index + 1)
      dut.imem.memory[index] = 32'h0000_0013;

    // Arithmetic, all R-type operations, store/load, and a taken BEQ.
    dut.imem.memory[0]  = encode_i(10, 0, 1);                    // ADDI x1, x0, 10
    dut.imem.memory[1]  = encode_i(20, 0, 2);                    // ADDI x2, x0, 20
    dut.imem.memory[2]  = encode_r(7'b0, 2, 1, 3'b000, 3);       // ADD x3, x1, x2
    dut.imem.memory[3]  = encode_r(7'b0100000, 1, 3, 3'b000, 4); // SUB x4, x3, x1
    dut.imem.memory[4]  = encode_r(7'b0, 2, 1, 3'b111, 5);       // AND x5, x1, x2
    dut.imem.memory[5]  = encode_r(7'b0, 2, 1, 3'b110, 6);       // OR x6, x1, x2
    dut.imem.memory[6]  = encode_s(0, 0, 3);                     // SW x3, 0(x0)
    dut.imem.memory[7]  = encode_lw(0, 0, 7);                    // LW x7, 0(x0)
    dut.imem.memory[8]  = encode_b(8, 7, 3);                     // BEQ x7, x3, +8
    dut.imem.memory[9]  = encode_i(99, 0, 8);                    // skipped
    dut.imem.memory[10] = encode_i(42, 0, 9);                    // ADDI x9, x0, 42

    reset = 1'b1;
    repeat (2) @(posedge clk);
    reset = 1'b0;
    repeat (12) @(posedge clk);
    #1;

    check_register(1, 32'd10);
    check_register(2, 32'd20);
    check_register(3, 32'd30);
    check_register(4, 32'd20);
    check_register(5, 32'd0);
    check_register(6, 32'd30);
    check_register(7, 32'd30);
    check_register(8, 32'd0);
    check_register(9, 32'd42);
    if (dut.dmem.memory[0] !== 32'd30)
      $fatal(1, "Data memory word 0 expected 30, got %h", dut.dmem.memory[0]);
    if (dut.regs.registers[0] !== 32'b0)
      $fatal(1, "Register x0 changed to %h", dut.regs.registers[0]);

    $display("PASS: single-cycle CPU tests");
    $finish;
  end
endmodule
