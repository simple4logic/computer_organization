// branch_target_buffer.v

/* The branch target buffer (BTB) stores the branch target address for
 * a branch PC. Our BTB is essentially a direct-mapped cache.
 */

module branch_target_buffer #(
	parameter DATA_WIDTH = 32,
	parameter NUM_ENTRIES = 256
) (
	input clk,
	input rstn,

	// update interface
	input update,                              // when 'update' is true, we update the BTB entry
	input [DATA_WIDTH-1:0] resolved_pc,
	input [DATA_WIDTH-1:0] resolved_pc_target,

	// access interface
	input [DATA_WIDTH-1:0] pc,

	output reg hit,
	output reg [DATA_WIDTH-1:0] target_address
);

// TODO: Implement BTB
localparam INDEX_BITS = $clog2(NUM_ENTRIES); // =8
localparam TAG_BITS   = DATA_WIDTH - INDEX_BITS - 2;// = 32-8-2 = 22

// storage
reg                  valid   [0:NUM_ENTRIES-1];
reg [TAG_BITS-1:0]   tagmem  [0:NUM_ENTRIES-1];
reg [DATA_WIDTH-1:0] datamem [0:NUM_ENTRIES-1];

wire [INDEX_BITS-1:0] access_idx = pc[INDEX_BITS+1:2];
wire [TAG_BITS-1:0]   access_tag = pc[DATA_WIDTH-1:INDEX_BITS+2];

// tag and index for update
wire [INDEX_BITS-1:0] update_idx = resolved_pc[INDEX_BITS+1:2];
wire [TAG_BITS-1:0]   update_tag = resolved_pc[DATA_WIDTH-1:INDEX_BITS+2];

// reset & update BTB when 'update' is true
integer i;
always @(posedge clk or negedge rstn) begin
	if (!rstn) begin
		for (i = 0; i < NUM_ENTRIES; i = i + 1) begin
		valid[i]   <= 1'b0;
		tagmem[i]  <= {TAG_BITS{1'b0}};
		datamem[i] <= {DATA_WIDTH{1'b0}};
		end
	end 
	else if (update) begin
		valid[update_idx]   <= 1'b1;
		tagmem[update_idx]  <= update_tag;
		datamem[update_idx] <= resolved_pc_target;
	end
end

// check if the BTB hit
always @(*) begin
	if (valid[access_idx] && tagmem[access_idx] == access_tag) begin
		hit            = 1'b1;
		target_address = datamem[access_idx];
	end 
	else begin
		hit            = 1'b0;
		target_address = {DATA_WIDTH{1'b0}}; // will not be used
	end
end

endmodule
