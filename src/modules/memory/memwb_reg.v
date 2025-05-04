// memwb_reg.v
// This module is the MEM/WB pipeline register.


module memwb_reg #(
  parameter DATA_WIDTH = 32
)(
  // TODO: Add flush or stall signal if it is needed

  //////////////////////////////////////
  // Inputs
  //////////////////////////////////////
  input clk,

  input [DATA_WIDTH-1:0] mem_pc_plus_4,

  // wb control
  input [1:0] mem_jump,
  input mem_memtoreg,
  input mem_regwrite,
  
  input [DATA_WIDTH-1:0] mem_readdata,
  input [DATA_WIDTH-1:0] mem_alu_result,
  input [4:0] mem_rd,
  
  //////////////////////////////////////
  // Outputs
  //////////////////////////////////////
  output [DATA_WIDTH-1:0] wb_pc_plus_4,

  // wb control
  output [1:0] wb_jump,
  output wb_memtoreg,
  output wb_regwrite,
  
  output [DATA_WIDTH-1:0] wb_readdata,
  output [DATA_WIDTH-1:0] wb_alu_result,
  output [4:0] wb_rd
);

// TODO: Implement MEM/WB pipeline register module

reg [DATA_WIDTH-1:0] reg_wb_pc_plus_4;

// wb control
reg [1:0] reg_wb_jump;
reg reg_wb_memtoreg;
reg reg_wb_regwrite;

reg [DATA_WIDTH-1:0] reg_wb_readdata;
reg [DATA_WIDTH-1:0] reg_wb_alu_result;
reg [4:0] reg_wb_rd;

always @(posedge clk) begin
  reg_wb_pc_plus_4 <= mem_pc_plus_4;
  
  // wb control
  reg_wb_jump     <= mem_jump;
  reg_wb_memtoreg <= mem_memtoreg;
  reg_wb_regwrite <= mem_regwrite;
  
  reg_wb_readdata     <= mem_readdata;
  reg_wb_alu_result   <= mem_alu_result;
  reg_wb_rd           <= mem_rd;
end

endmodule
