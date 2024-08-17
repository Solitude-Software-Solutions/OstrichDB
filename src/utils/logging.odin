package utils

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//


LOG_DIR_PATH :: "../bin/logs/"
RUNTIME_LOG :: "runtime.log"
ERROR_LOG :: "errors.log"

main :: proc() {
	os.make_directory("../bin/")
	os.make_directory(LOG_DIR_PATH)
	create_log_files()
}


create_log_files :: proc() -> int {

	fullRuntimePath := strings.concatenate([]string{LOG_DIR_PATH, RUNTIME_LOG})
	runtimeFile, openError := os.open(fullRuntimePath, os.O_CREATE, 0o666)
	if openError != 0 {
		error1 := new_err(.CANNOT_CREATE_FILE, get_err_msg(.CANNOT_CREATE_FILE), #procedure)
		throw_err(error1)
		log_err("Error creating runtime log file", "create_log_files")
		return -1
	}

	defer os.close(runtimeFile)

	fullErrorPath := strings.concatenate([]string{LOG_DIR_PATH, ERROR_LOG})
	errorFile, er := os.open(fullErrorPath, os.O_CREATE, 0o666)
	if er != 0 {
		log_err("Error creating error log file", "create_log_files")
		return -1
	}

	os.close(errorFile)
	return 0
}

//###############################|RUNTIME LOGGING|############################################
log_runtime_event :: proc(eventName: string, eventDesc: string) -> int {
	mBuf: [8]byte
	dBuf: [8]byte
	yBuf: [8]byte

	hBuf: [8]byte
	minBuf: [8]byte
	sBuf: [8]byte

	h, min, s := time.clock(time.now())
	y, m, d := time.date(time.now())

	mAsInt := int(m) //month comes base as a type "Month" so need to convert
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
	paramsAsMessage := strings.concatenate(
		[]string{"Event: ", eventName, "\n", "Desc: ", eventDesc, "\n"},
	)
	fullLogMessage := strings.concatenate(
		[]string {
			paramsAsMessage,
			"Event Logged: ",
			Date,
			"@ ",
			Hour,
			":",
			Minute,
			":",
			Second,
			" GMT\n",
			"---------------------------------------------\n",
		},
	)
	fullPath := strings.concatenate([]string{LOG_DIR_PATH, RUNTIME_LOG})
	LogMessage := transmute([]u8)fullLogMessage

	runtimeFile, openSuccess := os.open(fullPath, os.O_APPEND | os.O_RDWR, 0o666)
	defer os.close(runtimeFile)
	if openSuccess != 0 {
		log_err("Error opening runtime log file", "log_runtime_event")
		return 1
	}


	_, writeSuccess := os.write(runtimeFile, LogMessage)
	if writeSuccess != 0 {
		log_err("Error writing to runtime log file", "log_runtime_event")
		return 1
	}

	//every thing seems to have been converted correctly and passed correctly. The file does exist, the path is correct, the file is being opened correctly
	os.close(runtimeFile)
	return 0
}


//###############################|ERROR LOGGING|############################################
log_err :: proc(message: string, location: string) -> int {
	mBuf: [8]byte
	dBuf: [8]byte
	yBuf: [8]byte

	hBuf: [8]byte
	minBuf: [8]byte
	sBuf: [8]byte

	h, min, s := time.clock(time.now())
	y, m, d := time.date(time.now())

	mAsInt := int(m)

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
	paramsAsMessage := strings.concatenate(
		[]string{"Error: ", message, "\n", "Location: ", location, "\n"},
	)
	fullLogMessage := strings.concatenate(
		[]string {
			paramsAsMessage,
			"Error Occured: ",
			Date,
			"@ ",
			Hour,
			":",
			Minute,
			":",
			Second,
			" GMT\n",
			"---------------------------------------------\n",
		},
	)
	fullPath := strings.concatenate([]string{LOG_DIR_PATH, ERROR_LOG})
	LogMessage := transmute([]u8)fullLogMessage
	errorFile, openSuccess := os.open(fullPath, os.O_APPEND | os.O_RDWR, 0o666)
	defer os.close(errorFile)
	if openSuccess != 0 {
		return -1
	}


	_, writeSuccess := os.write(errorFile, LogMessage)
	if writeSuccess != 0 {
		return -1
	}
	return 0
}
