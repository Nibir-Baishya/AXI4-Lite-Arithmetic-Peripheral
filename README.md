# AXI4-Lite Arithmetic Peripheral

## Overview

This project implements an AXI4-Lite slave interface connected to a 16-bit signed saturating adder using Verilog HDL. The peripheral allows a processor or AXI master to write operands into memory-mapped registers and read the arithmetic result and overflow status.

The design was developed and simulated using Xilinx Vivado.

## Features

- AXI4-Lite read and write interface
- Memory-mapped operand, result, and status registers
- 16-bit signed saturating addition
- Positive and negative overflow detection
- Byte-enable support through `WSTRB`
- Behavioral simulation using a Verilog testbench

## Register Map

| Address | Register | Description |
|---|---|---|
| `0x00` | Control | General-purpose control storage |
| `0x04` | Status | Bit 0 indicates arithmetic overflow |
| `0x08` | Operand A | First signed operand |
| `0x0C` | Operand B | Second signed operand |
| `0x10` | Result | Saturated arithmetic result |

## Arithmetic Operation

The adder accepts two signed 16-bit operands, producing a result within the range -32768 to 32767.

For an out-of-range sum, the output is clamped to the nearest representable limit, and the overflow flag is asserted.

Examples:

| Operation | Expected Result | Overflow |
|---|---:|---:|
| 10000 + 10000 | 20000 | 0 |
| 25000 + 15000 | 32767 | 1 |
| -25000 + (-15000) | -32768 | 1 |



## Tools Used

- Verilog HDL
- Xilinx Vivado 2022.2
- Vivado XSim behavioral simulator

## Simulation

The testbench verifies register writes and reads, normal addition, positive saturation, and overflow status reporting.

The current simulation produced the expected results for the normal-addition and positive-overflow scenarios. Additional protocol and corner-case tests can extend the verification coverage.

## Future Improvements

- Expand AXI handshake and protocol corner-case verification.
- Add negative-overflow and invalid-address write tests.
- Perform synthesis and evaluate resource utilization.
- Extend the peripheral with additional arithmetic operations.

## Conclusion

This project demonstrates the integration of an AXI4-Lite slave interface with a signed saturating arithmetic unit, providing practical experience in RTL design, memory-mapped register access, and simulation-based verification.
