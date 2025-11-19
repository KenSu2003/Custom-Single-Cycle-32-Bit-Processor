# Filename: complete_test.s
# A comprehensive test suite for the custom single-cycle processor.
# This test verifies R-Type, I-Type, branching, jumping, and rstatus operations.

# --- Register Usage Convention for Test ---
# $1 - $5: Source/Setup registers
# $6: Memory Base Address (100)
# $10 - $11: Branch/BEX result registers
# $15 - $29: R-Type and I-Type result registers
# $30: $rstatus (used for SETX/BEX)
# $31: $ra (Return Address)

# =====================================================================
# 1. SETUP: Initialize Test Data
# =====================================================================

# Initialize source values
addi $1, $0, 10           # $1 = 10 (0xA)
addi $2, $0, 5            # $2 = 5
addi $3, $0, 255          # $3 = 255 (0xFF)
addi $4, $0, -2147483648 # $4 = 0x80000000 (Max Negative)
addi $5, $0, 2147483647 # $5 = 0x7FFFFFFF (Max Positive)
addi $6, $0, 100          # $6 = 100 (Memory Base Address)

j rtype_tests # Skip setup instructions if re-running test

# =====================================================================
# 2. R-TYPE ALU INSTRUCTIONS (OPCODE 00000)
# =====================================================================

rtype_tests:
# --- ADD Test: $16 = $1 + $2 = 15 (0x0F) ---
add $16, $1, $2
# EXPECTED: $16 = 0x0000000F

# --- SUB Test: $17 = $1 - $2 = 5 (0x05) ---
sub $17, $1, $2
# EXPECTED: $17 = 0x00000005

# --- AND Test: $18 = $1 AND $2 = 0x00000000 ---
and $18, $1, $2
# EXPECTED: $18 = 0x00000000

# --- OR Test: $19 = $1 OR $3 = 0x000000FF (255) ---
or $19, $1, $3
# EXPECTED: $19 = 0x000000FF

# --- SLL Test: $20 = $2 << 3 = 40 (0x28) ---
sll $20, $2, 3
# EXPECTED: $20 = 0x00000028

# --- SRA Test: $21 = $4 >>> 1 = 0xC0000000 (Sign-extended) ---
sra $21, $4, 1
# EXPECTED: $21 = 0xC0000000

j overflow_tests

# =====================================================================
# 3. OVERFLOW and RSTATUS (R-Type, I-Type)
# =====================================================================

overflow_tests:
# --- R-Type ADD Overflow Test: $rstatus = 1 ---
# $22 = $5 + $2 ($7FFFFFFF + 5 = 0x80000004)
add $22, $5, $2
# EXPECTED: $rstatus ($30) = 0x00000001 (Add overflow)

# --- ADDI Overflow Test: $rstatus = 2 ---
# $26 = $5 + 5 ($7FFFFFFF + 5 = 0x80000004)
addi $26, $5, 5
# EXPECTED: $rstatus ($30) = 0x00000002 (ADDI overflow)

# --- SUB Overflow Test: $rstatus = 3 ---
# $27 = $4 - $2 ($80000000 - 5 = 0x7FFFFFFB)
sub $27, $4, $2
# EXPECTED: $rstatus ($30) = 0x00000003 (Sub overflow)

# --- Clear $rstatus ---
setx 0

j itype_memory_tests

# =====================================================================
# 4. I-TYPE AND MEMORY INSTRUCTIONS (ADDI, LW, SW)
# =====================================================================

itype_memory_tests:
# --- ADDI Test: $23 = $1 + 100 = 110 (0x6E) ---
addi $23, $1, 100
# EXPECTED: $23 = 0x0000006E

# --- SW Test: Store $1 (10) at MEM[100+0] ---
# Base Address $6 = 100.
sw $1, 0($6)
# EXPECTED: MEM[100] = 0x0000000A

# --- LW Test: Load from MEM[100+0] into $24. Should be 10. ---
lw $24, 0($6)
# EXPECTED: $24 = 0x0000000A

# --- LW Test (Offset): Load from MEM[100+4] (uninitialized value) ---
lw $25, 4($6)
# EXPECTED: $25 = 0xDEADBEEF (Or initial memory value)

j branch_tests

# =====================================================================
# 5. BRANCHING INSTRUCTIONS (BNE, BLT)
# =====================================================================

branch_tests:
# --- BNE Check (Not Taken: $1 = $2) ---
addi $1, $0, 5
addi $2, $0, 5
bne $1, $2, bne_taken_path # $1 == $2, so NOT TAKEN
addi $28, $0, 100          # BNE Not Taken Path: $28 = 100
j blt_tests

bne_taken_path:
addi $28, $0, 99           # BNE Taken Path (Should be skipped)
j blt_tests

# --- BLT Check (Taken: $1 < $2) ---
blt_tests:
addi $1, $0, 2
addi $2, $0, 5
blt $1, $2, blt_taken_path # $1 < $2, so TAKEN
addi $29, $0, 100          # BLT Not Taken Path (Should be skipped)
j after_blt_taken

blt_taken_path:
addi $29, $0, 200          # BLT Taken Path: $29 = 200

after_blt_taken:
# EXPECTED: $28 = 100
# EXPECTED: $29 = 200

j jal_jr_tests

# =====================================================================
# 6. JUMP INSTRUCTIONS (J, JAL, JR)
# =====================================================================

jal_jr_tests:
addi $15, $0, 30        # Initialize $15
jal subroutine_1        # Call subroutine
addi $15, $15, 100      # $15 = 31 + 100 = 131 (Execute after JR)
j bex_tests

subroutine_1:
add $15, $15, $1        # $15 = 30 + 1 = 31
jr $31                  # Return to the instruction after JAL

# EXPECTED: $31 = PC of "addi $15, $15, 100" + 1 (The correct return address)
# EXPECTED: $15 = 131 (31 + 100)

# =====================================================================
# 7. BEX INSTRUCTION
# =====================================================================

bex_tests:
# --- BEX Check (Taken: $rstatus != 0) ---
setx 1           # Set $rstatus
bex bex_taken_path
addi $10, $0, 1000        # Not Taken Path (Should be skipped)
j skip_bex_fail

bex_taken_path:
addi $10, $0, 2000        # Taken Path: $10 = 2000

skip_bex_fail:
# EXPECTED: $10 = 2000

# --- BEX Check (Not Taken: $rstatus == 0) ---
setx 0                    # Clear $rstatus
bex bex_taken_path_2
addi $11, $0, 3000        # Not Taken: $11 = 3000
j final_check

bex_taken_path_2:
addi $11, $0, 4000        # Taken Path (Should be skipped)

# EXPECTED: $11 = 3000

# =====================================================================
# 8. FINAL CHECK & END
# =====================================================================

final_check:
# Attempt to write to $0 (should fail, $0 should remain 0)
addi $0, $1, 1000

# Clear $rstatus for final check
setx 0
# EXPECTED: $30 = 0x00000000

done:
nop