// imm_generator.v

module imm_generator #(
  parameter DATA_WIDTH = 32
)(
  input [31:0] instruction,

  output reg [DATA_WIDTH-1:0] sextimm
);

wire [6:0] opcode;
assign opcode = instruction[6:0]; // opcode parsing

always @(*) begin
  case (opcode)
    //////////////////////////////////////////////////////////////////////////
    // TODO : Generate sextimm using instruction
    // extend imm for all the instructions which contain imm value // do sign extension (always)
    7'b0010011: sextimm = {{20{instruction[31]}}, instruction[31:20]}; // I-type: ALU immediate
    7'b0000011: sextimm = {{20{instruction[31]}}, instruction[31:20]}; // I-type: Load
    7'b1100111: sextimm = {{20{instruction[31]}}, instruction[31:20]}; // I-type: JALR
    7'b0100011: sextimm = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]}; // S-type: Store
    7'b1100011: sextimm = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0}; // B-type: Branch
    7'b1101111: sextimm = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0}; // J-type: JAL
    //////////////////////////////////////////////////////////////////////////
    default:    sextimm = 32'h0000_0000;
  endcase
end


endmodule
