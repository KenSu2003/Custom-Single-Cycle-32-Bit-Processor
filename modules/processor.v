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
 * testbench can see which controls signal you active when. Therefore, there needs to be a way to
 * "inject" imem, dmem, and regfile interfaces from some external controller module. The skeleton
 * file acts as a small wrapper around your processor for this purpose.
 *
 * You will need to figure out how to instantiate two memory elements, called
 * "syncram," in Quartus: one for imem and one for dmem. Each should take in a
 * 12-bit address and allow for storing a 32-bit value at each address. Each
 * should have a single clock.
 *
 * Each memory element should have a corresponding .mif file that initializes
 * the memory element to certain value on start up. These should be named
 * imem.mif and dmem.mif respectively.
 *
 * Importantly, these .mif files should be placed at the top level, i.e. there
 * should be an imem.mif and a dmem.mif at the same level as process.v. You
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

    /* YOUR CODE STARTS HERE */

    /* ——————————————————————————————————— IF stage ——————————————————————————————————— */
    
    // ******************** Program Counter ********************    
    wire [11:0] pc, pc_next;


    // ******************** PC+1 ALU ********************
    wire [11:0] pc_plus_1;
    wire [31:0] pc_alu_result;
    alu pc_alu (
        .data_operandA({20'b0, pc}),
        .data_operandB(32'd1),
        .ctrl_ALUopcode(5'b00000),
        .ctrl_shiftamt(5'b00000),
        .data_result(pc_alu_result),
        .isNotEqual(),
        .isLessThan(),
        .overflow()
    );
    assign pc_plus_1 = pc_alu_result[11:0];


    // ******************** Instruction Memory ********************
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

    // +++++++++++++++++ PC -> Read Address +++++++++++++++++
    assign address_imem = pc;

    // Latch fetched instruction on processor clock for stable decode 
    /*
        THIS PART IS VERY IMPORTANT FOR TIMING AND FORWARDING THE LOADED DATA
    */
    wire [31:0] instr, instr_input;
    wire branch_src, jump_src;
    assign instr_input = (branch_src | jump_src) ? 32'b0 : q_imem;  // Bubble to delay by one cycle

    generate
        for (i = 0; i < 32; i = i + 1) begin : instr_reg_gen
            dffe_ref instr_dffe_i (
                .q(instr[i]),
                .d(instr_input[i]), // Use the MUXed input, not q_imem direct
                .clk(clock),
                .en(1'b1),
                .clr(reset)
            );
        end
    endgenerate

    /* ——————————————————————————————————— End of IF ——————————————————————————————————— */


    /* ——————————————————————————————————— ID stage ——————————————————————————————————— */
    wire [4:0] opcode;
    wire [4:0] rs, rt, rd, shamt;
    wire [4:0] alu_op;
    wire [16:0] immediate;
    wire [31:0] sign_extended;          // NOTE: ZEROES are just included in the sign-extended
    wire [26:0] target;

    // Universal
    assign opcode    = instr[31:27];    // main opcode
    assign rd        = instr[26:22];    // destination for R-type and I-type in this ISA
    assign rs        = instr[21:17];    // source 
    assign rt        = instr[16:12];    // target
    assign shamt     = instr[11:7];     // shift amount
    assign alu_op    = instr[6:2];      // r-type operations
    assign immediate = instr[16:0];     // Immediate
    assign sign_extended = {{15{immediate[16]}}, immediate};    // For calculating brach and the ALU in EX stage
    assign target    = instr[26:0];
    
    /* -------------------------------------------------------------------------------------
        NOTE: These types are later used to determine what operation the ALU is going to execute.
       ------------------------------------------------------------------------------------- */
 
    wire r_type, addi_type, lw_type, sw_type, bne_type, blt_type;
    wire add_func, sub_func, and_func, or_func, sll_func, sra_func;


    // ++++++++++++++++++++++++++ R-Type Decode ++++++++++++++++++++++++++
    and r_type_check (r_type, ~opcode[4], ~opcode[3], ~opcode[2], ~opcode[1], ~opcode[0]);  // r_type: opcode == 00000
    
    // Logic
    and add_check (add_func, ~alu_op[4], ~alu_op[3], ~alu_op[2], ~alu_op[1], ~alu_op[0]);
    and sub_check (sub_func, ~alu_op[4], ~alu_op[3], ~alu_op[2], ~alu_op[1], alu_op[0]);
    and and_check (and_func, ~alu_op[4], ~alu_op[3], ~alu_op[2], alu_op[1], ~alu_op[0]);
    and or_check  (or_func,  ~alu_op[4], ~alu_op[3], ~alu_op[2], alu_op[1], alu_op[0]);
    
    // Shifts
    and sll_check (sll_func, ~alu_op[4], ~alu_op[3], alu_op[2], ~alu_op[1], ~alu_op[0]);
    and sra_check (sra_func, ~alu_op[4], ~alu_op[3], alu_op[2], ~alu_op[1], alu_op[0]);


    // ++++++++++++++++++++++++++ I-Type Decode ++++++++++++++++++++++++++
    // Add Immediate
    and addi_check (addi_type, ~opcode[4], ~opcode[3], opcode[2], ~opcode[1], opcode[0]);   // addi: opcode == 00101

    // Load and Store
    and lw_check (lw_type, ~opcode[4], opcode[3], ~opcode[2], ~opcode[1], ~opcode[0]);      // lw: opcode == 01000
    and sw_check (sw_type, ~opcode[4], ~opcode[3], opcode[2], opcode[1], opcode[0]);        // sw: opcode == 00111

    // Branch Instructions
    and bne_check (bne_type, ~opcode[4], ~opcode[3], ~opcode[2], opcode[1], ~opcode[0]);        // sw: opcode == 00010
    and blt_check (blt_type, ~opcode[4], ~opcode[3], opcode[2], opcode[1], ~opcode[0]);         // sw: opcode == 00110

    
    // +++++++++++++++++ J-Type Decode +++++++++++++++++
    wire j_type, jal_type, jr_type, bex_type, setx_type;

    and j_check (j_type, ~opcode[4], ~opcode[3], ~opcode[2], ~opcode[1], opcode[0]);        // j: 00001
    and jal_check (jal_type, ~opcode[4], ~opcode[3], ~opcode[2], opcode[1], opcode[0]);     // jal: 00011
    and jr_check (jr_type, ~opcode[4], ~opcode[3], opcode[2], ~opcode[1], ~opcode[0]);      // jr: 00100
    and bex_check (bex_type, opcode[4], ~opcode[3], opcode[2], opcode[1], ~opcode[0]);      // bex: 10110
    and setx_check (setx_type, opcode[4], ~opcode[3], opcode[2], ~opcode[1], opcode[0]);    // setx: 10101


    // ++++++++++++++++++++++++++ r/w Permissions ++++++++++++++++++++++++++
    wire mem_read, mem_to_reg, mem_write, alu_src, reg_write;

    assign reg_write = r_type | addi_type | lw_type;
    assign mem_write = sw_type;
    assign mem_read  = lw_type;
    assign alu_src = addi_type | lw_type | sw_type;         // 0: dataRegA , 1: sign-exteded
    assign mem_to_reg = lw_type;


    // ++++++++++++++++++++++++++ Port Selection ++++++++++++++++++++++++++
    /* ---------------------------------------------------------------------
    // Regfile read ports:
    ctrl_readRegA =                 // Right term
        rd : jr
        rs : else
    ctrl_readRegB =                 // Left term
        rd : sw , bne , blt
        rt : else
    --------------------------------------------------------------------- */
    assign ctrl_readRegA = (bne_type | blt_type | jr_type) ? rd : (bex_type ? 5'd30 : rs);
    assign ctrl_readRegB = (bne_type | blt_type) ? rs : (sw_type ? rd : rt);

    /* ——————————————————————————————————— End of ID ——————————————————————————————————— */


    /* ——————————————————————————————————— EX stage ——————————————————————————————————— */
    /* --------------------------------------------------------------------- 
        R-type
        add $rd, $rs, $rt	    00000 (00000)
        sub $rd, $rs, $rt	    00000 (00001)
        and $rd, $rs, $rt	    00000 (00010)
        or $rd, $rs, $rt	    00000 (00011)
        sll $rd, $rs, shamt	    00000 (00100)
        sra $rd, $rs, shamt	    00000 (00101)

        I-type
        addi $rd, $rs, N	    00101
        sw $rd, N($rs)	        00111
        lw $rd, N($rs)	        01000
       --------------------------------------------------------------------- */
    
    
    // ++++++++++++++++++++++++++ Determine MAIN ALU OPERATION ++++++++++++++++++++++++++
    wire add_op, sub_op, and_op, or_op, sll_op, sra_op;
    wire [4:0] alu_control;
    assign add_op = (r_type & add_func) | addi_type;    // an '+' can be "add" (R-type) or "addi" (i-type)
    assign sub_op = (r_type & sub_func) | bne_type | blt_type;    // normal subtraction or for calcualting less than
    assign and_op = r_type & and_func;
    assign or_op  = r_type & or_func;
    assign sll_op = r_type & sll_func;
    assign sra_op = r_type & sra_func;


    // ***************** ALU Control *****************
    assign alu_control = add_op ? 5'b00000 :
                         sub_op ? 5'b00001 :
                         and_op ? 5'b00010 :
                         or_op  ? 5'b00011 :
                         sll_op ? 5'b00100 :
                         sra_op ? 5'b00101 :
                         5'b00000;


    // ***************** ALU Source Mux *****************
    // MUX to calcualte soruce b for the ALU
    wire [31:0] alu_src_b;
    mux_2_1 alu_src_mux (
        .out(alu_src_b),
        .a(data_readRegB),
        .b(sign_extended),
        .s(alu_src)
    );

    // ++++++++++++++++++++++++++ Execute the instruction ++++++++++++++++++++++++++
    wire [31:0] alu_result;
    wire alu_isNotEqual, alu_isLessThan, alu_overflow;

    // ***************** MAIN ALU *****************
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

    /* ---------------------------------------------------------------------
        Overflow / rstatus forwarding
        $rd = $rs + $rt         $rstatus = 1 if overflow
        $rd = $rs + N           $rstatus = 2 if overflow
        $rd = $rs - $rt         $rstatus = 3 if overflow
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



    // ++++++++++++++++++++++++++ Calculate Branch ++++++++++++++++++++++++++
    /* ---------------------------------------------------------------------
        Determine if we need to branch
        if:
            bne : alu_isNotEqual == True
        or
            blt : alu_isLessThan == True
        then 
            confirm_branch == True
       --------------------------------------------------------------------- */
    wire isBranch;
    assign isBranch = bne_type | blt_type;                      // check if branching is allowed
    assign branch_src = (bne_type & alu_isNotEqual) | (blt_type & alu_isLessThan);   
  
    /* ---------------------------------------------------------------------
        In the project because we are counting in words we don't 
        need to left-shift by 2. Instead we have to use:
            - branch_target = (PC+1) + SignExt(immed)
       --------------------------------------------------------------------- */
    wire [31:0] branch_target;
    alu branch_alu (
        .data_operandA(pc_plus_1),
        .data_operandB(sign_extended),
        .ctrl_ALUopcode(5'b00000),      // Add == 00000
        .ctrl_shiftamt(5'b00000),
        .data_result(branch_target),
        .isNotEqual(),
        .isLessThan(),
        .overflow()
    );

    // ***************** Branch Mux *****************     
    wire [11:0] branch_address;
    mux_2_1 branch_mux (
        .out(branch_address),
        .a(pc_plus_1),
        .b(branch_target[11:0]),
        .s(branch_src)
    );


    // ++++++++++++++++++++++++++ Calculate Jump ++++++++++++++++++++++++++
    /* ---------------------------------------------------------------------
        bex — if ($rstatus != 0) PC = T
       --------------------------------------------------------------------- */
    wire r30_not_zero = | data_readRegA;
    assign jump_src = j_type | jal_type | jr_type | (bex_type & r30_not_zero);
    
    wire [11:0] final_jump_target;
    assign final_jump_target = jr_type ? data_readRegA[11:0] : target[11:0];        // PC = $rd

    // ***************** Jump Mux *****************     
    mux_2_1 jump_mux (
        .out(pc_next),
        .a(branch_address),
        .b(final_jump_target),
        .s(jump_src)
    );
    /* ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ End of EX ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ */


    /* ——————————————————————————————————— MEM stage ——————————————————————————————————— */
    // Instatiated at the TOP
    assign address_dmem = alu_result[11:0];
    assign data = data_readRegB;
    assign wren = mem_write;
    /* ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ End of MEM ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ */


    /* ——————————————————————————————————— WB stage ——————————————————————————————————— */
    /* ---------------------------------------------------------------------
        ●	$r30 is the status register, also called $rstatus
            ○	It may be set and overwritten like a normal register; however, as indicated in the ISA, 
                it can also be set when certain exceptions occur
            ○	Exceptions take precedent when writing to $r30. 
                This means that any values written to $r30 
                due to an exception will override values from regular instructions, 
                ensuring that the status register reflects 
                the system's critical states first and foremost.
       --------------------------------------------------------------------- */

    // ***************** Write-Back Data MUX *****************
    wire [31:0] mem_to_reg_data;
    mux_2_1 mem_to_reg_mux (
        .out(mem_to_reg_data),        
        .a(alu_result),               // Input A: ALU computation result
        .b(q_dmem),                   // Input B: data from data memory (for lw)
        .s(mem_to_reg)                // Select: 0=ALU result, 1=memory data
    );


    /* 
        Output Register 
        - Overflow case: write to register 30 (rstatus register for exception handling)
        - Normal case: write to destination register (rd)
        NOTE: Exceptions take precedent when writing to $r30.
    */
    wire [4:0] final_write_reg;
    assign final_write_reg = jal_type ? 5'd31 : 
                             (overflow_write_rstatus | setx_type) ? 5'd30 : 
                             rd;


    /*
        Write Permission
        - Normal instruction wants to write (reg_write == 1)
        OR 
        - when we have an overflow and need to write status to r30
    */
    wire final_write_enable;
    assign final_write_enable = reg_write | overflow_write_rstatus | jal_type | setx_type;


    /*  DO NOT FORGET THIS PART!
        Check if we're trying to write to register 0
        ●	$r0 should ALWAYS be zero
            ○	Protip: make sure your bypass logic handles this
        NOTE: NOR of all bits should be 1 since all bits are 0
    */
    wire final_is_reg0;
    assign final_is_reg0 = ~ ( | final_write_reg );


    // Only enable write if we want to write AND it's not register 0
    assign ctrl_writeEnable = final_write_enable & ~final_is_reg0;
    

    // Tell the register file which register to write to
    assign ctrl_writeReg = final_write_reg;
    

    // Choose the final data to write
    assign data_writeReg = setx_type ? {5'b0, target} : 
                           jal_type ? {20'b0, pc_plus_1} : 
                           overflow_write_rstatus ? rstatus : 
                           mem_to_reg_data;

    /* ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ End of WB ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ */

endmodule