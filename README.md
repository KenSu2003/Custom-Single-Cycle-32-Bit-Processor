# Custom Single-Cycle 32-Bit MIPS Processor

A fully functional 32-bit single-cycle processor implemented in Verilog. The design supports R-type, I-type, and J-type instructions including branching, jumping, and exception handling, and operates on a 50 MHz clock.

---

## Design Overview

The processor implements the datapath and control logic for a custom MIPS-like ISA. The `processor.v` module is organized into five logical stages (IF, ID, EX, MEM, WB) to improve readability and signal tracking, even though execution is single-cycle.

---

## Implementation Details

### 1. Instruction Fetch (IF)

- 12-bit Program Counter interfaces with instruction memory (`imem`).
- PC increments by 1 (word-addressed memory).

### 2. Instruction Decode (ID)

- Control unit implemented with primitive `and` gates to decode opcodes.
- **Register read logic:**  
  - For `jr`, the processor reads the `$rd` register into `data_readRegA`.  
  - For `bex`, the read address is forced to `5'd30` ($rstatus) for exception checks.

### 3. Execution (EX) & J-Type Implementation

- Handles ALU operations and Next-PC logic for control flow.
- **Jump handling:** Specialized MUX logic (`jump_mux`) for `j`, `jal`, `jr`, and `bex`.
- **Branch/jump priority:** Jumps override branches; branches override PC+1.
- **`jr`:** Uses a `final_jump_target` MUX that selects `data_readRegA` when `jr_type` is active.

### 4. Memory (MEM)

- Interfaces with data memory (`dmem`): ALU result as address, `data_readRegB` as write data for stores.

### 5. Write-Back (WB) & Exception Handling

- Selects the final value written to the register file.
- **Overflow exceptions:** Detected for `add`, `addi`, and `sub`; exception codes 1, 2, and 3 written to `$r30`.
- **Status register ($r30):** On overflow, write enable is forced high and the exception code is written to `$r30`.
- **Special instructions:**  
  - `setx`: Writes the immediate target (T) to `$r30`.  
  - `jal`: Writes the return address (PC) to `$r31`.

---

## Implementation Note

The Instruction Memory IP was generated with **UNREGISTERED** outputs (`q`) so that instruction data is available within the same clock cycle after the address stabilizes.

---

## References

- ISA and project specification: "Checkpoint 5 - Full Processor.pdf"
- 4-bit CLA design: Wikipedia
- Single-cycle processor concepts: ECE 550 – Lecture 8, Slide 17

---

## Related

This processor was used as the core for the system project [Pong-on-Assembly](https://github.com/KenSu2003/Pong-on-Assembly), which adds VGA, PS2 keyboard, and a Pong game in assembly.
