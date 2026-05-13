module cpu_assertions (
  input logic        clk,
  input logic        reset,
  input logic [31:0] pc,
  input logic [31:0] if_id_instruction,
  input logic        id_ex_valid,
  input logic [31:0] registers_x0,
  input logic        ex_mem_valid,
  input logic        ex_mem_mem_write,
  input logic        data_mem_write,
  input logic        mem_wb_valid,
  input logic        mem_wb_reg_write,
  input logic [4:0]  mem_wb_rd,
  input logic        stall
);
  logic        checking;
  logic        previous_stall;
  logic [31:0] previous_pc;
  logic [31:0] previous_if_id_instruction;

  always @(negedge clk) begin
    if (reset) begin
      assert (pc == 32'b0)
        else $fatal(1, "Assertion failed: reset must clear PC");
      checking = 1'b0;
    end else begin
      checking = 1'b1;
    end

    if (checking) begin
      assert (registers_x0 == 32'b0)
        else $fatal(1, "Assertion failed: x0 changed to %h", registers_x0);
      assert (!(ex_mem_valid && ex_mem_mem_write) || data_mem_write)
        else $fatal(1, "Assertion failed: store control was not propagated");
      assert (!mem_wb_valid || !mem_wb_reg_write ||
              (^mem_wb_rd !== 1'bx))
        else $fatal(1, "Assertion failed: writeback destination is unknown");
      if (previous_stall) begin
        assert (pc == previous_pc)
          else $fatal(1, "Assertion failed: PC changed during a stall");
        assert (if_id_instruction == previous_if_id_instruction)
          else $fatal(1, "Assertion failed: IF/ID changed during a stall");
        assert (!id_ex_valid)
          else $fatal(1, "Assertion failed: stall did not insert an ID/EX bubble");
      end
    end

    previous_stall             = stall;
    previous_pc                = pc;
    previous_if_id_instruction = if_id_instruction;
  end
endmodule
