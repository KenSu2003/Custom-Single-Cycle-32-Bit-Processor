/*
    The diagrams are correct but remember that it's xyz and not zyx
*/
module decoder_3_8_en(out, data, en);
    
    // Inputs
    input[2:0] data;
    input en;

    // Outputs
    output[7:0] out;

    // Wires
    wire not_x, not_y, not_z;
    wire [7:0] n;

    // NOT gates - fix bit ordering: x=MSB, y=middle, z=LSB
    not not1 (not_x, data[2]);  // data[2] is MSB (x)
    not not2 (not_y, data[1]);  // data[1] is middle (y)
    not not3 (not_z, data[0]);  // data[0] is LSB (z)

    // Calculate - correct bit ordering: x=MSB, y=middle, z=LSB
    and and1 (n[0], not_x, not_y, not_z);      // 000
    and and2 (n[1], not_x, not_y, data[0]);   // 001 (z=LSB)
    and and3 (n[2], not_x, data[1], not_z);   // 010
    and and4 (n[3], not_x, data[1], data[0]); // 011
    and and5 (n[4], data[2], not_y, not_z);   // 100 (x=MSB)
    and and6 (n[5], data[2], not_y, data[0]); // 101
    and and7 (n[6], data[2], data[1], not_z); // 110
    and and8 (n[7], data[2], data[1], data[0]); // 111

    // Enabler
    and en1 (out[0], n[0], en);
    and en2 (out[1], n[1], en);
    and en3 (out[2], n[2], en);
    and en4 (out[3], n[3], en);
    and en5 (out[4], n[4], en);
    and en6 (out[5], n[5], en);
    and en7 (out[6], n[6], en);
    and en8 (out[7], n[7], en);
    
endmodule