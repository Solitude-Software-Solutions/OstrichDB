package transfer

import "../../../utils"
import "../../const"
import "../data"
import "../data/metadata"
import "core:encoding/csv"
import "core:fmt"
import "core:os"
import "core:strings"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
*********************************************************/
_import_ :: proc(fn: string) {
	collectionPath := utils.concat_collection_name(fn)
	csvClusterName := fmt.tprintf("%s_%s", fn, const.CSV_CLU)
	csvFile := fmt.tprintf("./%s.csv", fn)
	// OST_ENSURE_CSV_RECORD_LENGTH(fn)
	head, body, recordCount := OST_GET_CSV_DATA(csvFile)
	inferSucces, types := OST_INFER_CSV_RECORD_TYPES(head, recordCount)
	if !inferSucces {
		fmt.printfln("Failed to infer record types")
		return
	}
	data.OST_CREATE_COLLECTION(fn, 0) //create a collection with the name of the .csv file
	id := data.OST_GENERATE_ID(true)
	data.OST_CREATE_CLUSTER(fn, csvClusterName, id)


	cols := OST_ORGANIZE_CSV_INTO_COLUMNS(body, recordCount)
	fmt.printfln("Cols: %v", cols) //debugging
	// Add bounds checking for the header access
	for colIndex := 0; colIndex < len(cols) && colIndex < len(head); colIndex += 1 {
		columnName := head[colIndex]
		columnType := types[columnName]

		// Convert column values to a single string representation
		columnValues := fmt.tprintf("%v", cols[colIndex])
		fmt.printfln("Column Values: %v", columnValues) //debugging
		OST_APPEND_CSV_RECORD_INTO_OSTRICH(
			collectionPath,
			csvClusterName,
			columnName,
			columnType,
			columnValues,
		)
	}


	// delete(head)
	// delete(body)
	// delete(types)
	// delete(cols)

}

// Gets all data from a .csv file and returns the "head"(first row) and "body"(everything else) respectively
// as well as the number of records in the .csv file
OST_GET_CSV_DATA :: proc(fn: string) -> ([dynamic]string, [dynamic]string, int) {
	csvRecordCount := 0
	head, body: [dynamic]string
	reader: csv.Reader
	reader.trim_leading_space = true
	reader.reuse_record = true
	reader.reuse_record_buffer = true
	defer csv.reader_destroy(&reader)

	data, ok := utils.read_file(fn, #procedure)
	defer delete(data)
	if ok {
		// Split the data into lines and process each line
		lines := strings.split_lines(string(data))
		for line, i in lines {
			if len(line) == 0 {continue}
			fields := strings.split(line, ",")

			if i == 0 {
				//append appropriate fields to head
				for field in fields {
					append(&head, strings.clone(strings.trim_space(field)))
				}
			} else {
				//append appropriate fields to body
				for field in fields {
					append(&body, strings.clone(strings.trim_space(field)))
				}
			}
			csvRecordCount += 1
		}
	}

	// fmt.printfln("Head: %v", head) //debugging
	// fmt.printfln("Body: %v", body) //debugging
	// fmt.printfln("CSV Record Count: %v", csvRecordCount) //debugging
	return head, body, csvRecordCount
}

//enusre that that each line(record) of the passed in .csv file has the same number of fields
OST_ENSURE_CSV_RECORD_LENGTH :: proc(fn: string, reader: ^csv.Reader) -> (bool, int) {
	recordLen: int
	lenIsSame := true

	data, ok := os.read_entire_file(fn)
	if ok {
		csv.reader_init_with_string(reader, string(data))
	} else {

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
OST_GET_CSV_RECORD_LENGTH :: proc(csvRecord: []string) -> int {
	recordLen := len(csvRecord)
	return recordLen
}

//extracts a single field from a .csv file
OST_EXTRACT_CSV_FIELD :: proc(csvRecords: [dynamic]string, iterations: int) -> [dynamic]string {
	field: []string
	arr: [dynamic]string
	for rec in csvRecords {
		field = strings.split_n(rec, ",", iterations)
		// fmt.printfln("Field: %v", sfield) //debugging
		for f in field {
			append(&arr, strings.clone(f))
		}
	}
	// fmt.printfln("arr: %v", arr) //debugging

	return arr
}


//handles the actual logic for moving csv data into the OstrichDB collection file
OST_APPEND_CSV_RECORD_INTO_OSTRICH :: proc(fn, cn, rn, rType, rd: string) -> int {
	// csvCollectionFile := fmt.tprintf("./collections/%s.ost", fn)
	data, readSuccess := utils.read_file(fn, #procedure)
	defer delete(data)
	if !readSuccess {
		fmt.println("Failed to read file") //debugging
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


	//remove the check for if the record exists, since this procedure is called automatically for
	// each record in the .csv file i'd rather it not bug out if there is duplicate data while storing into
	// a cluster, will justt add a scan or something to check for duplicates later

	//if the cluster is not found or the structure is invalid, return
	if clusterStart == -1 || closingBrace == -1 {
		error2 := utils.new_err(
			.CANNOT_FIND_CLUSTER,
			utils.get_err_msg(.CANNOT_FIND_CLUSTER),
			#procedure,
		)
		utils.throw_err(error2)
		utils.log_err("Unable to find cluster/valid structure", #procedure)
		fmt.println("Unable to find cluster/valid structure") //debugging
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
		fmt.println("Failed to write to file") //debugging
		return -1
	}
	return 0
}

OST_ORGANIZE_CSV_INTO_COLUMNS :: proc(
	body: [dynamic]string,
	index: int,
) -> [dynamic][dynamic]string {
	result := make([dynamic][dynamic]string, index)

	// Initialize dynamic arrays for each column
	for i := 0; i < index; i += 1 { 	// Changed from i := index to i := 0
		result[i] = make([dynamic]string)
	}

	// Organize data into columns
	for i := 0; i < len(body); i += index {
		for j := 0; j < index && (i + j) < len(body); j += 1 {
			append(&result[j], body[i + j])
		}
	}


	return result

}
