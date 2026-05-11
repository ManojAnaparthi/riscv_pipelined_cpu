`timescale 1ns/1ps

module pipelined_cpu_tb;
  import riscv_defs::*;

  logic clk = 1'b0;
  logic reset;
  logic [31:0] pc;
  logic stall_seen = 1'b0;
  logic ex_mem_forward_seen = 1'b0;
  logic mem_wb_forward_seen = 1'b0;
  logic store_forward_seen = 1'b0;
  pipelined_cpu dut (.clk(clk), .reset(reset), .pc(pc));
  always #5 clk = ~clk;
  always @(posedge clk) begin
    if (dut.stall)
      stall_seen = 1'b1;
    if ((dut.forward_a == 2'b10) || (dut.forward_b == 2'b10))
      ex_mem_forward_seen = 1'b1;
    if ((dut.forward_a == 2'b01) || (dut.forward_b == 2'b01))
      mem_wb_forward_seen = 1'b1;
    if (dut.id_ex_mem_write && dut.id_ex_valid && (dut.forward_b != 2'b00))
      store_forward_seen = 1'b1;
  end

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

  function automatic [31:0] encode_lw(input integer imm, input integer rs1, input integer rd);
    encode_lw = {imm[11:0], rs1[4:0], 3'b010, rd[4:0], OPCODE_LOAD};
  endfunction

  function automatic [31:0] encode_s(input integer imm, input integer rs1, input integer rs2);
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
    $dumpfile("build/pipelined_cpu.vcd");
    $dumpvars(0, pipelined_cpu_tb);

    for (index = 0; index < 256; index = index + 1)
      dut.imem.memory[index] = 32'h0000_0013;

    dut.imem.memory[0] = encode_i(5, 0, 1);                     // ADDI x1, x0, 5
    dut.imem.memory[1] = encode_i(7, 0, 2);                     // ADDI x2, x0, 7
    dut.imem.memory[2] = encode_i(100, 0, 5);                   // ADDI x5, x0, 100
    dut.imem.memory[3] = encode_r(7'b0, 2, 1, 3'b000, 3);       // ADD x3, x1, x2
    dut.imem.memory[4] = encode_s(0, 5, 3);                     // SW x3, 0(x5)
    dut.imem.memory[5] = encode_lw(0, 5, 6);                    // LW x6, 0(x5)
    dut.imem.memory[6] = encode_r(7'b0, 1, 6, 3'b000, 7);       // ADD x7, x6, x1
    dut.imem.memory[7] = encode_r(7'b0, 3, 7, 3'b110, 8);       // OR x8, x7, x3
    dut.imem.memory[8] = encode_r(7'b0100000, 1, 3, 3'b000, 4); // SUB x4, x3, x1
    dut.imem.memory[9] = encode_b(8, 1, 1);                      // BEQ x1, x1, +8
    dut.imem.memory[10] = encode_i(99, 0, 9);                   // skipped
    dut.imem.memory[11] = encode_i(11, 0, 10);                  // branch target
    dut.imem.memory[12] = encode_i(2, 0, 11);
    dut.imem.memory[13] = encode_b(8, 1, 2);                    // not taken
    dut.imem.memory[14] = encode_i(14, 0, 12);                  // executes
    dut.imem.memory[15] = encode_i(15, 0, 13);

    reset = 1'b1;
    repeat (2) @(posedge clk);
    reset = 1'b0;
    repeat (24) @(posedge clk);
    #1;

    check_register(1, 32'd5);
    check_register(2, 32'd7);
    check_register(3, 32'd12);
    check_register(4, 32'd7);
    check_register(5, 32'd100);
    check_register(6, 32'd12);
    check_register(7, 32'd17);
    check_register(8, 32'd29);
    check_register(9, 32'd0);
    check_register(10, 32'd11);
    check_register(12, 32'd14);
    if (dut.dmem.memory[25] !== 32'd12)
      $fatal(1, "Data memory word 25 expected 12, got %h", dut.dmem.memory[25]);
    if (!ex_mem_forward_seen)
      $fatal(1, "EX/MEM forwarding was not exercised");
    if (!mem_wb_forward_seen)
      $fatal(1, "MEM/WB forwarding was not exercised");
    if (!store_forward_seen)
      $fatal(1, "Store-data forwarding was not exercised");
    if (!stall_seen)
      $fatal(1, "Load-use stall control never activated");
    check_register(0, 32'd0);
    if (dut.if_id_valid !== 1'b1 || dut.id_ex_valid !== 1'b1 ||
        dut.ex_mem_valid !== 1'b1 || dut.mem_wb_valid !== 1'b1)
      $fatal(1, "Pipeline valid bits did not remain active during execution");

    $display("PASS: pipelined CPU tests");
    $finish;
  end
endmodule
