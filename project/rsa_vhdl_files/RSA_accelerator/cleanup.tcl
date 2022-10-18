cd [file dirname [file normalize [info script]]]


set origin_dir "."
set project_name [suggested_project_name]

source -notrace [file normalize "$origin_dir/../procedures.tcl"]
safe_close_project

rescue\
	[file normalize "$origin_dir/${project_name}/${project_name}.srcs/sources_1"]\
	[file normalize "$origin_dir/source/"]

rescue\
	[file normalize "$origin_dir/${project_name}/${project_name}.srcs/sim_1"]\
	[file normalize "$origin_dir/testbench/"]

cleanse [list\
	[file normalize "$origin_dir/IP"]\
	[file normalize "$origin_dir/${project_name}"]\
	[file normalize "$origin_dir/.Xil/"]\
]
