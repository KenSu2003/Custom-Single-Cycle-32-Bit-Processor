# extreme_test.s
# Derived from user's extreme_test.s (base file). This version adds full J-type coverage:
# setx, bex, jal, jr, and j — combined with the original blocks that test ALU, shifts, lw/sw, overflow, branches, etc.
# Original base file: extreme_test.s. :contentReference[oaicite:1]{index=1}

nop

# Block A: Initialize registers (addresses 0..4)
addi $1,  $0,   7        # $1 = 7
addi $2,  $0,  13        # $2 = 13
addi $3,  $0,  -5        # $3 = -5 (sign-extended)
addi $5,  $0, 100        # $5 = 100  (base for memory tests)
addi $12, $0,   1        # $12 = 1   (for shifts)

# Block B: R-type arithmetic (addresses 5..8)
add  $6,  $1,  $2        # $6 = $1 + $2  => 20
sub  $7,  $2,  $1        # $7 = $2 - $1  => 6
and  $8,  $1,  $2        # $8 = 7 & 13
or   $9,  $1,  $2        # $9 = 7 | 13

# Block C: addi and sign-extension (addresses 9..10)
addi $10, $1,  -3        # $10 = 7 + (-3) => 4
addi $11, $3,   1        # $11 = -5 + 1 => -4

# Block D: shifts (addresses 11..13)
sll  $13, $12,  4        # $13 = 1 << 4 => 16
addi $14, $0, -16        # $14 = -16
sra  $15, $14,  2        # $15 = -16 >>> 2 => -4

# Block E: memory store/load round-trip (addresses 14..15)
# store $6 (which should be 20) into MEM[$5 + 3] => MEM[103]
sw   $6,  3($5)          # MEM[103] = $6 (20)
lw   $7,  3($5)          # $7 = MEM[103] => overwrites $7 with 20

# Block F: add overflow using shifts (addresses 16..18)
# Construct $20 = 1 << 30 = 0x4000_0000
addi $20, $0, 1          # $20 = 1
sll  $20, $20, 30        # $20 = 1 << 30 = 0x40000000
add  $21, $20, $20       # $21 = $20 + $20 => 0x80000000 (signed overflow)
# After this ADD, rstatus should be set to 1 in $30 (exception write)

# Block G: addi overflow (addresses 19..22)
addi $28, $0, 32767      # $28 = 32767
sll  $28, $28, 16        # $28 <<= 16 => 0x7FFF0000
addi $28, $28, 65535     # -> 0x7FFFFFFF (INT_MAX)
addi $28, $28, 1         # overflow -> $28 becomes 0x80000000 and rstatus=2 in $30

# Block H: sub overflow (addresses 23..25)
addi $29, $0, 1          # $29 = 1
sll  $29, $29, 31        # $29 = 1 << 31 = 0x80000000 (signed MIN)
sub  $23, $29, $12       # causes overflow -> rstatus = 3 in $30

# Block I: Synthetic mini-program (addresses 26..33)
addi $16, $1, 4          # $16 = $1 + 4   ; idx = 11
addi $17, $0, 999        # $17 = 999      ; value to store
sw   $17, 11($5)         # MEM[$5 + 11] = 999
lw   $18, 11($5)         # $18 = MEM[$5 + 11] => 999
add  $19, $18, $6        # $19 = $18 + $6  => 999 + 20 = 1019

# --- ADDI edge cases (covers sign-extension & bounds) ---
addi $24, $0, 65535       # $24 = 65535
addi $25, $0, -65536      # $25 = -65536

# Use addi as address calculation for lw/sw
sw   $1, 0($5)            # MEM[$5 + 0] = $1 (7)
sw   $1, -1($5)           # MEM[$5 - 1] = $1 (tests negative offset)
lw   $26, 0($5)           # $26 = MEM[$5 + 0] -> should be 7
lw   $27, -1($5)          # $27 = MEM[$5 - 1] -> should be 7

# --- LW/SW permutations (cover different rd/rs combinations) ---
sw   $3, 5($5)            # MEM[$5 + 5] = $3 (-5)
lw   $14, 5($5)           # $14 = MEM[$5 + 5] -> should be -5

