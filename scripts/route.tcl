# ==========================================
# Routing Script for UART
# ==========================================

set pdk_path "/home/aarthi/RTL_GDS/caravel_user_project/dependencies/pdks/volare/sky130/versions/78b7bc32ddb4b6f14f76883c2e2dc5b5de9d1cbc/sky130A"

file mkdir runs/uart_run_1/results/route
file mkdir runs/uart_run_1/reports/route

set result_dir "/home/aarthi/RTL_GDS/OpenROAD/src/RTL_GDSII/UART/runs/uart_run_1/results/route"
set report_dir "/home/aarthi/RTL_GDS/OpenROAD/src/RTL_GDSII/UART/runs/uart_run_1/reports/route"

# Read Technology and Macro LEFs
read_lef "$pdk_path/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef"
read_lef "$pdk_path/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"

# Read Liberty Library File
read_liberty "$pdk_path/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

read_db runs/uart_run_1/results/cts/uart.cts.odb

# Read SDC constraints
read_sdc constraint/uart.sdc

# Configure RC estimation
set_wire_rc -signal -layer met2
set_wire_rc -clock -layer met5

# Configure routing layers
set_routing_layers \
    -signal met1-met5 \
    -clock met2-met5

# Global routing
global_route -congestion_iterations 30

# Detailed routing
detailed_route

# Estimate routed parasitics
estimate_parasitics -global_routing

# Final timing reports
report_checks -path_delay max > $report_dir/route_setup_timing.txt
report_checks -path_delay min > $report_dir/route_hold_timing.txt

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

# Save final database
write_db "$result_dir/uart.routed.odb"

# Export DEF
write_def "$result_dir/uart.routed.def"

# Export final Verilog
write_verilog "$result_dir/uart.routed.v"

puts "\n========== UART ROUTING COMPLETED ==========\n"

