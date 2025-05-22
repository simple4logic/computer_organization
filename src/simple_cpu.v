// simple_cpu.v
// a pipelined RISC-V microarchitecture (RV32I)

///////////////////////////////////////////////////////////////////////////////////////////
//// [*] In simple_cpu.v you should connect the correct wires to the correct ports
////     - All modules are given so there is no need to make new modules
////       (it does not mean you do not need to instantiate new modules)
////     - However, you may have to fix or add in / out ports for some modules
////     - In addition, you are still free to instantiate simple modules like multiplexers,
////       adders, etc.
///////////////////////////////////////////////////////////////////////////////////////////

module simple_cpu
#(parameter DATA_WIDTH = 32)(
  input clk,
  input rstn
);

///////////////////////////////////////////////////////////////////////////////
// TODO:  Declare all wires / registers that are needed
///////////////////////////////////////////////////////////////////////////////
// 1) Pipeline registers (wires to / from pipeline register modules)
// 2) In / Out ports for other modules
// 3) Additional wires for multiplexers or other mdoules you instantiate

//////// IF stage ////////
wire [DATA_WIDTH-1:0] IF_instruction;
wire [DATA_WIDTH-1:0] IF_PC_PLUS_4;
wire [DATA_WIDTH-1:0] IF_PC_PREDICTED;

wire hit;
wire branch_pred;

//////// ID stage ////////
// notation : XX_ : XX stage에서 "쓰는" 정보, AABB_reg 이면 BB에서 쓰이는 정보
wire [DATA_WIDTH-1:0] ID_instruction;
wire [DATA_WIDTH-1:0] ID_PC;
wire [DATA_WIDTH-1:0] ID_PC_PLUS_4;
wire [DATA_WIDTH-1:0] ID_PC_PREDICTED;
wire ID_branch_pred;

// instruction fields
wire [6:0] ID_opcode = ID_instruction[6:0];
wire [6:0] ID_funct7 = ID_instruction[31:25];
wire [2:0] ID_funct3 = ID_instruction[14:12];

// for R type
wire [4:0] ID_rs1  = ID_instruction[19:15];
wire [4:0] ID_rs2  = ID_instruction[24:20];
wire [4:0] ID_rd   = ID_instruction[11:7];

// regfile output
wire [31:0] ID_rs1_out, ID_rs2_out;

// immgen
wire [DATA_WIDTH-1:0] ID_sextimm; // sign-extended immediate value

// control unit
wire [1:0]	ID_jump;
wire 		ID_branch;      	
wire [1:0] 	ID_alu_op; 	
wire 		ID_alu_src; 		
wire 		ID_mem_read; 		
wire 		ID_mem_to_reg; 	
wire 		ID_mem_write;	
wire 		ID_reg_write; 	

wire stall, flush;

//////// EX stage ////////
wire [DATA_WIDTH-1:0] EX_PC;
wire [DATA_WIDTH-1:0] EX_PC_PLUS_4;
wire [DATA_WIDTH-1:0] EX_PC_TARGET;
wire [DATA_WIDTH-1:0] EX_PC_PREDICTED;
wire EX_branch_pred;

wire [6:0] EX_funct7;
wire [2:0] EX_funct3;

wire [4:0] EX_rs1, EX_rs2, EX_rd;
wire [31:0] EX_rs1_out, EX_rs2_out, EX_rs1_mid_out, EX_rs2_mid_out;
wire [6:0] EX_opcode; // u-type instruction

wire [DATA_WIDTH-1:0] EX_sextimm; // sign-extended immediate value

// control unit
wire [1:0] 	EX_jump;
wire 		EX_branch;
wire [1:0] 	EX_alu_op;
wire 		EX_alu_src;
wire 		EX_mem_read;
wire 		EX_mem_to_reg;
wire 		EX_mem_write;
wire 		EX_reg_write;

wire [31:0] EX_alu_result;
wire EX_alu_check;
wire EX_taken;
wire [3:0] EX_alu_func;

wire [1:0] forward_a, forward_b; // forwarding signals
wire [31:0] EX_alu_in1_fwd, EX_alu_in2_fwd; // ALU inputs after forwarding

//////// MEM stage ////////
wire [DATA_WIDTH-1:0] MEM_PC;
wire [DATA_WIDTH-1:0] MEM_PC_PLUS_4;
wire [DATA_WIDTH-1:0] MEM_PC_PREDICTED;
wire MEM_branch_pred;
wire [DATA_WIDTH-1:0] MEM_PC_TARGET;
wire [DATA_WIDTH-1:0] MEM_RESOLVED_PC_TARGET;

