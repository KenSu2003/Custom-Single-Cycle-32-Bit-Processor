/**
 * READ THIS DESCRIPTION!
 *
 * The processor takes in several inputs from a skeleton file.
 *
 * Inputs
 * clock: this is the clock for your processor at 50 MHz
 * reset: we should be able to assert a reset to start your pc from 0 (sync or
 * async is fine)
 *
 * Imem: input data from imem
 * Dmem: input data from dmem
 * Regfile: input data from regfile
 *
 * Outputs
 * Imem: output control signals to interface with imem
 * Dmem: output control signals and data to interface with dmem
 * Regfile: output control signals and data to interface with regfile
 *
 * Notes
 *
 * Ultimately, your processor will be tested by subsituting a master skeleton, imem, dmem, so the
 * testbench can see which controls signal you active when.
 * Therefore, there needs to be a way to
 * "inject" imem, dmem, and regfile interfaces from some external controller module.
 * The skeleton
 * file acts as a small wrapper around your processor for this purpose.
 *
 * You will need to figure out how to instantiate two memory elements, called
 * "syncram," in Quartus: one for imem and one for dmem.
 * Each should take in a
 * 12-bit address and allow for storing a 32-bit value at each address.
 * Each
 * should have a single clock.
 *
 * Each memory element should have a corresponding .mif file that initializes
 * the memory element to certain value on start up.
 * These should be named
 * imem.mif and dmem.mif respectively.
 *
 * Importantly, these .mif files should be placed at the top level, i.e. there
 * should be an imem.mif and a dmem.mif at the same level as process.v.
 * You
 * should figure out how to point your generated imem.v and dmem.v files at
 * these MIF files.
 *
 * imem
 * Inputs:  12-bit address, 1-bit clock enable, and a clock
 * Outputs: 32-bit instruction
 *
 * dmem
 * Inputs:  12-bit address, 1-bit clock, 32-bit data, 1-bit write enable
 * Outputs: 32-bit data at the given address
 *
 */
module processor(
    // Control signals
    clock,                          // I: The master clock
    reset,                          // I: A reset signal

    // Imem
    address_imem,                   // O: The address of the data to get from imem
    q_imem,                         // I: The data from imem

    // Dmem
    address_dmem,                   // O: The address of the data to get or put from/to dmem
    data,                           // O: The data to write to dmem
    wren,                           // O: Write enable for dmem
    q_dmem,                         // I: The data from dmem

    // Regfile
    ctrl_writeEnable,               // O: Write enable for regfile
    ctrl_writeReg,                  // O: Register to write to in regfile
    ctrl_readRegA,                  // O: Register to read from port A of regfile
    ctrl_readRegB,                  // O: Register to read from port B of regfile
    data_writeReg,                  // O: Data to write to for regfile
    data_readRegA,                  // I: Data from port A of regfile
    data_readRegB                   // I: Data from port B of regfile
);
// Control signals
    input clock, reset;

    // Imem
    output [11:0] address_imem;
    input [31:0] q_imem;
// Dmem
    output [11:0] address_dmem;
    output [31:0] data;
    output wren;
    input [31:0] q_dmem;
