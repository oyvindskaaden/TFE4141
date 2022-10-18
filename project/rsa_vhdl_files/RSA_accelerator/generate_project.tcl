cd [file dirname [file normalize [info script]]]
set origin_dir "."

# Set the project name
set _xil_proj_name_ "RSA_accelerator"

#top level design module
set top_design $_xil_proj_name_

#top leves simulation module
set top_design_testbench "${top_design}_tb"

#directory for user IPs
set IP_directory ""

#include useful procedures
source -notrace [file normalize "${origin_dir}/../procedures.tcl"]

#source for to be included in synthesis
set source_files [list \
	{*}[glob -nocomplain -directory [file normalize "$origin_dir/source/"] -type f *] \
	{*}[include_from_file $origin_dir [file normalize "$origin_dir/include.txt"]] \
]



disp auto $source_files

#source file to be only included in simulation
set sim_files [list \
	{*}[glob -nocomplain -directory [file normalize "$origin_dir/testbench/"] -type f *]\
	{*}[findFiles [file normalize "$origin_dir/testbench/"] *.txt]\
]

genProj $_xil_proj_name_ $top_design $top_design_testbench $source_files $sim_files $IP_directory