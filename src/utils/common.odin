package utils

import "../core/const"
import "core:fmt"
import "core:os"
import "core:strings"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//

// Helper proc that reads an entire file and returns the content as bytes along with a success boolean
read_file :: proc(filepath: string, location: string) -> ([]byte, bool) {
	data, success := os.read_entire_file(filepath)
	if !success {
		error := new_err(.CANNOT_READ_FILE, get_err_msg(.CANNOT_READ_FILE), location)
		throw_err(error)
		log_err("Error reading file", location)
		return nil, false
	}
	return data, true
}

// Helper proc that writes data to a file and returns a success boolean
write_to_file :: proc(filepath: string, data: []byte, location: string) -> bool {
	success := os.write_entire_file(filepath, data)
	if !success {
		error := new_err(.CANNOT_WRITE_TO_FILE, get_err_msg(.CANNOT_WRITE_TO_FILE), location)
		throw_err(error)
		log_err("Error writing to file", location)
		return false
	}
	return true
}

// Helper proc that opens a file with specified flags and returns file handle and success boolean
open_file :: proc(filepath: string, flags: int, mode: int, location: string) -> (os.Handle, bool) {
	handle, err := os.open(filepath, flags, mode)
	if err != 0 {
		error := new_err(.CANNOT_OPEN_FILE, get_err_msg(.CANNOT_OPEN_FILE), location)
		throw_err(error)
		log_err("Error opening file", location)
		return 0, false
	}
	return handle, true
}


//helper used for updating collection file metadata from the command line
concat_collection_name :: proc(colFileName: string) -> string {
	return strings.clone(
		fmt.tprintf("%s%s%s", const.OST_COLLECTION_PATH, colFileName, const.OST_FILE_EXTENSION),
	)
}

get_input :: proc() -> string {
	buf: [1024]byte

	n, err := os.read(os.stdin, buf[:])
	// fmt.printf("Debug: Read %d bytes, err = %v\n", n, err)
	if err != 0 {
		fmt.println("Debug: Error occurred")
		return ""
	}
	result := strings.trim_right(string(buf[:n]), "\r\n")
	// fmt.printf("Debug: Returning result: '%s'\n", result)
	return strings.clone(result)
}
