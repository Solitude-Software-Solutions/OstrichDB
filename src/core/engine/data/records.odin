package data

import "../../../utils"
import "../../const"
import "../../types"
import "./metadata"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright 2024 - Present Marshall A Burns & Solitude Software Solutions LLC
*********************************************************/

record: types.Record


//can be used to check if a single record exists within a cluster
OST_CHECK_IF_RECORD_EXISTS :: proc(fn, cn, rn: string) -> bool {
	using const
	data, readSuccess := utils.read_file(fn, #procedure)
	defer delete(data)
	if !readSuccess {
		fmt.println("Failed to read file")
		return false
	}


	content := string(data)
	clusters := strings.split(content, "},")

	for cluster in clusters {
		cluster := strings.trim_space(cluster)
		if strings.contains(cluster, fmt.tprintf("cluster_name :identifier: %s", cn)) {
			// Found the correct cluster, now look for the record
			lines := strings.split(cluster, "\n")
			for line in lines {
				line := strings.trim_space(line)
				if strings.has_prefix(line, fmt.tprintf("%s :", rn)) {
					return true
				}
			}
			// fmt.printfln("Record: %s not found in cluster: %s", rn, cn) //this mf right here is causing so much confusion
			return false
		}
	}

	// If we've gone through all clusters and didn't find the specified cluster
	error2 := utils.new_err(
		.CANNOT_FIND_CLUSTER,
		utils.get_err_msg(.CANNOT_FIND_CLUSTER),
		#procedure,
	)
	utils.throw_custom_err(error2, fmt.tprintf("Specified cluster not found: %s", cn))
	utils.log_err("Specified cluster not found", #procedure)
	return false
}


//appends a line to the end of a cluster with the data thats passed in. Not quite the same as the SET_RECORD_VALUE proc. that one is more for updating a records value
//fn-filename, cn-clustername,id-cluster id, rn-record name, rd-record data
OST_APPEND_RECORD_TO_CLUSTER :: proc(fn, cn, rn, rd, rType: string, ID: ..i64) -> int {
	data, readSuccess := utils.read_file(fn, #procedure)
	defer delete(data)
	if !readSuccess {
		return -1
	}
	// fmt.println("passing fn:, ", fn) //debugging
	// fmt.println("passing cn:, ", cn) //debugging
	// fmt.println("passing rn:, ", rn) //debugging
	// fmt.println("passing rd:, ", rd) //debugging
	// fmt.println("passing rType:, ", rType) //debugging
	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)

	clusterStart := -1
	closingBrace := -1

	// Find the cluster and its closing brace
	for i := 0; i < len(lines); i += 1 {
		if strings.contains(lines[i], cn) {
			clusterStart = i
		}
		if clusterStart != -1 && strings.contains(lines[i], "}") {
			closingBrace = i
			break
		}
	}

	//check if the record name already exists if it does return
	recordExists := OST_CHECK_IF_RECORD_EXISTS(fn, cn, rn)
	if recordExists {
		fmt.printfln(
			"Record: %s%s%s already exists within Collection: %s%s%s. Located in Cluster: %s%s%s",
			utils.BOLD_UNDERLINE,
			rn,
			utils.RESET,
			utils.BOLD,
			fn,
			utils.RESET,
			utils.BOLD_UNDERLINE,
			cn,
			utils.RESET,
		)
		return 1
	}
	//if the cluster is not found or the structure is invalid, return
	if clusterStart == -1 || closingBrace == -1 {
		error2 := utils.new_err(
			.CANNOT_FIND_CLUSTER,
			utils.get_err_msg(.CANNOT_FIND_CLUSTER),
			#procedure,
		)
		utils.throw_err(error2)
		utils.log_err("Unable to find cluster/valid structure", #procedure)
		return -1
	}

	// Create the new line
	new_line := fmt.tprintf("\t%s :%s: %s", rn, rType, rd)

	// Insert the new line and adjust the closing brace
	new_lines := make([dynamic]string, len(lines) + 1)
	copy(new_lines[:closingBrace], lines[:closingBrace])
	new_lines[closingBrace] = new_line
	new_lines[closingBrace + 1] = "},"
	if closingBrace + 1 < len(lines) {
		copy(new_lines[closingBrace + 2:], lines[closingBrace + 1:])
	}

	new_content := strings.join(new_lines[:], "\n")
	writeSuccess := utils.write_to_file(fn, transmute([]byte)new_content, #procedure)
	if !writeSuccess {
		return -1
	}
	return 0
}


//the same as above but without the check becuase the check breaks shit when doing credential stuff
OST_APPEND_CREDENTIAL_RECORD :: proc(fn, cn, rn, rd, rType: string, ID: ..i64) -> int {
	data, readSuccess := utils.read_file(fn, #procedure)
	defer delete(data)
	if !readSuccess {
		return -1
	}
	// fmt.println("passing fn:, ", fn) //debugging
	// fmt.println("passing cn:, ", cn) //debugging
	// fmt.println("passing rn:, ", rn) //debugging
	// fmt.println("passing rd:, ", rd) //debugging
	// fmt.println("passing rType:, ", rType) //debugging
	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)

	clusterStart := -1
	closingBrace := -1

	// Find the cluster and its closing brace
	for i := 0; i < len(lines); i += 1 {
		if strings.contains(lines[i], cn) {
			clusterStart = i
		}
		if clusterStart != -1 && strings.contains(lines[i], "}") {
			closingBrace = i
			break
		}
	}

	//if the cluster is not found or the structure is invalid, return
	if clusterStart == -1 || closingBrace == -1 {
		error2 := utils.new_err(
			.CANNOT_FIND_CLUSTER,
			utils.get_err_msg(.CANNOT_FIND_CLUSTER),
			#procedure,
		)
		utils.throw_err(error2)
		utils.log_err("Unable to find cluster/valid structure", #procedure)
		return -1
	}

	// Create the new line
	new_line := fmt.tprintf("\t%s :%s: %s", rn, rType, rd)

	// Insert the new line and adjust the closing brace
	new_lines := make([dynamic]string, len(lines) + 1)
	copy(new_lines[:closingBrace], lines[:closingBrace])
	new_lines[closingBrace] = new_line
	new_lines[closingBrace + 1] = "},"
	if closingBrace + 1 < len(lines) {
		copy(new_lines[closingBrace + 2:], lines[closingBrace + 1:])
	}

	new_content := strings.join(new_lines[:], "\n")
	writeSuccess := utils.write_to_file(fn, transmute([]byte)new_content, #procedure)
	if !writeSuccess {
		return -1
	}
	return 0
}

// // get the value from the right side of a key value
OST_READ_RECORD_VALUE :: proc(fn, cn, rType, rn: string) -> string {
	data, readSuccess := utils.read_file(fn, #procedure)
	defer delete(data)
	if !readSuccess {
		return ""
	}

	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)

	clusterStart := -1
	closingBrace := -1

	// Find the cluster and its closing brace
	for line, i in lines {
		if strings.contains(line, cn) {
			clusterStart = i
		}
		if clusterStart != -1 && strings.contains(line, "}") {
			closingBrace = i
			break
		}
	}

	// If the cluster is not found or the structure is invalid, return an empty string
	if clusterStart == -1 || closingBrace == -1 {
		error2 := utils.new_err(
			.CANNOT_FIND_CLUSTER,
			utils.get_err_msg(.CANNOT_FIND_CLUSTER),
			#procedure,
		)
		utils.throw_err(error2)
		utils.log_err("Unable to find cluster/valid structur", #procedure)
		return ""
	}

	type := fmt.tprintf(":%s:", rType)
	for i in clusterStart ..= closingBrace {
		if strings.contains(lines[i], rn) {
			record := strings.split(lines[i], type)
			if len(record) > 1 {
				return strings.clone(strings.trim_space(record[1]))
			}
			return ""
		}
	}
	return ""
}


//gets every record of the passed in rName and returns the record type, the records data, the cluster it is in, and the collection it is in
//exclusivley used with the RENAME command if the user is NOT using dot notation
OST_FETCH_EVERY_RECORD_BY_NAME :: proc(rName: string) -> [dynamic]string {
	allRecords := make([dynamic]string)
	defer delete(allRecords)
	clusterName: string
	recordType: string
	recordData: string

	collectionDir, openDirSuccess := os.open(const.OST_COLLECTION_PATH)
	collections, readDirSuccess := os.read_dir(collectionDir, -1) //might not be -1

	for collection in collections {
		colPath := fmt.tprintf("%s%s", const.OST_COLLECTION_PATH, collection.name)
		data, collectionReadSuccess := os.read_entire_file(colPath)
		defer delete(data)
		content := string(data)

		colNameNoExt := strings.trim_right(collection.name, const.OST_FILE_EXTENSION)
		//getting the name of each cluster that the record name is found in per database
		clusters := strings.split(content, "}")
		for cluster in clusters {
			if strings.contains(cluster, rName) {
				cluster := strings.trim_space(cluster)
				if cluster == "" do continue
				//get the cluster name
				nameStart := strings.index(cluster, "cluster_name :identifier:")
				if nameStart == -1 do continue
				nameStart += len("cluster_name :identifier:")
				nameEnd := strings.index(cluster[nameStart:], "\n")
				if nameEnd == -1 do continue
				clusterName = strings.trim_space(cluster[nameStart:][:nameEnd])

				//split the cluster into lines to find the record type and record data
				lines := strings.split(cluster, "\n")
				for line in lines {
					line := strings.trim_space(line)
					if strings.has_prefix(line, rName) {
						// Split the line into parts
						parts := strings.split(line, ":")
						if len(parts) >= 3 {
							recordType = strings.trim_space(parts[1])
							recordData = strings.trim_space(strings.join(parts[2:], ":"))

							// Append record info to allRecords
							recordInfo := fmt.tprintf(
								"Collection: %s | Cluster Name: %s | Record Type: %s | Record Data: %s",
								collection.name,
								clusterName,
								recordType,
								recordData,
							)
							append(&allRecords, recordInfo)
							fmt.printfln(
								"Collection: %s%s%s | Cluster Name: %s%s%s",
								utils.BOLD_UNDERLINE,
								colNameNoExt,
								utils.RESET,
								utils.BOLD_UNDERLINE,
								clusterName,
								utils.RESET,
							)
							fmt.printfln(
								"Record Type: %s%s%s | Record Data: %s%s%s",
								utils.BOLD_UNDERLINE,
								recordType,
								utils.RESET,
								utils.BOLD_UNDERLINE,
								recordData,
								utils.RESET,
							)
						}
						break
					}
				}
			}
		}
	}
	return allRecords
}

//Does what it says, renames a record
//So basically since I started implementing dot notation on the command line I had to rework a lot of shit.
//"params" is only given an arg when used during dot notation. We will call this a temp fix but lets be real... - Marshall Burns aka @SchoolyB Oct5th 2024
OST_RENAME_RECORD :: proc(fn, cn, old, new: string) -> (result: int) {

	if !OST_CHECK_IF_COLLECTION_EXISTS(fn, 0) {
		fmt.printfln("Collection with name:%s%s%s does not exist", utils.BOLD, fn, utils.RESET)
		fmt.println("Please try again with a different name")
		return -1
	}

	collectionPath := utils.concat_collection_name(fn)


	if !OST_CHECK_IF_CLUSTER_EXISTS(collectionPath, cn) {
		fmt.printfln("Cluster with name:%s%s%s does not exist", utils.BOLD, cn, utils.RESET)
		return -1
	}

	rExists := OST_CHECK_IF_RECORD_EXISTS(collectionPath, cn, new)

	switch rExists 
	{
	case true:
		fmt.printfln(
			"A record with the name: %s%s%s. Already exists within cluster: %s%s%s Please try again.",
			utils.BOLD_UNDERLINE,
			old,
			utils.RESET,
			utils.BOLD_UNDERLINE,
			cn,
			utils.RESET,
		)
		return -1
	case false:
		data, readSuccess := os.read_entire_file(collectionPath)
		if !readSuccess {
			utils.throw_err(
				utils.new_err(.CANNOT_READ_FILE, utils.get_err_msg(.CANNOT_READ_FILE), #procedure),
			)
			utils.log_err("Could not read file", #procedure)
			return -1
		}
		defer delete(data)

		content := string(data)
		clusters := strings.split(content, "},")
		newContent := make([dynamic]u8)
		defer delete(newContent)
		recordFound := false

		for cluster in clusters {
			cluster := strings.trim_space(cluster)
			if strings.contains(cluster, fmt.tprintf("cluster_name :identifier: %s", cn)) {
				// Found the correct cluster, now look for the record to rename
				lines := strings.split(cluster, "\n")
				newCluster := make([dynamic]u8)
				defer delete(newCluster)

				for line in lines {
					trimmedLine := strings.trim_space(line)
					if strings.has_prefix(trimmedLine, fmt.tprintf("%s :", old)) {
						// Found the record to rename
						recordFound = true
						newLine, _ := strings.replace(
							trimmedLine,
							fmt.tprintf("%s :", old),
							fmt.tprintf("%s :", new),
							1,
						)
						append(&newCluster, "\t")
						append(&newCluster, ..transmute([]u8)newLine)
						append(&newCluster, "\n")
					} else if len(trimmedLine) > 0 {
						// Keep other lines unchanged
						append(&newCluster, ..transmute([]u8)line)
						append(&newCluster, "\n")
					}
				}

				// Add the modified cluster to the new content
				// fmt.printfln("New Cluster: %s", newCluster) //debugging
				append(&newContent, ..newCluster[:])
				append(&newContent, "}")
				append(&newContent, ",\n\n")
			} else if len(cluster) > 0 {
				fmt.printfln("Cluster: %s", cluster)
				// Keep other clusters unchanged
				append(&newContent, ..transmute([]u8)cluster)
				append(&newContent, "\n}")
				append(&newContent, ",\n\n")
			}
		}

		if !recordFound {
			fmt.printfln(
				"Record %s%s%s not found within cluster %s%s%s of collection %s%s%s",
				utils.BOLD_UNDERLINE,
				old,
				utils.RESET,
				utils.BOLD_UNDERLINE,
				cn,
				utils.RESET,
				utils.BOLD_UNDERLINE,
				fn,
				utils.RESET,
			)
			return -1
		}

		// write new content to file
		writeSuccess := os.write_entire_file(collectionPath, newContent[:])
		if !writeSuccess {
			utils.throw_err(
				utils.new_err(
					.CANNOT_WRITE_TO_FILE,
					utils.get_err_msg(.CANNOT_WRITE_TO_FILE),
					#procedure,
				),
			)
			utils.log_err("Could not write to file", #procedure)
			result = 0
		}
		break
	}

	return result
}

//Displays all collections as a tree. also shows size in bytes. DOES NOT subrtact metadata header sizes
OST_GET_DATABASE_TREE :: proc() {
	OST_GET_ALL_COLLECTION_NAMES(true)
	// on MacOS, the below call always shows 64b as the size of all collections so need to always subract 64b from the total size even if there are no collections
	//need to test on Linux
	totalSize := metadata.OST_GET_FS(const.OST_COLLECTION_PATH).size
	sizeMinus64 := totalSize - 64

	// output data size
	fmt.printfln("Size of data: %dBytes", sizeMinus64)

}

//here is where the type that the user enters in their command is passed
OST_SET_RECORD_TYPE :: proc(rType: string) -> (string, int) {
	for type in const.VALID_RECORD_TYPES {
		if rType == type {
			//evaluate the shorthand type name and assign the full type name to the record
			switch (rType) 
			{
			case const.STR:
				record.type = const.STRING
				break
			case const.INT:
				record.type = const.INTEGER
				break
			case const.FLT:
				record.type = const.FLOAT
				break
			case const.BOOL:
				record.type = const.BOOLEAN
				break
			case const.CHAR:
				record.type = const.CHAR
				break
			case const.STR_ARRAY:
				record.type = const.STRING_ARRAY
				break
			case const.INT_ARRAY:
				record.type = const.INTEGER_ARRAY
				break
			case const.FLT_ARRAY:
				record.type = const.FLOAT_ARRAY
				break
			case const.BOOL_ARRAY:
				record.type = const.BOOLEAN_ARRAY
				break
			case const.DATE:
				record.type = const.DATE
				break
			case const.TIME:
				record.type = const.TIME
				break
			case const.DATETIME:
				record.type = const.DATETIME
				break
			case:
				//if the user enters the full type name
				record.type = rType
				break
			}
			return record.type, 0
		}
	}
	fmt.printfln("Invalid record type %s%s%s", utils.BOLD_UNDERLINE, rType, utils.RESET)
	return strings.clone(record.type), 1
}

//finds a the passed in record, and updates its type. keeps its value which will eventually need to be changed
OST_CHANGE_RECORD_TYPE :: proc(fn, cn, rn, rd, newType: string) -> bool {
	data, readSuccess := utils.read_file(fn, #procedure)
	defer delete(data)
	if !readSuccess {
		return false
	}

	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)

	newLines := make([dynamic]string)
	defer delete(newLines)

	inTargetCluster := false
	recordUpdated := false

	// Find the cluster and update the record
	for line in lines {
		trimmedLine := strings.trim_space(line)

		if trimmedLine == "{" {
			inTargetCluster = false
		}

		if strings.contains(trimmedLine, fmt.tprintf("cluster_name :identifier: %s", cn)) {
			inTargetCluster = true
		}

		if inTargetCluster && strings.contains(trimmedLine, fmt.tprintf("%s :", rn)) {
			// Keep the original indentation
			leadingWhitespace := strings.split(line, rn)[0]
			// Create new line with updated type
			newLine := fmt.tprintf("%s%s :%s: %s", leadingWhitespace, rn, newType, rd)
			append(&newLines, newLine)
			recordUpdated = true
		} else {
			append(&newLines, line)
		}

		if inTargetCluster && trimmedLine == "}," {
			inTargetCluster = false
		}
	}

	if !recordUpdated {
		fmt.printfln(
			"Record %s%s%s not found in cluster %s%s%s",
			utils.BOLD_UNDERLINE,
			rn,
			utils.RESET,
			utils.BOLD_UNDERLINE,
			cn,
			utils.RESET,
		)
		return false
	}

	// Write the updated content back to file
	newContent := strings.join(newLines[:], "\n")
	writeSuccess := utils.write_to_file(fn, transmute([]byte)newContent, #procedure)
	return writeSuccess
}

//finds the location of the passed in record in the passed in cluster
OST_FIND_RECORD_IN_CLUSTER :: proc(
	collectionName, clusterName, recordName: string,
) -> (
	types.Record,
	string,
	bool,
) {
	collectionPath := fmt.tprintf(
		"%s%s%s",
		const.OST_COLLECTION_PATH,
		strings.to_upper(collectionName),
		const.OST_FILE_EXTENSION,
	)
	data, readSuccess := os.read_entire_file(collectionPath)
	if !readSuccess {
		fmt.printfln(
			"Failed to read collection file: %s%s%s",
			utils.BOLD_UNDERLINE,
			collectionPath,
			utils.RESET,
		)
		return types.Record{}, "", false
	}
	defer delete(data)

	content := string(data)
	clusters := strings.split(content, "},")
	targetClusterName := strings.to_upper(clusterName)


	for cluster, clusterIndex in clusters {
		clusterLines := strings.split(cluster, "\n")
		inTargetCluster := false


		for line, lineIndex in clusterLines {
			trimmedLine := strings.trim_space(line)

			if strings.contains(trimmedLine, "cluster_name :identifier:") {
				clusterNameParts := strings.split(trimmedLine, ":")
				if len(clusterNameParts) >= 3 {
					currentClusterName := strings.trim_space(clusterNameParts[2])
					if currentClusterName == targetClusterName {
						inTargetCluster = true
					}
				}
			}

			if inTargetCluster {
				recordPrefix := fmt.tprintf("%s :", recordName)
				if strings.has_prefix(trimmedLine, recordPrefix) {
					parts := strings.split(trimmedLine, ":")
					if len(parts) >= 3 {
						record := types.Record {
							name  = strings.trim_space(parts[0]),
							type  = strings.trim_space(parts[1]),
							value = strings.trim_space(parts[2]),
						}
						return record, strings.clone(record.type), true
					}
				}
			}
		}

		if inTargetCluster {
			fmt.printfln("  Finished searching target cluster, record not found")
			break
		}
	}

	fmt.printfln("Record not found in specified cluster")
	return types.Record{}, "", false
}

//reads over a collection file and the passed in cluster to get the passed in records data type and return it
OST_GET_RECORD_TYPE :: proc(fn, cn, rn: string) -> (recordType: string, success: bool) {
	data, readSuccess := utils.read_file(fn, #procedure)
	defer delete(data)
	if !readSuccess {
		return "", false
	}

	content := string(data)
	clusters := strings.split(content, "},")

	for cluster in clusters {
		//check for cluster
		if strings.contains(cluster, fmt.tprintf("cluster_name :identifier: %s", cn)) {
			lines := strings.split(cluster, "\n")
			for line in lines {
				line := strings.trim_space(line)
				// Check if this line contains our record
				if strings.has_prefix(line, fmt.tprintf("%s :", rn)) {
					// Split the line into parts using ":"
					parts := strings.split(line, ":")
					if len(parts) >= 2 {
						// Return the type of the record
						return strings.clone(strings.trim_space(parts[1])), true
					}
				}
			}
		}
	}

	return "", false
}


//reads over a specific collection file and looks for records with the passed in name
OST_SCAN_COLLECTION_FOR_RECORD :: proc(
	collectionName, recordName: string,
) -> (
	colName: string,
	cluName: string,
	success: bool,
) {
	collectionPath := fmt.tprintf("%s%s", const.OST_COLLECTION_PATH, collectionName)

	data, readSuccess := utils.read_file(collectionPath, #procedure)
	if !readSuccess {
		return "", "", false
	}
	defer delete(data)

	content := string(data)
	clusters := strings.split(content, "},")

	for cluster in clusters {
		if !strings.contains(cluster, "cluster_name :identifier:") {
			continue // Skip non-cluster content
		}

		// Extract cluster name
		nameStart := strings.index(cluster, "cluster_name :identifier:")
		if nameStart == -1 do continue
		nameStart += len("cluster_name :identifier:")
		nameEnd := strings.index(cluster[nameStart:], "\n")
		if nameEnd == -1 do continue
		currentClusterName := strings.trim_space(cluster[nameStart:][:nameEnd])
		// Look for record in this cluster
		lines := strings.split(cluster, "\n")
		for line in lines {
			line := strings.trim_space(line)
			if strings.has_prefix(line, fmt.tprintf("%s :", recordName)) {
				return strings.clone(collectionName), strings.clone(currentClusterName), true
			}
		}
	}

	return "", "", false
}

//same as above but for ALL collection files
OST_SCAN_COLLECTIONS_FOR_RECORD :: proc(
	rName: string,
) -> (
	colNames: []string,
	cluNames: []string,
) {
	collections := make([dynamic]string)
	clusters := make([dynamic]string)

	defer delete(collections)
	defer delete(clusters)

	colDir, openDirSuccess := os.open(const.OST_COLLECTION_PATH)

	files, err := os.read_dir(colDir, 1)
	if err != 0 {
		error := utils.new_err(
			.CANNOT_READ_DIRECTORY,
			utils.get_err_msg(.CANNOT_READ_DIRECTORY),
			#procedure,
		)
		utils.throw_err(error)
		utils.log_err("Could not read collection directory", #procedure)
		return {}, {}
	}
	defer delete(files)

	for file in files {
		if !strings.has_suffix(file.name, ".ost") do continue
		filepath := strings.join([]string{const.OST_COLLECTION_PATH, file.name}, "")
		data, readSuccess := os.read_entire_file(filepath)
		if !readSuccess {
			fmt.println("Error reading file:", file.name)
			continue
		}
		defer delete(data)

		content := string(data)
		foundMatches := OST_FIND_RECORD_MATCHES_IN_CLUSTERS(content, rName)

		for match in foundMatches {
			withoutExt := strings.split(file.name, const.OST_FILE_EXTENSION)
			append(&collections, withoutExt[0])
			append(&clusters, match)
		}

		delete(foundMatches)
	}
	// fmt.printfln("Collections: %v", collections)
	// fmt.printfln("Clusters: %s", clusters[:])
	return collections[:], clusters[:]
}

//reads over the passed in content and looks for the record with the passed in name.. Nesting is so much fun...I should have done a diffent databsse format.
OST_FIND_RECORD_MATCHES_IN_CLUSTERS :: proc(content: string, rName: string) -> []string {
	clusters := make([dynamic]string)
	lines := strings.split(content, "\n")
	defer delete(lines)

	currentCluName: string
	in_cluster := false
	found_in_current_cluster := false

	for line in lines {
		line := strings.trim_space(line)
		if line == "{" {
			in_cluster = true
			currentCluName = ""
			found_in_current_cluster = false
		} else if line == "}," {
			in_cluster = false
			found_in_current_cluster = false
		} else if in_cluster {
			parts := strings.split(line, ":")
			if len(parts) == 3 {
				name := strings.trim_space(parts[0])
				type := strings.trim_space(parts[1])
				value := strings.trim_space(parts[2])

				if name == "cluster_name" && type == "identifier" {
					currentCluName = value
				} else if name == rName && !found_in_current_cluster {
					append(&clusters, currentCluName)
					found_in_current_cluster = true
				}
			}
		}
	}

	return clusters[:]
}

//Reworked for dot notation - Marshall Burns aka @SchoolyB
OST_SET_RECORD_VALUE :: proc(file, cn, rn, rValue: string) -> bool {
	using const

	result := OST_CHECK_IF_RECORD_EXISTS(file, cn, rn)

	if !result {
		fmt.println("Cannot set record due to not finding record")
		return false
	}

	// Read the collection file
	data, readSuccess := utils.read_file(file, #procedure)
	defer delete(data)
	if !readSuccess {
		return false
	}

	recordType, getTypeSuccess := OST_GET_RECORD_TYPE(file, cn, rn)
	//Array allocations
	intArrayValue: [dynamic]int
	fltArrayValue: [dynamic]f64
	boolArrayValue: [dynamic]bool
	stringArrayValue, timeArrayValue, dateTimeArrayValue, charArrayValue, dateArrayValue, uuidArrayValue: [dynamic]string


	//Standard value allocation
	valueAny: any = 0
	ok: bool = false
	setValueOk := false
	switch (recordType) {
	case INTEGER:
		record.type = INTEGER
		valueAny, ok = OST_CONVERT_RECORD_TO_INT(rValue)
		setValueOk = ok
		break
	case FLOAT:
		record.type = FLOAT
		valueAny, ok = OST_CONVERT_RECORD_TO_FLOAT(rValue)
		setValueOk = ok
		break
	case BOOLEAN:
		record.type = BOOLEAN
		valueAny, ok = OST_CONVERT_RECORD_TO_BOOL(rValue)
		setValueOk = ok
		break
	case STRING:
		record.type = STRING
		valueAny = utils.append_qoutations(rValue)
		setValueOk = true
		break
	case CHAR:
		record.type = CHAR
		if len(rValue) != 1 {
			setValueOk = false
			fmt.println("Failed to set record value")
			fmt.printfln(
				"Value of type %s%s%s must be a single character",
				utils.BOLD_UNDERLINE,
				recordType,
				utils.RESET,
			)
		} else {
			valueAny = utils.append_single_qoutations__string(rValue)
			setValueOk = true
		}
		break
	case INTEGER_ARRAY:
		record.type = INTEGER_ARRAY
		verifiedValue := OST_VERIFY_ARRAY_VALUES(INTEGER_ARRAY, rValue)
		if !verifiedValue {
			fmt.printfln(
				"Invalid value given. Must be an array of Type: %sINTEGER%s",
				utils.BOLD_UNDERLINE,
				utils.RESET,
			)
			return false
		}
		intArrayValue, ok := OST_CONVERT_RECORD_TO_INT_ARRAY(rValue)
		valueAny = intArrayValue
		setValueOk = ok
		break
	case FLOAT_ARRAY:
		record.type = FLOAT_ARRAY
		verifiedValue := OST_VERIFY_ARRAY_VALUES(FLOAT, rValue)
		if !verifiedValue {
			fmt.printfln(
				"Invalid value given. Must be an array of Type: %sFLOAT%s",
				utils.BOLD_UNDERLINE,
				utils.RESET,
			)
			return false
		}
		fltArrayValue, ok := OST_CONVERT_RECORD_TO_FLT_ARRAY(rValue)
		valueAny = fltArrayValue
		setValueOk = ok
		break
	case BOOLEAN_ARRAY:
		record.type = BOOLEAN_ARRAY
		verifiedValue := OST_VERIFY_ARRAY_VALUES(BOOLEAN_ARRAY, rValue)
		if !verifiedValue {
			fmt.printfln(
				"Invalid value given. Must be an array of Type: %BOOLEAN%s",
				utils.BOLD_UNDERLINE,
				utils.RESET,
			)
			return false
		}
		boolArrayValue, ok := OST_CONVERT_RECORD_TO_BOOL_ARRAY(rValue)
		valueAny = boolArrayValue
		setValueOk = ok
		break
	case STRING_ARRAY:
		record.type = STRING_ARRAY
		stringArrayValue, ok := OST_CONVERT_RECORD_TO_STRING_ARRAY(rValue)
		valueAny = stringArrayValue
		setValueOk = ok
		break
	case CHAR_ARRAY:
		record.type = CHAR_ARRAY
		charArrayValue, ok := OST_CONVERT_RECORD_TO_CHAR_ARRAY(rValue)
		valueAny = charArrayValue
		setValueOk = ok
		break
	case DATE_ARRAY:
		record.type = DATE_ARRAY
		dateArrayValue, ok := OST_CONVERT_RECORD_TO_DATE_ARRAY(rValue)
		valueAny = dateArrayValue
		setValueOk = ok
		break
	case TIME_ARRAY:
		record.type = TIME_ARRAY
		timeArrayValue, ok := OST_CONVERT_RECORD_TO_TIME_ARRAY(rValue)
		valueAny = timeArrayValue
		setValueOk = ok
		break
	case DATETIME_ARRAY:
		record.type = DATETIME_ARRAY
		dateTimeArrayValue, ok := OST_CONVERT_RECORD_TO_DATETIME_ARRAY(rValue)
		valueAny = dateTimeArrayValue
		setValueOk = ok
		break
	case DATE:
		record.type = DATE
		date, ok := OST_CONVERT_RECORD_TO_DATE(rValue)
		if ok {
			valueAny = date
			setValueOk = ok
		}
		break
	case TIME:
		record.type = TIME
		time, ok := OST_CONVERT_RECORD_TO_TIME(rValue)
		if ok {
			valueAny = time
			setValueOk = ok
		}
		break
	case DATETIME:
		record.type = DATETIME
		dateTime, ok := OST_CONVERT_RECORD_TO_DATETIME(rValue)
		if ok {
			valueAny = dateTime
			setValueOk = ok
		}
		break
	case UUID:
		record.type = UUID
		uuid, ok := OST_CONVERT_RECORD_TO_UUID(rValue)
		if ok {
			valueAny = uuid
			setValueOk = ok
		}
		break
	case UUID_ARRAY:
		record.type = UUID_ARRAY
		uuidArrayValue, ok := OST_CONVERT_RECORD_TO_UUID_ARRAY(rValue)
		valueAny = uuidArrayValue
		setValueOk = ok
		break
	case NULL:
		record.type = NULL
		valueAny = NULL
		setValueOk = true
		break
	}

	if setValueOk != true {
		valueTypeError := utils.new_err(
			.INVALID_VALUE_FOR_EXPECTED_TYPE,
			utils.get_err_msg(.INVALID_VALUE_FOR_EXPECTED_TYPE),
			#procedure,
		)
		utils.throw_custom_err(
			valueTypeError,
			fmt.tprintf(
				"%sInvalid value given. Expected a value of type: %s%s",
				utils.BOLD_UNDERLINE,
				record.type,
				utils.RESET,
			),
		)
		utils.log_err(
			"User entered a value of a different type than what was expected.",
			#procedure,
		)

		return false
	}

	// Update the record in the file
	success := OST_UPDATE_RECORD_IN_FILE(file, cn, rn, valueAny)


	//Don't forget to free memory :) - Marshall Burns aka @SchoolyB
	delete(intArrayValue)
	delete(fltArrayValue)
	delete(boolArrayValue)
	delete(stringArrayValue)
	delete(charArrayValue)
	delete(dateArrayValue)
	delete(timeArrayValue)
	delete(dateTimeArrayValue)
	delete(uuidArrayValue)
	return success

}


//handles the actual updating of the record value
OST_UPDATE_RECORD_IN_FILE :: proc(
	filePath: string,
	clusterName: string,
	recordName: string,
	newValue: any,
) -> bool {
	data, success := os.read_entire_file(filePath)
	if !success {
		fmt.printfln("Failed to read file: %s%s%s", utils.BOLD_UNDERLINE, filePath, utils.RESET)
		return false
	}
	defer delete(data)

	lines := strings.split(string(data), "\n")
	inTargetCluster := false
	recordUpdated := false

	for line, i in lines {
		trimmedLine := strings.trim_space(line)

		if trimmedLine == "{" {
			inTargetCluster = false
		}

		if strings.contains(trimmedLine, "cluster_name :identifier:") {
			clusterNameParts := strings.split(trimmedLine, ":")
			if len(clusterNameParts) >= 3 {
				currentClusterName := strings.trim_space(clusterNameParts[2])
				if strings.to_upper(currentClusterName) == strings.to_upper(clusterName) {
					inTargetCluster = true
				}
			}
		}

		// if in the target cluster, find the record and update it
		if inTargetCluster && strings.contains(trimmedLine, recordName) {
			leadingWhitespace := strings.split(line, recordName)[0]
			parts := strings.split(trimmedLine, ":")
			if len(parts) >= 2 {
				lines[i] = fmt.tprintf(
					"%s%s:%s: %v",
					leadingWhitespace,
					parts[0],
					parts[1],
					newValue,
				)
				recordUpdated = true
				break
			}
		}

		if inTargetCluster && trimmedLine == "}," {
			break
		}
	}

	if !recordUpdated {
		fmt.printfln(
			"Record %s%s%s not found in cluster %s%s%s",
			utils.BOLD_UNDERLINE,
			recordName,
			utils.RESET,
			utils.BOLD_UNDERLINE,
			clusterName,
			utils.RESET,
		)
		return false
	}
	newContent := strings.join(lines, "\n")
	writeSuccess := os.write_entire_file(filePath, transmute([]byte)newContent)
	if !writeSuccess {
		fmt.printfln(
			"Failed to write updated content to file: %s%s%s",
			utils.BOLD_UNDERLINE,
			filePath,
			utils.RESET,
		)
	} else {
		writeSuccess = true
	}
	return writeSuccess
}


//used to fetch a the all data for the passed in record and display it
// fn - collection name, cn - cluster name, rn - record name
OST_FETCH_RECORD :: proc(fn: string, cn: string, rn: string) -> (types.Record, bool) {
	clusterContent: string
	recordContent: string
	collectionPath := utils.concat_collection_name(fn)

	clusterExists := OST_CHECK_IF_CLUSTER_EXISTS(collectionPath, cn)
	if !clusterExists {
		fmt.printfln(
			"Cluster %s%s%s does not exist in collection %s%s%s",
			utils.BOLD_UNDERLINE,
			cn,
			utils.RESET,
			utils.BOLD_UNDERLINE,
			fn,
			utils.RESET,
		)
		return types.Record{}, false
	}


	recordExists := OST_CHECK_IF_RECORD_EXISTS(collectionPath, cn, rn)
	if !recordExists {
		fmt.printfln(
			"Record %s%s%s does not exist in cluster %s%s%s",
			utils.BOLD_UNDERLINE,
			rn,
			utils.RESET,
			utils.BOLD_UNDERLINE,
			cn,
			utils.RESET,
		)
		return types.Record{}, false
	}

	//read the file and find the passed in cluster
	data, readSuccess := os.read_entire_file(collectionPath)
	if !readSuccess {
		utils.throw_err(
			utils.new_err(.CANNOT_READ_FILE, utils.get_err_msg(.CANNOT_READ_FILE), #procedure),
		)
		return types.Record{}, false
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
				// return strings.clone(clusterContent)
			}
		}
	}

	for line in strings.split_lines(clusterContent) {
		if strings.contains(line, rn) {
			return OST_PARSE_RECORD(line), true
		}
	}
	return types.Record{}, false
}

//Used to send records back in 3 parts
OST_PARSE_RECORD :: proc(record: string) -> types.Record {
	recordParts := strings.split(record, ":")
	if len(recordParts) < 2 {
		return types.Record{}
	}
	recordName := strings.trim_space(recordParts[0])
	recordType := strings.trim_space(recordParts[1])
	recordValue := strings.trim_space(recordParts[2])
	return types.Record {
		name = strings.clone(recordName),
		type = strings.clone(recordType),
		value = strings.clone(recordValue),
	}
}

//deletes a arecord from a cluster
OST_ERASE_RECORD :: proc(fn: string, cn: string, rn: string) -> bool {
	using utils
	collection_path := concat_collection_name(fn)
	fmt.printfln(
		"Are you sure that you want to delete Record: %s%s%s?\nThis action can not be undone.",
		utils.BOLD_UNDERLINE,
		rn,
		utils.RESET,
	)
	fmt.printfln("Type 'yes' to confirm or 'no' to cancel.")
	buf: [64]byte
	n, inputSuccess := os.read(os.stdin, buf[:])
	if inputSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_READ_INPUT,
			utils.get_err_msg(.CANNOT_READ_INPUT),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Error reading user input", #procedure)
		return false
	}

	confirmation := strings.trim_right(string(buf[:n]), "\r\n")
	cap := strings.to_upper(confirmation)

	switch cap {
	case const.NO:
		utils.log_runtime_event("User canceled deletion", "User canceled deletion of record")
		return false
	case const.YES:
	// Continue with deletion
	case:
		utils.log_runtime_event(
			"User entered invalid input",
			"User entered invalid input when trying to delete record",
		)
		error2 := utils.new_err(.INVALID_INPUT, utils.get_err_msg(.INVALID_INPUT), #procedure)
		utils.throw_custom_err(error2, "Invalid input. Please type 'yes' or 'no'.")
		return false
	}


	data, readSuccess := utils.read_file(collection_path, #procedure)
	defer delete(data)
	if !readSuccess {
		return false
	}

	content := string(data)
	lines := strings.split(content, "\n")
	newLines := make([dynamic]string)
	defer delete(newLines)

	inTargetCluster := false
	recordFound := false
	isLastRecord := false
	recordCount := 0

	// First pass - count records in target cluster
	for line in lines {
		trimmedLine := strings.trim_space(line)
		if strings.contains(trimmedLine, fmt.tprintf("cluster_name :identifier: %s", cn)) {
			inTargetCluster = true
			continue
		}
		if inTargetCluster {
			if trimmedLine == "}," {
				inTargetCluster = false
				continue
			}
			if len(trimmedLine) > 0 &&
			   !strings.has_prefix(trimmedLine, "cluster_name") &&
			   !strings.has_prefix(trimmedLine, "cluster_id") {
				recordCount += 1
			}
		}
	}

	// Second pass - rebuild content
	inTargetCluster = false
	for line in lines {
		trimmedLine := strings.trim_space(line)

		if strings.contains(trimmedLine, fmt.tprintf("cluster_name :identifier: %s", cn)) {
			inTargetCluster = true
			append(&newLines, line)
			continue
		}

		if inTargetCluster {
			if strings.has_prefix(trimmedLine, fmt.tprintf("%s :", rn)) {
				recordFound = true
				if recordCount == 1 {
					isLastRecord = true
				}
				continue
			}

			if trimmedLine == "}," {
				if !isLastRecord {
					append(&newLines, line)
				} else {
					append(&newLines, "}")
				}
				inTargetCluster = false
				continue
			}
		}

		if !inTargetCluster || !strings.has_prefix(trimmedLine, fmt.tprintf("%s :", rn)) {
			append(&newLines, line)
		}
	}

	if !recordFound {
		return false
	}

	// Write updated content
	newContent := strings.join(newLines[:], "\n")
	writeSuccess := utils.write_to_file(collection_path, transmute([]byte)newContent, #procedure)
	return writeSuccess
}


//used for the history command,
//reads over the passed in collection file and
//the specified cluster and stores the value of each record into the array
OST_PUSH_RECORDS_TO_ARRAY :: proc(cn: string) -> [dynamic]string {
	records: [dynamic]string
	histBuf: [1024]byte

	data, readSuccess := utils.read_file(const.OST_HISTORY_PATH, #procedure)
	defer delete(data)
	if !readSuccess {
		return records
	}

	content := string(data)
	clusters := strings.split(content, "},")

	for cluster, i in clusters {
		if strings.contains(cluster, fmt.tprintf("cluster_name :identifier: %s", cn)) {
			lines := strings.split(cluster, "\n")
			for line, j in lines {
				if strings.contains(line, ":COMMAND:") {
					parts := strings.split(line, ":COMMAND:")
					if len(parts) >= 2 {
						value := strings.trim_space(parts[1])
						append(&records, value)
					}
				}
			}
			break
		}
	}
	return records
}


//reads over the passed in collection file and the specified cluster and returns the number of records in that cluster
//excluding the cluster_name and cluster_id records. potential way of doing this would be to get all of them and just subtract 2
//the isCounting param is set to true if this proc is being called during the COUNT command
OST_COUNT_RECORDS_IN_CLUSTER :: proc(fn, cn: string, isCounting: bool) -> int {
	collectionPath: string
	if isCounting == true {
		collectionPath = fmt.tprintf(
			"%s%s%s",
			const.OST_COLLECTION_PATH,
			fn,
			const.OST_FILE_EXTENSION,
		)
	} else if isCounting == false {
		collectionPath = fmt.tprintf("%s%s%s", const.OST_CORE_PATH, fn, const.OST_FILE_EXTENSION)
		// fmt.printfln(
		// 	"%s procedure is counting records in cluster: %s within collection: %s",
		// 	#procedure,
		// 	cn,
		// 	fn,
		// ) //debugging
	}

	data, readSuccess := utils.read_file(collectionPath, #procedure)
	if !readSuccess {
		return -1
	}
	defer delete(data)

	content := string(data)
	clusters := strings.split(content, "},")
	// fmt.printfln("clusters: %s", clusters) //debugging
	for cluster in clusters {
		if strings.contains(cluster, fmt.tprintf("cluster_name :identifier: %s", cn)) {
			lines := strings.split(cluster, "\n")
			recordCount := 0

			for line in lines {
				// fmt.printfln("line: %s", line) //debugging
				trimmedLine := strings.trim_space(line)
				if len(trimmedLine) > 0 &&
				   !strings.has_prefix(trimmedLine, "cluster_name") &&
				   !strings.has_prefix(trimmedLine, "cluster_id") &&
				   !strings.contains(trimmedLine, "#") &&
				   !strings.contains(trimmedLine, const.METADATA_START) &&
				   !strings.contains(trimmedLine, const.METADATA_END) &&
				   strings.contains(trimmedLine, ":") {
					// fmt.printfln("trimmedLine: %s", trimmedLine) //debugging
					recordCount += 1
				}
			}
			// fmt.printfln("Record count: %d", recordCount) //debugging
			return recordCount
		}
	}
	fmt.printfln(
		"Cluster %s%s%s not found in collection %s%s%s",
		utils.BOLD_UNDERLINE,
		cn,
		utils.RESET,
		utils.BOLD_UNDERLINE,
		fn,
		utils.RESET,
	)
	return -1
}

//reads over the passed in collection file and returns the number of records in that collection
OST_COUNT_RECORDS_IN_COLLECTION :: proc(fn: string) -> int {
	collectionPath := utils.concat_collection_name(fn)
	data, readSuccess := utils.read_file(collectionPath, #procedure)
	if !readSuccess {
		return -1
	}
	defer delete(data)

	content := string(data)
	clusters := strings.split(content, "},")
	recordCount := 0
	for cluster in clusters {
		if !strings.contains(cluster, "cluster_name :identifier:") {
			continue // Skip non-cluster content
		}
		lines := strings.split(cluster, "\n")
		for line in lines {
			trimmedLine := strings.trim_space(line)
			if len(trimmedLine) > 0 &&
			   !strings.has_prefix(trimmedLine, "cluster_name") &&
			   !strings.has_prefix(trimmedLine, "cluster_id") &&
			   strings.contains(trimmedLine, ":") &&
			   !strings.contains(trimmedLine, const.METADATA_START) &&
			   !strings.contains(trimmedLine, const.METADATA_END) {
				recordCount += 1
			}
		}
	}

	return recordCount
}

//deletes the data value of the passed in record but keeps the name and type
OST_PURGE_RECORD :: proc(fn, cn, rn: string) -> bool {
	collection_path := utils.concat_collection_name(fn)
	// Read the entire file
	data, readSuccess := utils.read_file(collection_path, #procedure)
	if !readSuccess {
		return false
	}
	defer delete(data)

	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)

	newLines := make([dynamic]string)
	defer delete(newLines)

	inTargetCluster := false
	recordPurged := false

	for line in lines {
		trimmedLine := strings.trim_space(line)

		if trimmedLine == "{" {
			inTargetCluster = false
		}

		if strings.contains(trimmedLine, fmt.tprintf("cluster_name :identifier: %s", cn)) {
			inTargetCluster = true
		}

		if inTargetCluster && strings.contains(trimmedLine, fmt.tprintf("%s :", rn)) {
			parts := strings.split(trimmedLine, ":")
			if len(parts) >= 3 {
				// Keep the record name and type, but remove the value
				// Maintain the original indentation and spacing
				leadingWhitespace := strings.split(line, rn)[0]
				newLine := fmt.tprintf(
					"%s%s :%s:",
					leadingWhitespace,
					strings.trim_space(parts[0]),
					strings.trim_space(parts[1]),
				)
				append(&newLines, newLine)
				recordPurged = true
			} else {
				append(&newLines, line)
			}
		} else {
			append(&newLines, line)
		}

		if inTargetCluster && trimmedLine == "}," {
			inTargetCluster = false
		}
	}

	if !recordPurged {
		fmt.printfln(
			"Record %s%s%s not found in cluster %s%s%s",
			utils.BOLD_UNDERLINE,
			rn,
			utils.RESET,
			utils.BOLD_UNDERLINE,
			cn,
			utils.RESET,
		)
		return false
	}

	newContent := strings.join(newLines[:], "\n")
	writeSuccess := utils.write_to_file(collection_path, transmute([]byte)newContent, #procedure)
	return writeSuccess
}

OST_GET_RECORD_SIZE :: proc(
	collection_name: string,
	cluster_name: string,
	record_name: string,
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
	data, read_success := utils.read_file(collection_path, #procedure)
	if !read_success {
		return 0, false
	}
	defer delete(data)

	content := string(data)
	clusters := strings.split(content, "},")

	for cluster in clusters {
		if strings.contains(cluster, fmt.tprintf("cluster_name :identifier: %s", cluster_name)) {
			lines := strings.split(cluster, "\n")
			for line in lines {
				parts := strings.split(line, ":")
				if strings.has_prefix(line, fmt.tprintf("\t%s", record_name)) {
					//added the \t to the prefix because all records are indented in the plain text collection file - Marshall Burns Jan 2025
					parts := strings.split(line, ":")
					if len(parts) == 3 {
						record_value := strings.trim_space(strings.join(parts[2:], ":"))
						return len(record_value), true
					}
				}
			}
		}
	}
	return 0, false
}


OST_COUNT_RECORDS_IN_HISTORY_CLUSTER :: proc(username: string) -> int {
	data, readSuccess := utils.read_file(const.OST_HISTORY_PATH, #procedure)
	if !readSuccess {
		return -1
	}
	defer delete(data)

	content := string(data)
	clusters := strings.split(content, "},")

	for cluster in clusters {
		if strings.contains(cluster, fmt.tprintf("cluster_name :identifier: %s", username)) {
			lines := strings.split(cluster, "\n")
			recordCount := 0

			for line in lines {
				trimmedLine := strings.trim_space(line)
				if len(trimmedLine) > 0 &&
				   !strings.has_prefix(trimmedLine, "cluster_name") &&
				   !strings.has_prefix(trimmedLine, "cluster_id") &&
				   strings.contains(trimmedLine, ":") {
					recordCount += 1
				}
			}
			return recordCount
		}
	}
	return -1
}


//todo: finish this for normal collection records after done with user records
// OST_SCAN_FOR_RECORD_VALUE :: proc(rv: string) -> (string, bool) {}

// See issue #https://github.com/Solitude-Software-Solutions/OstrichDB/issues/214
// To store user input values into OstrichDB, the values need to be formatted as its string representation.
// So when trying to work on adding []DATE, []TIME, []DATETIME, etc; to OstrichDB, I ran into
// a problem where I could not store the values of those types in a [dynamic]string array. Because those values
// //will always be within qoutations thus the stored value in a record would look like this:
// Student_DOB :[]DATE: ["2022-01-01", "2022-01-02", "2022-01-03"]
// es no bueno

//This proc looks for the passed in records array value and depending on the record type will format that value
//If the type is a []CHAR then remove the double qoutes and replace them with single qoutes
//if []DATE, []TIME, []DATETIME then remove the qoutes and replace them with nothing
OST_MODIFY_ARRAY_VALUES :: proc(fn, cn, rn, rType: string) -> (string, bool) {
	// Get the current record value
	recordValue := OST_READ_RECORD_VALUE(fn, cn, rType, rn)
	if recordValue == "" {
		return "", false
	}

	// Remove the outer brackets
	value := strings.trim_space(recordValue)
	if !strings.has_prefix(value, "[") || !strings.has_suffix(value, "]") {
		return "", false
	}
	value = value[1:len(value) - 1]

	// Split the array elements
	elements := strings.split(value, ",")
	defer delete(elements)

	// Create a new array to store modified values
	modifiedElements := make([dynamic]string)
	defer delete(modifiedElements)

	// Process each element based on type
	for element in elements {
		element := strings.trim_space(element)

		switch rType {
		case const.CHAR_ARRAY:
			// Replace double quotes with single quotes
			if strings.has_prefix(element, "\"") && strings.has_suffix(element, "\"") {
				element = fmt.tprintf("'%s'", element[1:len(element) - 1])
			}
		case const.DATE_ARRAY, const.TIME_ARRAY, const.DATETIME_ARRAY:
			// Remove quotes entirely
			if strings.has_prefix(element, "\"") && strings.has_suffix(element, "\"") {
				element = element[1:len(element) - 1]
			}
		}
		append(&modifiedElements, element)
	}

	// Join the modified elements back into an array string
	result := fmt.tprintf("[%s]", strings.join(modifiedElements[:], ", "))

	// Update the record with the modified value
	success := OST_UPDATE_RECORD_IN_FILE(fn, cn, rn, result)

	return result, success
}
