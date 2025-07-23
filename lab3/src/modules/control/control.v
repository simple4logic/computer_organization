// control.v

// The main control module takes as input the opcode field of an instruction
// (i.e., instruction[6:0]) and generates a set of control signals.

module control(
	input [6:0] opcode,

	output [1:0] jump,
	output branch,
	output mem_read,
	output mem_to_reg,
	output [1:0] alu_op,
	output mem_write,
	output alu_src,
	output reg_write
);

reg [9:0] controls;

// combinational logic
always @(*) begin
	case (opcode)
		7'b0110011: controls = 10'b00_000_10_001; // R-type (always)
		
		//////////////////////////////////////////////////////////////////////////
		// TODO : Implement signals for other instruction types
		// jump[1:0], branch, mem_read, mem_to_reg, alu_op[1:0], mem_write, alu_src, reg_write
		7'b0010011: controls = 10'b00_000_11_011; // I-type (ALU immediate)
		7'b0000011: controls = 10'b00_011_00_011; // I-type (load)
		7'b0100011: controls = 10'b00_00x_00_110; // S-type (store)
		7'b1100011: controls = 10'b00_10x_01_000; // B-type (branch)
		7'b1100111: controls = 10'b11_000_00_011; // I-type (JALR)
		7'b1101111: controls = 10'b01_000_xx_011; // J-type (JAL)

		7'b0110111: controls = 10'b00_000_00_011; // U-type (LUI)
		7'b0010111: controls = 10'b00_000_00_011; // U-type (AUIPC)
		//////////////////////////////////////////////////////////////////////////

		default:    controls = 10'b00_000_00_000;
	endcase
end

assign {jump, branch, mem_read, mem_to_reg, alu_op, mem_write, alu_src, reg_write} = controls;

endmodule

/*
alu_src 	: 두번째 입력을 imm로 사용할지 아니면 reg 값 쓸지	// 0 : reg2, 1 : imm
mem_to_reg 	: ALU 결과를 reg에 쓸지 mem에서 읽은 값을 쓸지	   // 0 : ALU, 1 : mem
*/