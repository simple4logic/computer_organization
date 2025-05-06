// hazard.v

// This module determines if pipeline stalls or flushing are required

// TODO: declare propoer input and output ports and implement the
// hazard detection unit

module hazard (
    input [4:0] ID_rs1, // Source register 1
    input [4:0] ID_rs2, // Source register 2
    input [4:0] EX_rd, // EX inst destination register
    input EX_mem_read, // Memory read signal
    input branch_taken, // Branch taken signal

    output stall,
    output flush
);

// stall logic
// when lw && dist = 1 (EX)
wire lw_hazard = EX_mem_read &&
    ((ID_rs1 != 5'd0 && ID_rs1 == EX_rd) ||
    (ID_rs2 != 5'd0 && ID_rs2 == EX_rd) );

// flush logic
assign stall = lw_hazard;
assign flush = branch_taken;

endmodule
