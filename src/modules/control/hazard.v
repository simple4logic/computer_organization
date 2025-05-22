// hazard.v

// This module determines if pipeline stalls or flushing are required

// TODO: declare propoer input and output ports and implement the
// hazard detection unit

module hazard #(
    parameter DATA_WIDTH = 32
)(
    input [4:0] ID_rs1, // Source register 1
    input [4:0] ID_rs2, // Source register 2
    input [4:0] EX_rd, // EX inst destination register
    input EX_mem_read, // Memory read signal
    input MEM_is_control_flow,
    input MEM_is_predict_correct,


    output stall,
    output flush
);

// stall logic
// when lw && dist = 1 (EX)
assign stall =  (EX_mem_read && (ID_rs1 != 0) && (ID_rs1 == EX_rd)) ||
                (EX_mem_read && (ID_rs2 != 0) && (ID_rs2 == EX_rd));

// flush logic
// when jump -> target wrong
// when branch -> target wrong or prediction wrong
assign flush = MEM_is_control_flow & !MEM_is_predict_correct; // jump but wrong target

endmodule
