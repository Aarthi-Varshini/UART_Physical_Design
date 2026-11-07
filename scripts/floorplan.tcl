# ==========================================
# Floorplan Script for UART
# ==========================================

set pdk_path "/home/aarthi/RTL_GDS/caravel_user_project/dependencies/pdks/volare/sky130/versions/78b7bc32ddb4b6f14f76883c2e2dc5b5de9d1cbc/sky130A"

file mkdir runs/uart_run_1/results/floorplan
file mkdir runs/uart_run_1/reports/floorplan

set result_dir "/home/aarthi/RTL_GDS/OpenROAD/src/RTL_GDSII/UART/runs/uart_run_1/results/floorplan"
set report_dir "/home/aarthi/RTL_GDS/OpenROAD/src/RTL_GDSII/UART/runs/uart_run_1/reports/floorplan"

# Read Technology and Macro LEFs
read_lef "$pdk_path/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef"
read_lef "$pdk_path/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"

# Read Liberty Library File
read_liberty "$pdk_path/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

# Read Synthesized Netlist & Link Design
read_verilog runs/uart_run_1/results/synthesis/uart.synthesis.v
link_design uart

# Read SDC Timing Constraints
read_sdc constraint/uart.sdc

# Initialize Floorplan (40% utilization, 1.0 aspect ratio)
initialize_floorplan -utilization 40 -aspect_ratio 1.0 -core_space 2 -site unithd

# Generate Routing Tracks & Place Pins
make_tracks
place_pins -hor_layers met3 -ver_layers met2

# Timing estimation
set_wire_rc -signal -layer met2
set_wire_rc -clock -layer met5

estimate_parasitics -placement

# Generate timing reports
report_checks -path_delay max > $report_dir/floorplan_setup_timing.txt
report_checks -path_delay min > $report_dir/floorplan_hold_timing.txt

# SETUP TIMING SUMMARY
puts "PD_SETUP_WNS"
report_worst_slack -max -digits 4
puts "PD_SETUP_TNS"
report_tns -max -digits 4

# HOLD TIMING SUMMARY
puts "PD_HOLD_WHS"
report_worst_slack -min -digits 4
puts "PD_HOLD_TNS"
report_tns -min -digits 4

report_design_area

write_db "$result_dir/uart.floorplan.odb"
write_def "$result_dir/uart.floorplan.def"

puts "\n========== UART FLOORPLANNING COMPLETED ==========\n"
