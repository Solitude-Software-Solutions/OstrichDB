package data

import "../../../utils"
import "../../const"
import "../../types"
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
					// fmt.println("Record found:", line)
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
	utils.throw_err(error2)
	fmt.println("Specified cluster not found")
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
			"Record: %s%s%s already exists within Collection: %s%s%s -> Cluster: %s%s%s",
			utils.BOLD,
			rn,
			utils.RESET,
			utils.BOLD,
			fn,
			utils.RESET,
			utils.BOLD,
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
		return ""
	}

	type := fmt.tprintf(":%s:", rType)
	// Check if the record exists within the cluster
	for i in cluster_start ..= closing_brace {
		if strings.contains(lines[i], rn) {
			record := strings.split(lines[i], type)
			if len(record) > 1 {
				return strings.trim_space(record[1])
			}
			return ""
		}
	}

	return ""
}

//here is where the type that the user enters in their command is passed
OST_SET_RECORD_TYPE :: proc(rType: string) -> (string, int) {
	for type in const.VALID_RECORD_TYPES {
		if rType == type {
			record.type = rType
			return record.type, 0
		}
	}

	fmt.printfln("Invalid record type %s", rType)
	return record.type, 1
}


OST_SET_RECORD_NAME :: proc(rn: string) -> (string, int) {
	if len(rn) > 256 {
		fmt.println("The Entered Record Name is too long. Please try again.")
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
		utils.BOLD,
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
	}


	collectionName := strings.trim_right(string(buf[:n]), "\r\n")
	collectionNameUpper := strings.to_upper(collectionName)
	collectionExists := OST_CHECK_IF_COLLECTION_EXISTS(collectionNameUpper, 0)
	fmt.printfln(
		"Select the cluster that you would like to store the record: %s%s%s in.",
		utils.BOLD,
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
								"Collection: %s | Cluster Name: %s",
								colNameNoExt,
								clusterName,
							)
							fmt.printfln(
								"Record Type: %s | Record Data: %s",
								recordType,
								recordData,
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


OST_RENAME_RECORD :: proc(old: string, new: string) -> (result: int) {
	OST_FETCH_EVERY_RECORD_BY_NAME(old)
	buf := make([]byte, 1024)
	defer delete(buf)
	fn, cn: string


	fmt.printfln(
		"Enter the name of the collection that contains the record: %s%s%s that you would like to rename.",
		utils.BOLD,
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
			"A record named: %s. Already exists within cluster:%s Please try again.",
			old,
			cn,
		)
		return -1
	case false:
		data, readSuccess := os.read_entire_file(collectionPath)
		if !readSuccess {
			utils.throw_err(
				utils.new_err(.CANNOT_READ_FILE, utils.get_err_msg(.CANNOT_READ_FILE), #procedure),
			)
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
			fmt.printfln("Record '%s' not found in cluster '%s' ,collection %s", old, cn, fn)
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
			result = 0
		}
		break
	}

	return result


}
