// 4-Bit CLA Design 
// https://www.elprocus.com/carry-look-ahead-adder/
// https://ijcrt.org/papers/IJCRTT020020.pdf

// Logic
// https://www.youtube.com/watch?v=SQKdnxysXnw

module cla_4 (s, cout, a, b, cin, overflow);

    // Inputs
    input [3:0] a, b;
    input cin;

    // Outputs
    output [3:0] s;
    output cout, overflow;

    // Wires
    wire [3:0] p, g;
    wire [9:0] n;
    wire [2:0] c;

    // Layer 0
    xor xor1 (p[0], a[0], b[0]);
    and and1 (g[0], a[0], b[0]);

    xor xor2 (p[1], a[1], b[1]);
    and and2 (g[1], a[1], b[1]);

    xor xor3 (p[2], a[2], b[2]);
    and and_3 (g[2], a[2], b[2]);

    xor xor4 (p[3], a[3], b[3]);
    and and_4 (g[3], a[3], b[3]);

    // Layer 1
    xor xor5 (s[0], cin, p[0]);
    and and5 (n[0], p[0], cin);
    
    or or1 (c[0], g[0], n[0]);

    // Layer2
    xor xor6 (s[1], c[0], p[1]);

    and and6 (n[1], p[1], g[0]);
    and_3 and7 (n[2], p[1], p[0], cin);
    
    or_3 or2 (c[1], g[1], n[1], n[2]);

    // Layer 3
    xor xor7 (s[2], c[1], p[2]);

    and and8 (n[3], p[2], g[1]);
    and_3 and9 (n[4], p[2], p[1], g[0]);
    and_4 and10 (n[5], p[2], p[1], p[0], cin);

    or_4 or3 (c[2], g[2], n[3], n[4], n[5]);

    // Layer 4
    xor xor8 (s[3], c[2], p[3]);

    and and11 (n[6], p[3], g[2]);
    and_3 and12 (n[7], p[3], p[2], g[1]);
    and_4 and13 (n[8], p[3], p[2], p[1], g[0]);
    and_5 and14 (n[9], p[3], p[2], p[1], p[0], cin);

    or_5 or4 (cout, g[3], n[6], n[7], n[8], n[9]);

    // Calculate for overflow
    xor xor9 (overflow, cout, c[2]);

endmodule