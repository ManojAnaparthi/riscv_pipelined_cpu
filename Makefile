RTL := rtl/riscv_defs.sv rtl/alu.sv rtl/register_file.sv \
       rtl/immediate_generator.sv rtl/control_unit.sv \
       rtl/instruction_memory.sv rtl/data_memory.sv \
       rtl/single_cycle_cpu.sv rtl/pipeline_if_id.sv \
       rtl/pipeline_id_ex.sv rtl/pipeline_ex_mem.sv \
       rtl/pipeline_mem_wb.sv rtl/forwarding_unit.sv \
       rtl/hazard_unit.sv rtl/pipelined_cpu.sv rtl/cpu_assertions.sv
BUILD_DIR := build

.PHONY: test test-components test-single-cycle test-pipeline clean

test: test-components test-single-cycle test-pipeline

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

test-pipeline:
	mkdir -p $(BUILD_DIR)
	iverilog -g2012 -s pipelined_cpu_tb -o $(BUILD_DIR)/pipelined_cpu.vvp \
		$(RTL) tb/pipelined_cpu_tb.sv
	vvp $(BUILD_DIR)/pipelined_cpu.vvp

clean:
	rm -rf $(BUILD_DIR)
