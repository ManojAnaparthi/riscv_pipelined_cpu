module pipeline_id_ex (
  input logic clk,
  input logic reset,
  input logic flush,
  input logic [31:0] pc_in,
  input logic [31:0] rs1_data_in,
  input logic [31:0] rs2_data_in,
  input logic [31:0] immediate_in,
  input logic [4:0] rs1_in,
  input logic [4:0] rs2_in,
  input logic [4:0] rd_in,
  input logic reg_write_in,
  input logic mem_read_in,
  input logic mem_write_in,
  input logic mem_to_reg_in,
  input logic alu_src_in,
  input logic branch_in,
  input logic [3:0] alu_control_in,
  input logic valid_in,
  output logic [31:0] pc_out,
  output logic [31:0] rs1_data_out,
  output logic [31:0] rs2_data_out,
  output logic [31:0] immediate_out,
  output logic [4:0] rs1_out,
  output logic [4:0] rs2_out,
  output logic [4:0] rd_out,
  output logic reg_write_out,
  output logic mem_read_out,
  output logic mem_write_out,
  output logic mem_to_reg_out,
  output logic alu_src_out,
  output logic branch_out,
  output logic [3:0] alu_control_out,
  output logic valid_out
);
  always_ff @(posedge clk) begin
    if (reset || flush) begin
      pc_out          <= 32'b0;
      rs1_data_out    <= 32'b0;
      rs2_data_out    <= 32'b0;
      immediate_out   <= 32'b0;
      rs1_out         <= 5'b0;
      rs2_out         <= 5'b0;
      rd_out          <= 5'b0;
      reg_write_out   <= 1'b0;
      mem_read_out    <= 1'b0;
      mem_write_out   <= 1'b0;
      mem_to_reg_out  <= 1'b0;
      alu_src_out     <= 1'b0;
      branch_out      <= 1'b0;
      alu_control_out <= 4'b0;
      valid_out       <= 1'b0;
    end else begin
      pc_out          <= pc_in;
      rs1_data_out    <= rs1_data_in;
      rs2_data_out    <= rs2_data_in;
      immediate_out   <= immediate_in;
      rs1_out         <= rs1_in;
      rs2_out         <= rs2_in;
      rd_out          <= rd_in;
      reg_write_out   <= reg_write_in;
      mem_read_out    <= mem_read_in;
      mem_write_out   <= mem_write_in;
      mem_to_reg_out  <= mem_to_reg_in;
      alu_src_out     <= alu_src_in;
      branch_out      <= branch_in;
      alu_control_out <= alu_control_in;
      valid_out       <= valid_in;
    end
  end
endmodule
