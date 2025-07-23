// perceptron.v

/* The perceptron predictor uses the simplest form of neural networks
 * (perceptron), instead of using two-bit counters.  Note that PC[1:0] is not
 * used when indexing into the table of perceptrons.
 *
 * D. Jimenez and C. Lin. "Dynamic Branch Prediction with Perceptrons" HPCA 2001.
 */

module perceptron #(
	parameter DATA_WIDTH = 32,
	parameter HIST_LEN = 25, // Since x0 is always 1(=bias), 26 weights will reside in the perceptron table 
	parameter NUM_ENTRIES = 32
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

// TODO: Implement the perceptron branch predictor
// NOTE: DO NOT CHANGE the local parameters
localparam INDEX_WIDTH     = $clog2(NUM_ENTRIES);
localparam THRESHOLD       = $rtoi($floor(1.93 * HIST_LEN + 14));
localparam WEIGHT_BITWIDTH = 1 + $clog2(THRESHOLD + 1);
localparam WEIGHT_MAX      = $signed({1'b0, {WEIGHT_BITWIDTH-1{1'b1}}}); // MSB  = +
localparam WEIGHT_MIN      = $signed({1'b1, {WEIGHT_BITWIDTH-1{1'b0}}}); // MSB  = -
localparam OUTPUT_BITWIDTH = 1 + $clog2((HIST_LEN + 1) * WEIGHT_MAX + 1);

//-------------------------------------------------------------------------
// storage
//-------------------------------------------------------------------------
reg signed [WEIGHT_BITWIDTH-1:0] weight_mem [0:NUM_ENTRIES-1][0:HIST_LEN];
reg [HIST_LEN-1:0] GHR;

// index calculation
wire [INDEX_WIDTH-1:0] access_idx = pc        [INDEX_WIDTH+1:2];
wire [INDEX_WIDTH-1:0] update_idx = resolved_pc[INDEX_WIDTH+1:2];

reg signed [OUTPUT_BITWIDTH-1:0] sum_access;

//-------------------------------------------------------------------------
// 1) branch prediction (combinational)
//-------------------------------------------------------------------------
integer i;
always @* begin
	sum_access = weight_mem[access_idx][0];  // bias

	for (i = 1; i <= HIST_LEN; i = i + 1) begin
		if (GHR[i-1]) // taken or not taken history
			sum_access = sum_access + weight_mem[access_idx][i];
		else
			sum_access = sum_access - weight_mem[access_idx][i];
	end
	pred = (sum_access >= 0); 
end

//-------------------------------------------------------------------------
// function: weight clamp
//-------------------------------------------------------------------------
function signed [WEIGHT_BITWIDTH-1:0] clamp;
    input signed [WEIGHT_BITWIDTH-1:0] current_val; // 현재 가중치 값
    input signed [1:0]                 delta;       // 더할 값 (+1 또는 -1)

    begin
        if (delta == 2'd1) begin
            if (current_val == WEIGHT_MAX) begin
                clamp = WEIGHT_MAX;
            end else begin
                clamp = current_val + delta;
            end
        end
        else begin // if (delta == -1) 
            if (current_val == WEIGHT_MIN) begin
                clamp = WEIGHT_MIN;
            end else begin
                clamp = current_val + delta;
            end
        end
    end
endfunction

//-------------------------------------------------------------------------
// 2) update weight and GHR (sequential)
//-------------------------------------------------------------------------
reg signed [OUTPUT_BITWIDTH-1:0] sum_update;
reg                           pred_update;
integer                       actual_bit;

integer j;
always @(posedge clk or negedge rstn) begin
	if (!rstn) begin
		for (i = 0; i < NUM_ENTRIES; i = i + 1) begin
			for (j = 0; j <= HIST_LEN; j = j + 1)
				weight_mem[i][j] <= 'd0;
		end
		GHR <= 'd0;
	end 
	else begin
		if (update) begin
			
			// when predcition is resolved, update parameters
			sum_update = weight_mem[update_idx][0];
			
			for (i = 1; i <= HIST_LEN; i = i + 1) begin
				if (GHR[i-1])
					sum_update = sum_update + weight_mem[update_idx][i];
				else
					sum_update = sum_update - weight_mem[update_idx][i];
			end
			pred_update = (sum_update >= 0);
			actual_bit = actually_taken ?  1 : -1;

			// update condition
			// 1) wrong prediction
			// 2) |sum| ≤ threshold // when confidence is too low(than threshold)
			if ((pred_update != actually_taken)
				|| (sum_update <= THRESHOLD && sum_update >= -THRESHOLD)) begin

				weight_mem[update_idx][0] <= clamp(weight_mem[update_idx][0], actual_bit);


				for (i = 1; i <= HIST_LEN; i = i + 1) begin
					if (actually_taken==GHR[i-1])
						weight_mem[update_idx][i] <= clamp(weight_mem[update_idx][i],  1); // when correct, increase weight
					else
						weight_mem[update_idx][i] <= clamp(weight_mem[update_idx][i],  -1); // if not, decrease weight
				end

			end

			GHR <= {GHR[HIST_LEN-2:0], actually_taken};
		end
	end
end


endmodule
