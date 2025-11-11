// write port: https://www.cs.uni.edu/~fienup/cs041f03/lectures/Register_File.htm

module regfile (
    clock,
    ctrl_writeEnable,
    ctrl_reset, ctrl_writeReg,
    ctrl_readRegA, ctrl_readRegB, data_writeReg,
    data_readRegA, data_readRegB
);

   input clock, ctrl_writeEnable, ctrl_reset;
   input [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
   input [31:0] data_writeReg;

   output [31:0] data_readRegA, data_readRegB;

   /* YOUR CODE HERE */

// ——————————————————————— Write port ———————————————————————
genvar i, j;

// Decoder 
wire [31:0] write_en;
decoder_5_32 decoder_write_port (write_en, ctrl_writeReg);

// Generate the writeEnable ands
wire [31:0] dffe_en;
generate
    for (i = 0; i < 32; i = i + 1) begin : and_write_port_gen
        and and_write_i (dffe_en[i], write_en[i], ctrl_writeEnable);
    end
endgenerate 

// ——————————————————————— Registers ———————————————————————
// 32 registers each is 32 bits wide
wire [31:0] reg_out [31:0];

// Generate 32 registers each with 32 bits
register_32 reg_0 (reg_out[0], data_writeReg, dffe_en[0], 1, clock);    // set register_32 as 0;
generate
    for (i = 1; i < 32; i = i + 1) begin : register_gen
        register_32 reg_i (reg_out[i], data_writeReg, dffe_en[i], ctrl_reset, clock);
    end
endgenerate

// ——————————————————————— Read Port A ———————————————————————

// Decoder
wire [31:0] tristate_en_A;
decoder_5_32 decoder_read_port_A (tristate_en_A, ctrl_readRegA);

generate
    for (j = 0; j < 32; j = j + 1) begin : read_port_A_gen
        for (i = 0; i < 32; i = i + 1) begin : tristate_A_gen
            tristate_buffer tristate_A_ij (data_readRegA[j], reg_out[i][j], tristate_en_A[i]);
        end
    end
endgenerate

// ——————————————————————— Read Port B ———————————————————————

// Decoder
wire [31:0] tristate_en_B;
decoder_5_32 decoder_read_port_B (tristate_en_B, ctrl_readRegB);

generate
    for (j = 0; j < 32; j = j + 1) begin : read_port_B_gen
        for (i = 0; i < 32; i = i + 1) begin : tristate_B_gen
            tristate_buffer tristate_B_ij (data_readRegB[j], reg_out[i][j], tristate_en_B[i]);
        end
    end
endgenerate

endmodule
