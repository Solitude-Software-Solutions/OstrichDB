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
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            This file contains all the logic for interacting with
            OstrichDB as the cluster level. This includes creating,
            deleting, renaming, fetching, etc.
*********************************************************/


main :: proc() {
	using const

	metadata.OST_CREATE_FFVF()
	os.make_directory(OST_CORE_PATH)
	os.make_directory(OST_QUARANTINE_PATH)
	os.make_directory(OST_COLLECTION_PATH)
	OST_CREATE_ID_COLLECTION_AND_CLUSTERS()
	OST_CREATE_BACKUP_DIR()
}


//used to return the value of a ALL cluster ids of all clusters within the passed in file
OST_GET_ALL_CLUSTER_IDS :: proc(fn: string) -> ([dynamic]i64, [dynamic]string) {
	using utils
	//the following dynamic arrays DO NOT get deleted at the end of the procedure. They are deleted in the calling procedure
	IDs := make([dynamic]i64)
	idsStringArray := make([dynamic]string)

	fullPath := concat_collection_name(fn)
	data, readSuccess := os.read_entire_file(fullPath)
	if !readSuccess {
		error1 := new_err(.CANNOT_READ_FILE, get_err_msg(.CANNOT_READ_FILE), #procedure)
		throw_err(error1)
		log_err("Error reading collection file", #procedure)
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
				log_err(fmt.tprintf("Error parsing cluster ID: %s", idStr), #procedure)
			}
		}
	}
	return IDs, idsStringArray
}


//used to return the value of a single cluster id of the passed in cluster
//reads over a file, looks for the passed in cluster and returns its id
//if fn is an empty string("") then its looking for a cluster in a secure file
OST_GET_CLUSTER_ID :: proc(fn: string, cn: string) -> (ID: i64) {
	using utils

	if fn != "" {
		fullPath := concat_collection_name(fn)
		data, readSuccess := os.read_entire_file(fullPath)
		if !readSuccess {
			error1 := new_err(.CANNOT_READ_FILE, get_err_msg(.CANNOT_READ_FILE), #procedure)
			throw_err(error1)
			log_err("Error reading collection file", #procedure)
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
							log_err("Error parsing cluster ID", #procedure)
							return 0
						}
					}
				}
			}
		}

		log_err("Cluster not found", #procedure)
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
			error1 := new_err(.CANNOT_READ_FILE, get_err_msg(.CANNOT_READ_FILE), #procedure)
			throw_err(error1)
			log_err("Error reading secure file", #procedure)
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
							log_err("Error parsing cluster ID", #procedure)
							return 0
						}
					}
				}
			}
		}

		log_err("Cluster not found", #procedure)
		return 0
	}
}


