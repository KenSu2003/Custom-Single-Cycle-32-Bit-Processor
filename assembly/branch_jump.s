# branch_jump.s -- simple branch coverage (bne, blt, jal, setx, bex)

# --- BNE CHECK (Not Taken Case: $1 = $2) ---
addi $1, $0, 5
addi $2, $0, 5
bne  $1, $2, bne_taken
addi $3, $0, 99
j    next_test

bne_taken:
addi $3, $0, 7

# --- BLT CHECK (Taken Case: $4 < $3) ---
next_test:
addi $4, $0, 2
addi $6, $0, 7
blt  $4, $3, blt_pass
addi $5, $0, 0

blt_pass:
addi $5, $0, 3
j    jal_test

# --- JAL CHECK (Subroutine Call) ---
jal_test:
addi $7, $0, 10
jal  my_subroutine

after_call:
add  $9, $8, $0
j    setx_test       # Jump to setx/bex tests

# --- Subroutine Definition ---
my_subroutine:
addi $8, $7, 1
jr   $ra

# --- SETX / BEX (Taken Case) ---
setx_test:
setx 123           # $rstatus ($r30) = 123
bex  bex_taken_path  # Branch SHOULD be taken (123 != 0)
addi $10, $0, 55     # NOT TAKEN PATH. $10 should remain 0
j    bex_not_taken_test

bex_taken_path:
addi $11, $0, 77     # TAKEN PATH. $11 = 77
j    bex_not_taken_test

# --- BEX (Not Taken Case) ---
bex_not_taken_test:
setx 0             # $rstatus ($r30) = 0
bex  bex_fail_path   # Branch SHOULD NOT be taken (0 == 0)
addi $12, $0, 88     # NOT TAKEN PATH. $12 = 88
j    done

bex_fail_path:
addi $13, $0, 99     # TAKEN PATH (ERROR). $13 should remain 0
j    done

done:
nop                # Program terminates