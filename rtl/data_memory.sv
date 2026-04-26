module data_memory (
  input  logic        clk,
  input  logic        reset,
  input  logic        mem_read,
  input  logic        mem_write,
  input  logic [31:0] address,
  input  logic [31:0] write_data,
  output logic [31:0] read_data
);
  logic [31:0] memory [0:255];
  integer index;

  always_ff @(posedge clk) begin
    if (reset) begin
      for (index = 0; index < 256; index = index + 1)
        memory[index] <= 32'b0;
    end else if (mem_write) begin
      memory[address[9:2]] <= write_data;
    end
  end

  always_comb begin
    read_data = mem_read ? memory[address[9:2]] : 32'b0;
  end
endmodule
