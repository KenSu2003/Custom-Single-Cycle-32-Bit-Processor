module or_3 (out, a, b, c);

    // Inputs 
    input a, b, c;

    // Outputs
    output out;

    // Wires
    wire n1;

    // Layer 1
    or or1 (n1, a, b);

    // Layer 2
    or or2 (out, n1, c);

endmodule