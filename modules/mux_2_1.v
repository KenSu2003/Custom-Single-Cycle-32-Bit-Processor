module mux_2_1(out, a, b, s);

    // Inputs
    input [31:0] a, b;
    input s;

    // Outputs
    output [31:0] out;

    // Wires
    wire n1;
    wire [31:0] n2, n3;

    // Layer 1
    not not1 (n1, s);

    // Layer 2
    and and1 [31:0] (n2, a, n1);
    and and2 [31:0] (n3, s, b);

    // Layer 3
    or or1 [31:0] (out, n2, n3);
    
endmodule 