// control unit
wire [1:0] 	MEM_jump;
wire 		MEM_branch;
wire [1:0] 	MEM_alu_op;
wire 		MEM_alu_src;
wire 		MEM_mem_read;
wire 		MEM_mem_to_reg;
wire 		MEM_mem_write;
wire 		MEM_reg_write;

wire MEM_taken;
wire [31:0] MEM_alu_result;
wire [2:0] 	MEM_funct3;
wire [4:0] 	MEM_rd;
wire [31:0] MEM_write_data;
wire [31:0] MEM_read_data;

//////// WB stage ////////
wire [DATA_WIDTH-1:0] WB_PC_PLUS_4;

// control unit
wire [1:0] 	WB_jump;
wire 		WB_mem_to_reg;
wire 		WB_reg_write;

wire [31:0] WB_read_data;
wire [31:0] WB_alu_result;
wire [4:0] 	WB_rd;

wire [31:0] WB_write_data;

///////////////////////////////////////////////////////////////////////////////
// Instruction Fetch (IF)
///////////////////////////////////////////////////////////////////////////////

reg [DATA_WIDTH-1:0] PC;    // program counter (32 bits)

wire [DATA_WIDTH-1:0] NEXT_PC;
wire [DATA_WIDTH-1:0] NEXT_PC_mid_out;
wire [DATA_WIDTH-1:0] NEXT_PC_resolved;
wire [DATA_WIDTH-1:0] branch_target;

/////////////// PC selection muxes ///////////////
// resolve mux for branch
mux_2x1 m_resolve_branch_mux(
  .in1(MEM_PC_PLUS_4), // PC+4
  .in2(MEM_PC_TARGET), // branch target

  .select(MEM_taken), // branch taken

  .out(NEXT_PC_mid_out)
);

