// gshare.v

/* The Gshare predictor consists of the global branch history register (BHR)
 * and a pattern history table (PHT). Note that PC[1:0] is not used for
 * indexing.
 */

module gshare #(
	parameter DATA_WIDTH = 32,
	parameter COUNTER_WIDTH = 2,
	parameter NUM_ENTRIES = 256
) (
	input clk,
	input rstn,

	// update interface
	input update,
	input actually_taken,
	input [DATA_WIDTH-1:0] resolved_pc,

	// access interface
	input [DATA_WIDTH-1:0] pc,

	output reg pred
);

  // TODO: Implement gshare branch predictor
localparam INDEX_BITS = $clog2(NUM_ENTRIES); // =8
localparam [COUNTER_WIDTH-1:0] INIT_COUNT = {1'b1, 1'b0}; // 01

reg [INDEX_BITS-1:0]	BHR;                     
reg [COUNTER_WIDTH-1:0] PHT [0:NUM_ENTRIES-1];  // 2-bit saturating counters

// make entry (PC XOR BHR)
wire [INDEX_BITS-1:0] idx_update = resolved_pc [INDEX_BITS+1:2] ^ BHR;
wire [INDEX_BITS-1:0] idx_entry  = pc          [INDEX_BITS+1:2] ^ BHR;

// update logic
integer i;
always @(posedge clk or negedge rstn) begin
	if (!rstn) begin
		BHR <= {INDEX_BITS{1'b0}};
		for (i = 0; i < NUM_ENTRIES; i = i + 1) begin
			PHT[i] <= INIT_COUNT;
		end
	end 
	else if (update) begin
		if (actually_taken) begin // if the branch is taken -> increment
			if (PHT[idx_update] != { 1'b1, 1'b1 })
				PHT[idx_update] <= PHT[idx_update] + 1'b1;
		end 
		else begin // if the branch is not taken -> decrement
			if (PHT[idx_update] != { 1'b0, 1'b0 })
				PHT[idx_update] <= PHT[idx_update] - 1'b1;
		end

		BHR <= { BHR[INDEX_BITS-2:0], actually_taken };
	end
end

// do prediction
always @(*) begin
	// take prediction from MSB of counter
	pred = PHT[idx_entry][COUNTER_WIDTH-1];
end

endmodule
