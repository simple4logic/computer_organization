// ifid_reg.v
// This module is the IF/ID pipeline register.


module ifid_reg #(
	parameter DATA_WIDTH = 32
)(
	// TODO: Add flush or stall signal if it is needed
	input flush,
	input stall,

	//////////////////////////////////////
	// Inputs
	//////////////////////////////////////
	input clk,

	input [DATA_WIDTH-1:0] if_PC,
	input [DATA_WIDTH-1:0] if_pc_plus_4,
	input [DATA_WIDTH-1:0] if_pc_predicted, // for branch predictor update
	input if_branch_pred,
	input [DATA_WIDTH-1:0] if_instruction,

	//////////////////////////////////////
	// Outputs
	//////////////////////////////////////
	output [DATA_WIDTH-1:0] id_PC,
	output [DATA_WIDTH-1:0] id_pc_plus_4,
	output [DATA_WIDTH-1:0] id_pc_predicted, // for branch predictor update
	output id_branch_pred,
	output [DATA_WIDTH-1:0] id_instruction
);

// TODO: Implement IF/ID pipeline register module

reg [DATA_WIDTH-1:0] reg_id_PC;
reg [DATA_WIDTH-1:0] reg_id_pc_plus_4;
reg [DATA_WIDTH-1:0] reg_id_pc_predicted;
reg reg_id_branch_pred;
reg [DATA_WIDTH-1:0] reg_id_instruction;

always @(posedge clk) begin
	if(flush) begin
		reg_id_PC           <= 0;
		reg_id_pc_plus_4    <= 0;
		reg_id_pc_predicted <= 32'h0;
		reg_id_branch_pred  <= 1'b0;
		reg_id_instruction  <= 32'h0; 
	end
	else if (stall) begin
		reg_id_PC           <= reg_id_PC;
		reg_id_pc_plus_4    <= reg_id_pc_plus_4;
		reg_id_pc_predicted <= reg_id_pc_predicted;
		reg_id_branch_pred  <= reg_id_branch_pred;
		reg_id_instruction  <= reg_id_instruction;
	end
	else begin // normal operation
		reg_id_PC           <= if_PC;
		reg_id_pc_plus_4    <= if_pc_plus_4;
		reg_id_pc_predicted <= if_pc_predicted;
		reg_id_branch_pred  <= if_branch_pred;
		reg_id_instruction  <= if_instruction;
	end
end

assign id_PC           = reg_id_PC;
assign id_pc_plus_4    = reg_id_pc_plus_4;
assign id_pc_predicted = reg_id_pc_predicted;
assign id_branch_pred  = reg_id_branch_pred;
assign id_instruction  = reg_id_instruction;

endmodule
