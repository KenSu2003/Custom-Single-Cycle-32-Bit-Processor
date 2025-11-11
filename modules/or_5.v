module or_5 (out, a, b, c, d, e);

    // Inputs 
    input a, b, c, d, e;
    output out;

    wire n1, n2, n3, n4, n5;
    
    or or1 (n1, a, b);    // a & b
    or or2 (n2, c, d);    // c & d
    or or3 (n3, n1, n2);  // a & b & c & d  
    or or4 (out, n3, e);  // a & b & c & d & e

endmodule