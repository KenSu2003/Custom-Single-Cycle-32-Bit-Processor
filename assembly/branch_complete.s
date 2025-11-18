# branch_complete.s -- simple branch coverage (bne and blt, taken/not-taken)

# BNE : True
addi $1, $0, 1       # $1 = 1
addi $2, $0, 2       # $2 = 2
addi $4, $0, 99       # $4 = 99 (should later be changed to 4)
bne  $1, $2, bne_true
addi $3, $0, 99      # SKIPPED

bne_true:
addi $4, $0, 4       # $4 = 4

nop

# BLT : True
addi $5, $0, -1      # $5 = -1 (0xFFFFFFFF)
addi $7, $0, 99       # $7 = 99 (should later be changed to 7)
blt  $5, $1, blt_true
addi $6, $0, -1     # Skipped

blt_true:
addi $7, $0, 7       # $7 = 7

nop

# BNE : False
addi $8, $0, 1          # $8 = 1
addi $9, $0, 1          # $9 = 1
addi $10, $0, 99         # $10 = 99 (should later be changed to 1)
bne  $8, $9, bne_false
addi $10, $0, 1         # $10 = 1

bne_false:
nop

nop

# BLT : False
addi $11, $0, 2       # $1 = 2
addi $12, $0, 1       # $2 = 1
addi $13, $0, 99       # $13 = 99 (should later be changed to 1)
blt  $11, $12, blt_false
addi $13, $0, 1       # $13 = 1

blt_false:
nop

nop