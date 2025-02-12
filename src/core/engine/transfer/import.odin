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
	csvFile := fmt.tprintf("./%s.csv", fn)
	// OST_ENSURE_CSV_RECORD_LENGTH(fn)
	head, body, recordCount := OST_GET_CSV_DATA(csvFile)
	// inferSucces, types := OST_INFER_CSV_RECORD_TYPES(head, recordCount)
	// if !inferSucces {
	// 	fmt.printfln("Failed to infer record types")
	// 	return
	// }
	// // fmt.printfln(".csv file contains the following types: %v", types) //debugging
	// fmt.printfln("Head: %v", head) //debugging
	// fmt.println("body: ", body) //debugging
	// // fmt.printfln("Record Count: %v", recordCount) //debugging
	//
	//


	// delete(head)
	// delete(body)


	data.OST_CREATE_COLLECTION(fn, 0) //create a collection with the name of the .csv file
	id := data.OST_GENERATE_ID(true)
	data.OST_CREATE_CLUSTER(fn, fmt.tprintf("%s_%s", fn, const.CSV_CLU), id)

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
	if ok {
		lines := strings.split_lines(string(data))
		for line, i in lines {
			if len(line) == 0 {continue}
			fields := strings.split(line, ",")

			if i == 0 {
				// Process header
				for field in fields {
					append(&head, strings.clone(strings.trim_space(field)))
				}
			} else {
				// Process body
				for field in fields {
					append(&body, strings.clone(strings.trim_space(field)))
				}
			}
			csvRecordCount += 1
		}
	}

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
OST_EXTRACT_CSV_FIELD :: proc(csvRecord: []string, iterations: int) -> [dynamic]string {
	field: []string
	arr: [dynamic]string
	for rec in csvRecord {
		field = strings.split_n(rec, ",", iterations)
		// fmt.printfln("Field: %v", field) //debugging
		for f in field {
			append(&arr, strings.clone(f))
			// fmt.printfln("arr: %v", arr) //debugging
		}


	}

	return arr
}


//handles the actual logic for moving csv data into the OstrichDB collection file
OST_STORE_CSV_RECORD_INTO_OSTRICH :: proc(fn: string) {}
