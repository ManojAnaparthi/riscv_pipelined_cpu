module register_file (
  input  logic        clk,
  input  logic        reset,
  input  logic [4:0]  read_addr_1,
  input  logic [4:0]  read_addr_2,
  output logic [31:0] read_data_1,
  output logic [31:0] read_data_2,
  input  logic        write_enable,
  input  logic [4:0]  write_addr,
  input  logic [31:0] write_data
);
  logic [31:0] registers [0:31];
  integer index;

  always_ff @(posedge clk) begin
    if (reset) begin
      for (index = 0; index < 32; index = index + 1)
        registers[index] <= 32'b0;
    end else begin
      if (write_enable && (write_addr != 5'b0))
        registers[write_addr] <= write_data;
      registers[0] <= 32'b0;
    end
  end

  always_comb begin
    if (read_addr_1 == 5'b0)
      read_data_1 = 32'b0;
    else if (write_enable && (write_addr == read_addr_1) && (write_addr != 5'b0))
      read_data_1 = write_data;
    else
      read_data_1 = registers[read_addr_1];

    if (read_addr_2 == 5'b0)
      read_data_2 = 32'b0;
    else if (write_enable && (write_addr == read_addr_2) && (write_addr != 5'b0))
      read_data_2 = write_data;
    else
      read_data_2 = registers[read_addr_2];
  end
endmodule
