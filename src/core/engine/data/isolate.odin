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
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB

Contributors:
    @CobbCoding1

License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC
File Description:
            Implements the logic for the ISOLATE command. This
            allows users to manually quarantine collections that
            are suspected to be corrupted or otherwise problematic.
*********************************************************/

//NOTE: At one point this file was named quarantine.odin, but was renamed to isolate.odin so you will see
//references to quarantine all throughout. Just know its the same thing. - SchoolyB

//moves the passed in collection file from the collections dir to the quarantine dir
PERFORM_COLLECTION_ISOLATION :: proc(fn: string) -> (int, string) {
	using const

	collectionPath := utils.concat_standard_collection_name(fn)

	// Generate a unique filename for the quarantined file
	timestamp := time.now()
	quarantineFilename := fmt.tprintf(
		"%s_%v%s",
		strings.trim_suffix(fn, OST_EXT),
		timestamp,
		OST_EXT,
	)
	isolationPath := fmt.tprintf("%s%s", QUARANTINE_PATH, quarantineFilename)
	// Move the file to quarantine
	//


	//TODO: So on mac this is throwing an error below but its working as intended. IDK why lol - Schooly
	//The Odin compiler on Darwin expects a bool return from os.rename
	// when ODIN_OS == .Darwin {
	// 	if err == true {
	// 		fmt.printfln("Error moving file to quarantine: %s", err)
	// 		return -2 , ""
	// 	}
	// }
	//

	//ID REMOVAL STUFF
	idsAsInt, idsAsStr := GET_ALL_CLUSTER_IDS(fn)
	idRemovaleResult := REMOVE_ISOLATED_CLUSTER_IDS_FROM_ID_COLLECTION(idsAsStr)
	if !idRemovaleResult {
		utils.log_err("Error removing isolated cluster IDs", #procedure)
		return -3, ""
	}

	delete(idsAsStr)
	delete(idsAsInt)
	//END ID REMOVAL STUFF


	err := os.rename(collectionPath, isolationPath)
	//THe Odin compiler on Linux doesnt expect a bool return from os.rename
	when ODIN_OS == .Linux {
		if err != os.ERROR_NONE {
			return -1, ""
		}
	}


	result := APPEND_NEW_ISOLATION_METADATA(fn, isolationPath)
	return result, quarantineFilename
}


//Appends 3 new metadata header members to a collection file.
//%ocn - Original Collection Name
//%doq - Date of Quarantine
//%toq - Time of Quarantine
APPEND_NEW_ISOLATION_METADATA :: proc(fn: string, isolationPath: string) -> int {

	data, readSuccess := utils.read_file(isolationPath, #procedure)
	if !readSuccess {
		return -2
	}
	defer delete(data)

	// Format date and time strings
	date, h, m, s := utils.get_date_and_time()


	new_metadata := fmt.tprintf(
		"# Original Collection Name: %s\n# Date of Quarantine: %s\n# Time of Quarantine: %s:%s:%s",
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
		if strings.has_prefix(line, strings.trim_right(const.METADATA_END, "\n")) {
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

	// Copy lines up to header end
	for i := 0; i < header_end_idx; i += 1 {
		append(&new_lines, lines[i])
	}

	// Add new metadata lines
	append(&new_lines, new_metadata)
	append(&new_lines, strings.trim_right(const.METADATA_END, "\n")) // Remove \n as join will add it

	// Add remaining content
	for i := header_end_idx + 1; i < len(lines); i += 1 {
		append(&new_lines, lines[i])
	}

	// Write updated content back to file
	new_content := strings.join(new_lines[:], "\n")
	writeSuccess := os.write_entire_file(isolationPath, transmute([]byte)new_content)

	if !writeSuccess {
		utils.log_err("Error writing updated metadata to quarantined file", #procedure)
		return 1
	}

	return 0
}

//TODO:
//in the event that a cluster id in a standard collectionn file
// is modified, the check systsem bugs out. its looking for an exact match of the cluster
// id so if that is modified there can be no match thus the id is not found and removed...
REMOVE_ISOLATED_CLUSTER_IDS_FROM_ID_COLLECTION :: proc(idsAsStr: [dynamic]string) -> bool {
	// Remove the cluster id from the cluster ids file
	for id in idsAsStr {
		// Remove the cluster id from the cluster ids file
		REMOVE_ID_FROM_ID_COLLECTION(id, false)
	}

	return true
}
