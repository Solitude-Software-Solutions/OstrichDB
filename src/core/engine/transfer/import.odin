package transfer

import "../../../utils"
import "../../const"
import "../../types"
import "../data"
import "../data/metadata"
import "../security"
import "core:encoding/csv"
import "core:fmt"
import "core:os"
import "core:strings"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            This file contains the logic for importing data from external sources
            into OstrichDB. Currently, only .csv files are supported.
*********************************************************/

//hanldes all logic for importing the passed in .csv file into OstrichDB as a new foriegn collection
__import_csv__ :: proc(fn: string) {
	using data

	collectionPath := utils.concat_standard_collection_name(fn)
	csvClusterName := fmt.tprintf("%s_%s", fn, const.CSV_CLU)
	csvFile := fmt.tprintf("./%s.csv", strings.to_upper(fn))

	head, body, recordCount := OST_GET_CSV_DATA(csvFile)
	inferSucces, csvTypes := OST_INFER_CSV_RECORD_TYPES(head, recordCount)
	if !inferSucces {
		fmt.printfln("Failed to infer record types")
		return
	}

	OST_CREATE_COLLECTION(strings.to_upper(fn), .STANDARD_PUBLIC) //create a collection with the name of the .csv file
	id := OST_GENERATE_ID(true)
	OST_CREATE_CLUSTER(strings.to_upper(fn), csvClusterName, id)


	cols := OST_ORGANIZE_CSV_INTO_COLUMNS(body, len(head))

	for colIndex := 0; colIndex < len(cols) && colIndex < len(head); colIndex += 1 {
		columnName := head[colIndex]
		columnType := csvTypes[columnName]

		columnValues := (fmt.tprintf("%v", cols[colIndex]))

		OST_APPEND_CSV_RECORD_INTO_OSTRICH(
			collectionPath,
			csvClusterName,
			columnName,
			columnType,
			columnValues,
		)
	}

	metadata.OST_UPDATE_METADATA_ON_CREATE(collectionPath)
	security.OST_ENCRYPT_COLLECTION(fn, .STANDARD_PUBLIC, types.system_user.m_k.valAsBytes, false)


	delete(head)
	delete(body)
	delete(csvTypes)
	delete(cols)


}

// Gets all data from a .csv file and returns the "head"(first row) and "body"(everything else) respectively
// as well as the number of records in the .csv file
OST_GET_CSV_DATA :: proc(fn: string) -> ([dynamic]string, [dynamic]string, int) {
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
OST_APPEND_CSV_RECORD_INTO_OSTRICH :: proc(fn, cn, rn, rType, rd: string) -> int {
	// csvCollectionFile := fmt.tprintf("./collections/%s.ost", fn)
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
//This helps with the inferance of record types, but could be used for other things I guess
OST_ORGANIZE_CSV_INTO_COLUMNS :: proc(
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


//Unused but helpful UTILS
//enusre that that each line(record) of the passed in .csv file has the same number of fields
ensure_csv_record_length :: proc(fn: string, reader: ^csv.Reader) -> (bool, int) {
	recordLen: int
	lenIsSame := true

	data, ok := os.read_entire_file(fn)
	if ok {
		csv.reader_init_with_string(reader, string(data))
	} else {
		//TODO: uhhhh do something with this error
	}
	defer delete(data)

	for r, i, err in csv.iterator_next(reader) {
		if err != nil { /*TODO: Do something with error */}
		recordLen = len(r)
		for r in r {
			if len(r) != recordLen {
				fmt.printfln("Record Lengths do not match")
				return false, recordLen
			} else {
				continue
			}
		}
	}
	return true, recordLen
}

//almost the same as above but doesnt do anything but return the length of the record
get_csv_record_length :: proc(csvRecord: []string) -> int {
	recordLen := len(csvRecord)
	return recordLen
}

//extracts a single field from a .csv file
extract_csv_field :: proc(csvRecords: [dynamic]string, iterations: int) -> [dynamic]string {
	field: []string
	arr: [dynamic]string
	for rec in csvRecords {
		field = strings.split_n(rec, ",", iterations)
		for f in field {
			append(&arr, strings.clone(f))
		}
	}

	return arr
}
