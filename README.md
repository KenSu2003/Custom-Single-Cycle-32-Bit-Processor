# Checkpoint 5: Single-Cycle MIPS Processor Design

**Name:** Ken Su
**NetID:** hs452

## Design Overview
I have implemented a fully functional 32-bit single-cycle processor in Verilog. [cite_start]This design completes the datapath and control logic required to support R-Type, I-Type, and J-Type instructions, including branching, jumping, and exception handling[cite: 38]. [cite_start]The processor adheres to the custom ISA provided in the project specifications [cite: 123] [cite_start]and operates on a 50 MHz clock[cite: 79].

## Implementation Details

### Pipeline Organization
[cite_start]Although this is a single-cycle processor, I organized the `processor.v` module into five logical stages (IF, ID, EX, MEM, WB) to improve code readability and signal tracking[cite: 148, 159, 193, 228, 229].

### 1. Instruction Fetch (IF)
[cite_start]The PC increments by 1 (word-addressed memory) rather than 4[cite: 83]. [cite_start]I utilized a 12-bit Program Counter that interfaces with the instruction memory (`imem`)[cite: 154].

### 2. Instruction Decode (ID)
[cite_start]I implemented the Control Unit using primitive `and` gates to decode opcodes [cite: 172-187].
* **Register Read Logic:** To support J-Type instructions, I modified the register read logic:
    * [cite_start]For `jr`, the processor reads the `$rd` register into `data_readRegA`[cite: 191].
    * [cite_start]For `bex`, the processor explicitly forces the read address to `5'd30` ($rstatus) to check for exceptions[cite: 192].

### 3. Execution (EX) & J-Type Implementation
The Execution stage handles ALU operations and calculates Next-PC logic for control flow.
* [cite_start]**Jump Handling:** I implemented a specialized MUX logic (`jump_mux`) to handle `j`, `jal`, `jr`, and `bex` instructions[cite: 227].
* **Branch/Jump Priority:** The Next-PC logic prioritizes Jumps over Branches, and Branches over the standard PC+1 increment.
* **The `jr` Instruction:** Unlike `j` or `jal` which use immediate targets, `jr` jumps to a register value. [cite_start]I implemented a `final_jump_target` MUX that selects `data_readRegA` specifically when `jr_type` is active[cite: 227].

### 4. Memory (MEM)
[cite_start]This stage interfaces with the data memory (`dmem`), using the ALU result as the address and `data_readRegB` as the write data for store operations[cite: 228].

### 5. Write-Back (WB) & Exception Handling
The Write-Back stage selects the final data to write to the register file.
* **Overflow Exceptions:** I implemented logic to detect overflows for `add`, `addi`, and `sub`. [cite_start]These generate exception codes (1, 2, and 3 respectively)[cite: 214].
* **Status Register ($r30):** Exception events take precedence over standard instructions. [cite_start]If an overflow occurs, the write enable is forced high, and the exception code is written to `$r30`[cite: 217, 240].
* **Special Instructions:**
    * [cite_start]`setx`: Writes the immediate target (T) directly to `$r30`[cite: 244].
    * [cite_start]`jal`: Writes the return address (`pc`) to `$r31`[cite: 245].

## Implementation Note
* **IMEM Settings:** The Instruction Memory IP was generated with **UNREGISTERED** outputs ("q"). This configuration is required to ensure the instruction data is available within the single clock cycle immediately after the address stabilizes.

## Citations / References
- Project specification and ISA details referenced from "Checkpoint 5 - Full Processor.pdf"
- 4-bit CLA design referenced from Wikipedia.
- Single-cycle processor concepts referenced from ECE 550 – Lecture 8: Slide 17.