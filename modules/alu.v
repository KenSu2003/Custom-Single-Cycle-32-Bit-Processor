module alu(data_operandA, data_operandB, ctrl_ALUopcode, ctrl_shiftamt, data_result, isNotEqual, isLessThan, overflow);

   input [31:0] data_operandA, data_operandB;
   input [4:0] ctrl_ALUopcode, ctrl_shiftamt;

   output [31:0] data_result;
   output isNotEqual, isLessThan, overflow;

   // —————————————————— YOUR CODE HERE —————————————————— //


   // —————————————————— ALU —————————————————— //
   // IMPORTANT: Both data_operandA and data_operandB are signed

   // Wire
   wire [31:0] not_b;          // value of b when subtracting
   wire [31:0] mux_out;        // The ±value
   wire [31:0] add_sub_out;   // The arithmetic output

   // Carry wires
   wire cout0, cout1, cout2, cout3, cout4, cout5, cout6, cout7;
   
   // Overflow wires for CLAs
   wire overflow0, overflow1, overflow2, overflow3, overflow4, overflow5, overflow6, overflow7;

   /* Step 1 – Determine Operation
      Use a multiplexer to check for add or subtract.
      If subtract then just apply 2's complement.
      Start by applying 1's complement on b,
      the addional +1 will come from the cin value.
      This cin value will be the OP code (0 for add, 1 for sub).
         - Add (ALO_OP_Code = 0000 => cin = 0)
         - Subtract (ALO_OP_Code = 0001 => cin = 1) , the 1 is the +1 in the 2's complement.
   */ 
   not not1 [31:0] (not_b, data_operandB);
   mux_2_1 mux1 (mux_out, data_operandB, not_b, ctrl_ALUopcode[0]);

   // Step 2 – Add or Subtract
   cla_4 cla0 (add_sub_out[3:0], cout0, data_operandA[3:0], mux_out[3:0], ctrl_ALUopcode[0], overflow0);
   cla_4 cla1 (add_sub_out[7:4], cout1, data_operandA[7:4], mux_out[7:4], cout0, overflow1);
   cla_4 cla2 (add_sub_out[11:8], cout2, data_operandA[11:8], mux_out[11:8], cout1, overflow2);
   cla_4 cla3 (add_sub_out[15:12], cout3, data_operandA[15:12], mux_out[15:12], cout2, overflow3);
   cla_4 cla4 (add_sub_out[19:16], cout4, data_operandA[19:16], mux_out[19:16], cout3, overflow4);
   cla_4 cla5 (add_sub_out[23:20], cout5, data_operandA[23:20], mux_out[23:20], cout4, overflow5);
   cla_4 cla6 (add_sub_out[27:24], cout6, data_operandA[27:24], mux_out[27:24], cout5, overflow6);
   cla_4 cla7 (add_sub_out[31:28], cout7, data_operandA[31:28], mux_out[31:28], cout6, overflow);

   // —————————————————— AND —————————————————— //
   wire [31:0] and_out;
   and_32 and_mod (and_out, data_operandA, data_operandB);

   // —————————————————— OR —————————————————— //
   wire [31:0] or_out;
   or_32 or_mod (or_out, data_operandA, data_operandB);

   // —————————————————— Left Shift —————————————————— //
   wire [31:0] sll_out;
   left_shift sll0 (sll_out, data_operandA, ctrl_shiftamt);

   // —————————————————— Arithmetic Right Shift —————————————————— //
   wire [31:0] sra_out;
   right_shift_arithmetic sra0 (sra_out, data_operandA, ctrl_shiftamt);
   
   // —————————————————— ALU OP Selector ——————————————————
   // Use a MUX to decide which result to use 
   mux_6_1 mux_6_1_s (data_result, add_sub_out, add_sub_out, and_out, or_out, sll_out, sra_out, ctrl_ALUopcode);

   
   // —————————————————— Less Than ——————————————————
   /* 
      A < B is true when either:
         1. A is negative and B is positive  (xor msb)
         2. A - B is negative (there can underflow if B is a positive number)
   */

   wire neg_pos, pos_overflow, neg_no_overflow;
   and and_neg_pos (neg_pos, data_operandA[31], ~data_operandB[31]);
   and and_pos_overflow (pos_overflow, add_sub_out[31], overflow);        // 0xxx...xxxxx , should have overflow
   and and_neg_no_overflow (neg_no_overflow, add_sub_out[31], ~overflow); // 1xxx...xxxxx , should have no overflow
   or or_less_than (isLessThan, neg_pos, pos_overflow, neg_no_overflow);

   // —————————————————— Not Equal ——————————————————
   // XOR each bit and then or all of them. 
   // You can also do subtraction

   wire [31:0] ne_bits;
   
   genvar i;
   generate
      for (i = 0; i < 32; i = i + 1) begin : xor_ne_gen
         xor xor_ne_bit_i (ne_bits[i], data_operandA[i], data_operandB[i]);
      end
   endgenerate

   // OR wires to store stages (think of a pyramid scheme lolllllllll)
   wire [15:0] or_ne_stage1;
   wire [7:0] or_ne_stage2;
   wire [3:0] or_ne_stage3;
   wire [1:0] or_ne_stage4;

   // Stage 1
   generate
      for (i = 0; i < 16; i = i + 1) begin : or_ne_stage1_gen
         or or1 (or_ne_stage1[i], ne_bits[i*2], ne_bits[i*2+1]);
      end
   endgenerate

   // Stage 2
   generate
      for (i = 0; i < 8; i = i + 1) begin : or_ne_stage2_gen
         or or2 (or_ne_stage2[i], or_ne_stage1[i*2], or_ne_stage1[i*2+1]);
      end
   endgenerate

   // Stage 3
   generate
      for (i = 0; i < 4; i = i + 1) begin : or_ne_stage3_gen
         or or3 (or_ne_stage3[i], or_ne_stage2[i*2], or_ne_stage2[i*2+1]);
      end
   endgenerate

   // Stage 4
   generate
      for (i = 0; i < 2; i = i + 1) begin : or_ne_stage4_gen
         or or4 (or_ne_stage4[i], or_ne_stage3[i*2], or_ne_stage3[i*2+1]);
      end
   endgenerate

   // Final Stage
   or or_ne (isNotEqual, or_ne_stage4[0], or_ne_stage4[1]);
   
endmodule