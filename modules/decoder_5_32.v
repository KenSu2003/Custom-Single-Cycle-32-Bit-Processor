// https://codestall.wordpress.com/2017/09/02/532-decoder-design-using-4-38-decoders-and-1-24-decoder-in-verilog/

module decoder_5_32(out, data);

    // Inputs
    input [4:0] data;

    // Outputs
    output [31:0] out;

    // wire
    wire [3:0] en;

    // Stage 1
    decoder_2_4 decoder_2_4 (en, data[4:3]);

    // Stage 2
    decoder_3_8_en dec1 (out[7:0],data[2:0],en[0]);
    decoder_3_8_en dec2 (out[15:8],data[2:0],en[1]);
    decoder_3_8_en dec3 (out[23:16],data[2:0],en[2]);
    decoder_3_8_en dec4 (out[31:24],data[2:0],en[3]);

endmodule