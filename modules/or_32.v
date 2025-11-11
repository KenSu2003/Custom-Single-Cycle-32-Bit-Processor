module or_32(out, a, b);
    
    // Inputs 
    input [31:0] a, b;

    // Outputs
    output [31:0] out;

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : or_gen
                or or_i (out[i], a[i], b[i]);
        end
    endgenerate 

endmodule