//Creates and appends a new cluster to the specified .ost file
//todo: since I have the OST_CREATE_CLUSTER proc, idk if this is needed anymore
OST_CREATE_CLUSTER_BLOCK :: proc(fileName: string, clusterID: i64, clusterName: string) -> int {
	using utils

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
		error1 := new_err(.CANNOT_OPEN_FILE, get_err_msg(.CANNOT_OPEN_FILE), #procedure)
		throw_err(error1)
		log_err("Error opening collection file", #procedure)
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
				error2 := new_err(
					.CANNOT_UPDATE_CLUSTER,
					get_err_msg(.CANNOT_UPDATE_CLUSTER),
					#procedure,
				)
				throw_err(error2)
				log_err("Error placing id into cluster template", #procedure)
			}
			writeClusterID, writeSuccess := os.write(clusterFile, transmute([]u8)newClusterID)
			if writeSuccess != 0 {
				error2 := new_err(
					.CANNOT_WRITE_TO_FILE,
					get_err_msg(.CANNOT_WRITE_TO_FILE),
					#procedure,
				)

				log_err("Error writing cluster block to file", #procedure)
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
	data, readSuccess := utils.read_file(fn, #procedure)
	defer delete(data)

	content := string(data)

	clusterStrings := strings.split(content, "},")
	defer delete(clusterStrings)

	for clusterStr in clusterStrings {
		clusterStr := strings.trim_space(clusterStr)
		if clusterStr == "" do continue
		// Finds the start index of "cluster_name :" in the string
		nameStart := strings.index(clusterStr, "cluster_name :identifier:")
		// If "cluster_name :" is not found, skip this cluster
		if nameStart == -1 do continue
		// Move the start index to after "cluster_name :"
		nameStart += len("cluster_name :identifier:")
		// Find the end of the cluster name
		nameEnd := strings.index(clusterStr[nameStart:], "\n")
		// If newline is not found, skip this cluster
		if nameEnd == -1 do continue
		// Extract the cluster name and remove leading/trailing whitespace
		cluster_name := strings.trim_space(clusterStr[nameStart:][:nameEnd])
		// Compare the extracted cluster name with the provided cluster name
		if strings.compare(cluster_name, cn) == 0 {
			return true
		}
	}
	return false
}

OST_RENAME_CLUSTER :: proc(fn: string, old: string, new: string) -> bool {
	using utils

	collectionPath := concat_collection_name(fn)
	// check if the desired new cluster name already exists
	if OST_CHECK_IF_CLUSTER_EXISTS(collectionPath, new) {
		fmt.printfln(
			"Cluster with name:%s%s%s already exists in collection: %s%s%s",
			BOLD_UNDERLINE,
			new,
			RESET,
			BOLD_UNDERLINE,
			fn,
			RESET,
		)
		fmt.println("Please try again with a different name")
		return false
	}

	data, readSuccess := read_file(collectionPath, #procedure)
	defer delete(data)

	content := string(data)
	clusters := strings.split(content, "},")
	newContent := make([dynamic]u8)
	defer delete(newContent)

	clusterFound := false
	for cluster in clusters {
		// Find the cluster name in the current cluster
		nameStart := strings.index(cluster, "cluster_name :identifier:")
		if nameStart != -1 {
			// Move past the identifier prefix
			nameStart += len("cluster_name :identifier:")
			// Find the end of the line
			nameEnd := strings.index(cluster[nameStart:], "\n")
			fmt.println("nameEnd: ", nameEnd) //debugging
			if nameEnd != -1 {
				// Extract the actual cluster name
				cluster_name := strings.trim_space(cluster[nameStart:][:nameEnd])

				// Check for exact match
				if cluster_name == old {
					clusterFound = true
					newCluster, e := strings.replace(
						cluster,
						fmt.tprintf("cluster_name :identifier: %s", old),
						fmt.tprintf("cluster_name :identifier: %s", new),
						1,
					)
					append(&newContent, ..transmute([]u8)newCluster)
					append(&newContent, "},")
				} else if len(strings.trim_space(cluster)) > 0 {
					append(&newContent, ..transmute([]u8)cluster)
					append(&newContent, "},")
				}
			}
		}
	}

	// fmt.println("new content: ", string(newContent[:])) //debugging

	if !clusterFound {
		throw_err(
			new_err(
				.CANNOT_FIND_CLUSTER,
				fmt.tprintf(
					"Cluster: %s%s%s not found in collection: %s%s%s",
					BOLD_UNDERLINE,
					old,
					RESET,
					BOLD_UNDERLINE,
					fn,
					RESET,
				),
				#procedure,
			),
		)
		log_err("Error finding cluster in collection file", #procedure)
		return false
	}

	// write new content to file
	writeSuccess := write_to_file(collectionPath, newContent[:], #procedure)

	return writeSuccess
}


//only used to create a cluster from the COMMAND LINE
OST_CREATE_CLUSTER :: proc(fn: string, clusterName: string, id: i64) -> int {
	using utils

	collectionPath := concat_collection_name(fn)

	clusterExist := OST_CHECK_IF_CLUSTER_EXISTS(collectionPath, clusterName)
	if clusterExist {
		return -1
	}

	FIRST_HALF: []string = {"\n{\n\tcluster_name :identifier: %n"}
	LAST_HALF: []string = {"\n\tcluster_id :identifier: %i\n\t\n},\n"} //defines the base structure of a cluster block in a .ost file
	buf: [32]byte
	//step#1: open the file
	clusterFile, openSuccess := os.open(collectionPath, os.O_APPEND | os.O_WRONLY, 0o666)
	defer os.close(clusterFile)
	if openSuccess != 0 {
		error1 := new_err(.CANNOT_OPEN_FILE, get_err_msg(.CANNOT_OPEN_FILE), #procedure)
		throw_err(error1)
		log_err("Error opening collection file", #procedure)
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
				error2 := new_err(
					.CANNOT_UPDATE_CLUSTER,
					get_err_msg(.CANNOT_UPDATE_CLUSTER),
					#procedure,
				)
				throw_err(error2)
				log_err("Error placing id into cluster template", #procedure)
				return 2
			}
			writeClusterID, writeSuccess := os.write(clusterFile, transmute([]u8)newClusterID)
			if writeSuccess != 0 {
				error2 := new_err(
					.CANNOT_WRITE_TO_FILE,
					get_err_msg(.CANNOT_WRITE_TO_FILE),
					#procedure,
				)
				log_err("Error writing cluster block to file", #procedure)
				return 3
			}
		}
	}
	return 0
}


OST_ERASE_CLUSTER :: proc(fn: string, cn: string) -> bool {
	using utils

	buf: [64]byte
	file: string
	collectionPath := concat_collection_name(fn)

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
		error1 := new_err(.CANNOT_READ_INPUT, get_err_msg(.CANNOT_READ_INPUT), #procedure)
		throw_err(error1)
		return false
	}

	confirmation := strings.trim_right(string(buf[:n]), "\r\n")
	cap := strings.to_upper(confirmation)

	switch cap {
	case const.NO:
		log_runtime_event("User canceled deletion", "User canceled deletion of database")
		return false
	case const.YES:
	// Continue with deletion
	case:
		log_runtime_event(
			"User entered invalid input",
			"User entered invalid input when trying to delete cluster",
		)
		error2 := new_err(.INVALID_INPUT, get_err_msg(.INVALID_INPUT), #procedure)
		throw_custom_err(error2, "Invalid input. Please type 'yes' or 'no'.")
		return false
	}

	data, readSuccess := read_file(collectionPath, #procedure)
	defer delete(data)

	content := string(data)

	// Find the end of the metadata header
	headerEnd := strings.index(content, const.METADATA_END)
	// Move past the metadata header
	headerEnd += len(const.METADATA_END) + 1

	//split content into metadata header and body
	metaDataHeader := content[:headerEnd]
	body := content[headerEnd:]


	clusters := strings.split(content, "},")
	newContent := make([dynamic]u8)
	defer delete(newContent)
	clusterFound := false
	append(&newContent, ..transmute([]u8)metaDataHeader)


	for cluster in clusters {
		// Find the cluster name in the current cluster
		nameStart := strings.index(cluster, "cluster_name :identifier:")
		if nameStart != -1 {
			// Move past the identifier prefix
			nameStart += len("cluster_name :identifier:")
			// Find the end of the line
			nameEnd := strings.index(cluster[nameStart:], "\n")
			if nameEnd != -1 {
				// Extract the actual cluster name and remove leading/trailing whitespace
				cluster_name := strings.trim_space(cluster[nameStart:][:nameEnd])

				// Skip this cluster if it matches the one we want to delete
				if cluster_name == cn {
					clusterFound = true
					continue
				}
			}
		}
		//perseve non-empty clusters
		if len(strings.trim_space(cluster)) > 0 {
			append(&newContent, ..transmute([]u8)cluster)
			append(&newContent, "},")
		}
	}


	if !clusterFound {
		throw_err(
			new_err(
				.CANNOT_FIND_CLUSTER,
				fmt.tprintf(
					"Cluster: %s%s%s not found in collection: %s%s%s",
					BOLD_UNDERLINE,
					cn,
					RESET,
					BOLD_UNDERLINE,
					fn,
					RESET,
				),
				#procedure,
			),
		)
		log_err("Error finding cluster in collection", #procedure)
		return false
	}
	writeSuccess := write_to_file(collectionPath, newContent[:], #procedure)
	log_runtime_event(
		"Database Cluster",
		"User confirmed deletion of cluster and it was successfully deleted.",
	)
	return writeSuccess
}


OST_FETCH_CLUSTER :: proc(fn: string, cn: string) -> string {
	using const
	using utils

	clusterContent: string
	collectionPath := concat_collection_name(fn)

	clusterExists := OST_CHECK_IF_CLUSTER_EXISTS(collectionPath, cn)
	switch clusterExists 
	{
	case false:
		fmt.printfln(
			"Cluster %s%s%s does not exist within collection '%s%s%s'",
			BOLD_UNDERLINE,
			cn,
			RESET,
			BOLD_UNDERLINE,
			fn,
			RESET,
		)
		break
	}
	data, readSuccess := os.read_entire_file(collectionPath)
	if !readSuccess {
		throw_err(new_err(.CANNOT_READ_FILE, get_err_msg(.CANNOT_READ_FILE), #procedure))
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
				clusterContent = cluster[start_index + 1:]
				// Trim any leading or trailing whitespace
				clusterContent = strings.trim_space(clusterContent)
				return strings.clone(clusterContent)
			}
		}
	}

	throw_err(
		new_err(
			.CANNOT_FIND_CLUSTER,
			fmt.tprintf(
				"Cluster %s%s%s not found in collection: %s%s%s",
				BOLD_UNDERLINE,
				cn,
				RESET,
				BOLD_UNDERLINE,
				fn,
				RESET,
			),
			#procedure,
		),
	)
	log_err("Error finding cluster in collection", #procedure)
	return ""
}


OST_LIST_CLUSTERS_IN_FILE :: proc(fn: string, showRecords: bool) -> int {
	using const
	using utils

	buf := make([]byte, 64)
	defer delete(buf)
	filePath := concat_collection_name(fn)
	data, readSuccess := os.read_entire_file(filePath)
	if !readSuccess {
		throw_err(new_err(.CANNOT_READ_FILE, get_err_msg(.CANNOT_READ_FILE), #procedure))
		return 0
	}

	content := string(data)
	defer delete(content)
	clusters := strings.split(content, "}")
	for cluster in clusters {
		cluster := strings.trim_space(cluster)
		if cluster == "" do continue
		// Finds the start index of "cluster_name :" in the string
		nameStart := strings.index(cluster, "cluster_name :identifier:")
		// If "cluster_name :" is not found, skip this cluster
		if nameStart == -1 do continue
		// Move the start index to after "cluster_name :"
		nameStart += len("cluster_name :identifier:")
		// Find the end of the cluster name
		nameEnd := strings.index(cluster[nameStart:], "\n")
		// If newline is not found, skip this cluster
		if nameEnd == -1 do continue
		// Extract the cluster name and remove leading/trailing whitespace
		cluster_name := strings.trim_space(cluster[nameStart:][:nameEnd])

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
	using const
	using utils

	file := concat_collection_name(fn)

	data, readSuccess := os.read_entire_file(file)
	if !readSuccess {
		return 1, true
	}
	defer delete(data)

	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)

	inCluster := false
	bracketCount := 0
	clusterStartLine := 0

	for line, line_number in lines {
		trimmed := strings.trim_space(line)

		if trimmed == "{" {
			if inCluster {
				return -1, true
			}
			inCluster = true
			bracketCount += 1
			clusterStartLine = line_number
		} else if trimmed == "}," {
			if !inCluster {
				return -2, true
			}
			bracketCount -= 1
			if bracketCount == 0 {
				inCluster = false
			}
		} else if trimmed == "}" {
			return -3, true
		}
	}

	if inCluster {
		return -4, true
	}

	if bracketCount != 0 {
		return -5, true
	}

	return 0, false
}

//counts the number of clusters in a collection file
OST_COUNT_CLUSTERS :: proc(fn: string) -> int {
	using utils

	file := concat_collection_name(fn)
	data, readSuccess := os.read_entire_file(file)
	if !readSuccess {
		utils.log_err("Failed to read collection file", #procedure)
		return 0
	}
	defer delete(data)

	content := string(data)
	clusterCount := 0
	inCluster := false

	lines := strings.split(content, "\n")
	defer delete(lines)

	for line in lines {
		trimmed := strings.trim_space(line)
		if trimmed == "{" {
			inCluster = true
			clusterCount += 1
		} else if trimmed == "}," {
			inCluster = false
		}
	}

	return clusterCount
}

//deletes all data from a cluster except identifier data such as cluster name and id
//Dude...THIS IS A FUCKING MESS AND ITS ALL AI GENERATED AND WORKS LMAO
// Added some comments to help explain as best as I can - SchoolyB
OST_PURGE_CLUSTER :: proc(fn: string, cn: string) -> bool {
	using const
	using utils

	collectionPath := concat_collection_name(fn)

	// Read the entire file
	data, readSuccess := os.read_entire_file(collectionPath)
	if !readSuccess {
		throw_err(new_err(.CANNOT_READ_FILE, get_err_msg(.CANNOT_READ_FILE), #procedure))
		log_err("Error reading collection file", #procedure)
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
	newContent := make([dynamic]u8)
	defer delete(newContent)

	//check if the cluster exists
	clusterFound := false
	for i := 0; i < len(clusters); i += 1 {
		if i == 0 {
			// Preserve the metadata header and its following whitespace
			append(&newContent, ..transmute([]u8)clusters[i])
			continue
		}
		//concatenate the open brace with the cluster
		cluster := strings.concatenate([]string{openBrace, clusters[i]})
		//if the cluster name matches the one we want to purge, we need to preserve the cluster's data
		if strings.contains(cluster, fmt.tprintf("cluster_name :identifier: %s", cn)) {
			clusterFound = true
			lines := strings.split(cluster, "\n")
			append(&newContent, ..transmute([]u8)openBraceWithNewline)
			emptyLineAdded := false
			for line, lineIndex in lines {
				trimmedLine := strings.trim_space(line)
				if strings.contains(trimmedLine, "cluster_name :identifier:") ||
				   strings.contains(trimmedLine, "cluster_id :identifier:") {

					//preserves the indentation
					indent := strings.index(line, trimmedLine)
					if indent > 0 {
						append(&newContent, ..transmute([]u8)line[:indent])
					}
					//adds the line line and a newline character to the newContent array
					append(&newContent, ..transmute([]u8)strings.trim_space(line))
					append(&newContent, '\n')

					//this ensures that the cluster_id line is followed by an empty line for formatting purposes
					if strings.contains(trimmedLine, "cluster_id :identifier:") &&
					   !emptyLineAdded {
						if lineIndex + 1 < len(lines) &&
						   len(strings.trim_space(lines[lineIndex + 1])) == 0 {
							append(&newContent, '\n')
							emptyLineAdded = true
						}
					}
				}
			}
			append(&newContent, ..transmute([]u8)closeBrace)

			//this ensures that the closing brace is followed by any trailing whitespace
			if lastBrace := strings.last_index(cluster, "}"); lastBrace != -1 {
				append(&newContent, ..transmute([]u8)cluster[lastBrace + 1:])
			}
		} else {
			append(&newContent, ..transmute([]u8)cluster)
		}
	}

	if !clusterFound {
		throw_err(new_err(.CANNOT_FIND_CLUSTER, get_err_msg(.CANNOT_FIND_CLUSTER), #procedure))
		log_err("Error finding cluster in collection", #procedure)
		return false
	}
	//write the new content to the collection file
	writeSuccess := os.write_entire_file(collectionPath, newContent[:])
	if !writeSuccess {
		throw_err(new_err(.CANNOT_WRITE_TO_FILE, get_err_msg(.CANNOT_WRITE_TO_FILE), #procedure))
		log_err("Error writing to collection file", #procedure)
		return false
	}

	return true
}

OST_GET_CLUSTER_SIZE :: proc(fn: string, cn: string) -> (size: int, success: bool) {
	using const
	using utils

	collectionPath := concat_collection_name(fn)
	data, readSuccess := os.read_entire_file(collectionPath)
	if !readSuccess {
		return 0, false
	}
	defer delete(data)

	content := string(data)
	clusters := strings.split(content, "},")

	for cluster in clusters {
		if strings.contains(cluster, fmt.tprintf("cluster_name :identifier: %s", cn)) {
			return len(cluster), true
		}
	}

	return 0, false
}


//removes a users history from the history collecion. Used when DELETING a user and tests
