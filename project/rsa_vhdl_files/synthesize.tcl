
set start_time [clock clicks -milliseconds]
cd [file dirname [file normalize [info script]]]

#load procedures
source -notrace [file normalize "$origin_dir/procedures.tcl"]

#close_project
safe_close_project

set origin_dir "."
source -notrace [file normalize "${origin_dir}/generate_IP.tcl"]
cd [file dirname [file normalize [info script]]]


puts [file normalize "${origin_dir}/RSA_soc/RSA_soc/RSA_soc.xpr"]
open_project [file normalize "${origin_dir}/RSA_soc/RSA_soc/RSA_soc.xpr"]
#to prevent random crash
#might be enough to reset part of the project, but have no way to determine what
reset_project	
#to force the project to acknowledge all the ips
open_bd_design [list [file normalize "${origin_dir}/RSA_soc/boards/rsa_soc.bd"]]

close_bd_design [get_bd_designs rsa_soc]
update_compile_order -fileset sources_1


report_ip_status -name ip_status
upgrade_ip -vlnv xilinx.com:user:rsa_accelerator:1.0 [get_ips  rsa_soc_rsa_acc_0] -log ip_upgrade.log
update_compile_order -fileset sources_1
#sythesizing
reset_run synth_1
launch_runs synth_1 -jobs 8
wait_on_run synth_1

set synth_status [get_property STATUS [get_runs synth_1]]
if {$synth_status != "synth_design Complete!"} {
	error [format_box auto [list \
		"Error in synth design: ${synth_status}" \
		"Please check your design" \
	]]
}

update_compile_order -fileset sources_1
#implementing/writing bitstream
reset_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

set impl_status [get_property STATUS [get_runs impl_1]]
if {$impl_status != "write_bitstream Complete!"} {
	error [format_box auto [list \
		"Error in implement design: ${impl_status}" \
		"Please check your design" \
	]]
}
update_compile_order -fileset sources_1
#writing boardfile
open_bd_design [list [file normalize "${origin_dir}/RSA_soc/boards/rsa_soc.bd"]]
write_bd_tcl -force [file normalize "${origin_dir}/Bitfiles/rsa_soc.tcl"]
close_bd_design [get_bd_designs rsa_soc]

if {![file exists [file normalize "$origin_dir/Bitfiles"]]} {
	file mkdir [file normalize "$origin_dir/Bitfiles"]
}
if {![file exists [file normalize "$origin_dir/Reports"]]} {
	file mkdir [file normalize "$origin_dir/Reports"]
}
#copy out bitfile
if [file exists [file normalize "${origin_dir}/RSA_soc/RSA_soc/RSA_soc.runs/impl_1/RSA_soc_wrapper.bit"]] {
	file copy -force \
		[file normalize "${origin_dir}/RSA_soc/RSA_soc/RSA_soc.runs/impl_1/RSA_soc_wrapper.bit"]\
		[file normalize "${origin_dir}/Bitfiles/rsa_soc.bit"]
}
#copy out hwh file
if [file exists [file normalize "${origin_dir}/RSA_soc/boards/hw_handoff/rsa_soc.hwh"]] {
	file copy -force \
		[file normalize "${origin_dir}/RSA_soc/boards/hw_handoff/rsa_soc.hwh"]\
		[file normalize "${origin_dir}/Bitfiles/rsa_soc.hwh"]
}

#copying/generating reports
#RSA accelerator utilization
set file [file normalize "${origin_dir}/RSA_soc/RSA_soc/RSA_soc.runs/rsa_soc_rsa_acc_0_synth_1/rsa_soc_rsa_acc_0_utilization_synth.rpt"]
if [file exists $file] {
	file copy -force $file [file normalize "${origin_dir}/Reports/rsa_accelerator_utilization.txt"]
}
#full design utilization
set file [file normalize "${origin_dir}/RSA_soc/RSA_soc/RSA_soc.runs/impl_1/RSA_soc_wrapper_utilization_placed.rpt"]
if [file exists $file] {
	file copy -force $file [file normalize "${origin_dir}/Reports/placed_design_utilization.txt"]
}
open_run impl_1
report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 10 -input_pins -routable_nets -name timing_1
#full design timing summary
set file [file normalize "${origin_dir}/RSA_soc/RSA_soc/RSA_soc.runs/impl_1/RSA_soc_wrapper_timing_summary_routed.rpt"]
if [file exists $file] {
	file copy -force $file [file normalize "${origin_dir}/Reports/placed_design_timing_summary.txt"]
}


safe_close_project


set done_time	"[expr ([clock clicks -milliseconds] - $start_time) / 1000 ] seconds"
disp 80 [list   \
	"DONE synth" \
	$done_time    \
]