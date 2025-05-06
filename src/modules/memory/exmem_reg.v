//exmem_reg.v


module exmem_reg #(
  	parameter DATA_WIDTH = 32
)(
	// TODO: Add flush or stall signal if it is needed
	// Nothing is needed

	//////////////////////////////////////
	// Inputs
	//////////////////////////////////////
	input clk,

	input [DATA_WIDTH-1:0] ex_pc_plus_4,
	input [DATA_WIDTH-1:0] ex_pc_target,
	input ex_taken,

	// mem control
	input ex_memread,
	input ex_memwrite,

	// wb control
	input [1:0] ex_jump,
	input ex_memtoreg,
	input ex_regwrite,

	input [DATA_WIDTH-1:0] ex_alu_result,
	input [DATA_WIDTH-1:0] ex_writedata,
	input [2:0] ex_funct3,
	input [4:0] ex_rd,

	//////////////////////////////////////
	// Outputs
	//////////////////////////////////////
	output [DATA_WIDTH-1:0] mem_pc_plus_4,
	output [DATA_WIDTH-1:0] mem_pc_target,
	output mem_taken,

	// mem control
	output mem_memread,
	output mem_memwrite,

	// wb control
	output [1:0] mem_jump,
	output mem_memtoreg,
	output mem_regwrite,

	output [DATA_WIDTH-1:0] mem_alu_result,
	output [DATA_WIDTH-1:0] mem_writedata,
	output [2:0] mem_funct3,
	output [4:0] mem_rd
);

// TODO: Implement EX / MEM pipeline register module
reg [DATA_WIDTH-1:0] reg_mem_pc_plus_4;
reg [DATA_WIDTH-1:0] reg_mem_pc_target;
reg reg_mem_taken;

// mem control
reg reg_mem_memread;
reg reg_mem_memwrite;

// wb control
reg [1:0] reg_mem_jump;
reg reg_mem_memtoreg;
reg reg_mem_regwrite;

reg [DATA_WIDTH-1:0] reg_mem_alu_result;
reg [DATA_WIDTH-1:0] reg_mem_writedata;
reg [2:0] reg_mem_funct3;
reg [4:0] reg_mem_rd;

always @(posedge clk) begin
	reg_mem_pc_plus_4 	<= ex_pc_plus_4;
	reg_mem_pc_target 	<= ex_pc_target;
	reg_mem_taken     	<= ex_taken;

	// mem control
	reg_mem_memread   	<= ex_memread;
	reg_mem_memwrite  	<= ex_memwrite;

	// wb control
	reg_mem_jump      	<= ex_jump;
	reg_mem_memtoreg  	<= ex_memtoreg;
	reg_mem_regwrite  	<= ex_regwrite;

	reg_mem_alu_result  <= ex_alu_result;
	reg_mem_writedata   <= ex_writedata;
	reg_mem_funct3      <= ex_funct3;
	reg_mem_rd          <= ex_rd;
end

assign mem_pc_plus_4    = reg_mem_pc_plus_4;
assign mem_pc_target    = reg_mem_pc_target;
assign mem_taken        = reg_mem_taken;

// mem control
assign mem_memread     = reg_mem_memread;
assign mem_memwrite    = reg_mem_memwrite;

// wb control
assign mem_jump        = reg_mem_jump;
assign mem_memtoreg    = reg_mem_memtoreg;
assign mem_regwrite    = reg_mem_regwrite;

assign mem_alu_result   = reg_mem_alu_result;
assign mem_writedata    = reg_mem_writedata;
assign mem_funct3       = reg_mem_funct3;
assign mem_rd           = reg_mem_rd;

endmodule
