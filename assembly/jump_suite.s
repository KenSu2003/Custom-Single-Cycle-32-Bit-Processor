# jump_suite_no_jr.s
# Tests j, jal (without jr), and bex (uses addi $30 to set rstatus)

# PART 1: j (unconditional)
addi $1, $0, 1        # $1 = 1
j    L1               # jump to L1
addi $1, $0, 99        # $1 = 1
L1:
addi $2, $0, 2        # $2 = 2
nop

# PART 2: jal (call)
addi $3, $0, 3        # $1 = 3
jal    L1               # jump to L1
L3:
addi $5, $0, 5        # $5 = 5
nop

L2:
addi $4, $0, 4        # $4 = 4
j    L3               # jump to L1

# PART 3: bex (branch on status)
addi $30, $0, 42        # $30 = 42
bex    BEX_SKIP         # branch to BEX_SKIP
addi $6, $0, 99
BEX_SKIP:
addi $6, $0, 6        # $6 = 6

# End
nop                    # instr 18
