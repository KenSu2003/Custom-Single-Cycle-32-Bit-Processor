/*

https://vlsigyan.com/barrel-shifter-verilog-code/    
    Check ./designs/right-shift

    0 is on the top.

    The right shift is basically the vertical-mirror of the left_shift.

    Just negate the shiftamt.

*/


module right_shift_arithmetic (out, data, shiftamt);

    // Inputs
    input [31:0] data;
    input [4:0] shiftamt;

    // Outputs
    output [31:0] out;

    // Wires for the different stages
    wire [31:0] stage0, stage1, stage2, stage3, stage4;

    localparam N = 32;

    /*
        Look carefully at the 0 inputs. Determine shifts by 2^stage

        NOTE:
                MUX (out, top, bottom, select_bit)
                Make sure you place the correct value for the top and bottom mux inputs
    */

    genvar i;

    // —————————————————— Stage 0: Shift by 16 bit ——————————————————
    generate
        for (i = 0; i < N; i = i + 1) begin : stage0_gen
                if (i >= N-16) begin
                    mux_2_1 mux_stage0_i (stage0[i], data[i], data[31], shiftamt[4]);
                end 
                
                else begin
                    mux_2_1 mux_stage0_i (stage0[i], data[i], data[i+16], shiftamt[4]);
                end
        end
    endgenerate

    // —————————————————— Stage 1: Shift by 8 bit ——————————————————
    generate
        for (i = 0; i < N; i = i + 1) begin : stage1_gen
                if (i >= N-8) begin
                    mux_2_1 mux_stage1_i (stage1[i], stage0[i], data[31], shiftamt[3]);
                end 
                
                else begin
                    mux_2_1 mux_stage1_i (stage1[i], stage0[i], stage0[i+8], shiftamt[3]);
                end
        end
    endgenerate

    // —————————————————— Stage 2: Shift by 4 bit ——————————————————
    generate
        for (i = 0; i < N; i = i + 1) begin : stage2_gen
                if (i >= N-4) begin
                    mux_2_1 mux_stage2_i (stage2[i], stage1[i], data[31], shiftamt[2]);
                end 
                
                else begin
                    mux_2_1 mux_stage2_i (stage2[i], stage1[i], stage1[i+4], shiftamt[2]);
                end
        end
    endgenerate


    // —————————————————— Stage 3: Shift by 2 bit ——————————————————
    generate
        for (i = 0; i < N; i = i + 1) begin : stage3_gen
                if (i >= N-2) begin
                    mux_2_1 mux_stage3_i (stage3[i], stage2[i], data[31], shiftamt[1]);
                end 
                
                else begin
                    mux_2_1 mux_stage3_i (stage3[i], stage2[i], stage2[i+2], shiftamt[1]);
                end
        end
    endgenerate

    // —————————————————— Stage 4: Shift by 1 bit ——————————————————
    generate
        for (i = 0; i < N; i = i + 1) begin : stage4_gen
                if (i >= N-1) begin
                    mux_2_1 mux_stage3_i (out[i], stage3[i], data[31], shiftamt[0]);
                end 
                
                else begin
                    mux_2_1 mux_stage3_i (out[i], stage3[i], stage3[i+1], shiftamt[0]);
                end
        end
    endgenerate

endmodule