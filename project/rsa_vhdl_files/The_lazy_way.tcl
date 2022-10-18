cd [file dirname [file normalize [info script]]]

set origin_dir "."
#load procedures
source -notrace [file normalize "$origin_dir/procedures.tcl"]
#executing the script will change the current directory
#calculate the locations before executing starts
set regen 	[file normalize "${origin_dir}/regenerate_projects.tcl"]
set synth 	[file normalize "${origin_dir}/synthesize.tcl"]
set clean 	[file normalize "${origin_dir}/cleanup.tcl"]

source -notrace $regen
source -notrace $synth
source -notrace $clean