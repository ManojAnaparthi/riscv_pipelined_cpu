RTL := rtl/riscv_defs.sv rtl/alu.sv rtl/register_file.sv \
       rtl/immediate_generator.sv rtl/control_unit.sv \
       rtl/instruction_memory.sv rtl/data_memory.sv \
       rtl/single_cycle_cpu.sv
BUILD_DIR := build

.PHONY: test test-components test-single-cycle clean

test: test-components test-single-cycle

test-components:
	mkdir -p $(BUILD_DIR)
	iverilog -g2012 -s components_tb -o $(BUILD_DIR)/components.vvp \
		rtl/riscv_defs.sv rtl/alu.sv rtl/register_file.sv \
		rtl/immediate_generator.sv rtl/control_unit.sv tb/components_tb.sv
	vvp $(BUILD_DIR)/components.vvp

test-single-cycle:
	mkdir -p $(BUILD_DIR)
	iverilog -g2012 -s single_cycle_cpu_tb -o $(BUILD_DIR)/single_cycle_cpu.vvp \
		$(RTL) tb/single_cycle_cpu_tb.sv
	vvp $(BUILD_DIR)/single_cycle_cpu.vvp

clean:
	rm -rf $(BUILD_DIR)