// Regfile
    output ctrl_writeEnable;
    output [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
    output [31:0] data_writeReg;
    input [31:0] data_readRegA, data_readRegB;
/* ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ DO NOT CHANGE CODE ABOVE ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ */

    // ******* Are Components
    // +++++++ Are Logics


    /* —————————————————————————— IF stage —————————————————————————— */
    wire [11:0] pc;
    wire [11:0] pc_plus_1, pc_next;
    wire pc_src;

    // ************** Calculate PC+1 **************
    /*
        Using ALU since we can't use '+' and its what the schematic uses.
        #IMPORTANT: Remember that we are using +1 NOT +4 !
     */
    wire [31:0] pc_alu_result;
    alu pc_alu (
        .data_operandA({20'b0, pc}),
        .data_operandB(32'd1),          // using +1 NOT +4
        .ctrl_ALUopcode(5'b00000),      // Add == 00000
        .ctrl_shiftamt(5'b00000),
        .data_result(pc_alu_result),
        .isNotEqual(),
        .isLessThan(),
        .overflow()
    );
    assign pc_plus_1 = pc_alu_result[11:0]; // alu returns 32-bits have to parse to 12-bits

    // ************** Calculate PC+2 for JAL Compensation **************
    wire [31:0] pc_plus_two_result;
    alu pc_alu_plus_two (
        .data_operandA({20'b0, pc}),
        .data_operandB(32'd2),      // Using +2 to compensate for PC lag
        .ctrl_ALUopcode(5'b00000),  // Add == 00000
        .ctrl_shiftamt(5'b00000),
        .data_result(pc_plus_two_result),
        .isNotEqual(),
        .isLessThan(),
        .overflow()
    );


    // ++++++++++++++ Calculate and Select Branch Target ++++++++++++++
    /* Used pc_plus_1 for checkpoint 4 since it doesn't require it.
        assign branch_target = pc_plus_1;   // THIS NEEDS TO BE CHANGED FOR CHECKPOINT 5

        Now we are going to implementing it.
        The address would come from the PC_MUX in var branch_target
     */


    // ************** Branch Mux **************
    wire [11:0] branch_or_pc_plus_1, branch_target;
    mux_2_1 branch_mux (
        .out(branch_or_pc_plus_1),
        .a(pc_plus_1),
        .b(branch_target),
        .s(pc_src)              // 1 if bne/blt is taken
    );
    // ************** J/JAL/JR Muxes **************
    // jr_func, is_j_or_jal : ID/EX Stage
    // j_or_jal_target : ID Stage
    
    wire [11:0] j_or_jal_target, jump_mux_out;
    wire is_j_or_jal;
    
    mux_2_1 jump_mux (
        .out(jump_mux_out),
        .a(branch_or_pc_plus_1),
        .b(j_or_jal_target),
        .s(is_j_or_jal)
    );
    // ************** jr mux **************
    /*
        Selects between (previous result) AND (Register Value)
    */
    wire jr_func; // Defined in ID Stage
    wire [11:0] jr_mux_out;
    // Create intermediate wire
    mux_2_1 jr_mux (
        .out(jr_mux_out),
        .a(jump_mux_out),
        .b(data_readRegA[11:0]),    // Value from RegFile (e.g., $ra)
        .s(jr_func)                 // Select if jr
    );
    // ************** bex mux **************
    /*
        Selects between (previous result) AND (T)
    */
    wire isBex; // Defined in EX Stage
    mux_2_1 bex_mux (
        .out(pc_next),
        .a(jr_mux_out),          // The PC value from the previous stages
        .b(j_or_jal_target),     // The jump target T
        .s(isBex)         // Select T if bex is taken
    );
    // ************** Instruction Memory **************
    /* Used 32-DFFEs to store each bit of the instruction.
    */ 
    genvar i;
    generate
        for (i = 0; i < 12; i = i + 1) begin : pc_reg_gen
            dffe_ref pc_dffe_i (
                .q(pc[i]),
                .d(pc_next[i]),
                .clk(clock),
         
                .en(1'b1),
                .clr(reset)
            );
        end
    endgenerate


    // ++++++++++++++ PC -> Read Address ++++++++++++++
    assign address_imem = pc;
    
    wire [31:0] instr;
    assign instr = q_imem;


    /* ———————————————————————————————————————————————————— ID stage ———————————————————————————————————————————————————— */
    wire [4:0] opcode;
    wire [4:0] rs, rt, rd, shamt;
    wire [4:0] alu_op;
    wire [16:0] immediate;
    wire [31:0] sign_extended;
    
    // ++++++++++++++ Universal ++++++++++++++
    assign opcode    = instr[31:27];
    
    // ++++++++++++++ Decode R-Type ++++++++++++++
    assign rd        = instr[26:22]; // destination for R-type and I-type in this ISA
    assign rs        = instr[21:17]; // source 
    assign rt        = instr[16:12];
    assign shamt     = instr[11:7];
    assign alu_op    = instr[6:2];
    // NOTE: ZEROES are just included in the sign exteded


    // ++++++++++++++ Decode I-type ++++++++++++++
    assign immediate = instr[16:0];
    
    // ************** Sign Extended **************
    assign sign_extended = {{15{immediate[16]}}, immediate};
    
    // ++++++++++++++ Decode J-type ++++++++++++++
    // *** FIX: Correctly assign j_target_full from instr[26:0] and truncate ***
    wire [26:0] j_target_full;
    assign j_target_full = instr[26:0];          // Get 27-bit target
    assign j_or_jal_target = j_target_full[11:0];  // Truncate to 12-bit PC
    
    
    /* * -------------------------------------------------------------------------------------
    * MOVED ALL DECODERS HERE (from EX Stage)
    * This fixes the hazard where control signals were used before they were defined.
    * ------------------------------------------------------------------------------------- 
    */
 
    // ++++++++++++++ R-Type Functions, the ([xxxxx]) ++++++++++++++
    wire add_func, sub_func, and_func, or_func, sll_func, sra_func;
    and add_check (add_func, ~alu_op[4], ~alu_op[3], ~alu_op[2], ~alu_op[1], ~alu_op[0]);
    and sub_check (sub_func, ~alu_op[4], ~alu_op[3], ~alu_op[2], ~alu_op[1], alu_op[0]);
    and and_check (and_func, ~alu_op[4], ~alu_op[3], ~alu_op[2], alu_op[1], ~alu_op[0]);
    and or_check  (or_func,  ~alu_op[4], ~alu_op[3], ~alu_op[2], alu_op[1], alu_op[0]);
    and sll_check (sll_func, ~alu_op[4], ~alu_op[3], alu_op[2], ~alu_op[1], ~alu_op[0]);
    and sra_check (sra_func, ~alu_op[4], ~alu_op[3], alu_op[2], ~alu_op[1], alu_op[0]);

    // ++++++++++++++ I-Type Instructions ++++++++++++++
    wire r_type, addi_type, lw_type, sw_type;
    and r_type_check (r_type, ~opcode[4], ~opcode[3], ~opcode[2], ~opcode[1], ~opcode[0]);  // r_type: 00000
    and addi_check (addi_type, ~opcode[4], ~opcode[3], opcode[2], ~opcode[1], opcode[0]); // addi:   00101
    and lw_check (lw_type, ~opcode[4], opcode[3], ~opcode[2], ~opcode[1], ~opcode[0]);   // lw:     01000
    and sw_check (sw_type, ~opcode[4], ~opcode[3], opcode[2], opcode[1], opcode[0]);   // sw:     00111
    
    // ++++++++++++++ Branch Instructions ++++++++++++++
    wire bne_func, blt_func;
    and bne_check (bne_func, ~opcode[4], ~opcode[3], ~opcode[2], opcode[1], ~opcode[0]); // bne : 00010
    and blt_check (blt_func, ~opcode[4], ~opcode[3], opcode[2], opcode[1], ~opcode[0]); // blt : 00110
    
    // ++++++++++++++ J-Type Instructions ++++++++++++++
    wire j_func, jal_func, setx_func, bex_func; // jr_func defined earlier
    and j_check (j_func, ~opcode[4], ~opcode[3], ~opcode[2], ~opcode[1], opcode[0]);    // j:    00001
    and jal_check  (jal_func, ~opcode[4], ~opcode[3], ~opcode[2], opcode[1], opcode[0]); // jal:  00011
    and jr_check (jr_func, ~opcode[4], ~opcode[3], opcode[2], ~opcode[1], ~opcode[0]);   // jr:   00100
    and setx_check (setx_func, opcode[4], ~opcode[3], opcode[2], ~opcode[1], opcode[0]); // setx: 10101
    and bex_check (bex_func, opcode[4], ~opcode[3], opcode[2], opcode[1], ~opcode[0]);   // bex:  10110

    // ++++++++++++++ Main Decoder (Control Signals) ++++++++++++++
    wire mem_read, mem_to_reg, mem_write, alu_src, reg_write;

    assign reg_write = r_type | addi_type | lw_type;
    assign mem_write = sw_type;
    assign mem_read  = lw_type;
    assign alu_src = addi_type | lw_type | sw_type;
    assign mem_to_reg = lw_type;
    or is_j_or_jal_or (is_j_or_jal, j_func, jal_func); // Used in IF stage MUX


    // ++++++++++++++ Regfile Read Port Logic (NOW WORKS) ++++++++++++++
    /* ctrl_readRegA = rs, except:
        - bex: 30 ($rstatus)
        - jr:  rd ($ra)
       ctrl_readRegB = rt, except:
        - sw:  rd
        - bne: rd
        - blt: rd
    */
    wire readA_is_rd = jr_func | blt_func;
    assign ctrl_readRegA = bex_func ? 5'd30 : (readA_is_rd ? rd : rs);    

    wire need_rd_for_B;
    or readRegB_or (need_rd_for_B, sw_type, bne_func);
    assign ctrl_readRegB = need_rd_for_B ? rd : (blt_func ? rs : rt);


    // ************** Branch Address ALU **************
    alu leftshift_ALU (
        .data_operandA(pc_plus_1),
        .data_operandB(sign_extended),
        .ctrl_ALUopcode(5'b00000),      // Add == 00000
        .ctrl_shiftamt(5'b00000),
        .data_result(branch_target),
        .isNotEqual(),
        .isLessThan(),
        .overflow()
    );


    /* ———————————————————————————————————————————————————— EX stage ———————————————————————————————————————————————————— */
    
    // ++++++++++++++ Check if it's a branch operation ++++++++++++++
    wire isBranch;
    or checkBranch (isBranch, bne_func, blt_func);

    // Check which operation to use for ALU
    wire add_op, sub_op, and_op, or_op, sll_op, sra_op;
    wire [4:0] alu_control;
    assign add_op = (r_type & add_func) | addi_type | lw_type | sw_type; // lw/sw need add for offset
    assign sub_op = (r_type & sub_func) | bne_func | blt_func;       // an '-' or bne or blt
    assign and_op = r_type & and_func;
    assign or_op  = r_type & or_func;
    assign sll_op = r_type & sll_func;
    assign sra_op = r_type & sra_func;
    
    assign alu_control = add_op ? 5'b00000 :
                         sub_op ? 5'b00001 :
                         and_op ? 5'b00010 :
                         or_op  ? 5'b00011 :
                         sll_op ? 5'b00100 :
                         sra_op ? 5'b00101 :
                         5'b00000;
                         
    // ************** ALU Src MUX **************
    wire [31:0] alu_src_b;
    mux_2_1 alu_src_mux (
        .out(alu_src_b),
        .a(data_readRegB),
        .b(sign_extended),
        .s(alu_src)
    );
    
    // ************** MAIN ALU **************
    wire [31:0] alu_result;
    wire alu_isNotEqual, alu_isLessThan, alu_overflow;
    alu main_alu (
        .data_operandA(data_readRegA),
        .data_operandB(alu_src_b),
        .ctrl_ALUopcode(alu_control),
        .ctrl_shiftamt(shamt),
        .data_result(alu_result),
        .isNotEqual(alu_isNotEqual),
        .isLessThan(alu_isLessThan),
        .overflow(alu_overflow)
    );
    
    // Check if branching is required
    wire confirm_branch;
    wire branch_bne, branch_blt;
    and bne_and (branch_bne, alu_isNotEqual, bne_func);
    and blt_and (branch_blt, alu_isLessThan, blt_func);
    or(confirm_branch, branch_bne, branch_blt);
    
    and branch_and (pc_src, isBranch, confirm_branch); // update PC_SRC


    // BEX condition check
    wire rstatus_is_not_zero;
    assign rstatus_is_not_zero = | data_readRegA; // OR-reduction (NOW WORKS)
    
    // isBex is used by PC Mux in IF stage
    assign isBex = bex_func & rstatus_is_not_zero;

    
    /* ---------------------------------------------------------------------
        Overflow / rstatus forwarding
      --------------------------------------------------------------------- */
    wire r_add_overflow = r_type & add_func & alu_overflow;
    wire i_addi_overflow = addi_type & alu_overflow;
    wire r_sub_overflow = sub_op & alu_overflow;
    
    // Set the overflow status accordingly
    wire [31:0] rstatus;
    assign rstatus = i_addi_overflow ? 32'd2 :      // moving this up fixed an issue, no idea why
                     r_add_overflow ? 32'd1 :
                     r_sub_overflow ? 32'd3 :
                     32'd0;
                     
    // Signal for r30 if there is an overflow
    wire overflow_write_rstatus;
    assign overflow_write_rstatus = r_add_overflow | i_addi_overflow | r_sub_overflow;


    /* —————————————————————————— MEM stage —————————————————————————— */
    // Instatiated at the TOP
    assign address_dmem = alu_result[11:0];
    assign data = data_readRegB;
    assign wren = mem_write;


    /* —————————————————————————— WB stage —————————————————————————— */

    // Pick the data to write to register
    wire [31:0] mem_to_reg_data;
    mux_2_1 mem_to_reg_mux (
        .out(mem_to_reg_data),        
        .a(alu_result),               // Input A: ALU computation result
        .b(q_dmem),                   // Input B: data from data memory (for lw)
        .s(mem_to_reg)                // Select: 0=ALU result, 1=memory data
    );
    
    /* Output Register (Priority top-down) [overflow > SETX > JAL > normal]
    */
    wire [4:0] final_write_reg;

    wire is_setx_or_overflow;
    or setx_overflow_or (is_setx_or_overflow, overflow_write_rstatus, setx_func);
    assign final_write_reg  = is_setx_or_overflow ? 5'd30 : (jal_func ? 5'd31 : rd);
    
    /*
        Write Permission
    */
    wire final_write_enable;
    or final_write_or (final_write_enable, reg_write, overflow_write_rstatus, jal_func, setx_func);

    /*
        Check if we're trying to write to register 0
    */
    wire final_is_reg0;
    assign final_is_reg0 = ~ ( | final_write_reg );


    // Only enable write if we want to write AND it's not register 0
    assign ctrl_writeEnable = final_write_enable & ~final_is_reg0;
    
    // Tell the register file which register to write to
    assign ctrl_writeReg = final_write_reg;
    
    // ++++++++++++++ Choose the final data to write ++++++++++++++
    /*
        If overflow, write rstatus.
        Else if setx, write T. 
        Else if jal, write PC+1.
        Else, write normal data.
    */
    wire [31:0] target;
    assign target = {5'b0, j_target_full}; // Zero-extend T (instr[26:0]) to 32 bits
    
    assign data_writeReg = overflow_write_rstatus ? rstatus :
                        (setx_func ? target :
                        (jal_func ? pc_plus_two_result : mem_to_reg_data));
endmodule