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
	head, body := OST_GET_CSV_DATA(fn)
	OST_INFER_CSV_RECORD_TYPES(head)
}

// Gets all data from a .csv file and returns the header and body
OST_GET_CSV_DATA :: proc(fn: string) -> ([dynamic]string, [dynamic]string) {
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
				append(&body, strings.clone(f))
			}
			// append(&head, f)
		}
	}
	fmt.printfln("Head: %v", head) //debugging
	// fmt.printfln("Body: %v", body) //debugging
	return head, body
}
