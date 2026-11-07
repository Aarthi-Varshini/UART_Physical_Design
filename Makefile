# ==========================================
# Makefile for UART OpenROAD Flow
# ==========================================

DESIGN = uart
RUN_DIR = runs/uart_run_1

# Sky130nm PDK installation
PDK_PATH ?= /home/aarthi/RTL_GDS/caravel_user_project/dependencies/pdks/volare/sky130/versions/78b7bc32ddb4b6f14f76883c2e2dc5b5de9d1cbc/sky130A
export PDK_PATH

# Standard cell and technology library paths
LIB_FILE  = $(PDK_PATH)/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
LEF_FILE  = $(PDK_PATH)/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef
TLEF_FILE = $(PDK_PATH)/libs.tech/lef/sky130A.tlef

export LIB_FILE
export LEF_FILE
export TLEF_FILE

# KLayout configuration
KLAYOUT = /usr/bin/klayout
DEF2STREAM = /home/aarthi/RTL_GDS/OpenROAD/src/RTL_GDSII/def2stream.py
KLAYOUT_TECH = /home/aarthi/RTL_GDS/OpenROAD/src/RTL_GDSII/klayout.lyt
GDS_LAYER_MAP = $(PDK_PATH)/libs.tech/klayout/tech/sky130A.map

# Sky130 standard-cell GDS files
GDS_FILES = $(PDK_PATH)/libs.ref/sky130_fd_sc_hd/gds/sky130_fd_sc_hd.gds

# Final GDS output
GDS_FINAL_FILE = /home/aarthi/RTL_GDS/OpenROAD/src/RTL_GDSII/UART/runs/uart_run_1/results/route/uart.gds

.PHONY: all directories synth floorplan place cts route gds report clean

# Default target runs the entire end-to-end flow
all: directories synth floorplan place cts route gds report
	@echo "=========================================="
	@echo " Full RTL-to-GDS Flow Completed Successfully!"
	@echo " Output GDS: $(RUN_DIR)/results/$(DESIGN).gds"
	@echo " Physical Design Report: $(RUN_DIR)/reports/python_analysis/physical_design_summary.csv"
	@echo " Timing Report: $(RUN_DIR)/reports/python_analysis/timing_summary.csv"
	@echo "=========================================="

# Directories creation
directories:
	mkdir -p $(RUN_DIR)/logs $(RUN_DIR)/results/synthesis  $(RUN_DIR)/results/floorplan  $(RUN_DIR)/results/placement  $(RUN_DIR)/results/cts  $(RUN_DIR)/results/route $(RUN_DIR)/reports/synthesis $(RUN_DIR)/reports/floorplan $(RUN_DIR)/reports/placement $(RUN_DIR)/reports/cts $(RUN_DIR)/reports/route

# Step 1: Synthesis with Yosys
synth: directories
	@echo "[1/7] Running Logic Synthesis (Yosys)..."
	yosys -p "read_liberty -ignore_miss_func $(LIB_FILE); \
	          read_verilog src/baudrategenerator.v src/transmitter.v src/receiver.v src/top.v; \
	          synth -top $(DESIGN); \
		  synth -top $(DESIGN); \
                  dfflibmap -liberty $(LIB_FILE); \
	          abc -liberty $(LIB_FILE); \
		  clean; \
		  write_verilog -noattr -noexpr $(RUN_DIR)/results/synthesis/$(DESIGN).synthesis.v; \
	          tee -o $(RUN_DIR)/reports/synthesis/synth_stat.txt stat -liberty $(LIB_FILE)" > $(RUN_DIR)/logs/synthesis.log 2>&1
	@echo "[1/7] Running Post-Synthesis Timing Analysis (OpenROAD)..."
	openroad -exit scripts/synthesis.tcl > $(RUN_DIR)/logs/synthesis.log 2>&1

# Step 2: Floorplan with OpenROAD
floorplan: synth
	@echo "[2/7] Running Floorplan (OpenROAD)..."
	openroad -exit scripts/floorplan.tcl > $(RUN_DIR)/logs/floorplan.log 2>&1

# Step 3: Placement with OpenROAD
place: floorplan
	@echo "[3/7] Running Placement (OpenROAD)..."
	openroad -exit scripts/placement.tcl > $(RUN_DIR)/logs/placement.log 2>&1

# Step 4: Clock Tree Synthesis (CTS) with OpenROAD
cts: place
	@echo "[4/7] Running Clock Tree Synthesis (OpenROAD)..."
	openroad -exit scripts/cts.tcl > $(RUN_DIR)/logs/cts.log 2>&1

# Step 5: Routing with OpenROAD (TritonRoute)
route: cts
	@echo "[5/7] Running Routing (OpenROAD)..."
	openroad -exit scripts/route.tcl > $(RUN_DIR)/logs/route.log 2>&1

# Step 6: Generating GDS using KLayout 
#.PHONY: gds
gds : route
	@echo "[6/7] Generating GDS using KLayout..."
	$(KLAYOUT) -zz \
		-rd design_name=uart \
		-rd in_def=/home/aarthi/RTL_GDS/OpenROAD/src/RTL_GDSII/UART/runs/uart_run_1/results/route/uart.routed.def \
		-rd in_files="$(GDS_FILES)" \
		-rd seal_file="" \
		-rd out_file=$(GDS_FINAL_FILE) \
		-rd tech_file=$(KLAYOUT_TECH) \
		-rd layer_map=$(GDS_LAYER_MAP) \
		-r $(DEF2STREAM)
	@echo "GDS generation completed: $(GDS_FINAL_FILE)"

# Step 7: Generate Physical Design and Timing Reports
report: route
	@echo "[7/7] Generating Physical Design and Timing Reports..."
	python3 python_script/physical_design_automation_script.py
	@echo "=========================================="
	@echo " Physical Design Reports Generated Successfully!"
	@echo "=========================================="

# Clean up generated runs folder
clean:
	rm -rf runs/ reports/
