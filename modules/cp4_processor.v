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

    /* —————————————————————————— IF stage —————————————————————————— */
    wire [11:0] pc;
    wire [11:0] pc_plus_1, pc_next;
    wire pc_src;
    assign pc_src = 1'b0;

    // Calcualte pc+1 , using ALU since we can't use '+' and its what the schematic uses
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

    // Calculate and select branch target, use pc_plus_1 for now since checkpoint 4 doesn't require it
    wire [11:0] branch_target;
    assign branch_target = pc_plus_1;   // THIS NEEDS TO BE CHANGED FOR CHECKPOINT 5

    mux_2_1 pc_mux (
        .out(pc_next),
        .a(pc_plus_1),
        .b(branch_target),
        .s(pc_src)
    );

    // DFFEs to store the instructions
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

    // PC -> Read Address
    assign address_imem = pc;

    // Latch fetched instruction on processor clock for stable decode 
    /*
        THIS PART IS VERY IMPORTANT FOR TIMING AND FORWARDING THE LOADED DATA
    */
    wire [31:0] instr;
    generate
        for (i = 0; i < 32; i = i + 1) begin : instr_reg_gen
            dffe_ref instr_dffe_i (
                .q(instr[i]),
                .d(q_imem[i]),
                .clk(clock),
                .en(1'b1),
                .clr(reset)
            );
        end
    endgenerate


    /* —————————————————————————— ID stage —————————————————————————— */
    wire [4:0] opcode;
    wire [4:0] rs, rt, rd, shamt;
    wire [4:0] alu_op;
    wire [16:0] immediate;
    wire [31:0] sign_extended;

    // Universal
    assign opcode    = instr[31:27];
    
    // R-Type
    assign rd        = instr[26:22];    // destination for R-type and I-type in this ISA
    assign rs        = instr[21:17];    // source 
    assign rt        = instr[16:12];
    assign shamt     = instr[11:7];
    assign alu_op    = instr[6:2];
    // NOTE: ZEROES are just included in the sign exteded

    // I-type
    assign immediate = instr[16:0];

    // For calculating brach and the ALU in EX stage
    assign sign_extended = {{15{immediate[16]}}, immediate};

    /* -------------------------------------------------------------------------------------
        NOTE: Decoder moved here so lw_tpye and sw_type exists before use.
        These types are later used to determine what operation the ALU is going to execute.
       ------------------------------------------------------------------------------------- */

    wire mem_read, mem_to_reg, mem_write, alu_src, reg_write;
    wire r_type, addi_type, lw_type, sw_type;

    and r_type_check (r_type, ~opcode[4], ~opcode[3], ~opcode[2], ~opcode[1], ~opcode[0]);  // r_type: opcode == 00000
    and addi_check (addi_type, ~opcode[4], ~opcode[3], opcode[2], ~opcode[1], opcode[0]);   // addi: opcode == 00101
    and lw_check (lw_type, ~opcode[4], opcode[3], ~opcode[2], ~opcode[1], ~opcode[0]);      // lw: opcode == 01000
    and sw_check (sw_type, ~opcode[4], ~opcode[3], opcode[2], opcode[1], opcode[0]);        // sw: opcode == 00111

    assign reg_write = r_type | addi_type | lw_type;
    assign mem_write = sw_type;
    assign mem_read  = lw_type;
    assign alu_src = addi_type | lw_type | sw_type;
    assign mem_to_reg = lw_type;


    /* ---------------------------------------------------------------------
       IMPORTANT!
       Regfile read ports:
       ctrl_readRegA = rs
       ctrl_readRegB = rd when sw (store) else rt
       --------------------------------------------------------------------- */

    assign ctrl_readRegA = rs;
    assign ctrl_readRegB = sw_type ? rd : rt;


    /* —————————————————————————— EX stage —————————————————————————— */
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
    
    
    // R-Type , the ([xxxxx])
    wire add_func, sub_func, and_func, or_func, sll_func, sra_func;
    and add_check (add_func, ~alu_op[4], ~alu_op[3], ~alu_op[2], ~alu_op[1], ~alu_op[0]);
    and sub_check (sub_func, ~alu_op[4], ~alu_op[3], ~alu_op[2], ~alu_op[1], alu_op[0]);
    and and_check (and_func, ~alu_op[4], ~alu_op[3], ~alu_op[2], alu_op[1], ~alu_op[0]);
    and or_check  (or_func,  ~alu_op[4], ~alu_op[3], ~alu_op[2], alu_op[1], alu_op[0]);
    and sll_check (sll_func, ~alu_op[4], ~alu_op[3], alu_op[2], ~alu_op[1], ~alu_op[0]);
    and sra_check (sra_func, ~alu_op[4], ~alu_op[3], alu_op[2], ~alu_op[1], alu_op[0]);


    // Check which operation to use
    wire add_op, sub_op, and_op, or_op, sll_op, sra_op;
    wire [4:0] alu_control;
    assign add_op = (r_type & add_func) | addi_type;    // an '+' can be "add" (R-type) or "addi" (i-type)
    assign sub_op = r_type & sub_func;
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


    // MUX to calcualte soruce b for the ALU
    wire [31:0] alu_src_b;

    mux_2_1 alu_src_mux (
        .out(alu_src_b),
        .a(data_readRegB),
        .b(sign_extended),
        .s(alu_src)
    );


    // Execute the instruction
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


    /* —————————————————————————— MEM stage —————————————————————————— */
    // Instatiated at the TOP
    assign address_dmem = alu_result[11:0];
    assign data = data_readRegB;
    assign wren = mem_write;


    /* —————————————————————————— WB stage —————————————————————————— */

    /*
        ●	$r30 is the status register, also called $rstatus
            ○	It may be set and overwritten like a normal register; however, as indicated in the ISA, 
                it can also be set when certain exceptions occur
            ○	Exceptions take precedent when writing to $r30. 
                This means that any values written to $r30 
                due to an exception will override values from regular instructions, 
                ensuring that the status register reflects 
                the system's critical states first and foremost.
    */


    // Pick the data to write to register
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
    assign final_write_reg  = overflow_write_rstatus ? 5'd30 : rd;


    /*
        Write Permission
        - Normal instruction wants to write (reg_write == 1)
        OR 
        - when we have an overflow and need to write status to r30
    */
    wire final_write_enable;
    assign final_write_enable = reg_write | overflow_write_rstatus;


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
    assign data_writeReg = overflow_write_rstatus ? rstatus : mem_to_reg_data;


endmodule