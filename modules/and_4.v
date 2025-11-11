module and_4 (out, a, b, c, d);

    input a, b, c, d;
    output out;

    wire n1, n2, n3, n4, n5;
    
    and and1 (n1, a, b);
    and and2 (n2, c, d);
    and and3 (n3, n1, n1);
    and and4 (n4, n2, n2);
    and and5 (out, n3, n4);

endmodule