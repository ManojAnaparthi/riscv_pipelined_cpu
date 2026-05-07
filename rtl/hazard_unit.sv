module hazard_unit (
  input  logic       id_ex_mem_read,
  input  logic [4:0] id_ex_rd,
  input  logic [4:0] if_id_rs1,
  input  logic [4:0] if_id_rs2,
  input  logic       use_rs1,
  input  logic       use_rs2,
  output logic       stall
);
  always_comb begin
    stall = id_ex_mem_read && (id_ex_rd != 5'b0) &&
            ((use_rs1 && (id_ex_rd == if_id_rs1)) ||
             (use_rs2 && (id_ex_rd == if_id_rs2)));
  end
endmodule
