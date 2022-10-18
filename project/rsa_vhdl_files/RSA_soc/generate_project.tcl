cd [file dirname [file normalize [info script]]]
set origin_dir "."

# Set the project name
set _xil_proj_name_ "RSA_soc"

#top level design module
set top_design "${_xil_proj_name_}_wrapper"

#top leves simulation module
set top_design_testbench "${top_design}"

#directory for user IPs
set IP_directory [file normalize "${origin_dir}/../RSA_accelerator/IP"]

#include useful procedures
source -notrace [file normalize "${origin_dir}/../procedures.tcl"]


#source for to be included in synthesis
set source_files [list \
  {*}[glob -nocomplain -directory [file normalize "$origin_dir/source/"] -type f *] \
  {*}[glob -nocomplain -directory [file normalize "$origin_dir/boards/"] -type f *] \
]

#source file to be only included in simulation
set sim_files [list \
	{*}[glob -nocomplain -directory [file normalize "$origin_dir/testbench/"] -type f *]\
]

genProj $_xil_proj_name_ $top_design $top_design_testbench $source_files $sim_files $IP_directory