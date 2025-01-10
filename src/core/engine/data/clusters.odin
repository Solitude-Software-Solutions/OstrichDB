package data
import "../../../utils"
import "../../const"
import "../../types"
import "./metadata"
import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:strconv"
import "core:strings"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//


main :: proc() {
	metadata.OST_CREATE_FFVF()
	OST_CREATE_ID_COLLECTION_AND_CLUSTERS()
	OST_CREATE_BACKUP_DIR()
	os.make_directory(const.OST_QUARANTINE_PATH)
	os.make_directory(const.OST_COLLECTION_PATH)
}


//used to return the value of a ALL cluster ids of all clusters within the passed in file
OST_GET_ALL_CLUSTER_IDS :: proc(fn: string) -> ([dynamic]i64, [dynamic]string) {
	//the following dynamic arrays DO NOT get deleted at the end of the procedure. They are deleted in the calling procedure
	IDs := make([dynamic]i64)
	idsStringArray := make([dynamic]string)

	fullPath := utils.concat_collection_name(fn)
	data, readSuccess := os.read_entire_file(fullPath)
	if !readSuccess {
		error1 := utils.new_err(
			.CANNOT_READ_FILE,
			utils.get_err_msg(.CANNOT_READ_FILE),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Error reading collection file", #procedure)
		return IDs, idsStringArray
	}

	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)

	clusterIdLine := "cluster_id :identifier:"
	for line in lines {
		if strings.contains(line, clusterIdLine) {
			idStr := strings.trim_space(strings.split(line, ":")[2])
			ID, ok := strconv.parse_i64(idStr)
			if ok {
				append(&IDs, ID)
				append(&idsStringArray, idStr)
			} else {
				utils.log_err(fmt.tprintf("Error parsing cluster ID: %s", idStr), #procedure)
			}
		}
	}
	return IDs, idsStringArray
}


//used to return the value of a single cluster id of the passed in cluster
//reads over a file, looks for the passed in cluster and returns its id
//if fn is an empty string("") then its looking for a cluster in a secure file
OST_GET_CLUSTER_ID :: proc(fn: string, cn: string) -> (ID: i64) {
	if fn != "" {
		fullPath := utils.concat_collection_name(fn)
		data, readSuccess := os.read_entire_file(fullPath)
		if !readSuccess {
			error1 := utils.new_err(
				.CANNOT_READ_FILE,
				utils.get_err_msg(.CANNOT_READ_FILE),
				#procedure,
			)
			utils.throw_err(error1)
			utils.log_err("Error reading collection file", #procedure)
			return 0
		}

		content := string(data)
		lines := strings.split(content, "\n")
		defer delete(lines)

		clusterNameLine := fmt.tprintf("cluster_name :identifier: %s", cn)
		clusterIdLine := "cluster_id :identifier:"

		for i := 0; i < len(lines); i += 1 {
			if strings.contains(lines[i], clusterNameLine) {
				for j := i + 1; j < len(lines) && j < i + 5; j += 1 {
					if strings.contains(lines[j], clusterIdLine) {
						idStr := strings.trim_space(strings.split(lines[j], ":")[2])
						ID, ok := strconv.parse_i64(idStr)
						if ok {
							return ID
						} else {
							utils.log_err("Error parsing cluster ID", #procedure)
							return 0
						}
					}
				}
			}
		}

		utils.log_err("Cluster not found", #procedure)
		return 0
	} else {
		//secure file

		secFile := fmt.tprintf(
			"%ssecure_%s%s",
			const.OST_SECURE_COLLECTION_PATH,
			cn,
			const.OST_FILE_EXTENSION,
		)
		data, readSuccess := os.read_entire_file(secFile)
		if !readSuccess {
			error1 := utils.new_err(
				.CANNOT_READ_FILE,
				utils.get_err_msg(.CANNOT_READ_FILE),
				#procedure,
			)
			utils.throw_err(error1)
			utils.log_err("Error reading secure file", #procedure)
			return 0
		}

		content := string(data)
		lines := strings.split(content, "\n")
		defer delete(lines)

		clusterNameLine := fmt.tprintf("cluster_name :identifier: %s", cn)
		clusterIdLine := "cluster_id :identifier:"

		for i := 0; i < len(lines); i += 1 {
			if strings.contains(lines[i], clusterNameLine) {
				for j := i + 1; j < len(lines) && j < i + 5; j += 1 {
					if strings.contains(lines[j], clusterIdLine) {
						idStr := strings.trim_space(strings.split(lines[j], ":")[2])
						ID, ok := strconv.parse_i64(idStr)
						if ok {
							// fmt.println("ID found: ", ID) //debugging
							return ID
						} else {
							utils.log_err("Error parsing cluster ID", #procedure)
							return 0
						}
					}
				}
			}
		}

		utils.log_err("Cluster not found", #procedure)
		return 0
	}
}

/*
Creates and appends a new cluster to the specified .ost file
*/
OST_CREATE_CLUSTER_BLOCK :: proc(fileName: string, clusterID: i64, clusterName: string) -> int {

	clusterExists := OST_CHECK_IF_CLUSTER_EXISTS(fileName, clusterName)
	if clusterExists == true {
		utils.log_err("Cluster already exists in file", #procedure)
		return 1
	}


	FIRST_HALF: []string = {"{\n\tcluster_name :identifier: %n"}
	LAST_HALF: []string = {"\n\tcluster_id :identifier: %i\n\t\n},\n"} //defines the base structure of a cluster block in a .ost file
	buf: [32]byte
	//step#1: open the file
	clusterFile, openSuccess := os.open(fileName, os.O_APPEND | os.O_WRONLY, 0o666)
	if openSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_OPEN_FILE,
			utils.get_err_msg(.CANNOT_OPEN_FILE),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Error opening collection file", #procedure)
	}


	for i := 0; i < len(FIRST_HALF); i += 1 {
		if (strings.contains(FIRST_HALF[i], "%n")) {
			//step#5: replace the %n with the cluster name
			newClusterName, replaceSuccess := strings.replace(FIRST_HALF[i], "%n", clusterName, -1)
			writeClusterName, writeSuccess := os.write(clusterFile, transmute([]u8)newClusterName)
		}
	}
	//step#2: iterate over the FIRST_HALF array and replace the %s with the passed in clusterID
	for i := 0; i < len(LAST_HALF); i += 1 {
		//step#3: check if the string contains the %s placeholder if it does replace it with the clusterID
		if strings.contains(LAST_HALF[i], "%i") {
			//step#4: replace the %s with the clusterID that is now being converted to a string
			newClusterID, replaceSuccess := strings.replace(
				LAST_HALF[i],
				"%i",
				strconv.append_int(buf[:], clusterID, 10),
				-1,
			)
			if replaceSuccess == false {
				error2 := utils.new_err(
					.CANNOT_UPDATE_CLUSTER,
					utils.get_err_msg(.CANNOT_UPDATE_CLUSTER),
					#procedure,
				)
				utils.throw_err(error2)
				utils.log_err("Error placing id into cluster template", #procedure)
			}
			writeClusterID, writeSuccess := os.write(clusterFile, transmute([]u8)newClusterID)
			if writeSuccess != 0 {
				error2 := utils.new_err(
					.CANNOT_WRITE_TO_FILE,
					utils.get_err_msg(.CANNOT_WRITE_TO_FILE),
					#procedure,
				)

				utils.log_err("Error writing cluster block to file", #procedure)
			}
		}
	}
	//step#FINAL: close the file
	os.close(clusterFile)
	return 0
}


// =====================================DATA INTERACTION=====================================//

//exclusivley used for checking if the name of a cluster exists...NOT the ID
//fn- filename, cn- clustername
OST_CHECK_IF_CLUSTER_EXISTS :: proc(fn: string, cn: string) -> bool {
	// fmt.println("Reading collection file: ", fn) //debugging
	// fmt.println("Checking if cluster exists: ", cn) //debugging
	data, read_success := utils.read_file(fn, #procedure)
	defer delete(data)

	content := string(data)

	cluster_strings := strings.split(content, "},")
	defer delete(cluster_strings)

	for cluster_str in cluster_strings {
		cluster_str := strings.trim_space(cluster_str)
		if cluster_str == "" do continue
		// Finds the start index of "cluster_name :" in the string
		name_start := strings.index(cluster_str, "cluster_name :identifier:")
		// If "cluster_name :" is not found, skip this cluster
		if name_start == -1 do continue
		// Move the start index to after "cluster_name :"
		name_start += len("cluster_name :identifier:")
		// Find the end of the cluster name
		name_end := strings.index(cluster_str[name_start:], "\n")
		// If newline is not found, skip this cluster
		if name_end == -1 do continue
		// Extract the cluster name and remove leading/trailing whitespace
		cluster_name := strings.trim_space(cluster_str[name_start:][:name_end])
		// Compare the extracted cluster name with the provided cluster name
		if strings.compare(cluster_name, cn) == 0 {
			return true
		}
	}
	return false
}

OST_RENAME_CLUSTER :: proc(collection_name: string, old: string, new: string) -> bool {
	collection_path := utils.concat_collection_name(collection_name)
	// check if the desired new cluster name already exists
	if OST_CHECK_IF_CLUSTER_EXISTS(collection_path, new) {
		fmt.printfln(
			"Cluster with name:%s%s%s already exists in collection: %s%s%s",
			utils.BOLD_UNDERLINE,
			new,
			utils.RESET,
			utils.BOLD_UNDERLINE,
			collection_name,
			utils.RESET,
		)
		fmt.println("Please try again with a different name")
		return false
	}

	data, readSuccess := utils.read_file(collection_path, #procedure)
	defer delete(data)

	content := string(data)
	clusters := strings.split(content, "}")
	newContent := make([dynamic]u8)
	defer delete(newContent)

	clusterFound := false
	for cluster in clusters {
		if strings.contains(cluster, fmt.tprintf("cluster_name :identifier: %s", old)) {
			// if a cluster with the old name is found, replace the name with the new name
			clusterFound = true
			newCluster, e := strings.replace(
				cluster,
				fmt.tprintf("cluster_name :identifier: %s", old),
				fmt.tprintf("cluster_name :identifier: %s", new),
				1,
			)
			//append the new data to the new content variable
			append(&newContent, ..transmute([]u8)newCluster)
			// append the closing brace
			append(&newContent, '}')
		} else if len(strings.trim_space(cluster)) > 0 {
			// For other clusters, just add them back unchanged and add the closing brace
			append(&newContent, ..transmute([]u8)cluster)
			// append(&newContent, '}')
		}
	}

	if !clusterFound {
		utils.throw_err(
			utils.new_err(
				.CANNOT_FIND_CLUSTER,
				fmt.tprintf(
					"Cluster: %s%s%s not found in collection: %s%s%s",
					utils.BOLD_UNDERLINE,
					old,
					utils.RESET,
					utils.BOLD_UNDERLINE,
					collection_name,
					utils.RESET,
				),
				#procedure,
			),
		)
		utils.log_err("Error finding cluster in collection file", #procedure)
		return false
	}

	// write new content to file
	writeSuccess := utils.write_to_file(collection_path, newContent[:], #procedure)

	return writeSuccess
}


//only used to create a cluster from the COMMAND LINE
OST_CREATE_CLUSTER_FROM_CL :: proc(collectionName: string, clusterName: string, id: i64) -> int {

	collection_path := utils.concat_collection_name(collectionName)

	clusterExist := OST_CHECK_IF_CLUSTER_EXISTS(collection_path, clusterName)
	if clusterExist {
		return -1
	}

	FIRST_HALF: []string = {"\n{\n\tcluster_name :identifier: %n"}
	LAST_HALF: []string = {"\n\tcluster_id :identifier: %i\n\t\n},\n"} //defines the base structure of a cluster block in a .ost file
	buf: [32]byte
	//step#1: open the file
	clusterFile, openSuccess := os.open(collection_path, os.O_APPEND | os.O_WRONLY, 0o666)
	defer os.close(clusterFile)
	if openSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_OPEN_FILE,
			utils.get_err_msg(.CANNOT_OPEN_FILE),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Error opening collection file", #procedure)
		return 1
	}


	for i := 0; i < len(FIRST_HALF); i += 1 {
		if (strings.contains(FIRST_HALF[i], "%n")) {
			//step#5: replace the %n with the cluster name
			newClusterName, replaceSuccess := strings.replace(FIRST_HALF[i], "%n", clusterName, -1)
			writeClusterName, writeSuccess := os.write(clusterFile, transmute([]u8)newClusterName)
		}
	}
	//step#2: iterate over the FIRST_HALF array and replace the %s with the passed in clusterID
	for i := 0; i < len(LAST_HALF); i += 1 {
		//step#3: check if the string contains the %s placeholder if it does replace it with the clusterID
		if strings.contains(LAST_HALF[i], "%i") {
			//step#4: replace the %s with the clusterID that is now being converted to a string
			newClusterID, replaceSuccess := strings.replace(
				LAST_HALF[i],
				"%i",
				strconv.append_int(buf[:], id, 10),
				-1,
			)
			if replaceSuccess == false {
				error2 := utils.new_err(
					.CANNOT_UPDATE_CLUSTER,
					utils.get_err_msg(.CANNOT_UPDATE_CLUSTER),
					#procedure,
				)
				utils.throw_err(error2)
				utils.log_err("Error placing id into cluster template", #procedure)
				return 2
			}
			writeClusterID, writeSuccess := os.write(clusterFile, transmute([]u8)newClusterID)
			if writeSuccess != 0 {
				error2 := utils.new_err(
					.CANNOT_WRITE_TO_FILE,
					utils.get_err_msg(.CANNOT_WRITE_TO_FILE),
					#procedure,
				)
				utils.log_err("Error writing cluster block to file", #procedure)
				return 3
			}
		}
	}
	return 0
}


OST_ERASE_CLUSTER :: proc(fn: string, cn: string) -> bool {
	buf: [64]byte
	file: string
	collection_path := utils.concat_collection_name(fn)

	// Skip confirmation if in testing mode
	if !types.TESTING {
		fmt.printfln(
			"Are you sure that you want to delete Cluster: %s%s%s from Collection: %s%s%s?\nThis action can not be undone.",
			utils.BOLD,
			cn,
			utils.RESET,
			utils.BOLD,
			fn,
			utils.RESET,
		)
		fmt.printfln("Type 'yes' to confirm or 'no' to cancel.")
		n, inputSuccess := os.read(os.stdin, buf[:])
		if inputSuccess != 0 {
			error1 := utils.new_err(
				.CANNOT_READ_INPUT,
				utils.get_err_msg(.CANNOT_READ_INPUT),
				#procedure,
			)
			utils.throw_err(error1)
			return false
		}

		confirmation := strings.trim_right(string(buf[:n]), "\r\n")
		cap := strings.to_upper(confirmation)

		switch cap {
		case const.NO:
			utils.log_runtime_event("User canceled deletion", "User canceled deletion of database")
			return false
		case const.YES:
		// Continue with deletion
		case:
			utils.log_runtime_event(
				"User entered invalid input",
				"User entered invalid input when trying to delete cluster",
			)
			error2 := utils.new_err(.INVALID_INPUT, utils.get_err_msg(.INVALID_INPUT), #procedure)
			utils.throw_custom_err(error2, "Invalid input. Please type 'yes' or 'no'.")
			return false
		}
	}

	data, readSuccess := utils.read_file(collection_path, #procedure)
	defer delete(data)

	content := string(data)
	clusterClosingBrace := strings.split(content, "}")
	newContent := make([dynamic]u8)
	defer delete(newContent)
	clusterFound := false


	for i := 0; i < len(clusterClosingBrace); i += 1 {
		cluster := clusterClosingBrace[i] // everything in the file up to the first instance of "},"
		if strings.contains(cluster, fmt.tprintf("cluster_name :identifier: %s", cn)) {
			clusterFound = true
		} else if len(strings.trim_space(cluster)) > 0 {
			append(&newContent, ..transmute([]u8)cluster) // Add closing brace
			if i < len(clusterClosingBrace) - 1 {
				append(&newContent, "}")
			}
		}
	}

	if !clusterFound {
		utils.throw_err(
			utils.new_err(
				.CANNOT_FIND_CLUSTER,
				fmt.tprintf(
					"Cluster: %s%s%s not found in collection: %s%s%s",
					utils.BOLD_UNDERLINE,
					cn,
					utils.RESET,
					utils.BOLD_UNDERLINE,
					fn,
					utils.RESET,
				),
				#procedure,
			),
		)
		utils.log_err("Error finding cluster in collection", #procedure)
		return false
	}
	writeSuccess := utils.write_to_file(collection_path, newContent[:], #procedure)
	utils.log_runtime_event(
		"Database Cluster",
		"User confirmed deletion of cluster and it was successfully deleted.",
	)
	return writeSuccess
}


OST_FETCH_CLUSTER :: proc(fn: string, cn: string) -> string {
	cluster_content: string
	collection_path := fmt.tprintf(
		"%s%s%s",
		const.OST_COLLECTION_PATH,
		fn,
		const.OST_FILE_EXTENSION,
	)

	clusterExists := OST_CHECK_IF_CLUSTER_EXISTS(collection_path, cn)
	switch clusterExists 
	{
	case false:
		fmt.printfln(
			"Cluster %s%s%s does not exist within collection '%s%s%s'",
			utils.BOLD_UNDERLINE,
			cn,
			utils.RESET,
			utils.BOLD_UNDERLINE,
			fn,
			utils.RESET,
		)
		break
	}
	data, readSuccess := os.read_entire_file(collection_path)
	if !readSuccess {
		utils.throw_err(
			utils.new_err(.CANNOT_READ_FILE, utils.get_err_msg(.CANNOT_READ_FILE), #procedure),
		)
		return ""
	}
	defer delete(data)

	content := string(data)
	clusters := strings.split(content, "}")

	for cluster in clusters {
		if strings.contains(cluster, fmt.tprintf("cluster_name :identifier: %s", cn)) {
			// Find the start of the cluster (opening brace)
			start_index := strings.index(cluster, "{")
			if start_index != -1 {
				// Extract the content between braces
				cluster_content = cluster[start_index + 1:]
				// Trim any leading or trailing whitespace
				cluster_content = strings.trim_space(cluster_content)
				return strings.clone(cluster_content)
			}
		}
	}

	utils.throw_err(
		utils.new_err(
			.CANNOT_FIND_CLUSTER,
			fmt.tprintf(
				"Cluster %s%s%s not found in collection: %s%s%s",
				utils.BOLD_UNDERLINE,
				cn,
				utils.RESET,
				utils.BOLD_UNDERLINE,
				fn,
				utils.RESET,
			),
			#procedure,
		),
	)
	utils.log_err("Error finding cluster in collection", #procedure)
	return ""
}


OST_LIST_CLUSTERS_IN_FILE :: proc(fn: string, showRecords: bool) -> int {
	buf := make([]byte, 64)
	defer delete(buf)
	filePath := fmt.tprintf("%s%s%s", const.OST_COLLECTION_PATH, fn, const.OST_FILE_EXTENSION)
	data, readSuccess := os.read_entire_file(filePath)
	if !readSuccess {
		utils.throw_err(
			utils.new_err(.CANNOT_READ_FILE, utils.get_err_msg(.CANNOT_READ_FILE), #procedure),
		)
		return 0
	}

	content := string(data)
	defer delete(content)
	clusters := strings.split(content, "}")
	for cluster in clusters {
		cluster := strings.trim_space(cluster)
		if cluster == "" do continue
		// Finds the start index of "cluster_name :" in the string
		name_start := strings.index(cluster, "cluster_name :identifier:")
		// If "cluster_name :" is not found, skip this cluster
		if name_start == -1 do continue
		// Move the start index to after "cluster_name :"
		name_start += len("cluster_name :identifier:")
		// Find the end of the cluster name
		name_end := strings.index(cluster[name_start:], "\n")
		// If newline is not found, skip this cluster
		if name_end == -1 do continue
		// Extract the cluster name and remove leading/trailing whitespace
		cluster_name := strings.trim_space(cluster[name_start:][:name_end])

		clusterName := fmt.tprintf("|\n|_________%s", cluster_name)

		fmt.println(clusterName)

		if showRecords {
			lines := strings.split_lines(cluster)
			for line in lines {
				lineTrim := strings.trim_space(line)
				// ensure the line is not empty, and ensure it ends with ":" to make sure it's a RECORD line
				if len(lineTrim) > 0 && strings.has_suffix(lineTrim, ":") {
					lineData := fmt.tprintf("\t   |\n\t   |_________%s", lineTrim)
					lineSplit := strings.split(lineData, ":")
					// output the record name and the datatype
					fmt.printfln("%s: %s", lineSplit[0], lineSplit[1])
				}
			}
		}
		// print the extra newline
		fmt.println("")

	}
	return 0
}

//scans each cluster in a collection file and ensures its proper structure.
//Want this to return 0 and false if the scan was successful AND no invalid structures were found
OST_SCAN_CLUSTER_STRUCTURE :: proc(fn: string) -> (scanSuccess: int, invalidStructureFound: bool) {
	file := fmt.tprintf("%s%s%s", const.OST_COLLECTION_PATH, fn, const.OST_FILE_EXTENSION)

	data, read_success := os.read_entire_file(file)
	if !read_success {
		return 1, true
	}
	defer delete(data)

	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)

	in_cluster := false
	bracket_count := 0
	cluster_start_line := 0

	for line, line_number in lines {
		trimmed := strings.trim_space(line)

		if trimmed == "{" {
			if in_cluster {
				return 0, true
			}
			in_cluster = true
			bracket_count += 1
			cluster_start_line = line_number
		} else if trimmed == "}," {
			if !in_cluster {
				return 0, true
			}
			bracket_count -= 1
			if bracket_count == 0 {
				in_cluster = false
			}
		} else if trimmed == "}" {
			return 0, true
		}
	}

	if in_cluster {
		return 0, true
	}

	if bracket_count != 0 {
		return 0, true
	}

	return 0, false
}

//counts the number of clusters in a collection file
OST_COUNT_CLUSTERS :: proc(fn: string) -> int {
	file := fmt.tprintf("%s%s%s", const.OST_COLLECTION_PATH, fn, const.OST_FILE_EXTENSION)

	data, read_success := os.read_entire_file(file)
	if !read_success {
		utils.log_err("Failed to read collection file", #procedure)
		return 0
	}
	defer delete(data)

	content := string(data)
	cluster_count := 0
	in_cluster := false

	lines := strings.split(content, "\n")
	defer delete(lines)

	for line in lines {
		trimmed := strings.trim_space(line)
		if trimmed == "{" {
			in_cluster = true
			cluster_count += 1
		} else if trimmed == "}," {
			in_cluster = false
		}
	}

	return cluster_count
}

//deletes all data from a cluster except identifier data such as cluster name and id
//Dude...THIS IS A FUCKING MESS AND ITS ALL AI GENERATED AND WORKS LMAO
// Added some comments to help explain as best as I can - SchoolyB
OST_PURGE_CLUSTER :: proc(fn: string, cn: string) -> bool {
	collection_path := fmt.tprintf(
		"%s%s%s",
		const.OST_COLLECTION_PATH,
		fn,
		const.OST_FILE_EXTENSION,
	)

	// Read the entire file
	data, readSuccess := os.read_entire_file(collection_path)
	if !readSuccess {
		utils.throw_err(
			utils.new_err(.CANNOT_READ_FILE, utils.get_err_msg(.CANNOT_READ_FILE), #procedure),
		)
		utils.log_err("Error reading collection file", #procedure)
		return false
	}
	defer delete(data)

	//Have to make these 4 vars because transmute wont allow a non-typed string...dumb I know
	openBrace := "{"
	openBraceWithNewline := "{\n"
	closeBrace := "}"
	closeBraceWithComma := "},"

	//split the content into clusters
	content := string(data)
	clusters := strings.split(content, "{")
	new_content := make([dynamic]u8)
	defer delete(new_content)

	//check if the cluster exists
	clusterFound := false
	for i := 0; i < len(clusters); i += 1 {
		if i == 0 {
			// Preserve the metadata header and its following whitespace
			append(&new_content, ..transmute([]u8)clusters[i])
			continue
		}
		//concatenate the open brace with the cluster
		cluster := strings.concatenate([]string{openBrace, clusters[i]})
		//if the cluster name matches the one we want to purge, we need to preserve the cluster's data
		if strings.contains(cluster, fmt.tprintf("cluster_name :identifier: %s", cn)) {
			clusterFound = true
			lines := strings.split(cluster, "\n")
			append(&new_content, ..transmute([]u8)openBraceWithNewline)
			emptyLineAdded := false
			for line, line_index in lines {
				trimmed_line := strings.trim_space(line)
				if strings.contains(trimmed_line, "cluster_name :identifier:") ||
				   strings.contains(trimmed_line, "cluster_id :identifier:") {

					//preserves the indentation
					indent := strings.index(line, trimmed_line)
					if indent > 0 {
						append(&new_content, ..transmute([]u8)line[:indent])
					}
					//adds the line line and a newline character to the new_content array
					append(&new_content, ..transmute([]u8)strings.trim_space(line))
					append(&new_content, '\n')

					//this ensures that the cluster_id line is followed by an empty line for formatting purposes
					if strings.contains(trimmed_line, "cluster_id :identifier:") &&
					   !emptyLineAdded {
						if line_index + 1 < len(lines) &&
						   len(strings.trim_space(lines[line_index + 1])) == 0 {
							append(&new_content, '\n')
							emptyLineAdded = true
						}
					}
				}
			}
			append(&new_content, ..transmute([]u8)closeBrace)

			//this ensures that the closing brace is followed by any trailing whitespace
			if last_brace := strings.last_index(cluster, "}"); last_brace != -1 {
				append(&new_content, ..transmute([]u8)cluster[last_brace + 1:])
			}
		} else {
			append(&new_content, ..transmute([]u8)cluster)
		}
	}

	if !clusterFound {
		utils.throw_err(
			utils.new_err(
				.CANNOT_FIND_CLUSTER,
				utils.get_err_msg(.CANNOT_FIND_CLUSTER),
				#procedure,
			),
		)
		utils.log_err("Error finding cluster in collection", #procedure)
		return false
	}
	//write the new content to the collection file
	writeSuccess := os.write_entire_file(collection_path, new_content[:])
	if !writeSuccess {
		utils.throw_err(
			utils.new_err(
				.CANNOT_WRITE_TO_FILE,
				utils.get_err_msg(.CANNOT_WRITE_TO_FILE),
				#procedure,
			),
		)
		utils.log_err("Error writing to collection file", #procedure)
		return false
	}

	return true

}

OST_GET_CLUSTER_SIZE :: proc(
	collection_name: string,
	cluster_name: string,
) -> (
	size: int,
	success: bool,
) {
	collection_path := fmt.tprintf(
		"%s%s%s",
		const.OST_COLLECTION_PATH,
		collection_name,
		const.OST_FILE_EXTENSION,
	)
	data, read_success := os.read_entire_file(collection_path)
	if !read_success {
		return 0, false
	}
	defer delete(data)

	content := string(data)
	clusters := strings.split(content, "},")

	for cluster in clusters {
		if strings.contains(cluster, fmt.tprintf("cluster_name :identifier: %s", cluster_name)) {
			return len(cluster), true
		}
	}

	return 0, false
}


//removes a users history from the history collecion. Used when DELETING a user and tests
OST_ERASE_HISTORY_CLUSTER :: proc(userName: string) -> bool {

	historyPath := "./history.ost"
	data, readSuccess := os.read_entire_file(historyPath)
	defer delete(data)
	if !readSuccess {
		utils.throw_err(
			utils.new_err(.CANNOT_READ_FILE, utils.get_err_msg(.CANNOT_READ_FILE), #procedure),
		)
		utils.log_err("Error reading collection file", #procedure)
		return false
	}
	content := string(data)
	clusterClosingBrace := strings.split(content, "}")
	newContent := make([dynamic]u8)
	defer delete(newContent)
	clusterFound := false


	for i := 0; i < len(clusterClosingBrace); i += 1 {
		cluster := clusterClosingBrace[i] // everything in the file up to the first instance of "},"
		if strings.contains(cluster, fmt.tprintf("cluster_name :identifier: %s", userName)) {
			clusterFound = true
		} else if len(strings.trim_space(cluster)) > 0 {
			append(&newContent, ..transmute([]u8)cluster) // Add closing brace
			if i < len(clusterClosingBrace) - 1 {
				append(&newContent, "}")
			}
		}
	}

	if !clusterFound {
		utils.throw_err(
			utils.new_err(
				.CANNOT_FIND_CLUSTER,
				fmt.tprintf(
					"Cluster: %s%s%s not found in collection: %s%s%s",
					utils.BOLD_UNDERLINE,
					userName,
					utils.RESET,
					utils.BOLD_UNDERLINE,
					userName,
					utils.RESET,
				),
				#procedure,
			),
		)
		utils.log_err("Error finding cluster in collection", #procedure)
		return false
	}
	writeSuccess := os.write_entire_file(historyPath, newContent[:])
	if !writeSuccess {
		utils.throw_err(
			utils.new_err(
				.CANNOT_WRITE_TO_FILE,
				utils.get_err_msg(.CANNOT_WRITE_TO_FILE),
				#procedure,
			),
		)
		utils.log_err("Error writing to collection file", #procedure)
		return false
	}
	utils.log_runtime_event(
		"Database Cluster",
		"User confirmed deletion of cluster and it was successfully deleted.",
	)
	return true

}
