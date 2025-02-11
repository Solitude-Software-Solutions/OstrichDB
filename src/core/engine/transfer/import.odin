package transfer

import "../../../utils"
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
	head, body, recordCount := OST_GET_CSV_DATA(fn)
	inferSucces, types := OST_INFER_CSV_RECORD_TYPES(head, recordCount)
	if !inferSucces {
		fmt.printfln("Failed to infer record types")
		return
	}
	// fmt.printfln(".csv file contains the following types: %v", types) //debugging
	fmt.printfln("Head: %v", head) //debugging
	fmt.println("body: ", body) //debugging
	fmt.printfln("Record Count: %v", recordCount) //debugging
	delete(head)
	delete(body)
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

	data, ok := os.read_entire_file(fn)
	if ok {
		csv.reader_init_with_string(&reader, string(data))
	} else {

	}
	defer delete(data)

	//r- record, i- record number, f- field, j- field number
	for r, i, err in csv.iterator_next(&reader) {
		if err != nil { /*TODO: Do something with error */}
		for f, j in r {
			if i == 0 {
				//Get the .csv header(first row) and append it
				append(&head, strings.clone(f))
			} else {
				//if not the first row, append the rest of the rows as the body
				append(&body, strings.clone(f))
			}
		}
		csvRecordCount += 1
	}
	// fmt.printfln("Head: %v", head) //debugging
	// fmt.printfln("Body: %v", body) //debugging
	// fmt.printfln("CSV Record Count: %v", csvRecordCount) //debugging
	return head, body, csvRecordCount
}

//todo: add a check to make sure that all rows have the same number of fields???
