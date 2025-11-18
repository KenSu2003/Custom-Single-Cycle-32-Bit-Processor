# jump.s – isolated testing for jump
# $1 = 0
# $2 = 1

addi $1, $0, 0
j target  # jump to target
addi $1, $0, -1     # should NOT run this

target:     
addi $2, $0, 1