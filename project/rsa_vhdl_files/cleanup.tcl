cd [file dirname [file normalize [info script]]]

set origin_dir "."
set NA_folder [file normalize "$origin_dir/NA/"]
set Xil_folder [file normalize "$origin_dir/.Xil/"]
#load procedures
source -notrace [file normalize "$origin_dir/procedures.tcl"]
safe_close_project



set actual_folders ""
set potential_folders [glob -nocomplain -type d *]
foreach folder $potential_folders {
	if {[file exists [file normalize "$folder/generate_project.tcl"]] && [file exists [file normalize "$folder/cleanup.tcl"]]} {
		lappend actual_folders [file normalize $folder]
	}
}
disp last80 [list\
	"FOUND THESE PROJECTS"\
	"cleansing them"\
	[string repeat "-" 80]\
	{*}$actual_folders\
]

#clean all project folders
foreach folder $actual_folders {
	if {[file exists "$folder/cleanup.tcl"]} {
		puts "$folder/cleanup.tcl"
		source -notrace "$folder/cleanup.tcl"
	}
}

#delete NA folder
if {[file exists $NA_folder]} {
	puts "Deleting $NA_folder"
	file delete -force -- $NA_folder
}
#delete Xil folder
if {[file exists $Xil_folder]} {
	puts "Deleting $Xil_folder"
	file delete -force -- $Xil_folder
}

#reset working directory
cd [file dirname [file normalize [info script]]]
#delete log files
puts "\n Deleting .log files\n"
set to_delete [findFiles [file normalize $origin_dir] *.log]
foreach file $to_delete {
	puts "Deleting \"$file\""
	file delete -force -- $file
}