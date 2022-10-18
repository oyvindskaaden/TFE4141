#if {[lsearch -glob -inline [version] v2*] != "v2018.3"} {error "+[string repeat "-" 30]\n|\n| your version of vivado is [lsearch -glob -inline [version] v2*].\n| Pleasue upgrade to v2018.3\n|\n+[string repeat "-" 30]"}
cd [file dirname [file normalize [info script]]]
set start_time [clock clicks -milliseconds]


set origin_dir "."

#load procedures
source -notrace [file normalize "$origin_dir/procedures.tcl"]

#close_project
safe_close_project





###############################################################################
#	ADD subprojects to this list
#	ordering matters, top of the list is generated first
###############################################################################

set scripts ""
set potential_folders [glob -nocomplain -type d *]
foreach folder $potential_folders {
	#puts [file tail $folder]
	if {[file exists [file normalize "$folder/generate_project.tcl"]] && [file exists [file normalize "$folder/cleanup.tcl"]] && [file tail $folder] != "RSA_soc"} {
		lappend scripts [file normalize $folder]
	}
}
disp last80 [list\
	"FOUND THESE PROJECTS"\
	"generating them"\
	[string repeat "-" 80]\
	{*}$scripts\
]



set gen_IP [file normalize "$origin_dir/generate_IP.tcl"]
set gen_rsa_soc [file normalize "$origin_dir/RSA_soc/"]

puts "\n Running cleanup.tcl \n"
source -notrace [file normalize "$origin_dir/cleanup.tcl"]

foreach script $scripts {
	set Xil [file normalize "$script/.Xil/"]
	if {![file exists $Xil]} {
		puts "\ncreating directory $Xil\n"
		file mkdir $Xil
	}
	append script "/generate_project.tcl"
	puts "attempting to run:$script"
	if {[file exists $script]} {
		puts "\ngenerating \"${script}\"\n"
		catch {
			source -notrace "$script"
		} ignore
		puts $ignore
		safe_close_project
	}
}

puts $gen_IP
source -notrace $gen_IP

set script $gen_rsa_soc
set Xil [file normalize "$script/.Xil/"]
if {![file exists $Xil]} {
	puts "\ncreating directory $Xil\n"
	file mkdir $Xil
}
append script "/generate_project.tcl"
if {[file exists $script]} {
	puts "\ngenerating \"${script}\"\n"
	catch {
		source -notrace $script
	} ignore
	safe_close_project
}
cd [file dirname [file normalize [info script]]]
if {![file exists [file normalize "$origin_dir/Bitfiles"]]} {
	file mkdir [file normalize "$origin_dir/Bitfiles"]
}
if {![file exists [file normalize "$origin_dir/Reports"]]} {
	file mkdir [file normalize "$origin_dir/Reports"]
}

set done_time	"[expr ([clock clicks -milliseconds] - $start_time) / 1000 ] seconds"

disp 80 [list\
	""\
	"DONE" \
	$done_time\
	""\
]

#puts "\n\n\n+[string repeat "-" 72]+\n|[string repeat " " 72]|\n|[string repeat " " 34]DONE[string repeat " " 34]|\n|[string repeat " " 35]in ${done_time}[string repeat " " [expr 34 - [string length $done_time]]]|\n+[string repeat "-" 72]+"