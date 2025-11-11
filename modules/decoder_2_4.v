module decoder_2_4(out, data);
    
    // Inputs
    input[1:0] data;

    // Outputs
    output[3:0] out;

    // Wires
    wire n1, n2;

    // Step 1
    not not1 (n1, data[0]);
    not not2 (n2, data[1]);

    // Step 2
    and and1 (out[0],n1,n2);
    and and2 (out[1],data[0],n2);
    and and3 (out[2],data[1],n1);
    and and4 (out[3],data[0],data[1]);

endmodule