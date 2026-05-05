module pipeline_mem_wb (
  input logic clk,
  input logic reset,
  input logic [31:0] alu_result_in,
  input logic [31:0] memory_data_in,
  input logic [4:0] rd_in,
  input logic reg_write_in,
  input logic mem_to_reg_in,
  input logic valid_in,
  output logic [31:0] alu_result_out,
  output logic [31:0] memory_data_out,
  output logic [4:0] rd_out,
  output logic reg_write_out,
  output logic mem_to_reg_out,
  output logic valid_out
);
  always_ff @(posedge clk) begin
    if (reset) begin
      alu_result_out  <= 32'b0;
      memory_data_out <= 32'b0;
      rd_out          <= 5'b0;
      reg_write_out   <= 1'b0;
      mem_to_reg_out  <= 1'b0;
      valid_out       <= 1'b0;
    end else begin
      alu_result_out  <= alu_result_in;
      memory_data_out <= memory_data_in;
      rd_out          <= rd_in;
      reg_write_out   <= reg_write_in;
      mem_to_reg_out  <= mem_to_reg_in;
      valid_out       <= valid_in;
    end
  end
endmodule
