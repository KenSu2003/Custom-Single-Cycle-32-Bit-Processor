module and_3 (out, a, b, c);

    // Inputs 
    input a, b, c;

    // Outputs
    output out;

    // Wires
    wire n1;

    // Layer 1
    and and1 (n1, a, b);

    // Layer 2
    and and2 (out, n1, c);

endmodule