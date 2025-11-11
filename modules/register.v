module register_32 (out, data, en, rst, clk);
    
    // Inputs
    input [31:0] data;
    input en, rst, clk;
    
    // Outputs
    output [31:0] out;

    // Generate 32 DFFEs, each DFFE is one 1 bit
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : dffe_gen
            dffe_ref dffe_i (out[i], data[i], clk, en, rst);
        end
    endgenerate

endmodule
