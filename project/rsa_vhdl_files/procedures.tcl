

#if {! [info exists _procedures_loaded_]} {
if {1} {

puts "loaded procedures"

proc format_box {options list} {
	set length 0
	set toreturn {}
	if {[string tolower $options] == "auto"} {
		foreach text $list {
			if {[string length $text]>$length} {
				set length [string length $text]
			}
		}
	}
	if {[string is integer -strict $options]} {
		set length $options
	}
	if {[string match -nocase first* $options]} {
		if {![string is integer [string range $options 5 end]]} {error "first must specify an integer"}
		set length [expr max([string range $options 5 end] , 3 )]

		append toreturn "\n+[string repeat "-" [expr $length + 8]]+"

		foreach text $list {
			if {[string length $text]>$length} {
				append toreturn "\n|[string repeat " " 4][string range $text 0 [expr $length - 4]]...[string repeat " " 4]|"
			} else {
				append toreturn "\n|[string repeat " " 4]$text[string repeat " " [expr 4 + $length - ([string length $text])]]|"
			}
		}
		append toreturn "\n+[string repeat "-" [expr $length + 8]]+"

	} elseif {[string match -nocase last* $options]} {
		if {![string is integer [string range $options 4 end]]} {error "last must specify an integer"}
		set length [expr max([string range $options 4 end] , 3 ) ]

		append toreturn "\n+[string repeat "-" [expr $length + 8]]+"

		foreach text $list {
			if {[string length $text]>$length} {
				append toreturn "\n|[string repeat " " 4]...[string range $text [expr [string length $text] - $length +3] end][string repeat " " 4]|"
			} else {
				append toreturn "\n|[string repeat " " 4]$text[string repeat " " [expr 4 + $length - ([string length $text])]]|"
			}
		}
		append toreturn "\n+[string repeat "-" [expr $length + 8]]+"

	} else {
		if {$length <=0} {
			set length 3
		}
		append toreturn "\n+[string repeat "-" [expr $length + 8]]+"
		foreach text $list {
			append toreturn "\n|[string repeat " " 4]$text[string repeat " " [expr 4 + $length - ([string length $text])]]|"
		}
		append toreturn "\n+[string repeat "-" [expr $length + 8]]+"
	}
	return $toreturn
}

#this is the main version check
#should be made better

if {[version -short] < "2019"} {
	error [format_box auto [list \
		"" \
		"your version of vivado is [lsearch -glob -inline [version] v2*]" \
		"Please upgrade to v2019.0 or newer" \
		"" \
	]]
}
if {[lsearch -glob -inline [get_board_parts] *pynq-z1*] == "" } {
	error [format_box auto [list \
		"" \
		"Please install the Board files for the PYNQ-Z1" \
		"https://github.com/cathalmccabe/pynq-z1_board_files/raw/master/pynq-z1.zip" \
		"" \
	]]
}


#################################################################
#DISPLAY apply to dips and format_box
#################################################################
if {0} {
	#automatically adjust box width
	disp auto $text
	#fixed width, but text may exceed limit
	disp 80 $text
	#fixed width, but trim string if exceeding width of box
	#display last 80 characters
	disp last80 $text
	#display first 80 characters
	disp first80 $text

	#can display lists
	disp auto [list\
		"elem1"\
		"this is elemtn number 2"\
		"etc..."\
	]

	+-------------------------------+
	|    elem1                      |
	|    this is elemtn number 2    |
	|    etc...                     |
	+-------------------------------+
}
proc disp {options list} {
	puts [format_box $options $list]
}

proc cleanse {files} {
	foreach file $files {
		catch {
			if {[file exists $file]} {
				puts "Deleting $file"
				file delete -force -- $file
			}
		} "err_msg"
		if {$err_msg != ""} {
			puts "Error deleting $file reason: ${err_msg}"
		}
	}
}

#copy files from vivado project folder to source folders
proc rescue {from to} {
	if {[file exists "$from/"]} {
		set files [list \
			{*}[glob -nocomplain -directory [file normalize "$from/new/"] -type f *] \
			{*}[glob -nocomplain -directory [file normalize "$from/imports/source/"] -type f *] \
		]
		foreach file $files {
			set targetFileName [file rootname [file tail $file]]
			set targetFileExtension [file extension $file]
			set targetFile "${to}/${targetFileName}${targetFileExtension}"
			set copyNr 0

			while {[file exists $targetFile]} {
				set targetNewFileName "${targetFileName}_copy(${copyNr})"
				set copyNr [expr $copyNr + 1]
				set targetFile "${to}/${targetNewFileName}${targetFileExtension}"
			}
			catch {
				file copy -force $file $targetFile
			} "copyerror"
			if {$copyerror != ""} {
				puts "ERROR rescuing: $file reason ${copyerror}"
			} else {
				puts "rescuing: $file as $targetFile"
			}
		}
	}
}

proc safe_close_project {} {
	if {[current_project -quiet] != ""} {close_project}
}

proc findFiles { basedir pattern } {
	set basedir [string trimright [file join [file normalize $basedir] { }]]
	set fileList {}
	foreach fileName [glob -nocomplain -type {f r} -path $basedir $pattern] {
		lappend fileList $fileName
	}

	# Now look for any sub direcories in the current directory
	foreach dirName [glob -nocomplain -type {d  r} -path $basedir *] {
		set subDirList [findFiles $dirName $pattern]
		if { [llength $subDirList] > 0 } {
			foreach subDirFile $subDirList {
				lappend fileList $subDirFile
			}
		}
	}
	return $fileList
}

proc readLines {file} {
	set a [open $file]
	set lines [string trim [split [read $a] "\n"]]
	close $a
	#disp auto "{read the following lines}"
	#disp auto $lines
	return $lines
}

proc include_from_file_rec {origin_dir file visited} {
	set list [list ]
	set notFound ""
	#disp auto $visited
	foreach includeElement [readLines $file] {
		if {$includeElement != ""} {
			#puts "[lsearch -exact $visited $includeElement] $includeElement"
			if {[file exists [file normalize "$origin_dir/../${includeElement}/source/"]] && [file isdirectory [file normalize "$origin_dir/../${includeElement}/source/"]]} {
				if {[lsearch -exact $visited $includeElement] >= 0} {
					disp auto [list\
						"WARNIGN" \
						"$includeElement was included recursively" \
						"This indicates circular dependency" \
					]
				}
				if {[file exists [file normalize "$origin_dir/../${includeElement}/include.txt"]] && [lsearch -exact $visited $includeElement] < 0} {
					set visited [list \
						{*}$visited \
						$includeElement\
					]
					set list [list \
						{*}$list\
						{*}[glob -nocomplain -directory [file normalize "$origin_dir/../${includeElement}/source/"] -type f *]\
						{*}[include_from_file_rec $origin_dir [file normalize "$origin_dir/../${includeElement}/include.txt"] $visited]
					]
				}
			} else {
				lappend notFound $includeElement
			}
		}
	}

	if {$notFound != ""} {
		disp auto [list \
			"could not include the following subprojects" \
			{*}$notFound \
		]
	}
	return [lsort -unique $list]
}

proc include_from_file {origin_dir file} {
	return [include_from_file_rec $origin_dir $file ""]
}

proc suggested_project_name {} {
	return [file tail [file dirname [file normalize [info script]]]]
}

proc instantiate_subproject {name parents} {
	cd [file dirname [file normalize [info script]]]
	pwd
	puts [file normalize "./$name/"]
	if { ! [file exists [file normalize "./$name/"]]} {
		file mkdir [file normalize "./$name/"]
		file mkdir [file normalize "./$name/source/"]
		file mkdir [file normalize "./$name/testbench/"]
		set vhdlheader "--this is an instantiated file\n"
		#include.txt
		set tempFile [open [file normalize "./$name/include.txt"] w]
		close $tempFile
		#cleanup.tcl
		#this is awful
		set tempFile [open [file normalize "./$name/cleanup.tcl"] w]
		puts -nonewline $tempFile "cd \[file dirname \[file normalize \[info script\]\]\]\n\nset origin_dir \".\"\nsource -notrace \[file normalize \"\$origin_dir/../procedures.tcl\"\]\nset _xil_proj_name_ \[suggested_project_name\]\n\nsafe_close_project\n\nrescue\\\n\t\[file normalize \"\$origin_dir/\$\{_xil_proj_name_\}/\$\{_xil_proj_name_\}.srcs/sources_1\"\]\\\n\t\[file normalize \"\$origin_dir/source/\"\]\n\nrescue\\\n\t\[file normalize \"\$origin_dir/\$\{_xil_proj_name_\}/\$\{_xil_proj_name_\}.srcs/sim_1\"\]\\\n\t\[file normalize \"\$origin_dir/testbench/\"\]\n\ncleanse \[list\\\n\t\[file normalize \"\$origin_dir/\$\{_xil_proj_name_\}\"\]\\\n\t\[file normalize \"\$origin_dir/.Xil/\"\]\\\n\t\[file normalize \"\$origin_dir/NA/\"\]\\\n\]\n"
		close $tempFile

		#generate_project.tcl
		#this is awful
		set tempFile [open [file normalize "./$name/generate_project.tcl"] w]
		puts -nonewline $tempFile "cd \[file dirname \[file normalize \[info script\]\]\]\nset origin_dir \".\"\nsource -notrace \[file normalize \"\$\{origin_dir\}/../procedures.tcl\"\]\n\nset _xil_proj_name_ \[suggested_project_name\]\n\nset top_design \$_xil_proj_name_\nset top_design_testbench \"\$\{top_design\}_tb\"\nset IP_directory \"\"\n\n\nset source_files \[list \\\n\t\{\*\}\[glob -nocomplain -directory \[file normalize \"\$origin_dir/source/\"\] -type f \*\] \\\n\t\{\*\}\[include_from_file \$origin_dir \[file normalize \"\$origin_dir/include.txt\"\]\] \\\n\]\n\nset sim_files \[list \\\n\t\{\*\}\[glob -nocomplain -directory \[file normalize \"\$origin_dir/testbench/\"\] -type f \*\]\\\n\]\n\ngenProj \$_xil_proj_name_ \$top_design \$top_design_testbench \$source_files \$sim_files \$IP_directory"
		close $tempFile


		#vhd module
		set tempFile [open [file normalize "./$name/source/$name.vhd"] w]
		puts -nonewline $tempFile "${vhdlheader}library ieee;\nuse ieee.std_logic_1164.all;\n\nentity $name is\n\tgeneric (\n\t\tsomegeneric : integer := 256\n\t);\n\tport (\n\t\t--input data\n\t\tdata_in : in std_logic;\n\t\t--output\n\t\tdata_out : out std_logic\n\t);\nend $name;\n\n\narchitecture behaviour of $name is\nbegin\n\tdata_out <= data_in;\nend behaviour;"
		close $tempFile
		#vhd testbench
		set tempFile [open [file normalize "./$name/testbench/$name.vhd"] w]
		puts -nonewline $tempFile "${vhdlheader}library ieee;\nuse ieee.std_logic_1164.all;\n\nentity ${name}_tb is\n\tgeneric (\n\t\tsomegeneric : integer := 256\n\t);\nend ${name}_tb;\n\n\narchitecture behaviour of ${name}_tb is\n\tsignal data_in : std_logic;\n\tsignal data_out : std_logic;\nbegin\n\ti_${name} : entity work.${name}\n\t\tgeneric map (\n\t\t\tsomegeneric => somegeneric\n\t\t)\n\t\tport map (\n\t\t\tdata_in  => data_in,\n\t\t\tdata_out => data_out\n\t\t);\nend behaviour;"
		close $tempFile


		foreach parent $parents {
			if {[file exists [file normalize "./$parent/include.txt"]]} {
				set tempFile [open [file normalize "./$parent/include.txt"] a]
				puts -nonewline $tempFile "\n$name"
				close $tempFile
			}
		}

	} else {
		error [format_box auto [list \
			"error instantiating project"\
			"[file normalize "./$name/"] already exists" \
		]]
	}
}

#this was mostly automatically generated by vivado
#this probably can be greatly simplified

proc genProj {_xil_proj_name_ top_design top_design_testbench source_files sim_files repo_dir} {
	set board_part [lsearch -glob -inline [get_board_parts] *pynq-z1*]
	set implementation_part "xc7z020clg400-1"
	set origin_dir "."

	variable script_file
	set script_file "genProj.tcl"


	if {$board_part == "" } {
		error "\n+[string repeat "-" 30]\n|\n|->Please install the Board files for the PYNQ-Z1\n|\n+[string repeat "-" 30]\n"
	}

	# Create project
	create_project ${_xil_proj_name_} "./${_xil_proj_name_}" -part $implementation_part

	# Set the directory path for the new project
	set proj_dir [get_property directory [current_project]]

	# Set project properties
	set obj [current_project]
	set_property -name "board_part" -value $board_part -objects $obj
	set_property -name "default_lib" -value "xil_defaultlib" -objects $obj
	set_property -name "dsa.accelerator_binary_content" -value "bitstream" -objects $obj
	set_property -name "dsa.accelerator_binary_format" -value "xclbin2" -objects $obj
	set_property -name "dsa.description" -value "Vivado generated DSA" -objects $obj
	set_property -name "dsa.dr_bd_base_address" -value "0" -objects $obj
	set_property -name "dsa.emu_dir" -value "emu" -objects $obj
	set_property -name "dsa.flash_interface_type" -value "bpix16" -objects $obj
	set_property -name "dsa.flash_offset_address" -value "0" -objects $obj
	set_property -name "dsa.flash_size" -value "1024" -objects $obj
	set_property -name "dsa.host_architecture" -value "x86_64" -objects $obj
	set_property -name "dsa.host_interface" -value "pcie" -objects $obj
	set_property -name "dsa.num_compute_units" -value "60" -objects $obj
	set_property -name "dsa.platform_state" -value "pre_synth" -objects $obj
	set_property -name "dsa.vendor" -value "xilinx" -objects $obj
	set_property -name "dsa.version" -value "0.0" -objects $obj
	set_property -name "enable_vhdl_2008" -value "1" -objects $obj
	set_property -name "ip_cache_permissions" -value "read write" -objects $obj
	set_property -name "ip_output_repo" -value "$proj_dir/${_xil_proj_name_}.cache/ip" -objects $obj
	set_property -name "mem.enable_memory_map_generation" -value "1" -objects $obj
	#set_property -name "part" -value $implementation_part -objects $obj
	set_property -name "sim.central_dir" -value "$proj_dir/${_xil_proj_name_}.ip_user_files" -objects $obj
	set_property -name "sim.ip.auto_export_scripts" -value "1" -objects $obj
	set_property -name "simulator_language" -value "VHDL" -objects $obj
	set_property -name "target_language" -value "VHDL" -objects $obj

	# Create 'sources_1' fileset (if not found)
	if {[string equal [get_filesets -quiet sources_1] ""]} {
		create_fileset -srcset sources_1
	}

	############################################################################################################################
	# Set 'sources_1' fileset object
	set obj [get_filesets sources_1]
	#if this is the rsa_soc project, add the accelerator ip repository
	if {[info exists repo_dir]} {
		if {$repo_dir != ""} {
			set_property "ip_repo_paths" $repo_dir $obj
		}
		unset repo_dir
	}
	#include all source files
	add_files -norecurse -fileset $obj $source_files

	#iterate over all the included files
	foreach file [get_files -of [get_fileset {sources_1}]] {
		# if the file is a vhdl file, the set the property to vhdl 2008
		if {[lsearch -exact {".vhd" ".vhdl"} [file extension $file]] >= 0} {
			set file [file normalize $file]
			set file_obj [get_files -of_objects [get_filesets sources_1] [list "$file"]]
			#rsa_accelerator.vhd
			if {[file tail $file]=="rsa_accelerator.vhd"} {
				set_property -name "file_type" -value "VHDL" -objects $file_obj
			} else {
				set_property -name "file_type" -value "VHDL 2008" -objects $file_obj
			}
		}
		#common properties of board files
		if {[lsearch -exact {".bd"} [file extension $file]] >= 0} {
			set file [file normalize $file]
			set file_obj [get_files -of_objects [get_filesets sources_1] [list "$file"]]
			set_property -name "registered_with_manager" -value "1" -objects $file_obj
		}
	}
	#top level vhdl module which is used in board file cannot be vhdl 2008

	# Set 'sources_1' fileset properties
	set obj [get_filesets sources_1]
	set_property -name "top" -value $top_design -objects $obj

	############################################################################################################################


	# Create 'constrs_1' fileset (if not found)
	if {[string equal [get_filesets -quiet constrs_1] ""]} {
		create_fileset -constrset constrs_1
	}

	# Set 'constrs_1' fileset object
	set obj [get_filesets constrs_1]

	# Add/Import constrs file and set constrs file properties
	set file "[file normalize "${origin_dir}/../Master_constraints/PYNQ-Z1_C.xdc"]"
	set file_added [add_files -norecurse -fileset $obj [list $file]]
	set file "${origin_dir}/../Master_constraints/PYNQ-Z1_C.xdc"
	set file [file normalize $file]
	set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
	set_property -name "file_type" -value "XDC" -objects $file_obj

	# Set 'constrs_1' fileset properties
	set obj [get_filesets constrs_1]
	set_property -name "target_part" -value $implementation_part -objects $obj

	# Create 'sim_1' fileset (if not found)
	if {[string equal [get_filesets -quiet sim_1] ""]} {
		create_fileset -simset sim_1
	}

	# Set 'sim_1' fileset object
	set obj [get_filesets sim_1]
	set_property -name "top" -value $top_design_testbench -objects $obj
	set_property -name "top_lib" -value "xil_defaultlib" -objects $obj


	add_files -norecurse -fileset $obj $sim_files

	#iterate over all the included files
	foreach file [get_files -of [get_fileset {sim_1}]] {
		# if the file is a vhdl file, the set the property to vhdl 2008
		if {[lsearch -exact {".vhd" ".vhdl"} [file extension $file]] >= 0} {
			set file [file normalize $file]
			set file_obj [get_files -of_objects [get_filesets sim_1] [list "$file"]]
			set_property -name "file_type" -value "VHDL 2008" -objects $file_obj
			set_property -name "used_in" -value "simulation" -objects $file_obj
			set_property -name "used_in_synthesis" -value "0" -objects $file_obj
		}
	}

	# Import local files from the original project
	#set imported_files [import_files -fileset sim_1 $files]

	# Set 'sim_1' fileset file properties for remote files
	# None
	set obj [get_filesets sim_1]

	# Empty (no sources present)

	# Set 'utils_1' fileset properties
	set obj [get_filesets utils_1]

	# Create 'synth_1' run (if not found)
	if {[string equal [get_runs -quiet synth_1] ""]} {
			create_run -name synth_1 -part $implementation_part -flow {Vivado Synthesis 2018} -strategy "Vivado Synthesis Defaults" -report_strategy {No Reports} -constrset constrs_1
	} else {
		set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]
		set_property flow "Vivado Synthesis 2018" [get_runs synth_1]
	}
	set obj [get_runs synth_1]
	set_property set_report_strategy_name 1 $obj
	set_property report_strategy {Vivado Synthesis Default Reports} $obj
	set_property set_report_strategy_name 0 $obj
	# Create 'synth_1_synth_report_utilization_0' report (if not found)
	if { [ string equal [get_report_configs -of_objects [get_runs synth_1] synth_1_synth_report_utilization_0] "" ] } {
		create_report_config -report_name synth_1_synth_report_utilization_0 -report_type report_utilization:1.0 -steps synth_design -runs synth_1
	}
	set obj [get_report_configs -of_objects [get_runs synth_1] synth_1_synth_report_utilization_0]
	if { $obj != "" } {
		if {[lsearch -glob -nocase [list_property $obj] display_name] > 0} {
			set_property -name "display_name" -value "synth_1_synth_report_utilization_0" -objects $obj
		}

	}
	set obj [get_runs synth_1]
	set_property -name "part" -value $implementation_part -objects $obj
	set_property -name "strategy" -value "Vivado Synthesis Defaults" -objects $obj

	# set the current synth run
	current_run -synthesis [get_runs synth_1]

	# Create 'impl_1' run (if not found)
	if {[string equal [get_runs -quiet impl_1] ""]} {
			create_run -name impl_1 -part $implementation_part -flow {Vivado Implementation 2018} -strategy "Vivado Implementation Defaults" -report_strategy {No Reports} -constrset constrs_1 -parent_run synth_1
	} else {
		set_property strategy "Vivado Implementation Defaults" [get_runs impl_1]
		set_property flow "Vivado Implementation 2018" [get_runs impl_1]
	}
	set obj [get_runs impl_1]
	set_property set_report_strategy_name 1 $obj
	set_property report_strategy {Vivado Implementation Default Reports} $obj
	set_property set_report_strategy_name 0 $obj
	# Create 'impl_1_init_report_timing_summary_0' report (if not found)
	if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_init_report_timing_summary_0] "" ] } {
		create_report_config -report_name impl_1_init_report_timing_summary_0 -report_type report_timing_summary:1.0 -steps init_design -runs impl_1
	}
	set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_init_report_timing_summary_0]
	if { $obj != "" } {
	set_property -name "is_enabled" -value "0" -objects $obj
	if {[lsearch -glob -nocase [list_property $obj] display_name] > 0} {
			set_property -name "display_name" -value "impl_1_init_report_timing_summary_0" -objects $obj
		}

	}
	# Create 'impl_1_opt_report_drc_0' report (if not found)
	if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_opt_report_drc_0] "" ] } {
		create_report_config -report_name impl_1_opt_report_drc_0 -report_type report_drc:1.0 -steps opt_design -runs impl_1
	}
	set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_opt_report_drc_0]
	if { $obj != "" } {
		if {[lsearch -glob -nocase [list_property $obj] display_name] > 0} {
			set_property -name "display_name" -value "impl_1_opt_report_drc_0" -objects $obj
		}

	}
	# Create 'impl_1_opt_report_timing_summary_0' report (if not found)
	if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_opt_report_timing_summary_0] "" ] } {
		create_report_config -report_name impl_1_opt_report_timing_summary_0 -report_type report_timing_summary:1.0 -steps opt_design -runs impl_1
	}
	set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_opt_report_timing_summary_0]
	if { $obj != "" } {
	set_property -name "is_enabled" -value "0" -objects $obj
	if {[lsearch -glob -nocase [list_property $obj] display_name] > 0} {
			set_property -name "display_name" -value "impl_1_opt_report_timing_summary_0" -objects $obj
		}

	}
	# Create 'impl_1_power_opt_report_timing_summary_0' report (if not found)
	if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_power_opt_report_timing_summary_0] "" ] } {
		create_report_config -report_name impl_1_power_opt_report_timing_summary_0 -report_type report_timing_summary:1.0 -steps power_opt_design -runs impl_1
	}
	set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_power_opt_report_timing_summary_0]
	if { $obj != "" } {
	set_property -name "is_enabled" -value "0" -objects $obj
	if {[lsearch -glob -nocase [list_property $obj] display_name] > 0} {
			set_property -name "display_name" -value "impl_1_power_opt_report_timing_summary_0" -objects $obj
		}

	}
	# Create 'impl_1_place_report_io_0' report (if not found)
	if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_io_0] "" ] } {
		create_report_config -report_name impl_1_place_report_io_0 -report_type report_io:1.0 -steps place_design -runs impl_1
	}
	set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_io_0]
	if { $obj != "" } {
		if {[lsearch -glob -nocase [list_property $obj] display_name] > 0} {
			set_property -name "display_name" -value "impl_1_place_report_io_0" -objects $obj
		}

	}
	# Create 'impl_1_place_report_utilization_0' report (if not found)
	if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_utilization_0] "" ] } {
		create_report_config -report_name impl_1_place_report_utilization_0 -report_type report_utilization:1.0 -steps place_design -runs impl_1
	}
	set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_utilization_0]
	if { $obj != "" } {
		if {[lsearch -glob -nocase [list_property $obj] display_name] > 0} {
			set_property -name "display_name" -value "impl_1_place_report_utilization_0" -objects $obj
		}

	}
	# Create 'impl_1_place_report_control_sets_0' report (if not found)
	if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_control_sets_0] "" ] } {
		create_report_config -report_name impl_1_place_report_control_sets_0 -report_type report_control_sets:1.0 -steps place_design -runs impl_1
	}
	set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_control_sets_0]
	if { $obj != "" } {
		if {[lsearch -glob -nocase [list_property $obj] display_name] > 0} {
			set_property -name "display_name" -value "impl_1_place_report_control_sets_0" -objects $obj
		}

	}
	# Create 'impl_1_place_report_incremental_reuse_0' report (if not found)
	if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_incremental_reuse_0] "" ] } {
		create_report_config -report_name impl_1_place_report_incremental_reuse_0 -report_type report_incremental_reuse:1.0 -steps place_design -runs impl_1
	}
	set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_incremental_reuse_0]
	if { $obj != "" } {
	set_property -name "is_enabled" -value "0" -objects $obj
	if {[lsearch -glob -nocase [list_property $obj] display_name] > 0} {
			set_property -name "display_name" -value "impl_1_place_report_incremental_reuse_0" -objects $obj
		}

	}
	# Create 'impl_1_place_report_incremental_reuse_1' report (if not found)
	if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_incremental_reuse_1] "" ] } {
		create_report_config -report_name impl_1_place_report_incremental_reuse_1 -report_type report_incremental_reuse:1.0 -steps place_design -runs impl_1
	}
	set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_incremental_reuse_1]
	if { $obj != "" } {
	set_property -name "is_enabled" -value "0" -objects $obj
	if {[lsearch -glob -nocase [list_property $obj] display_name] > 0} {
			set_property -name "display_name" -value "impl_1_place_report_incremental_reuse_1" -objects $obj
		}

	}
	# Create 'impl_1_place_report_timing_summary_0' report (if not found)
	if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_timing_summary_0] "" ] } {
		create_report_config -report_name impl_1_place_report_timing_summary_0 -report_type report_timing_summary:1.0 -steps place_design -runs impl_1
	}
	set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_place_report_timing_summary_0]
	if { $obj != "" } {
	set_property -name "is_enabled" -value "0" -objects $obj
	if {[lsearch -glob -nocase [list_property $obj] display_name] > 0} {
			set_property -name "display_name" -value "impl_1_place_report_timing_summary_0" -objects $obj
		}

	}
	# Create 'impl_1_post_place_power_opt_report_timing_summary_0' report (if not found)
	if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_post_place_power_opt_report_timing_summary_0] "" ] } {
		create_report_config -report_name impl_1_post_place_power_opt_report_timing_summary_0 -report_type report_timing_summary:1.0 -steps post_place_power_opt_design -runs impl_1
	}
	set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_post_place_power_opt_report_timing_summary_0]
	if { $obj != "" } {
	set_property -name "is_enabled" -value "0" -objects $obj
	if {[lsearch -glob -nocase [list_property $obj] display_name] > 0} {
			set_property -name "display_name" -value "impl_1_post_place_power_opt_report_timing_summary_0" -objects $obj
		}

	}
	# Create 'impl_1_phys_opt_report_timing_summary_0' report (if not found)
	if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_phys_opt_report_timing_summary_0] "" ] } {
		create_report_config -report_name impl_1_phys_opt_report_timing_summary_0 -report_type report_timing_summary:1.0 -steps phys_opt_design -runs impl_1
	}
	set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_phys_opt_report_timing_summary_0]
	if { $obj != "" } {
	set_property -name "is_enabled" -value "0" -objects $obj
	if {[lsearch -glob -nocase [list_property $obj] display_name] > 0} {
			set_property -name "display_name" -value "impl_1_phys_opt_report_timing_summary_0" -objects $obj
		}

	}
	# Create 'impl_1_route_report_drc_0' report (if not found)
	if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_drc_0] "" ] } {
		create_report_config -report_name impl_1_route_report_drc_0 -report_type report_drc:1.0 -steps route_design -runs impl_1
	}
	set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_drc_0]
	if { $obj != "" } {
		if {[lsearch -glob -nocase [list_property $obj] display_name] > 0} {
			set_property -name "display_name" -value "impl_1_route_report_drc_0" -objects $obj
		}

	}
	# Create 'impl_1_route_report_methodology_0' report (if not found)
	if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_methodology_0] "" ] } {
		create_report_config -report_name impl_1_route_report_methodology_0 -report_type report_methodology:1.0 -steps route_design -runs impl_1
	}
	set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_methodology_0]
	if { $obj != "" } {
		if {[lsearch -glob -nocase [list_property $obj] display_name] > 0} {
			set_property -name "display_name" -value "impl_1_route_report_methodology_0" -objects $obj
		}

	}
	# Create 'impl_1_route_report_power_0' report (if not found)
	if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_power_0] "" ] } {
		create_report_config -report_name impl_1_route_report_power_0 -report_type report_power:1.0 -steps route_design -runs impl_1
	}
	set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_power_0]
	if { $obj != "" } {
		if {[lsearch -glob -nocase [list_property $obj] display_name] > 0} {
			set_property -name "display_name" -value "impl_1_route_report_power_0" -objects $obj
		}

	}
	# Create 'impl_1_route_report_route_status_0' report (if not found)
	if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_route_status_0] "" ] } {
		create_report_config -report_name impl_1_route_report_route_status_0 -report_type report_route_status:1.0 -steps route_design -runs impl_1
	}
	set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_route_status_0]
	if { $obj != "" } {
		if {[lsearch -glob -nocase [list_property $obj] display_name] > 0} {
			set_property -name "display_name" -value "impl_1_route_report_route_status_0" -objects $obj
		}

	}
	# Create 'impl_1_route_report_timing_summary_0' report (if not found)
	if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_timing_summary_0] "" ] } {
		create_report_config -report_name impl_1_route_report_timing_summary_0 -report_type report_timing_summary:1.0 -steps route_design -runs impl_1
	}
	set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_timing_summary_0]
	if { $obj != "" } {
		if {[lsearch -glob -nocase [list_property $obj] display_name] > 0} {
			set_property -name "display_name" -value "impl_1_route_report_timing_summary_0" -objects $obj
		}

	}
	# Create 'impl_1_route_report_incremental_reuse_0' report (if not found)
	if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_incremental_reuse_0] "" ] } {
		create_report_config -report_name impl_1_route_report_incremental_reuse_0 -report_type report_incremental_reuse:1.0 -steps route_design -runs impl_1
	}
	set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_incremental_reuse_0]
	if { $obj != "" } {
		if {[lsearch -glob -nocase [list_property $obj] display_name] > 0} {
			set_property -name "display_name" -value "impl_1_route_report_incremental_reuse_0" -objects $obj
		}

	}
	# Create 'impl_1_route_report_clock_utilization_0' report (if not found)
	if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_clock_utilization_0] "" ] } {
		create_report_config -report_name impl_1_route_report_clock_utilization_0 -report_type report_clock_utilization:1.0 -steps route_design -runs impl_1
	}
	set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_clock_utilization_0]
	if { $obj != "" } {
		if {[lsearch -glob -nocase [list_property $obj] display_name] > 0} {
			set_property -name "display_name" -value "impl_1_route_report_clock_utilization_0" -objects $obj
		}

	}
	# Create 'impl_1_route_report_bus_skew_0' report (if not found)
	if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_bus_skew_0] "" ] } {
		create_report_config -report_name impl_1_route_report_bus_skew_0 -report_type report_bus_skew:1.1 -steps route_design -runs impl_1
	}
	set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_route_report_bus_skew_0]
	if { $obj != "" } {
		if {[lsearch -glob -nocase [list_property $obj] display_name] > 0} {
			set_property -name "display_name" -value "impl_1_route_report_bus_skew_0" -objects $obj
		}

	}
	# Create 'impl_1_post_route_phys_opt_report_timing_summary_0' report (if not found)
	if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_post_route_phys_opt_report_timing_summary_0] "" ] } {
		create_report_config -report_name impl_1_post_route_phys_opt_report_timing_summary_0 -report_type report_timing_summary:1.0 -steps post_route_phys_opt_design -runs impl_1
	}
	set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_post_route_phys_opt_report_timing_summary_0]
	if { $obj != "" } {
		if {[lsearch -glob -nocase [list_property $obj] display_name] > 0} {
			set_property -name "display_name" -value "impl_1_post_route_phys_opt_report_timing_summary_0" -objects $obj
		}

	}
	# Create 'impl_1_post_route_phys_opt_report_bus_skew_0' report (if not found)
	if { [ string equal [get_report_configs -of_objects [get_runs impl_1] impl_1_post_route_phys_opt_report_bus_skew_0] "" ] } {
		create_report_config -report_name impl_1_post_route_phys_opt_report_bus_skew_0 -report_type report_bus_skew:1.1 -steps post_route_phys_opt_design -runs impl_1
	}
	set obj [get_report_configs -of_objects [get_runs impl_1] impl_1_post_route_phys_opt_report_bus_skew_0]
	if { $obj != "" } {
		if {[lsearch -glob -nocase [list_property $obj] display_name] > 0} {
			set_property -name "display_name" -value "impl_1_post_route_phys_opt_report_bus_skew_0" -objects $obj
		}

	}
	set obj [get_runs impl_1]
	set_property -name "part" -value $implementation_part -objects $obj
	set_property -name "strategy" -value "Vivado Implementation Defaults" -objects $obj
	set_property -name "steps.write_bitstream.args.readback_file" -value "0" -objects $obj
	set_property -name "steps.write_bitstream.args.verbose" -value "0" -objects $obj

	# set the current impl run
	current_run -implementation [get_runs impl_1]

	puts "INFO: Project created:${_xil_proj_name_}"
	set obj [get_dashboards default_dashboard]

	# Create 'drc_1' gadget (if not found)
	if {[string equal [get_dashboard_gadgets -of_objects [get_dashboards default_dashboard] [ list "drc_1" ] ] ""]} {
	create_dashboard_gadget -name {drc_1} -type drc
	}
	set obj [get_dashboard_gadgets -of_objects [get_dashboards default_dashboard] [ list "drc_1" ] ]
	set_property -name "reports" -value "impl_1#impl_1_route_report_drc_0" -objects $obj

	# Create 'methodology_1' gadget (if not found)
	if {[string equal [get_dashboard_gadgets -of_objects [get_dashboards default_dashboard] [ list "methodology_1" ] ] ""]} {
	create_dashboard_gadget -name {methodology_1} -type methodology
	}
	set obj [get_dashboard_gadgets -of_objects [get_dashboards default_dashboard] [ list "methodology_1" ] ]
	set_property -name "reports" -value "impl_1#impl_1_route_report_methodology_0" -objects $obj

	# Create 'power_1' gadget (if not found)
	if {[string equal [get_dashboard_gadgets -of_objects [get_dashboards default_dashboard] [ list "power_1" ] ] ""]} {
	create_dashboard_gadget -name {power_1} -type power
	}
	set obj [get_dashboard_gadgets -of_objects [get_dashboards default_dashboard] [ list "power_1" ] ]
	set_property -name "reports" -value "impl_1#impl_1_route_report_power_0" -objects $obj

	# Create 'timing_1' gadget (if not found)
	if {[string equal [get_dashboard_gadgets -of_objects [get_dashboards default_dashboard] [ list "timing_1" ] ] ""]} {
	create_dashboard_gadget -name {timing_1} -type timing
	}
	set obj [get_dashboard_gadgets -of_objects [get_dashboards default_dashboard] [ list "timing_1" ] ]
	set_property -name "reports" -value "impl_1#impl_1_route_report_timing_summary_0" -objects $obj

	# Create 'utilization_1' gadget (if not found)
	if {[string equal [get_dashboard_gadgets -of_objects [get_dashboards default_dashboard] [ list "utilization_1" ] ] ""]} {
	create_dashboard_gadget -name {utilization_1} -type utilization
	}
	set obj [get_dashboard_gadgets -of_objects [get_dashboards default_dashboard] [ list "utilization_1" ] ]
	set_property -name "reports" -value "synth_1#synth_1_synth_report_utilization_0" -objects $obj
	set_property -name "run.step" -value "synth_design" -objects $obj
	set_property -name "run.type" -value "synthesis" -objects $obj

	# Create 'utilization_2' gadget (if not found)
	if {[string equal [get_dashboard_gadgets -of_objects [get_dashboards default_dashboard] [ list "utilization_2" ] ] ""]} {
	create_dashboard_gadget -name {utilization_2} -type utilization
	}
	set obj [get_dashboard_gadgets -of_objects [get_dashboards default_dashboard] [ list "utilization_2" ] ]
	set_property -name "reports" -value "impl_1#impl_1_place_report_utilization_0" -objects $obj

	move_dashboard_gadget -name {utilization_1} -row 0 -col 0
	move_dashboard_gadget -name {power_1} -row 1 -col 0
	move_dashboard_gadget -name {drc_1} -row 2 -col 0
	move_dashboard_gadget -name {timing_1} -row 0 -col 1
	move_dashboard_gadget -name {utilization_2} -row 1 -col 1
	move_dashboard_gadget -name {methodology_1} -row 2 -col 1
	# Set current dashboard to 'default_dashboard'
	current_dashboard default_dashboard
}



set _procedures_loaded_ true
}