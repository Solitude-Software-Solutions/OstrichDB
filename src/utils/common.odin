package utils

import "../core/const"
import "core:c/libc"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"
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

//helper to get users input from the command line
get_input :: proc(isPassword: bool) -> string {
	buf: [1024]byte
	if isPassword {
		libc.system("stty -echo") //hide input
	} else {
		libc.system("stty echo")
	}
	n, err := os.read(os.stdin, buf[:])
	// fmt.printf("Debug: Read %d bytes, err = %v\n", n, err)
	if err != 0 {
		fmt.println("Debug: Error occurred")
		return ""
	}
	result := strings.trim_right(string(buf[:n]), "\r\n")
	// fmt.printf("Debug: Returning result: '%s'\n", result)
	libc.system("stty echo") //show input
	return strings.clone(result)
}


//gets the current date in GMT
get_date_and_time :: proc() -> (gmtDate: string, hour: string, minute: string, second: string) {
	mBuf: [8]byte
	dBuf: [8]byte
	yBuf: [8]byte

	hBuf: [8]byte
	minBuf: [8]byte
	sBuf: [8]byte

	h, min, s := time.clock(time.now())
	y, m, d := time.date(time.now())

	mAsInt := int(m) //month comes back as a type "Month" so need to convert
	// Conversions!!! because everything in Odin needs to be converted... :)

	Y := transmute(i64)y
	M := transmute(i64)m
	D := transmute(i64)d

	H := transmute(i64)h
	MIN := transmute(i64)min
	S := transmute(i64)s


	Month := strconv.append_int(mBuf[:], M, 10)
	Year := strconv.append_int(yBuf[:], Y, 10)
	Day := strconv.append_int(dBuf[:], D, 10)

	Hour := strconv.append_int(hBuf[:], H, 10)
	Minute := strconv.append_int(minBuf[:], MIN, 10)
	Second := strconv.append_int(sBuf[:], S, 10)


	switch (mAsInt) 
	{
	case 1:
		Month = "January"
		break
	case 2:
		Month = "February"
		break
	case 3:
		Month = "March"
		break
	case 4:
		Month = "April"
		break
	case 5:
		Month = "May"
		break
	case 6:
		Month = "June"
		break
	case 7:
		Month = "July"
		break
	case 8:
		Month = "August"
		break
	case 9:
		Month = "September"
		break
	case 10:
		Month = "October"
		break
	case 11:
		Month = "November"
		break
	case 12:
		Month = "December"
		break
	}

	Date := strings.concatenate([]string{Month, " ", Day, " ", Year, " "})
	return strings.clone(Date), strings.clone(Hour), strings.clone(Minute), strings.clone(Second)

}


//helper used to append qoutation marks to the beginning and end of a string record values
//if the value already has qoutation marks then it will not append them
append_qoutations :: proc(value: string) -> string {
	if strings.contains(value, "\"") {
		return strings.clone(value)
	}
	return strings.clone(fmt.tprintf("\"%s\"", value))
}

//helper used to append single qoutation marks to the beginning and end of CHAR record values
append_single_qoutations :: proc(value: string) -> string {
	if strings.contains(value, "'") {
		return strings.clone(value)
	}
	return strings.clone(fmt.tprintf("'%s'", value))
}
