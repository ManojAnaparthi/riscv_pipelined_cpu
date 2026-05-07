# Pipelined RV32I Processor

This repository contains a compact SystemVerilog implementation of the
five-stage pipelined processor described in
[riscv_pipelined_cpu_project_scope.md](./riscv_pipelined_cpu_project_scope.md).

## Core components

The project implements and tests the independent datapath components:

- `rtl/alu.sv` — `ADD`, `SUB`, `AND`, `OR`, and the zero flag
- `rtl/register_file.sv` — two asynchronous read ports, one synchronous write
  port, reset, and hard-wired `x0`
- `rtl/immediate_generator.sv` — I-, S-, and B-type immediates
- `rtl/control_unit.sv` — control decoding for `ADD`, `SUB`, `AND`, `OR`,
  `ADDI`, `LW`, `SW`, and `BEQ`
- `rtl/riscv_defs.sv` — shared opcode and ALU-control constants

The self-checking testbench is
[`tb/components_tb.sv`](./tb/components_tb.sv).

## Single-cycle CPU

The single-cycle CPU datapath is implemented in
[`rtl/single_cycle_cpu.sv`](./rtl/single_cycle_cpu.sv), using:

- [`rtl/instruction_memory.sv`](./rtl/instruction_memory.sv) — 256-word instruction memory
- [`rtl/data_memory.sv`](./rtl/data_memory.sv) — 256-word data memory
- The ALU, register file, immediate generator, and control unit

The CPU supports the complete eight-instruction project subset in one clock
cycle per instruction. The directed testbench
[`tb/single_cycle_cpu_tb.sv`](./tb/single_cycle_cpu_tb.sv) verifies arithmetic,
logical operations, load/store, a taken branch, skipped instructions, reset,
and the `x0` invariant. Run the complete test suite with:

```sh
make test
```

The standalone single-cycle test is available as:

```sh
make test-single-cycle
```

[`programs/single_cycle_cpu.hex`](./programs/single_cycle_cpu.hex) contains
the equivalent assembled test program for instruction-memory initialization.

## Five-stage pipeline

The pipelined implementation is [`rtl/pipelined_cpu.sv`](./rtl/pipelined_cpu.sv).
It separates instruction processing into IF, ID, EX, MEM, and WB using:

- [`rtl/pipeline_if_id.sv`](./rtl/pipeline_if_id.sv)
- [`rtl/pipeline_id_ex.sv`](./rtl/pipeline_id_ex.sv)
- [`rtl/pipeline_ex_mem.sv`](./rtl/pipeline_ex_mem.sv)
- [`rtl/pipeline_mem_wb.sv`](./rtl/pipeline_mem_wb.sv)

The pipeline now includes EX/MEM and MEM/WB forwarding, store-data
forwarding, and a one-cycle load-use stall with an ID/EX bubble.

The directed pipeline regression specifically exercises each hazard case:

- Back-to-back ALU dependency for EX/MEM forwarding
- Older producer dependency for MEM/WB forwarding
- Store using a recently produced register for store-data forwarding
- `LW` followed immediately by `ADD` for the load-use stall

Run the pipeline test independently with:

```sh
make test-pipeline
```

## Running the tests

Install Icarus Verilog or another SystemVerilog simulator, then run:

```sh
make test
```

The Makefile invokes Icarus with SystemVerilog-2012 support and runs the
component, single-cycle, and pipeline testbenches. A successful run prints:

```text
PASS: component tests
PASS: single-cycle CPU tests
PASS: pipelined CPU tests
```
