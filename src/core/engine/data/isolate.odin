package data

import "../../../utils"
import "../../const"
import "../../types"
import "/metadata"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//

//NOTE: At one point this file was named quarantine.odin, but was renamed to isolate.odin so you will see
//references to quarantine all throughout. Just know its the same thing. - SchoolyB

//moves the passed in collection file from the collections dir to the quarantine dir
OST_PERFORM_ISOLATION :: proc(fn: string) -> int {
	collectionFile := fmt.tprintf(
		"%s%s%s",
		const.OST_COLLECTION_PATH,
		fn,
		const.OST_FILE_EXTENSION,
	)

	// Generate a unique filename for the quarantined file
	timestamp := time.now()
	quarantineFilename := fmt.tprintf(
		"%s_%v%s",
		strings.trim_suffix(fn, const.OST_FILE_EXTENSION),
		timestamp,
		const.OST_FILE_EXTENSION,
	)
	quarantine_path := fmt.tprintf("%s%s", const.OST_QUARANTINE_PATH, quarantineFilename)
	// Move the file to quarantine
	//
	err := os.rename(collectionFile, quarantine_path)
	//THe Odin compiler on Linux doesnt expect a bool return from os.rename
	when ODIN_OS == .Linux {
		if err != os.ERROR_NONE {
			return -1
		}
	}

	//TODO: So on mac this is throwing an error below but its working as intended. IDK why lol - Schooly
	//The Odin compiler on Darwin expects a bool return from os.rename
	// when ODIN_OS == .Darwin {
	// 	if err != false {
	// 		fmt.printfln("Error moving file to quarantine: %s", err)
	// 		return -2
	// 	}
	// }

	result := OST_APPEND_QUARANTINE_METADATA(fn, quarantine_path)
	return result
}


//Appends 2 new metadata header members to a collection file.
//%ocn - Original Collection Name
//%doq - Date of Quarantine
OST_APPEND_QUARANTINE_METADATA :: proc(fn: string, quarantine_path: string) -> int {
	// Read the quarantined file
	data, readSuccess := utils.read_file(quarantine_path, #procedure)
	if !readSuccess {
		return -2
	}

	defer delete(data)
	// Format date and time strings
	date, h, m, s := utils.get_date_and_time()
	// Create new metadata entries
	new_metadata := fmt.tprintf(
		"# Original Collection Name: %s\n# Date of Quarantine: %s\n# Time of Quarantine: %s:%s:%s\n",
		fn,
		date,
		h,
		m,
		s,
	)

	// Find the end of the metadata header
	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)

	header_end_idx := -1
	for line, i in lines {
		if strings.has_prefix(line, "# [Ostrich File Header End]") {
			header_end_idx = i
			break
		}
	}

	if header_end_idx == -1 {
		utils.log_err("Could not find metadata header end", #procedure)
		return -1
	}

	// Insert new metadata before the header end
	new_lines := make([dynamic]string)
	defer delete(new_lines)

	for i := 0; i < header_end_idx; i += 1 {
		append(&new_lines, lines[i])
	}

	// Add new metadata lines
	append(&new_lines, new_metadata)
	append(&new_lines, lines[header_end_idx]) // Add header end line

	// Add remaining content
	for i := header_end_idx + 1; i < len(lines); i += 1 {
		append(&new_lines, lines[i])
	}

	// Write updated content back to file
	new_content := strings.join(new_lines[:], "\n")
	writeSuccess := os.write_entire_file(quarantine_path, transmute([]byte)new_content)

	if !writeSuccess {
		utils.log_err("Error writing updated metadata to quarantined file", #procedure)
		return 1
	}

	return 0
}
