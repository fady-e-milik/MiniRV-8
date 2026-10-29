# MiniRV-8: Educational 8-bit CPU

MiniRV-8 is a custom accumulator-based 8-bit processor implemented in SystemVerilog and simulated with Icarus Verilog.

## Architecture

- 8-bit program counter and accumulator
- 256-byte program memory
- 256-byte data memory
- 8-bit instruction opcodes and immediate operands
- One instruction executed per clock edge
- Signed relative branches
- Halt state and invalid-opcode handling
- Separate instruction and data memories

## Instruction set

| Opcode | Instruction | Description |
|---|---|---|
| 0x00 | NOP | No operation |
| 0x10 | LDI | Load immediate |
| 0x20 | ADDI | Add immediate |
| 0x30 | SUBI | Subtract immediate |
| 0x40 | JMP | Unconditional relative branch |
| 0x50 | JZ | Branch if accumulator is zero |
| 0x60 | STA | Store accumulator to data memory |
| 0x70 | LDA | Load accumulator from data memory |
| 0xF0 | HLT | Halt execution |

Instructions with operands occupy two bytes. Branch offsets are signed 8-bit values relative to the address immediately after the branch instruction. Arithmetic wraps modulo 256.

## Requirements

- Icarus Verilog 12.0 or compatible
- SystemVerilog support

## Run the basic simulation

```bash
mkdir -p build
iverilog -g2012 -Wall -s tb_minirv8 -o build/minirv8.vvp rtl/minirv8.sv tb/tb_minirv8.sv
vvp build/minirv8.vvp
```

## Run extended verification

```bash
iverilog -g2012 -Wall -s tb_minirv8_extended -o build/minirv8_extended.vvp rtl/minirv8.sv tb/tb_minirv8_extended.sv
vvp build/minirv8_extended.vvp
```

## Verification coverage

The basic testbench checks:
- Instruction execution and halt behavior
- Immediate arithmetic
- Data-memory store and load
- A taken conditional relative branch

The extended testbench checks:
- A negative relative branch in a loop
- A conditional branch that is not taken
- 8-bit arithmetic wraparound
- The final accumulator, stored results, program counter, and halt state

Both testbenches passed in the initial development environment. Run the commands above to reproduce the results.

## Project structure

- `rtl/minirv8.sv` ? processor RTL
- `tb/tb_minirv8.sv` ? basic integration testbench
- `tb/tb_minirv8_extended.sv` ? extended verification
- `build/` ? generated simulation artifacts; excluded from Git

## Limitations and future work

This is a behavioral educational CPU, not a commercial processor or a RISC-V implementation. It has not yet been synthesized or validated on an FPGA. Future work can include an assembler, more ALU operations, a register file, synthesis checks, and additional automated tests.
