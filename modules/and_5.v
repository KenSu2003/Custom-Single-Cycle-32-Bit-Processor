module and_5 (out, a, b, c, d, e);

    // Inputs 
    input a, b, c, d, e;
    output out;

    wire n1, n2, n3, n4, n5;
    
    and and1 (n1, a, b);    // a & b
    and and2 (n2, c, d);    // c & d
    and and3 (n3, n1, n2);  // a & b & c & d  
    and and4 (out, n3, e);  // a & b & c & d & e

endmodule