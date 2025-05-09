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

Contributors:
    @CobbCoding1

License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            Contains logic for handling records, including creating,
            deleting, and fetching records within clusters.
*********************************************************/

record: types.Record


//can be used to check if a single record exists within the passed in cluster of the passed in collection
CHECK_IF_SPECIFIC_RECORD_EXISTS :: proc(fn, cn, rn: string) -> bool {
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

	errorLocation:= utils.get_caller_location()
	// If we've gone through all clusters and didn't find the specified cluster
	error2 := utils.new_err(
		.CANNOT_FIND_CLUSTER,
		utils.get_err_msg(.CANNOT_FIND_CLUSTER),
		errorLocation
	)
	utils.throw_custom_err(error2, fmt.tprintf("Specified cluster not found: %s", cn))
	utils.log_err("Specified cluster not found", #procedure)
	return false
}


//appends a line to the end of a cluster with the data thats passed in
//fn-filename, cn-clustername,id-cluster id, rn-record name, rd-record data
CREATE_RECORD :: proc(fn, cn, rn, rd, rType: string, ID: ..i64) -> int {
	data, readSuccess := utils.read_file(fn, #procedure)
	defer delete(data)
	if !readSuccess {
		return -1
	}
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
	recordExists := CHECK_IF_SPECIFIC_RECORD_EXISTS(fn, cn, rn)
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
	errorLocation:= utils.get_caller_location()
		error2 := utils.new_err(
			.CANNOT_FIND_CLUSTER,
			utils.get_err_msg(.CANNOT_FIND_CLUSTER),
			errorLocation
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


//Same as the CREATE_RECORD() proc above but without the check, becuase the check breaks shit
CREATE_AND_APPEND_PRIVATE_RECORD :: proc(fn, cn, rn, rd, rType: string, ID: ..i64) -> int {
	data, readSuccess := utils.read_file(fn, #procedure)
	defer delete(data)
	if !readSuccess {
		return -1
	}

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
	errorLocation:= utils.get_caller_location()
		error2 := utils.new_err(
			.CANNOT_FIND_CLUSTER,
			utils.get_err_msg(.CANNOT_FIND_CLUSTER),
			errorLocation
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
GET_RECORD_VALUE :: proc(fn, cn, rType, rn: string) -> string {
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
	errorLocation:= utils.get_caller_location()
		error2 := utils.new_err(
			.CANNOT_FIND_CLUSTER,
			utils.get_err_msg(.CANNOT_FIND_CLUSTER),
			errorLocation
		)
		utils.throw_err(error2)
		utils.log_err("Unable to find cluster/valid structure", #procedure)
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
FIND_ALL_RECORDS_BY_NAME :: proc(rName: string) -> [dynamic]string {
	allRecords := make([dynamic]string)
	defer delete(allRecords)
	clusterName: string
	recordType: string
	recordData: string

	collectionDir, openDirSuccess := os.open(const.STANDARD_COLLECTION_PATH)
	collections, readDirSuccess := os.read_dir(collectionDir, -1) //might not be -1

	for collection in collections {
		colPath := fmt.tprintf("%s%s", const.STANDARD_COLLECTION_PATH, collection.name)
		data, collectionReadSuccess := os.read_entire_file(colPath)
		defer delete(data)
		content := string(data)

		colNameNoExt := strings.trim_right(collection.name, const.OST_EXT)
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
RENAME_RECORD :: proc(fn, cn, old, new: string) -> (result: int) {

	if !CHECK_IF_COLLECTION_EXISTS(fn, 0) {
		fmt.printfln("Collection with name:%s%s%s does not exist", utils.BOLD, fn, utils.RESET)
		fmt.println("Please try again with a different name")
		return -1
	}

	collectionPath := utils.concat_standard_collection_name(fn)


	if !CHECK_IF_CLUSTER_EXISTS(collectionPath, cn) {
		fmt.printfln("Cluster with name:%s%s%s does not exist", utils.BOLD, cn, utils.RESET)
		return -1
	}

	rExists := CHECK_IF_SPECIFIC_RECORD_EXISTS(collectionPath, cn, new)

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
		errorLocation:= utils.get_caller_location()
			utils.throw_err(
				utils.new_err(
					.CANNOT_READ_FILE,
					utils.get_err_msg(.CANNOT_READ_FILE),
					errorLocation
				),
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
		errorLocation:= utils.get_caller_location()
			utils.throw_err(
				utils.new_err(
					.CANNOT_WRITE_TO_FILE,
					utils.get_err_msg(.CANNOT_WRITE_TO_FILE),
					errorLocation
				),
			)
			utils.log_err("Could not write to file", #procedure)
			result = 0
		}
		break
	}

	return result
}


//Ensure the passed in type is valid. if a valid shorthand type is provided via the command line,
//then the 'longhand' value is assigned, then returned
SET_RECORD_TYPE :: proc(rType: string) -> (string, int) {
	using types
	using const

	for type in VALID_RECORD_TYPES {
		if rType == type {
			switch (rType)
			{ 	//The first 8 cases handle if the type is shorthand
			case Token[.STR]:
				record.type = Token[.STRING]
				break
			case Token[.INT]:
				record.type = Token[.INTEGER]
				break
			case Token[.FLT]:
				record.type = Token[.FLOAT]
				break
			case Token[.BOOL]:
				record.type = Token[.BOOLEAN]
				break
			case Token[.STR_ARRAY]:
				record.type = Token[.STRING_ARRAY]
				break
			case Token[.INT_ARRAY]:
				record.type = Token[.INTEGER_ARRAY]
				break
			case Token[.FLT_ARRAY]:
				record.type = Token[.FLOAT_ARRAY]
				break
			case Token[.BOOL_ARRAY]:
				record.type = Token[.BOOLEAN_ARRAY]
				break
			case:
				//The defualt case just sets the variable to the value so long as its valid
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
CHANGE_RECORD_TYPE :: proc(fn, cn, rn, rd, newType: string) -> bool {
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


//Returns the data type of the passed in record
GET_RECORD_TYPE :: proc(fn, cn, rn: string) -> (recordType: string, success: bool) {
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
SCAN_COLLECTION_FOR_RECORD :: proc(
	collectionName, recordName: string,
) -> (
	colName: string,
	cluName: string,
	success: bool,
) {
	collectionPath := fmt.tprintf("%s%s", const.STANDARD_COLLECTION_PATH, collectionName)

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


//Used to set a records value for the first time.
SET_RECORD_VALUE :: proc(file, cn, rn, rValue: string) -> bool {
	using const

	result := CHECK_IF_SPECIFIC_RECORD_EXISTS(file, cn, rn)

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

	recordType, getTypeSuccess := GET_RECORD_TYPE(file, cn, rn)
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
	case types.Token[.INTEGER]:
		record.type = recordType
		valueAny, ok = CONVERT_RECORD_TO_INT(rValue)
		setValueOk = ok
		break
	case types.Token[.FLOAT]:
		record.type = recordType
		valueAny, ok = CONVERT_RECORD_TO_FLOAT(rValue)
		setValueOk = ok
		break
	case types.Token[.BOOLEAN]:
		record.type = recordType
		valueAny, ok = CONVERT_RECORD_TO_BOOL(rValue)
		setValueOk = ok
		break
	case types.Token[.STRING]:
		record.type = recordType
		valueAny = utils.append_qoutations(rValue)
		setValueOk = true
		break
	case types.Token[.CHAR]:
		record.type = recordType
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
	case types.Token[.INTEGER_ARRAY]:
		record.type = recordType
		verifiedValue := VERIFY_ARRAY_VALUES(types.Token[.INTEGER_ARRAY], rValue)
		if !verifiedValue {
			fmt.printfln(
				"Invalid value given. Must be an array of Type: %sINTEGER%s",
				utils.BOLD_UNDERLINE,
				utils.RESET,
			)
			return false
		}
		intArrayValue, ok := CONVERT_RECORD_TO_INT_ARRAY(rValue)
		valueAny = intArrayValue
		setValueOk = ok
		break
	case types.Token[.FLOAT_ARRAY]:
		record.type = recordType
		verifiedValue := VERIFY_ARRAY_VALUES(types.Token[.FLOAT], rValue)
		if !verifiedValue {
			fmt.printfln(
				"Invalid value given. Must be an array of Type: %sFLOAT%s",
				utils.BOLD_UNDERLINE,
				utils.RESET,
			)
			return false
		}
		fltArrayValue, ok := CONVERT_RECORD_TO_FLOAT_ARRAY(rValue)
		valueAny = fltArrayValue
		setValueOk = ok
		break
	case types.Token[.BOOLEAN_ARRAY]:
		record.type = recordType
		verifiedValue := VERIFY_ARRAY_VALUES(types.Token[.BOOLEAN_ARRAY], rValue)
		if !verifiedValue {
			fmt.printfln(
				"Invalid value given. Must be an array of Type: %BOOLEAN%s",
				utils.BOLD_UNDERLINE,
				utils.RESET,
			)
			return false
		}
		boolArrayValue, ok := CONVERT_RECORD_TO_BOOL_ARRAY(rValue)
		valueAny = boolArrayValue
		setValueOk = ok
		break
	case types.Token[.STRING_ARRAY]:
		record.type = recordType
		stringArrayValue, ok := CONVERT_RECORD_TO_STRING_ARRAY(rValue)
		valueAny = stringArrayValue
		setValueOk = ok
		break
	case types.Token[.CHAR_ARRAY]:
		record.type = recordType
		charArrayValue, ok := CONVERT_RECORD_TO_CHAR_ARRAY(rValue)
		valueAny = charArrayValue
		setValueOk = ok
		break
	case types.Token[.DATE_ARRAY]:
		record.type = recordType
		dateArrayValue, ok := CONVERT_RECORD_TO_DATE_ARRAY(rValue)
		valueAny = dateArrayValue
		setValueOk = ok
		break
	case types.Token[.TIME_ARRAY]:
		record.type = recordType
		timeArrayValue, ok := CONVERT_RECORD_TO_TIME_ARRAY(rValue)
		valueAny = timeArrayValue
		setValueOk = ok
		break
	case types.Token[.DATETIME_ARRAY]:
		record.type = recordType
		dateTimeArrayValue, ok := CONVERT_RECORD_TO_DATETIME_ARRAY(rValue)
		valueAny = dateTimeArrayValue
		setValueOk = ok
		break
	case types.Token[.DATE]:
		record.type = types.Token[.DATE]
		date, ok := CONVERT_RECORD_TO_DATE(rValue)
		if ok {
			valueAny = date
			setValueOk = ok
		}
		break
	case types.Token[.TIME]:
		record.type = types.Token[.TIME]
		time, ok := CONVERT_RECORD_TO_TIME(rValue)
		if ok {
			valueAny = time
			setValueOk = ok
		}
		break
	case types.Token[.DATETIME]:
		record.type = recordType
		dateTime, ok := CONVERT_RECORD_TO_DATETIME(rValue)
		if ok {
			valueAny = dateTime
			setValueOk = ok
		}
		break
	case types.Token[.UUID]:
		record.type = recordType
		uuid, ok := CONVERT_RECORD_TO_UUID(rValue)
		if ok {
			valueAny = uuid
			setValueOk = ok
		}
		break
	case types.Token[.UUID_ARRAY]:
		record.type = recordType
		uuidArrayValue, ok := CONVERT_RECORD_TO_UUID_ARRAY(rValue)
		valueAny = uuidArrayValue
		setValueOk = ok
		break
	case types.Token[.NULL]:
		record.type = recordType
		valueAny = recordType
		setValueOk = true
		break
	}

	if setValueOk != true {
	errorLocation:= utils.get_caller_location()
		valueTypeError := utils.new_err(
			.INVALID_VALUE_FOR_EXPECTED_TYPE,
			utils.get_err_msg(.INVALID_VALUE_FOR_EXPECTED_TYPE),
			errorLocation
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
	success := UPDATE_RECORD(file, cn, rn, valueAny)


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


//Used to update a record to a new value. Similar to SET_RECORD_VALUE but records that already have a valuet thus overwriting it.
UPDATE_RECORD :: proc(
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
// output =    [NAME] :[TYPE]: [VALUE]
// fn - collection name, cn - cluster name, rn - record name
FETCH_RECORD :: proc(fn: string, cn: string, rn: string) -> (types.Record, bool) {
	clusterContent: string
	recordContent: string
	collectionPath := utils.concat_standard_collection_name(fn)

	clusterExists := CHECK_IF_CLUSTER_EXISTS(collectionPath, cn)
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


	recordExists := CHECK_IF_SPECIFIC_RECORD_EXISTS(collectionPath, cn, rn)
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
	errorLocation:= utils.get_caller_location()
		utils.throw_err(
			utils.new_err(
				.CANNOT_READ_FILE,
				utils.get_err_msg(.CANNOT_READ_FILE),
				errorLocation
			),
		)
		return types.Record{}, false
	}
	defer delete(data)

	content := string(data)
	clusters := strings.split(content, "}")

	for cluster in clusters {
		if strings.contains(cluster, fmt.tprintf("cluster_name :identifier: %s", cn)) {
			// Find the start of the cluster (opening brace)
			startIndex := strings.index(cluster, "{")
			if startIndex != -1 {
				// Extract the content between braces
				clusterContent = cluster[startIndex + 1:]
				// Trim any leading or trailing whitespace
				clusterContent = strings.trim_space(clusterContent)
				// return strings.clone(clusterContent)
			}
		}
	}

	for line in strings.split_lines(clusterContent) {
		if strings.contains(line, rn) {
			return parse_record(line), true
		}
	}
	return types.Record{}, false
}


//deletes a record from a cluster
ERASE_RECORD :: proc(fn: string, cn: string, rn: string, isOnServer: bool) -> bool {
	using utils
	collection_path := concat_standard_collection_name(fn)

	if !isOnServer {
		fmt.printfln(
			"Are you sure that you want to delete Record: %s%s%s?\nThis action can not be undone.",
			utils.BOLD_UNDERLINE,
			rn,
			utils.RESET,
		)
		fmt.printfln("Type 'yes' to confirm or 'no' to cancel.")
		input := utils.get_input(false)

		cap := strings.to_upper(input)

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
			errorLocation:= get_caller_location()
			error2 := utils.new_err(
				.INVALID_INPUT,
				utils.get_err_msg(.INVALID_INPUT),
				errorLocation
			)
			utils.throw_custom_err(error2, "Invalid input. Please type 'yes' or 'no'.")
			return false
		}
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



//reads over the passed in collection file and the specified cluster and returns the number of records in that cluster
//excluding the cluster_name and cluster_id records. potential way of doing this would be to get all of them and just subtract 2
//the isCounting param is set to true if this proc is being called during the COUNT command
GET_RECORD_COUNT_WITHIN_CLUSTER :: proc(fn, cn: string, isCounting: bool) -> int {
	collectionPath: string
	if isCounting == true {
		collectionPath = utils.concat_standard_collection_name(fn)

	} else if isCounting == false {
		collectionPath = fmt.tprintf("%s%s%s", const.PRIVATE_PATH, fn, const.OST_EXT)
	}

	data, readSuccess := utils.read_file(collectionPath, #procedure)
	if !readSuccess {
		return -1
	}
	defer delete(data)

	content := string(data)
	clusters := strings.split(content, "},")
	for cluster in clusters {
		if strings.contains(cluster, fmt.tprintf("cluster_name :identifier: %s", cn)) {
			lines := strings.split(cluster, "\n")
			recordCount := 0

			for line in lines {
				trimmedLine := strings.trim_space(line)
				if len(trimmedLine) > 0 &&
				   !strings.has_prefix(trimmedLine, "cluster_name") &&
				   !strings.has_prefix(trimmedLine, "cluster_id") &&
				   !strings.contains(trimmedLine, "#") &&
				   !strings.contains(trimmedLine, const.METADATA_START) &&
				   !strings.contains(trimmedLine, const.METADATA_END) &&
				   strings.contains(trimmedLine, ":") {
					recordCount += 1
				}
			}
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
GET_RECORD_COUNT_WITHIN_COLLECTION :: proc(fn: string) -> int {
	collectionPath := utils.concat_standard_collection_name(fn)
	data, readSuccess := utils.read_file(collectionPath, #procedure)
	if !readSuccess {
		return -1
	}
	defer delete(data)

	content := string(data)
	// Skip metadata section
	if metadataEnd := strings.index(content, "@@@@@@@@@@@@@@@BTM@@@@@@@@@@@@@@@");
	   metadataEnd >= 0 {
		content = content[metadataEnd + len("@@@@@@@@@@@@@@@BTM@@@@@@@@@@@@@@@"):]
	}

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
PURGE_RECORD :: proc(fn, cn, rn: string) -> bool {
	collection_path := utils.concat_standard_collection_name(fn)
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

GET_RECORD_SIZE :: proc(
	collection_name: string,
	cluster_name: string,
	record_name: string,
) -> (
	size: int,
	success: bool,
) {
	collection_path := fmt.tprintf(
		"%s%s%s",
		const.STANDARD_COLLECTION_PATH,
		collection_name,
		const.OST_EXT,
	)
	data, readSuccess := utils.read_file(collection_path, #procedure)
	if !readSuccess {
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



// helper used to parse records into 3 parts, the name, type and value. Appends to a struct then returns
parse_record :: proc(record: string) -> types.Record {
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