addi $2, $0, 21           # $2 = 21  (ensure $2 changed)
sw   $2, 7($5)            # MEM[$5 + 7] = $2 (21)
lw   $8, 7($5)            # $8 = 21

sw   $6, 1($5)            # MEM[$5 + 1] = 20
sw   $9, 2($5)            # MEM[$5 + 2] = ($9 from earlier)
lw   $21, 1($5)           # $21 = 20
lw   $22, 2($5)           # $22 = $9

# --- Overflow extra edgecases (ensure rstatus write and override) ---
addi $31, $0, 32767       # $31 = 32767
sll  $31, $31, 16         # $31 <<=16 -> 0x7FFF0000
addi $31, $31, 65535      # $31 = 0x7FFFFFFF
addi $31, $31, 1          # overflow -> $30 should be set to 2

# --------------------
# Block J: Branch tests (BNE, BLT)
# --------------------
addi $1,  $0,  7         # $1 = 7
addi $2,  $0,  8         # $2 = 8
bne  $1,  $2, branch_bne_pass
addi $30, $0, 1          # should be skipped if BNE works
branch_bne_pass:
addi $31, $0, 2          # marker for BNE path taken

addi $3,  $0,  -2        # $3 = -2
addi $4,  $0,   3        # $4 = 3
blt  $3,  $4, branch_blt_pass
addi $29, $0, 3          # should be skipped if BLT works
branch_blt_pass:
addi $28, $0, 4          # marker for BLT path taken

# --------------------
# Block K: Jump & Status tests (NEW)
#   - Tests setx / bex (status + conditional jump)
#   - Tests jal / jr (call/return)
#   - Tests j (unconditional jump)
# --------------------

# 1) Test setx + bex: set status, then bex should jump when rstatus != 0
setx  42         # $30 (rstatus) = 0x2A (42)  [setx takes a JI immediate; assembler should accept hex or decimal]
bex   SKIP_BEX           # if rstatus != 0 then PC = SKIP_BEX
# If bex fails, this addi will execute; it should be skipped
addi  $1, $0, 99         # skipped if bex worked
SKIP_BEX:
addi  $1, $0, 11         # $1 = 11  (marker that bex jumped)

# 2) Test jal / jr: call a function that modifies registers, then jr $31 returns
#    We place the call so that the saved return address (PC + 1) is well-defined by labels.
jal CALLER_FUNC          # $31 = PC+1 ; jump to CALLER_FUNC
# After returning from jr $31, the next instruction executed should be here:
addi  $5, $0, 0          # (placeholder) ensure location after return - we'll overwrite with meaningful op later
# use an unconditional jump to skip over a stub block
j     AFTER_STUB

# Stub area that should be skipped by j above
STUB:
addi $5, $0, 99          # should be skipped by j
j     CONTINUE_SKIPPED

AFTER_STUB:
# continue normal flow after returning from CALLER_FUNC
addi $6, $0, 6           # set $6 to 6 as a marker (will overwrite earlier $6 value; this checks return flow)

# CALLER_FUNC: do some work then return using jr $31
CALLER_FUNC:
addi $2, $0, 2           # $2 = 2 (local)
addi $3, $0, -5          # $3 = -5 (re-assert)
addi $4, $0, 4           # $4 = 4
# set a marker register inside function
addi $7, $0, 77          # $7 = 77
jr   $31                 # return to saved PC in $31

CONTINUE_SKIPPED:
# 3) Test unconditional j: jump ahead to J_TARGET
j     J_TARGET
# code here should be skipped
addi  $8, $0, 99         # skipped by j

J_TARGET:
addi  $8, $0, 8          # $8 = 8  (marker that j worked)

# 4) Test setx/bex interaction with zero: setx to 0 then bex must NOT jump
setx 0                   # clear rstatus
bex  SKIP_NO_JUMP        # should NOT jump since rstatus == 0
addi $9, $0, 99          # should be executed if bex does NOT jump
SKIP_NO_JUMP:
# keep $9 set to 99 as marker
addi $9, $0, 99

# End of program: a final nop
nop
