RTL := rtl/riscv_defs.sv rtl/alu.sv rtl/register_file.sv \
       rtl/immediate_generator.sv rtl/control_unit.sv
BUILD_DIR := build

.PHONY: test clean

test:
	mkdir -p $(BUILD_DIR)
	iverilog -g2012 -s components_tb -o $(BUILD_DIR)/components.vvp \
		$(RTL) tb/components_tb.sv
	vvp $(BUILD_DIR)/components.vvp

clean:
	rm -rf $(BUILD_DIR)
