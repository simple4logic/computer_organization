// branch_hardware.v

/* This module comprises a branch predictor and a branch target buffer.
 * Our CPU will use the branch target address only when BTB is hit.
 */

module branch_hardware #(
	parameter DATA_WIDTH = 32,
	parameter COUNTER_WIDTH = 2,
	parameter NUM_ENTRIES = 256 // 2^8
) (
	input clk,
	input rstn,

	// update interface
	input update_predictor,
	input update_btb,
	input actually_taken, // actually taken or not information comes in
	input [DATA_WIDTH-1:0] resolved_pc,
	input [DATA_WIDTH-1:0] resolved_pc_target,  // actual target address when the branch is resolved.

	// access interface
	input [DATA_WIDTH-1:0] pc,

	output reg hit,          // btb hit or not
	output reg pred,         // predicted taken or not
	output reg [DATA_WIDTH-1:0] branch_target  // branch target address for a hit
);

wire hit_o;
wire pred_o = 1'b0;
wire [DATA_WIDTH-1:0] branch_target_o;

`ifdef GSHARE
  // TODO: Instantiate the Gshare branch predictor
  gshare m_gshare (
    .clk(clk),
    .rstn(rstn),

    // update interface
    .update(update_predictor),
    .actually_taken(actually_taken),
    .resolved_pc(resolved_pc),

    // access interface
    .pc(pc),

    // output
    .pred(pred_o)
  );
`endif

`ifdef PERCEPTRON
  // TODO: Instantiate the Perceptron branch predictor
  perceptron m_perceptron(
	.clk(clk),
	.rstn(rstn),

	// update interface
	.update(update_predictor),
	.actually_taken(actually_taken),
	.resolved_pc(resolved_pc),

	// access interface
	.pc(pc),

	// output
	.pred(pred_o)
  );
`endif

branch_target_buffer m_BTB (
	.clk(clk),
	.rstn(rstn),

	// update interface
	.update(update_btb), // update only when actually_taken
	.resolved_pc(resolved_pc),
	.resolved_pc_target(resolved_pc_target),

	// access interface
	.pc(pc),

	// output
	.hit(hit_o),
	.target_address(branch_target_o)
);

always @(*) begin
	hit = hit_o;
	pred = pred_o;
	branch_target = branch_target_o;
end

endmodule