// resolve mux for jump
mux_4x1 m_resolve_jump_mux(
  .in1(NEXT_PC_mid_out),  // branch target or PC+4
  .in2(MEM_PC_TARGET),      // JAL
  .in3(32'b0),              // CANNOT FALL HERE
  .in4(MEM_alu_result),     // JALR

  .select(MEM_jump),

  .out(MEM_RESOLVED_PC_TARGET) // resolved in MEM stage
);

// predecoding
wire IF_is_jump = (IF_instruction[6:0] == 7'b1101111) | (IF_instruction[6:0] == 7'b1100111);
wire IF_is_branch = (IF_instruction[6:0] == 7'b1100011);

wire use_predicted_pc = hit & (IF_is_jump | (IF_is_branch & branch_pred));

mux_2x1 m_predict_mux(
  .in1(IF_PC_PLUS_4), // not taken (or miss)
  .in2(branch_target), // taken & hit & is control flow

  .select(use_predicted_pc), // check if this intruction is control flow

  .out(IF_PC_PREDICTED)
); // T, NT both are predicted 

// decide to take resolve or not
mux_2x1 m_resolve_final_mux(
  .in1(IF_PC_PREDICTED),        // keep going (predict correct)
  .in2(MEM_RESOLVED_PC_TARGET), // resolved target (need to flush)

  .select(MEM_is_control_flow & !MEM_is_predict_correct), // was control flow and wrong prediction (do resolve)

  .out(NEXT_PC_resolved)
);

// highest priority
mux_2x1 m_stall_mux(
  .in1(NEXT_PC_resolved),   // either branch, jump, PC+4
  .in2(PC),                // hold PC when stall

  .select(!flush && stall),

  .out(NEXT_PC)
);

/* m_next_pc_adder */
adder m_pc_plus_4_adder(
  .in_a   (PC),
  .in_b   (32'h0000_0004),

  .result (IF_PC_PLUS_4)
);

always @(posedge clk) begin
  if (rstn == 1'b0) begin
    PC <= 32'h00000000;
  end
  else PC <= NEXT_PC;
end

/* instruction: read current instruction from inst mem */
instruction_memory m_instruction_memory(
  .address    (PC),

  .instruction(IF_instruction)
);

// for unconditional, take prediction if hit
// for conditional, take prediction if hit & pred = 1
wire update_btb = (MEM_taken & MEM_branch) | MEM_jump[0];

branch_hardware m_branch_hardware(
  .clk(clk),
  .rstn(rstn),

  //// input
  // update interface (@ memory stage)
  .update_predictor(MEM_branch),                // branch instruction only
  .update_btb(update_btb),                      // branch taken OR jump
  .actually_taken(MEM_taken),                   // actual resolved result (T, NT)
  .resolved_pc(MEM_PC),                         // pc index in the table
  .resolved_pc_target(MEM_RESOLVED_PC_TARGET),  // target address(either jump or branch)

  // access interface
  .pc(PC), // current pc which i want to predict

  //// output
  .hit(hit), // 
  .pred(branch_pred), // predicted taken or not
  .branch_target(branch_target)
);

/* forward to IF/ID stage registers */
ifid_reg m_ifid_reg(
  // TODO: Add flush or stall signal if it is needed
  .clk            (clk),
  .if_PC          (PC),
  .if_pc_plus_4   (IF_PC_PLUS_4),
  .if_pc_predicted(IF_PC_PREDICTED),
  .if_branch_pred (branch_pred | IF_is_jump), // pred = 1 when bp result is taken or JUMP
  .if_instruction (IF_instruction),

  .id_PC          (ID_PC),
  .id_pc_plus_4   (ID_PC_PLUS_4),
  .id_pc_predicted(ID_PC_PREDICTED),
  .id_branch_pred (ID_branch_pred),
  .id_instruction (ID_instruction),

  .flush          (flush),
  .stall          (stall)
);


//////////////////////////////////////////////////////////////////////////////////
// Instruction Decode (ID)
//////////////////////////////////////////////////////////////////////////////////

/* m_hazard: hazard detection unit */
hazard m_hazard(
  // TODO: implement hazard detection unit & do wiring
  .ID_rs1(ID_rs1),
  .ID_rs2(ID_rs2),
  .EX_rd(EX_rd),
  .EX_mem_read(EX_mem_read),
  .MEM_is_control_flow(MEM_is_control_flow),
  .MEM_is_predict_correct(MEM_is_predict_correct),  

  .flush(flush),
  .stall(stall)
);

/* m_control: control unit */
control m_control(
  .opcode     (ID_opcode),

  .jump       (ID_jump),
  .branch     (ID_branch),
  .alu_op     (ID_alu_op),
  .alu_src    (ID_alu_src),
  .mem_read   (ID_mem_read),
  .mem_to_reg (ID_mem_to_reg),
  .mem_write  (ID_mem_write),
  .reg_write  (ID_reg_write)
);

/* m_imm_generator: immediate generator */
imm_generator m_immediate_generator(
  .instruction(ID_instruction),

  .sextimm    (ID_sextimm)
);

/* m_register_file: register file */
register_file m_register_file(
  .clk        (clk),
  .readreg1   (ID_rs1),
  .readreg2   (ID_rs2),
  .writereg   (WB_rd),
  .wen        (WB_reg_write),
  .writedata  (WB_write_data),

  .readdata1  (ID_rs1_out),
  .readdata2  (ID_rs2_out)
);

/* forward to ID/EX stage registers */
idex_reg m_idex_reg(
  // TODO: Add flush or stall signal if it is needed
  .clk            (clk),
  .id_PC          (ID_PC),
  .id_pc_plus_4   (ID_PC_PLUS_4),
  .id_pc_predicted(ID_PC_PREDICTED),
  .id_branch_pred (ID_branch_pred),
  .id_opcode      (ID_opcode),
  .id_jump        (ID_jump), // 2bit
  .id_branch      (ID_branch),
  .id_aluop       (ID_alu_op),
  .id_alusrc      (ID_alu_src),
  .id_memread     (ID_mem_read),
  .id_memwrite    (ID_mem_write),
  .id_memtoreg    (ID_mem_to_reg),
  .id_regwrite    (ID_reg_write),
  .id_sextimm     (ID_sextimm),
  .id_funct7      (ID_funct7),
  .id_funct3      (ID_funct3),
  .id_readdata1   (ID_rs1_out),
  .id_readdata2   (ID_rs2_out),
  .id_rs1         (ID_rs1),
  .id_rs2         (ID_rs2),
  .id_rd          (ID_rd),

  .ex_PC          (EX_PC),
  .ex_pc_plus_4   (EX_PC_PLUS_4),
  .ex_pc_predicted(EX_PC_PREDICTED),
  .ex_branch_pred (EX_branch_pred),
  .ex_opcode      (EX_opcode),
  .ex_jump        (EX_jump),
  .ex_branch      (EX_branch),
  .ex_aluop       (EX_alu_op),
  .ex_alusrc      (EX_alu_src),
  .ex_memread     (EX_mem_read),
  .ex_memwrite    (EX_mem_write),
  .ex_memtoreg    (EX_mem_to_reg),
  .ex_regwrite    (EX_reg_write),
  .ex_sextimm     (EX_sextimm),
  .ex_funct7      (EX_funct7),
  .ex_funct3      (EX_funct3),
  .ex_readdata1   (EX_rs1_out), // data from RF after reading
  .ex_readdata2   (EX_rs2_out),
  .ex_rs1         (EX_rs1),
  .ex_rs2         (EX_rs2),
  .ex_rd          (EX_rd),

  .flush          (flush),
  .stall          (stall)
);

//////////////////////////////////////////////////////////////////////////////////
// Execute (EX) 
//////////////////////////////////////////////////////////////////////////////////

wire [1:0] EX_u_type;
wire is_lui = (EX_opcode == 7'b0110111);
wire is_auipc = (EX_opcode == 7'b0010111);
assign EX_u_type = {is_auipc, is_lui}; // u_type

/* m_branch_target_adder: PC + imm for branch address */
adder m_branch_target_adder(
  .in_a   (EX_PC),
  .in_b   (EX_sextimm),

  .result (EX_PC_TARGET)
);

/* m_branch_control : checks T/NT */
branch_control m_branch_control(
  .branch (EX_branch),
  .check  (EX_alu_check),
  
  .taken  (EX_taken)
);

/* alu control : generates alu_func signal */
alu_control m_alu_control(
  .alu_op   (EX_alu_op),
  .funct7   (EX_funct7),
  .funct3   (EX_funct3),

  .alu_func (EX_alu_func)
);

/* m_alu */
alu m_alu(
  .alu_func (EX_alu_func),
  .in_a     (EX_alu_in1_fwd), 
  .in_b     (EX_alu_in2_fwd), 

  .result   (EX_alu_result),
  .check    (EX_alu_check)
);

forwarding m_forwarding(
  // TODO: implement forwarding unit & do wiring
  .rs1(EX_rs1),
  .rs2(EX_rs2),
  .rd_exmem(MEM_rd),
  .reg_write_exmem(MEM_reg_write),
  .rd_memwb(WB_rd),
  .reg_write_memwb(WB_reg_write),
  
  // 0 : no forward, 1 : forward from EX stage, 2 : forward from MEM stage
  .forward_a(forward_a), 
  .forward_b(forward_b)
);

mux_3x1 m_forward_a_mux(
  .in1(EX_rs1_out),
  .in2(MEM_alu_result), //alu forwarding from EX/MEM stage
  .in3(WB_write_data),  //alu forwarding from MEM/WB stage

  .select(forward_a),

  .out(EX_rs1_mid_out)
);

mux_3x1 m_forward_b_mux(
  .in1(EX_rs2_out),
  .in2(MEM_alu_result),
  .in3(WB_write_data),

  .select(forward_b),

  .out(EX_rs2_mid_out)
);

// mux 3x1 for u-type instruction
mux_3x1 m_utype_select(
  .in1(EX_rs1_mid_out),
  .in2(32'b0), // lui   = {0, 1}
  .in3(EX_PC), // auipc = {1, 0}

  .select(EX_u_type),

  .out(EX_alu_in1_fwd)
);

// mux 2x1 for ALU input 2 (choose between rs2 and imm)
mux_2x1 m_alu_src_mux(
  .in1(EX_rs2_mid_out), // rs2 value
  .in2(EX_sextimm),     // imm value

  .select(EX_alu_src),

  .out(EX_alu_in2_fwd) // ALU input 2
);

/* forward to EX/MEM stage registers */
exmem_reg m_exmem_reg(
  // TODO: Add flush or stall signal if it is needed
  .clk            (clk),
  .ex_pc          (EX_PC),
  .ex_pc_plus_4   (EX_PC_PLUS_4),
  .ex_pc_predicted(EX_PC_PREDICTED),
  .ex_branch_pred (EX_branch_pred),
  .ex_pc_target   (EX_PC_TARGET),
  .ex_taken       (EX_taken), 
  .ex_jump        (EX_jump),
  .ex_branch      (EX_branch),
  .ex_memread     (EX_mem_read),
  .ex_memwrite    (EX_mem_write),
  .ex_memtoreg    (EX_mem_to_reg),
  .ex_regwrite    (EX_reg_write),
  .ex_alu_result  (EX_alu_result),
  .ex_writedata   (EX_rs2_mid_out), // data to be written @ MEM stage
  .ex_funct3      (EX_funct3),
  .ex_rd          (EX_rd),
  
  .mem_pc         (MEM_PC),
  .mem_pc_plus_4  (MEM_PC_PLUS_4),
  .mem_pc_predicted(MEM_PC_PREDICTED),
  .mem_branch_pred(MEM_branch_pred),
  .mem_pc_target  (MEM_PC_TARGET),
  .mem_taken      (MEM_taken), 
  .mem_jump       (MEM_jump),
  .mem_branch     (MEM_branch),
  .mem_memread    (MEM_mem_read),
  .mem_memwrite   (MEM_mem_write),
  .mem_memtoreg   (MEM_mem_to_reg),
  .mem_regwrite   (MEM_reg_write),
  .mem_alu_result (MEM_alu_result),
  .mem_writedata  (MEM_write_data),
  .mem_funct3     (MEM_funct3),
  .mem_rd         (MEM_rd),

  .flush          (flush)
);

//////////////////////////////////////////////////////////////////////////////////
// Memory (MEM) 
//////////////////////////////////////////////////////////////////////////////////
wire MEM_is_control_flow = MEM_branch | (MEM_jump != 2'b00); // jump or branch
wire MEM_is_predict_correct = (MEM_PC_PREDICTED == MEM_RESOLVED_PC_TARGET) & (MEM_taken == MEM_branch_pred);

/* m_data_memory : main memory module */
data_memory m_data_memory(
  .clk         (clk),
  .address     (MEM_alu_result),
  .write_data  (MEM_write_data),
  .mem_read    (MEM_mem_read),
  .mem_write   (MEM_mem_write),
  .maskmode    (MEM_funct3[1:0]),
  .sext        (MEM_funct3[2]),

  .read_data   (MEM_read_data)
);

/* forward to MEM/WB stage registers */
memwb_reg m_memwb_reg(
  // TODO: Add flush or stall signal if it is needed
  .clk            (clk),
  .mem_pc_plus_4  (MEM_PC_PLUS_4),
  .mem_jump       (MEM_jump),
  .mem_memtoreg   (MEM_mem_to_reg),
  .mem_regwrite   (MEM_reg_write),
  .mem_readdata   (MEM_read_data),
  .mem_alu_result (MEM_alu_result),
  .mem_rd         (MEM_rd),

  .wb_pc_plus_4   (WB_PC_PLUS_4),
  .wb_jump        (WB_jump),
  .wb_memtoreg    (WB_mem_to_reg),
  .wb_regwrite    (WB_reg_write),
  .wb_readdata    (WB_read_data),
  .wb_alu_result  (WB_alu_result),
  .wb_rd          (WB_rd)
);

//////////////////////////////////////////////////////////////////////////////////
// Write Back (WB) 
//////////////////////////////////////////////////////////////////////////////////

// MUX for write data
mux_4x1 m_write_data_mux(
  .in1(WB_alu_result),
  .in2(WB_read_data),
  .in3(WB_PC_PLUS_4), // jalr jal
  .in4(WB_PC_PLUS_4), // jalr jal

  .select({WB_jump[0], WB_mem_to_reg}),

  .out(WB_write_data)
);

//////////////////////////////////////////////////////////////////////////////////
// Hardware Counters
//////////////////////////////////////////////////////////////////////////////////
wire [31:0] CORE_CYCLE;
wire [31:0] NUM_COND_BRANCHES;
wire [31:0] NUM_UNCOND_BRANCHES;
wire [31:0] BP_CORRECT;

hardware_counter m_core_cycle(
  .clk(clk),
  .rstn(rstn),
  .cond(1'b1),

  .counter(CORE_CYCLE)
);

hardware_counter m_num_cond_branches(
  .clk(clk),
  .rstn(rstn),
  .cond(MEM_branch),

  .counter(NUM_COND_BRANCHES)
);

hardware_counter m_num_uncond_branches(
  .clk(clk),
  .rstn(rstn),
  .cond(MEM_jump[0]),

  .counter(NUM_UNCOND_BRANCHES)
);

hardware_counter m_bp_correct(
  .clk(clk),
  .rstn(rstn),
  .cond(MEM_is_control_flow & MEM_is_predict_correct),

  .counter(BP_CORRECT)
);

endmodule
