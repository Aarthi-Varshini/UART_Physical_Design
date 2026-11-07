# ==========================================
# Placement Script for UART
# ==========================================

set pdk_path "/home/aarthi/RTL_GDS/caravel_user_project/dependencies/pdks/volare/sky130/versions/78b7bc32ddb4b6f14f76883c2e2dc5b5de9d1cbc/sky130A"

file mkdir runs/uart_run_1/results/placement
file mkdir runs/uart_run_1/reports/placement

set result_dir "/home/aarthi/RTL_GDS/OpenROAD/src/RTL_GDSII/UART/runs/uart_run_1/results/placement"
set report_dir "/home/aarthi/RTL_GDS/OpenROAD/src/RTL_GDSII/UART/runs/uart_run_1/reports/placement"

# Read Technology and Macro LEFs
read_lef "$pdk_path/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef"
read_lef "$pdk_path/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"

# Read Liberty Library File
read_liberty "$pdk_path/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

read_db runs/uart_run_1/results/floorplan/uart.floorplan.odb

#Read SDC Timing Constraints
read_sdc constraint/uart.sdc

# Set wire resistance and capacitance
set_wire_rc -signal -layer met2
set_wire_rc -clock -layer met5

# Global placement
global_placement -density 0.55

# Placement optimization
estimate_parasitics -placement
repair_design

# Detailed placement
detailed_placement

# Placement verification
check_placement

# Estimate parasitics
estimate_parasitics -placement

report_design_area

# Timing reports
report_checks -path_delay max > $report_dir/placement_setup_timing.txt
report_checks -path_delay min > $report_dir/placement_hold_timing.txt

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

# Save placement database
write_db "$result_dir/uart.placement.odb"
write_def "$result_dir/uart.placement.def"

puts "\n========== UART PLACEMENT COMPLETED ==========\n"

