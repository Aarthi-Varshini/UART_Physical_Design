# ==========================================
# CTS Script for UART
# ==========================================

set pdk_path "/home/aarthi/RTL_GDS/caravel_user_project/dependencies/pdks/volare/sky130/versions/78b7bc32ddb4b6f14f76883c2e2dc5b5de9d1cbc/sky130A"

file mkdir runs/uart_run_1/results/cts
file mkdir runs/uart_run_1/reports/cts

set result_dir "/home/aarthi/RTL_GDS/OpenROAD/src/RTL_GDSII/UART/runs/uart_run_1/results/cts"
set report_dir "/home/aarthi/RTL_GDS/OpenROAD/src/RTL_GDSII/UART/runs/uart_run_1/reports/cts"

# Read Technology and Macro LEFs
read_lef "$pdk_path/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef"
read_lef "$pdk_path/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"

# Read Liberty Library File
read_liberty "$pdk_path/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

read_db runs/uart_run_1/results/placement/uart.placement.odb

# Read timing constraints
read_sdc constraint/uart.sdc

# Configure RC estimation
set_wire_rc -signal -layer met2
set_wire_rc -clock -layer met5

# Clock Tree Synthesis
clock_tree_synthesis \
    -buf_list {
        sky130_fd_sc_hd__clkbuf_1
        sky130_fd_sc_hd__clkbuf_2
        sky130_fd_sc_hd__clkbuf_4
        sky130_fd_sc_hd__clkbuf_8
    } \
    -root_buf sky130_fd_sc_hd__clkbuf_8

# Propagated clock
set_propagated_clock [all_clocks]

# Detailed placement
detailed_placement

# Check placement
check_placement

# Estimate parasitics
estimate_parasitics -placement

# Timing optimization
repair_timing -setup

estimate_parasitics -placement

report_design_area

# Setup timing report
report_checks -path_delay max > $report_dir/cts_setup_timing.txt

# Hold timing report
report_checks -path_delay min > $report_dir/cts_hold_timing.txt

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

# Save CTS database
write_db "$result_dir/uart.cts.odb"
write_def "$result_dir/uart.cts.def"

puts "\n========== UART CTS COMPLETED ==========\n"
