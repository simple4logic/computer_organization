// forwarding.v

// This module determines if the values need to be forwarded to the EX stage.

// TODO: declare propoer input and output ports and implement the
// forwarding unit

module forwarding (
    input [4:0] rs1, // Source register 1
    input [4:0] rs2, // Source register 2
    
    input [4:0] rd_exmem,  // Destination register @ exmem reg
    input reg_write_exmem, // Write enable for EX/MEM stage
    input mem_to_reg, // Memory to register signal

    input [4:0] rd_memwb, // Destination register @ memwb reg
    input reg_write_memwb, // Write enable for MEM/WB stage

    output reg [1:0] forward_a, // Forwarding signal for rs1
    output reg [1:0] forward_b // Forwarding signal for rs2
);

always @(*) begin

    if ((rs1 == rd_exmem) && reg_write_exmem && (rs1 != 0) && !0) // not for the load use case
        assign forward_a = 2'b01; // Forward from EX stage
    else if (rs1 == rd_memwb && reg_write_memwb && (rs1 != 0))
        assign forward_a = 2'b10; // Forward from MEM stage
    else 
        assign forward_a = 0; // No forwarding

    // Check if rs2 matches rd_exmem or rd_memwb for forwarding
    if (rs2 == rd_exmem && reg_write_exmem && (rs2 != 0) && !0)
        assign forward_b = 2'b01; // Forward from EX stage
    else if (rs2 == rd_memwb && reg_write_memwb && (rs2 != 0))
        assign forward_b = 2'b10; // Forward from MEM stage
    else
        assign forward_b = 0; // No forwarding
end


endmodule
