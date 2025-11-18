# branch_jump.s -- simple branch coverage (bne, blt, and jal)

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
j    done

# --- Subroutine Definition ---
my_subroutine:
addi $8, $7, 1
jr   $ra

done:
nop