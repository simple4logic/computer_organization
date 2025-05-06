// idex_reg.v
// This module is the ID/EX pipeline register.


module idex_reg #(
	parameter DATA_WIDTH = 32
)(
	// TODO: Add flush or stall signal if it is needed
	input flush,
	input stall,

	//////////////////////////////////////
	// Inputs
	//////////////////////////////////////
	input clk,

	input [DATA_WIDTH-1:0] id_PC,
	input [DATA_WIDTH-1:0] id_pc_plus_4,

	// ex control
	input [1:0] id_jump,
	input id_branch,
	input [1:0] id_aluop,
	input id_alusrc,

	// mem control
	input id_memread,
	input id_memwrite,

	// wb control
	input id_memtoreg,
	input id_regwrite,

	input [DATA_WIDTH-1:0] id_sextimm,
	input [6:0] id_funct7,
	input [2:0] id_funct3,
	input [DATA_WIDTH-1:0] id_readdata1,
	input [DATA_WIDTH-1:0] id_readdata2,
	input [4:0] id_rs1,
	input [4:0] id_rs2,
	input [4:0] id_rd,

	//////////////////////////////////////
	// Outputs
	//////////////////////////////////////
	output [DATA_WIDTH-1:0] ex_PC,
	output [DATA_WIDTH-1:0] ex_pc_plus_4,

	// ex control
	output ex_branch,
	output [1:0] ex_aluop,
	output ex_alusrc,
	output [1:0] ex_jump,

	// mem control
	output ex_memread,
	output ex_memwrite,

	// wb control
	output ex_memtoreg,
	output ex_regwrite,

	output [DATA_WIDTH-1:0] ex_sextimm,
	output [6:0] ex_funct7,
	output [2:0] ex_funct3,
	output [DATA_WIDTH-1:0] ex_readdata1,
	output [DATA_WIDTH-1:0] ex_readdata2,
	output [4:0] ex_rs1,
	output [4:0] ex_rs2,
	output [4:0] ex_rd
);

// TODO: Implement ID/EX pipeline register module

reg [DATA_WIDTH-1:0] reg_ex_PC;
reg [DATA_WIDTH-1:0] reg_ex_pc_plus_4;

// ex control
reg reg_ex_branch;
reg [1:0] reg_ex_aluop;
reg reg_ex_alusrc;
reg [1:0] reg_ex_jump;

// mem control
reg reg_ex_memread;
reg reg_ex_memwrite;

// wb control
reg reg_ex_memtoreg;
reg reg_ex_regwrite;

reg [DATA_WIDTH-1:0] reg_ex_sextimm;
reg [6:0] reg_ex_funct7;
reg [2:0] reg_ex_funct3;
reg [DATA_WIDTH-1:0] reg_ex_readdata1;
reg [DATA_WIDTH-1:0] reg_ex_readdata2;
reg [4:0] reg_ex_rs1;
reg [4:0] reg_ex_rs2;
reg [4:0] reg_ex_rd;

always @(posedge clk) begin
	if(flush || stall) begin
		reg_ex_PC        <= 0;
		reg_ex_pc_plus_4 <= 0;

		// ex control
		reg_ex_branch    <= 0;
		reg_ex_aluop     <= 0;
		reg_ex_alusrc    <= 0;
		reg_ex_jump      <= 0;

		// mem control
		reg_ex_memread   <= 0;
		reg_ex_memwrite  <= 0;

		// wb control
		reg_ex_memtoreg  <= 0;
		reg_ex_regwrite  <= 0;

		reg_ex_sextimm   <= 0;
		reg_ex_funct7    <= 0;
		reg_ex_funct3    <= 0;
		reg_ex_readdata1 <= 0;
		reg_ex_readdata2 <= 0;
		reg_ex_rs1       <= 0;
		reg_ex_rs2       <= 0;
		reg_ex_rd        <= 0;
	end
	else begin
		reg_ex_PC        <= id_PC;
		reg_ex_pc_plus_4 <= id_pc_plus_4;

		// ex control
		reg_ex_branch    <= id_branch;
		reg_ex_aluop     <= id_aluop;
		reg_ex_alusrc    <= id_alusrc;
		reg_ex_jump      <= id_jump;

		// mem control
		reg_ex_memread   <= id_memread;
		reg_ex_memwrite  <= id_memwrite;

		// wb control
		reg_ex_memtoreg  <= id_memtoreg;
		reg_ex_regwrite  <= id_regwrite;

		reg_ex_sextimm   <= id_sextimm;
		reg_ex_funct7    <= id_funct7;
		reg_ex_funct3    <= id_funct3;
		reg_ex_readdata1 <= id_readdata1;
		reg_ex_readdata2 <= id_readdata2;
		reg_ex_rs1       <= id_rs1;
		reg_ex_rs2       <= id_rs2;
		reg_ex_rd        <= id_rd;
	end
end

assign ex_PC        = reg_ex_PC;
assign ex_pc_plus_4 = reg_ex_pc_plus_4;

// ex control
assign ex_branch    = reg_ex_branch;
assign ex_aluop     = reg_ex_aluop;
assign ex_alusrc    = reg_ex_alusrc;
assign ex_jump      = reg_ex_jump;

// mem control
assign ex_memread   = reg_ex_memread;
assign ex_memwrite  = reg_ex_memwrite;

// wb control
assign ex_memtoreg  = reg_ex_memtoreg;
assign ex_regwrite  = reg_ex_regwrite;

assign ex_sextimm   = reg_ex_sextimm;
assign ex_funct7    = reg_ex_funct7;
assign ex_funct3    = reg_ex_funct3;
assign ex_readdata1 = reg_ex_readdata1;
assign ex_readdata2 = reg_ex_readdata2;
assign ex_rs1       = reg_ex_rs1;
assign ex_rs2       = reg_ex_rs2;
assign ex_rd        = reg_ex_rd;

endmodule
