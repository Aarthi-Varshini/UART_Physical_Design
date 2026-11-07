# ==========================================
# Post-Synthesis Timing Analysis Script for UART
# ==========================================

set pdk_path "/home/aarthi/RTL_GDS/caravel_user_project/dependencies/pdks/volare/sky130/versions/78b7bc32ddb4b6f14f76883c2e2dc5b5de9d1cbc/sky130A"

file mkdir runs/uart_run_1/reports/synthesis

set report_dir "/home/aarthi/RTL_GDS/OpenROAD/src/RTL_GDSII/UART/runs/uart_run_1/reports/synthesis"

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

# Generate Timing Reports
report_checks -path_delay max > $report_dir/synthesis_setup_timing.txt
report_checks -path_delay min > $report_dir/synthesis_hold_timing.txt

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

puts "\n========== UART POST-SYNTHESIS TIMING ANALYSIS COMPLETED ==========\n"

