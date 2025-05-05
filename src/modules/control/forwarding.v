// forwarding.v

// This module determines if the values need to be forwarded to the EX stage.

// TODO: declare propoer input and output ports and implement the
// forwarding unit

module forwarding (
    input [4:0] rs1, // Source register 1
    input [4:0] rs2, // Source register 2
    input [4:0] rd_exmem,  // Destination register @ exmem reg
    input reg_write_exmem, // Write enable for EX/MEM stage
    input [4:0] rd_memwb, // Destination register @ memwb reg
    input reg_write_memwb, // Write enable for MEM/WB stage

    output reg [1:0] forward_a, // Forwarding signal for rs1
    output reg [1:0] forward_b // Forwarding signal for rs2
);

always @(*) begin
    // init
    forward_a = 2'b00;
    forward_b = 2'b00;

    // Check if rs1 matches rd_exmem or rd_memwb for forwarding
    if (rs1 != 0) begin
        if (rs1 == rd_exmem && reg_write_exmem) begin
            assign forward_a = 2'b01; // Forward from EX stage
        end 
        else if (rs1 == rd_memwb && reg_write_memwb) begin
            assign forward_a = 2'b10; // Forward from MEM stage
        end
        else begin
            assign forward_a = 0; // No forwarding
        end
    end

    // Check if rs2 matches rd_exmem or rd_memwb for forwarding
    if (rs2 != 0) begin
        if (rs2 == rd_exmem && reg_write_exmem) begin
            assign forward_b = 2'b01; // Forward from EX stage
        end 
        else if (rs2 == rd_memwb && reg_write_memwb) begin
            assign forward_b = 2'b10; // Forward from MEM stage
        end
        else begin
            assign forward_b = 0; // No forwarding
        end
    end
end


endmodule
