package import_formats

import "../../../utils"
import "../../const"
import "../../types"
import "../data"
import "../data/metadata"
import "../security"
import "core:encoding/csv"
import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            This file contains the logic for importing CSV data into OstrichDB
*********************************************************/

//Handles all logic for importing the passed in .csv file into OstrichDB as a new foriegn collection
CSV__IMPORT_CSV_FILE :: proc(name: string, fullPath: ..string) -> (success: bool) {
	using data
	success = false

	fmt.println("Please enter the desired name for the new OstrichDB collection.")
	desiredColName := utils.get_input(false)

	fmt.printfln(
		"Is the name %s%s%s correct?[Y/N]",
		utils.BOLD_UNDERLINE,
		desiredColName,
		utils.RESET,
	)
	colNameConfirmation := utils.get_input(false)


	if colNameConfirmation == "y" || colNameConfirmation == "Y" {
		//just continue on with procedure
	} else if colNameConfirmation == "n" || colNameConfirmation == "N" {
		fmt.println("Please try again")
		CSV__IMPORT_CSV_FILE(name, fullPath[0])
	} else {
		fmt.println("Invalid repsonse given. Please try again")
		CSV__IMPORT_CSV_FILE(name, fullPath[0])
	}

	csvClusterName := strings.to_upper(desiredColName)
	head, body, recordCount := CSV__GET_DATA_FROM_CSV_FILE(fullPath[0])
	inferSucces, csvTypes := INFER_CSV_RECORD_TYPES(head, recordCount)
	if !inferSucces {
		fmt.printfln("Failed to infer record types")
		return success
	}

	collectionPath := utils.concat_standard_collection_name(desiredColName)
	colCreationSuccess := CREATE_COLLECTION(strings.to_upper(desiredColName), .STANDARD_PUBLIC)
	if !colCreationSuccess {
		fmt.println("Failed to create collection for import file")
		return success
	}

	id := GENERATE_ID(true)
	cluCreationSuccess := CREATE_CLUSTER(strings.to_upper(desiredColName), csvClusterName, id)
	if cluCreationSuccess != 0 {
		fmt.println("Failed to create cluster within new import collection")
		return success
	}

	cols := CSV__ORGANIZE_CSV_DATA_INTO_COLUMNS(body, len(head))

	for colIndex := 0; colIndex < len(cols) && colIndex < len(head); colIndex += 1 {
		columnName := head[colIndex]
		columnType := csvTypes[columnName]
		columnValues := (fmt.tprintf("%v", cols[colIndex]))

		if CSV__APPEND_CSV_DATA_INTO_OSTRICH_COLLECTION(
			   collectionPath,
			   csvClusterName,
			   strings.to_upper(columnName),
			   columnType,
			   columnValues,
		   ) !=
		   0 {
			fmt.println(
				"Failed to append a CSV record into OstrichDB collection. Canceling operation",
			)
			return success
		}
	}

	metadata.UPDATE_METADATA_UPON_CREATION(collectionPath)
	encryptSuccess, _ := security.ENCRYPT_COLLECTION(
		desiredColName,
		.STANDARD_PUBLIC,
		types.current_user.m_k.valAsBytes,
		false,
	)

	if encryptSuccess != 0 {
		fmt.println("Failed to encrypt CSV import collection")
		return success
	}

	success = true
	delete(head)
	delete(body)
	delete(csvTypes)
	delete(cols)

	return success
}

// Gets all data from a .csv file and returns the "head"(first row) and "body"(everything else) respectively
// as well as the number of records in the .csv file
CSV__GET_DATA_FROM_CSV_FILE :: proc(fn: string) -> ([dynamic]string, [dynamic]string, int) {
	csvRecordCount := 0
	head, body: [dynamic]string

	data, ok := utils.read_file(fn, #procedure)
	defer delete(data)
	if ok {
		lines := strings.split_lines(string(data))
		for line, i in lines {
			if len(line) == 0 {continue}

			// Process each line as a complete record
			if i == 0 {
				// Handle head line
				fields := strings.split(line, ",")
				for field in fields {
					append(&head, strings.clone(strings.trim_space(field)))
				}
				csvRecordCount = len(fields)
			} else {
				// Handle body lines
				fields := strings.split(line, ",")
				// Ensure each line has the same number of fields as header
				for j := 0; j < len(head); j += 1 {
					if j < len(fields) {
						append(&body, strings.clone(strings.trim_space(fields[j])))
					} else {
						append(&body, "")
					}
				}
			}
		}
	}
	return head, body, csvRecordCount
}

//handles the actual logic for moving csv data into the OstrichDB collection file
CSV__APPEND_CSV_DATA_INTO_OSTRICH_COLLECTION :: proc(fn, cn, rn, rType, rd: string) -> int {
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

	//removed the check for if the record exists, since this procedure is called automatically for
	// each record in the .csv file i'd rather it not bug out if there is duplicate data while storing into
	// a cluster, will justt add a scan or something to check for duplicates later

	//if the cluster is not found or the structure is invalid, return
	if clusterStart == -1 || closingBrace == -1 {
		error2 := utils.new_err(
			.CANNOT_FIND_CLUSTER,
			utils.get_err_msg(.CANNOT_FIND_CLUSTER),
			#file,
			#procedure,
			#line,
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

//Takes fields of each record in a .csv file and organizes them into "columns"
CSV__ORGANIZE_CSV_DATA_INTO_COLUMNS :: proc(
	body: [dynamic]string,
	num_fields: int,
) -> [dynamic][dynamic]string {
	if num_fields <= 0 {
		return make([dynamic][dynamic]string)
	}

	result := make([dynamic][dynamic]string, num_fields)
	for i := 0; i < num_fields; i += 1 {
		result[i] = make([dynamic]string)
	}

	// Process one row at a time
	num_rows := len(body) / num_fields
	for row := 0; row < num_rows; row += 1 {
		for col := 0; col < num_fields; col += 1 {
			value_index := row * num_fields + col
			if value_index < len(body) {
				append(&result[col], body[value_index])
			}
		}
	}

	return result
}



//The following procedures are unused but could potentially be very helpful....DO NOT DELETE


// CSV__ENSURE_RECORD_LENGTH :: proc(fn: string, reader: ^csv.Reader) -> (bool, int) {
// 	recordLen: int
// 	lenIsSame := true

// 	data, ok := os.read_entire_file(fn)
// 	if ok {
// 		csv.reader_init_with_string(reader, string(data))
// 	} else {
// 		//TODO: uhhhh do something with this error
// 	}
// 	defer delete(data)

// 	for r, i, err in csv.iterator_next(reader) {
// 		if err != nil { /*TODO: Do something with error */}
// 		recordLen = len(r)
// 		for r in r {
// 			if len(r) != recordLen {
// 				fmt.printfln("Record Lengths do not match")
// 				return false, recordLen
// 			} else {
// 				continue
// 			}
// 		}
// 	}
// 	return true, recordLen
// }

// //almost the same as above but doesnt do anything but return the length of the record
// CSV__GET_RECORD_LENGTH :: proc(csvRecord: []string) -> int {
// 	recordLen := len(csvRecord)
// 	return recordLen
// }

// //extracts a single field from a .csv file
// extract_csv_field :: proc(csvRecords: [dynamic]string, iterations: int) -> [dynamic]string {
// 	field: []string
// 	arr: [dynamic]string
// 	for rec in csvRecords {
// 		field = strings.split_n(rec, ",", iterations)
// 		for f in field {
// 			append(&arr, strings.clone(f))
// 		}
// 	}

// 	return arr
// }
