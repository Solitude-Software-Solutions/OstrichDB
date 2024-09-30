package data

import "../../../utils"
import "../../const"
import "../../types"
import "./metadata"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//

record: types.Record


//can be used to check if a single record exists within a cluster
OST_CHECK_IF_RECORD_EXISTS :: proc(fn: string, cn: string, rn: string) -> bool {
	using const
	data, readSuccess := os.read_entire_file(fn)
	if !readSuccess {
		error1 := utils.new_err(
			.CANNOT_READ_FILE,
			utils.get_err_msg(.CANNOT_READ_FILE),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Could not real collection file", #procedure)
		return false
	}
	defer delete(data)

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
//fn-filename, cn-clustername,id-cluster id, rn-record name, rd-record data
OST_APPEND_RECORD_TO_CLUSTER :: proc(
	fn: string,
	cn: string,
	rn: string,
	rd: string,
	rType: string,
	ID: ..i64,
) -> int {
	data, readSuccess := os.read_entire_file(fn)
	if !readSuccess {
		error1 := utils.new_err(
			.CANNOT_READ_FILE,
			utils.get_err_msg(.CANNOT_READ_FILE),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Could not read collection file", #procedure)
		return -1
	}
	defer delete(data)

	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)

	cluster_start := -1
	closing_brace := -1

	// Find the cluster and its closing brace
	for i := 0; i < len(lines); i += 1 {
		if strings.contains(lines[i], cn) {
			cluster_start = i
		}
		if cluster_start != -1 && strings.contains(lines[i], "}") {
			closing_brace = i
			break
		}
	}

	//check if the record name already exists if it does return
	recordExists := OST_CHECK_IF_RECORD_EXISTS(fn, cn, rn)
	if recordExists == true {
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
	if cluster_start == -1 || closing_brace == -1 {
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
	copy(new_lines[:closing_brace], lines[:closing_brace])
	new_lines[closing_brace] = new_line
	new_lines[closing_brace + 1] = "},"
	if closing_brace + 1 < len(lines) {
		copy(new_lines[closing_brace + 2:], lines[closing_brace + 1:])
	}

	new_content := strings.join(new_lines[:], "\n")
	writeSuccess := os.write_entire_file(fn, transmute([]byte)new_content)
	if writeSuccess != true {
		error3 := utils.new_err(
			.CANNOT_WRITE_TO_FILE,
			utils.get_err_msg(.CANNOT_WRITE_TO_FILE),
			#procedure,
		)
		utils.throw_err(error3)
		utils.log_err("Could not write to collection file", #procedure)
		return -1
	}


	return 0
}

// // get the value from the right side of a key value
OST_READ_RECORD_VALUE :: proc(fn: string, cn: string, rType: string, rn: string) -> string {
	data, readSuccess := os.read_entire_file(fn)
	if !readSuccess {
		error1 := utils.new_err(
			.CANNOT_READ_FILE,
			utils.get_err_msg(.CANNOT_READ_FILE),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Could not read collection file", #procedure)
		return ""
	}
	defer delete(data)

	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)

	cluster_start := -1
	closing_brace := -1

	// Find the cluster and its closing brace
	for line, i in lines {
		if strings.contains(line, cn) {
			cluster_start = i
		}
		if cluster_start != -1 && strings.contains(line, "}") {
			closing_brace = i
			break
		}
	}

	// If the cluster is not found or the structure is invalid, return an empty string
	if cluster_start == -1 || closing_brace == -1 {
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
	// Check if the record exists within the cluster
	for i in cluster_start ..= closing_brace {
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


//set the record name, if the name is too long, return an error
OST_SET_RECORD_NAME :: proc(rn: string) -> (string, int) {
	if len(rn) > 256 {
		fmt.println("The entered record name is too long. Please try again.")
		return "", 1
	}

	record.name = rn
	return record.name, 0
}


//Present user with prompt on where to save the record
OST_CHOOSE_RECORD_LOCATION :: proc(rName: string, rType: string) -> (col: string, clu: string) {
	buf := make([]byte, 1024)
	defer delete(buf)

	fmt.printfln(
		"Select the collection that you would like to store the record: %s%s%s in.",
		utils.BOLD_UNDERLINE,
		rName,
		utils.RESET,
	)

	n, colNameSuccess := os.read(os.stdin, buf)
	if colNameSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_READ_INPUT,
			utils.get_err_msg(.CANNOT_READ_INPUT),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Could not read user input for collection name", #procedure)
	}


	collectionName := strings.trim_right(string(buf[:n]), "\r\n")
	collectionNameUpper := strings.to_upper(collectionName)
	collectionExists := OST_CHECK_IF_COLLECTION_EXISTS(collectionNameUpper, 0)
	fmt.printfln(
		"Select the cluster that you would like to store the record: %s%s%s in.",
		utils.BOLD_UNDERLINE,
		rName,
		utils.RESET,
	)

	switch collectionExists {
	case true:
		col = collectionNameUpper
		break
	case false:
		fmt.printfln("Could not find collection: %s. Please try again", collectionNameUpper)
		OST_CHOOSE_RECORD_LOCATION(rName, rType)
	}

	checks := OST_HANDLE_INTGRITY_CHECK_RESULT(collectionNameUpper)
	switch (checks) 
	{
	case -1:
		return "", ""
	}

	nn, cluNameSuccess := os.read(os.stdin, buf)
	if cluNameSuccess != 0 {
		error2 := utils.new_err(
			.CANNOT_READ_INPUT,
			utils.get_err_msg(.CANNOT_READ_INPUT),
			#procedure,
		)
		utils.throw_err(error2)
		utils.log_err("Could not read user input for cluster name", #procedure)
	}

	cluster := strings.trim_right(string(buf[:nn]), "\r\n")
	cluster = strings.to_upper(cluster)
	collectionPath := fmt.tprintf(
		"%s%s%s",
		const.OST_COLLECTION_PATH,
		collectionNameUpper,
		const.OST_FILE_EXTENSION,
	)
	clusterExists := OST_CHECK_IF_CLUSTER_EXISTS(collectionPath, cluster)

	switch clusterExists {
	case true:
		clu = cluster
		break
	case false:
		fmt.printfln("Could not find cluster: %s. Please try again", cluster)
		OST_CHOOSE_RECORD_LOCATION(rName, rType)
	}


	return col, clu
}
//gets every record of the passed in rName and returns the record type, the records data, the cluster it is in, and the collection it is in
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
				name_start := strings.index(cluster, "cluster_name :identifier:")
				if name_start == -1 do continue
				name_start += len("cluster_name :identifier:")
				name_end := strings.index(cluster[name_start:], "\n")
				if name_end == -1 do continue
				clusterName = strings.trim_space(cluster[name_start:][:name_end])

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
OST_RENAME_RECORD :: proc(old: string, new: string) -> (result: int) {
	OST_FETCH_EVERY_RECORD_BY_NAME(old)
	buf := make([]byte, 1024)
	defer delete(buf)
	fn, cn: string

	fmt.printfln(
		"Enter the name of the collection that contains the record: %s%s%s that you would like to rename.",
		utils.BOLD_UNDERLINE,
		old,
		utils.RESET,
	)

	col, colInputSuccess := os.read(os.stdin, buf)
	if colInputSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_READ_INPUT,
			utils.get_err_msg(.CANNOT_READ_INPUT),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Could not read user input for collection name", #procedure)
	}
	fn = strings.trim_right(string(buf[:col]), "\r\n")
	fn = strings.to_upper(fn)

	if !OST_CHECK_IF_COLLECTION_EXISTS(fn, 0) {
		fmt.printfln("Collection with name:%s%s%s does not exist", utils.BOLD, cn, utils.RESET)
		fmt.println("Please try again with a different name")
		return -1
	}

	collectionPath := fmt.tprintf(
		"%s%s%s",
		const.OST_COLLECTION_PATH,
		fn,
		const.OST_FILE_EXTENSION,
	)


	checks := OST_HANDLE_INTGRITY_CHECK_RESULT(fn)
	switch (checks) 
	{
	case -1:
		return -1
	}

	fmt.printfln(
		"Enter the name of the cluster that contains the record: %s%s%s that you would like to rename.",
		utils.BOLD,
		old,
		utils.RESET,
	)

	buf = make([]byte, 1024)
	clu, cluInputSuccess := os.read(os.stdin, buf)
	if cluInputSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_READ_INPUT,
			utils.get_err_msg(.CANNOT_READ_INPUT),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Could not read user input for cluster name", #procedure)
	}
	cn = strings.trim_right(string(buf[:clu]), "\r\n")
	cn = strings.to_upper(cn)


	if !OST_CHECK_IF_CLUSTER_EXISTS(collectionPath, cn) {
		fmt.printfln("Cluster with name:%s%s%s does not exist", utils.BOLD, cn, utils.RESET)
		fmt.println("Please try again with a different name")
		return -1
	}


	rExists := OST_CHECK_IF_RECORD_EXISTS(
		strings.to_upper(fn),
		strings.to_upper(cn),
		strings.to_upper(new),
	)

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
				append(&newContent, ..newCluster[:])
				append(&newContent, "}")
				append(&newContent, ",\n\n")
			} else if len(cluster) > 0 {
				// Keep other clusters unchanged
				append(&newContent, ..transmute([]u8)cluster)
				append(&newContent, "}")
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

OST_GET_DATABASE_TREE :: proc() {
	OST_GET_ALL_COLLECTION_NAMES(true)
	// output data size
	fmt.printfln("Size of data: %dB", metadata.OST_GET_FS(const.OST_COLLECTION_PATH).size)
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
			case:
				record.type = rType
				break
			}
			return record.type, 0
		}
	}
	fmt.printfln("Invalid record type %s%s%s", utils.BOLD_UNDERLINE, rType, utils.RESET)
	return strings.clone(record.type), 1
}


//finds the location of the passed in record in the passed in cluster
OST_FIND_RECORD_IN_CLUSTER :: proc(
	collectionName: string,
	clusterName: string,
	recordName: string,
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

//reads over a collection file looking for the passed in record and returns the record type
OST_GET_RECORD_TYPE :: proc(
	collection_name: string,
	record_name: string,
) -> (
	recordType: string,
	success: bool,
) {

	success = false
	recordType = ""

	collection_file := fmt.tprintf(
		"%s%s%s",
		const.OST_COLLECTION_PATH,
		strings.to_upper(collection_name),
		const.OST_FILE_EXTENSION,
	)

	data, read_success := os.read_entire_file(collection_file)
	if !read_success {
		fmt.println("Failed to read collection file:", collection_file)
		return strings.clone(recordType), success
	}

	lines := strings.split(string(data), "\n")

	for line in lines {
		line := strings.trim_space(line)
		if strings.has_prefix(line, record_name) {
			parts := strings.split(line, ":")
			if len(parts) >= 2 {
				recordType = strings.trim_space(parts[1])
				success = true
				return strings.clone(recordType), success
			}
		}
	}

	fmt.println("Record not found:", record_name)
	return strings.clone(recordType), success
}

//The following conversion funcs are used to convert the passed in record value to the correct data type
//Originally these where all in one single proce but that was breaking shit.
OST_CONVERT_RECORD_TO_INT :: proc(rValue: string) -> (int, bool) {
	val, ok := strconv.parse_int(rValue)
	if ok {
		return val, true
	} else {
		fmt.printfln("Failed to parse int")
		return 0, false
	}
}

OST_CONVERT_RECORD_TO_FLOAT :: proc(rValue: string) -> (f64, bool) {
	val, ok := strconv.parse_f64(rValue)
	if ok {
		return val, true
	} else {
		fmt.printfln("Failed to parse float")
		return 0.0, false
	}
}

OST_CONVERT_RECORD_TO_BOOL :: proc(rValue: string) -> (bool, bool) {
	lower_str := strings.to_lower(strings.trim_space(rValue))
	if lower_str == "true" {
		return true, true
	} else if lower_str == "false" {
		return false, true
	} else {
		//no need to do anything other than return here. Once false is returned error handling system will do its thing
		return false, false
	}
}

//reads over each file in the collections dir and looks for the record with the passed in name then returns the name of the collection and cluster that contains that record.
OST_SCAN_COLLECTIONS_FOR_RECORD :: proc(
	rName: string,
) -> (
	colNames: []string,
	cluNames: []string,
) {
	collections := make([dynamic]string)
	clusters := make([dynamic]string)

	colDir, openDirSuccess := os.open(const.OST_COLLECTION_PATH)

	// err: os.Errno
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
	fmt.printfln("Clusters: %s", clusters[:])
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

//This beefy procecure takes the input value from the SET command and assigns it to the record
OST_SET_RECORD_VALUE :: proc(rn: string, rValue: string) -> (fn: string, success: bool) {
	success = true
	colNameBuf := make([]byte, 1024)
	defer delete(colNameBuf)

	collectionMatch, clusterMatch := OST_SCAN_COLLECTIONS_FOR_RECORD(rn)
	switch len(collectionMatch) {
	case 0:
		fmt.println("Record not found")
		success = false
		return
	case 1:
		fmt.printfln(
			"%s1%s instance of record: %s%s%s Found.\n--------------------------------",
			utils.BOLD_UNDERLINE,
			utils.RESET,
			utils.BOLD_UNDERLINE,
			rn,
			utils.RESET,
		)
		fmt.printfln("%v\t\n|\n|_________%v", collectionMatch[0], clusterMatch[0])
		fmt.printf("\n")
		fmt.printf("\n")
	case:
		fmt.printfln(
			"%s%d%s instances of record: %s%s%s Found\n--------------------------------",
			utils.BOLD_UNDERLINE,
			len(collectionMatch),
			utils.RESET,
			utils.BOLD_UNDERLINE,
			rn,
			utils.RESET,
		)

		currentCollection := collectionMatch[0]
		fmt.printf("%s\t\n", currentCollection)
		fmt.println("|")

		for i := 0; i < len(collectionMatch); i += 1 {
			if collectionMatch[i] != currentCollection {
				fmt.printf("\n\n")
				currentCollection = collectionMatch[i]
				fmt.printf("%s\t\n", currentCollection)
				fmt.println("|")
			}

			if i == len(collectionMatch) - 1 || collectionMatch[i] != collectionMatch[i + 1] {
				fmt.printf("|_________%s\n", clusterMatch[i])
			} else {
				fmt.printf("|_________%s\n|\n", clusterMatch[i])
			}
		}
		fmt.printf("\n")
		fmt.printf("\n")
	}

	fmt.printfln(
		"Enter the name of the %sCOLLECTION%s that contains the record you'd like to SET the value of.",
		utils.BOLD,
		utils.RESET,
	)
	colInput, colNameSuccess := os.read(os.stdin, colNameBuf)
	if colNameSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_READ_INPUT,
			utils.get_err_msg(.CANNOT_READ_INPUT),
			#procedure,
		)
		utils.throw_err(error1)
		success = false
		return
	}
	collectionName := strings.trim_right(string(colNameBuf[:colInput]), "\r\n")
	collectionNameUpper := strings.to_upper(collectionName)
	collectionFile := fmt.tprintf(
		"%s%s%s",
		const.OST_COLLECTION_PATH,
		collectionNameUpper,
		const.OST_FILE_EXTENSION,
	)


	// Read the collection file
	data, readSuccess := os.read_entire_file(collectionFile)
	if !readSuccess {
		fmt.println("Failed to read collection file:", collectionFile)
		success = false
		return
	}
	defer delete(data)

	// Find clusters in the selected collection
	clustersInCollection := OST_FIND_RECORD_MATCHES_IN_CLUSTERS(string(data), rn)

	if len(clustersInCollection) == 0 {
		fmt.println("No matching clusters found in the selected collection.")
		success = false
		return
	}

	//NEw buffer because IDK how to free in Odin lang - SchoolyB
	cluNameBuf := make([]byte, 1024)
	defer delete(cluNameBuf)

	fmt.printfln(
		"\nEnter the name of the %sCLUSTER%s that contains the record you'd like to SET the value of:",
		utils.BOLD,
		utils.RESET,
	)
	cluInput, cluNameSuccess := os.read(os.stdin, cluNameBuf)
	if cluNameSuccess != 0 {
		error2 := utils.new_err(
			.CANNOT_READ_INPUT,
			utils.get_err_msg(.CANNOT_READ_INPUT),
			#procedure,
		)
		utils.throw_err(error2)
		success = false
		return
	}
	clusterName := strings.trim_right(string(cluNameBuf[:cluInput]), "\r\n")

	// look for the record in the file
	record, type, found := OST_FIND_RECORD_IN_CLUSTER(collectionNameUpper, clusterName, rn)
	if !found {
		fmt.printfln("Record not found: %s%s%s", utils.BOLD_UNDERLINE, rn, utils.RESET)
		success = false
		return
	}

	setType, setSuccess := OST_SET_RECORD_TYPE(type)
	if setSuccess == 1 {
		fmt.printfln("Invalid record type: %s%s%s", utils.BOLD_UNDERLINE, type, utils.RESET)
		return
	}

	valueAny: any = 0
	ok: bool
	switch setType {
	case const.INTEGER:
		valueAny, ok = OST_CONVERT_RECORD_TO_INT(rValue)
		break
	case const.FLOAT:
		valueAny, ok = OST_CONVERT_RECORD_TO_FLOAT(rValue)
		break
	case const.BOOLEAN:
		valueAny, ok = OST_CONVERT_RECORD_TO_BOOL(rValue)
		break
	case const.STRING:
		valueAny = rValue
		ok = true
		break
	}

	if ok != true {
		valueTypeError := utils.new_err(
			.INVALID_VALUE_FOR_EXPECTED_TYPE,
			utils.get_err_msg(.INVALID_VALUE_FOR_EXPECTED_TYPE),
			#procedure,
		)
		utils.throw_custom_err(
			valueTypeError,
			fmt.tprintf(
				"%sInvalid value given. Expected a value of type: %s%s%s",
				utils.BOLD_UNDERLINE,
				record.type,
				utils.RESET,
			),
		)
		utils.log_err(
			"User entered a value of a different type than what was expected.",
			#procedure,
		)
		success = false
		return
	}

	// Update the record in the file
	success = OST_UPDATE_RECORD_IN_FILE(collectionFile, clusterName, rn, valueAny)
	if success {
		fmt.printfln(
			"Successfully set %s%s%s to %s%v%s",
			utils.BOLD_UNDERLINE,
			rn,
			utils.RESET,
			utils.BOLD_UNDERLINE,
			valueAny,
			utils.RESET,
		)
	} else {
		fmt.printfln(
			"Failed to update record %s%s%s in file",
			utils.BOLD_UNDERLINE,
			rn,
			utils.RESET,
		)
	}

	return collectionNameUpper, success

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
					"%s%s:%s:%v",
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
	if writeSuccess {
		fmt.printfln(
			"Successfully updated record %s%s%s in cluster %s%s%s",
			utils.BOLD_UNDERLINE,
			recordName,
			utils.RESET,
			utils.BOLD_UNDERLINE,
			clusterName,
			utils.RESET,
		)
	} else {
		fmt.printfln(
			"Failed to write updated content to file: %s%s%s",
			utils.BOLD_UNDERLINE,
			filePath,
			utils.RESET,
		)
		return false
	}
	return writeSuccess
}
