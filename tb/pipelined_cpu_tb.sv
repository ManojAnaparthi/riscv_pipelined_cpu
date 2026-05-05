`timescale 1ns/1ps

module pipelined_cpu_tb;
  import riscv_defs::*;

  logic clk = 1'b0;
  logic reset;
  logic [31:0] pc;
  pipelined_cpu dut (.clk(clk), .reset(reset), .pc(pc));
  always #5 clk = ~clk;

  function automatic [31:0] encode_r(
    input integer funct7, input integer rs2, input integer rs1,
    input integer funct3, input integer rd
  );
    encode_r = {funct7[6:0], rs2[4:0], rs1[4:0], funct3[2:0],
                rd[4:0], OPCODE_R_TYPE};
  endfunction

  function automatic [31:0] encode_i(input integer imm, input integer rs1, input integer rd);
    encode_i = {imm[11:0], rs1[4:0], 3'b000, rd[4:0], OPCODE_I_TYPE};
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

    // Four NOPs separate dependent instructions until forwarding is introduced.
    dut.imem.memory[0] = encode_i(10, 0, 1);                     // ADDI x1, x0, 10
    dut.imem.memory[1] = 32'h0000_0013;
    dut.imem.memory[2] = 32'h0000_0013;
    dut.imem.memory[3] = 32'h0000_0013;
    dut.imem.memory[4] = 32'h0000_0013;
    dut.imem.memory[5] = encode_i(20, 0, 2);                     // ADDI x2, x0, 20
    dut.imem.memory[6] = 32'h0000_0013;
    dut.imem.memory[7] = 32'h0000_0013;
    dut.imem.memory[8] = 32'h0000_0013;
    dut.imem.memory[9] = 32'h0000_0013;
    dut.imem.memory[10] = encode_r(7'b0, 2, 1, 3'b000, 3);       // ADD x3, x1, x2
    dut.imem.memory[11] = 32'h0000_0013;
    dut.imem.memory[12] = 32'h0000_0013;
    dut.imem.memory[13] = 32'h0000_0013;
    dut.imem.memory[14] = 32'h0000_0013;
    dut.imem.memory[15] = encode_r(7'b0100000, 1, 3, 3'b000, 4); // SUB x4, x3, x1

    reset = 1'b1;
    repeat (2) @(posedge clk);
    reset = 1'b0;
    repeat (20) @(posedge clk);
    #1;

    check_register(1, 32'd10);
    check_register(2, 32'd20);
    check_register(3, 32'd30);
    check_register(4, 32'd20);
    check_register(0, 32'd0);
    if (dut.if_id_valid !== 1'b1 || dut.id_ex_valid !== 1'b1 ||
        dut.ex_mem_valid !== 1'b1 || dut.mem_wb_valid !== 1'b1)
      $fatal(1, "Pipeline valid bits did not remain active during execution");

    $display("PASS: pipelined CPU tests");
    $finish;
  end
endmodule
