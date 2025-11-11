module or_4 (out, a, b, c, d);

    input a, b, c, d;
    output out;

    wire n1, n2, n3, n4, n5;
    
    or or1 (n1, a, b);
    or or2 (n2, c, d);
    or or3 (out, n1, n2);

endmodule