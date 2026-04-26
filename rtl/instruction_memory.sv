module instruction_memory #(
  parameter INIT_FILE = ""
) (
  input  logic [31:0] address,
  output logic [31:0] instruction
);
  logic [31:0] memory [0:255];
  integer index;

  initial begin
    for (index = 0; index < 256; index = index + 1)
      memory[index] = 32'h0000_0013;
    if (INIT_FILE != "")
      $readmemh(INIT_FILE, memory);
  end

  always_comb begin
    instruction = memory[address[9:2]];
  end
endmodule
