module mux_6_1 (out, a, b, c, d, e, f, s);

    /*
        Match the bits
        Operation	ALU Opcode
        ADD	        00000
        SUBTRACT	00001
        AND	        00010
        OR	        00011
        SLL	        00100
        SRA	        00101
    */

    // Inputs
    input [31:0] a, b, c, d, e, f;
    input [2:0]s;

    // Outputs
    output [31:0] out;

    // Wires
    wire [31:0] n0, n1, n2, n3, n4;
    

    // —————————————————— Level 1: Check the s[0] ——————————————————
    // Determine even or odd operation on s[0]

    mux_2_1 mux0 (n0, a, b, s[0]);     // ADD vs SUB
    mux_2_1 mux1 (n1, c, d, s[0]);     // AND vs OR 
    mux_2_1 mux2 (n2, e, f, s[0]);     // SLL vs SRA

    // —————————————————— Level 2: Check the op[1] ——————————————————
    // Determine even or odd operation on s[1]

    mux_2_1 mux3 (n3, n0, n1, s[1]);   
    mux_2_1 mux4 (n4, n2, 32'b0, s[1]);

    // —————————————————— Level 2: Check the op[2] ——————————————————
    mux_2_1 mux5 (out, n3, n4, s[2]);

    
endmodule 