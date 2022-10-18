#if {[lsearch -glob -inline [version] v2*] != "v2018.3"} {error "+[string repeat "-" 30]\n|\n| your version of vivado is [lsearch -glob -inline [version] v2*].\n| Pleasue upgrade to v2018.3\n|\n+[string repeat "-" 30]"}
cd [file dirname [file normalize [info script]]]


set origin_dir "."
set project_name "RSA_soc"

source -notrace [file normalize "$origin_dir/../procedures.tcl"]
if {[current_project -quiet] != ""} {close_project}

rescue\
	[file normalize "$origin_dir/${project_name}/${project_name}.srcs/sources_1"]\
	[file normalize "$origin_dir/source/"]

rescue\
	[file normalize "$origin_dir/${project_name}/${project_name}.srcs/sim_1"]\
	[file normalize "$origin_dir/testbench/"]

cleanse [list\
	[file normalize "$origin_dir/NA"]\
	[file normalize "$origin_dir/${project_name}"]\
	[file normalize "$origin_dir/.Xil/"]\
	{*}[glob -nocomplain -directory [file normalize "$origin_dir/boards/"] -type d *]\
]
#	{*}[glob -nocomplain -directory [file normalize "$origin_dir/boards/"] -type f *.{bxml,xdc}]\
