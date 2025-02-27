package utils

import "../core/const"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            Contains logic for logging events and errors to the console and to log files.
*********************************************************/


main :: proc() {
	// os.make_directory("./")
	os.make_directory(const.LOG_DIR_PATH)
	create_log_files()
}


create_log_files :: proc() -> int {
	using const

	runtimeFile, openError := os.open(RUNTIME_LOG_PATH, os.O_CREATE, 0o666)
	if openError != 0 {
		error1 := new_err(.CANNOT_CREATE_FILE, get_err_msg(.CANNOT_CREATE_FILE), #procedure)
		throw_err(error1)
		log_err("Error creating runtime log file", "create_log_files")
		return -1
	}

	defer os.close(runtimeFile)

	errorFile, er := os.open(ERROR_LOG_PATH, os.O_CREATE, 0o666)
	if er != 0 {
		log_err("Error creating error log file", "create_log_files")
		return -1
	}

	os.close(errorFile)
	return 0
}

//###############################|RUNTIME LOGGING|############################################
log_runtime_event :: proc(eventName: string, eventDesc: string) -> int {

	date, h, m, s := get_date_and_time()
	paramsAsMessage := strings.concatenate(
		[]string{"Event: ", eventName, "\n", "Desc: ", eventDesc, "\n"},
	)
	fullLogMessage := strings.concatenate(
		[]string {
			paramsAsMessage,
			"Event Logged: ",
			date,
			"@ ",
			h,
			":",
			m,
			":",
			s,
			" GMT\n",
			"---------------------------------------------\n",
		},
	)

	LogMessage := transmute([]u8)fullLogMessage

	runtimeFile, openSuccess := os.open(const.RUNTIME_LOG_PATH, os.O_APPEND | os.O_RDWR, 0o666)
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
	date, h, m, s := get_date_and_time()
	paramsAsMessage := strings.concatenate(
		[]string{"Error: ", message, "\n", "Location: ", location, "\n"},
	)
	fullLogMessage := strings.concatenate(
		[]string {
			paramsAsMessage,
			"Error Occured: ",
			date,
			"@ ",
			h,
			":",
			m,
			":",
			s,
			" GMT\n",
			"---------------------------------------------\n",
		},
	)

	LogMessage := transmute([]u8)fullLogMessage
	errorFile, openSuccess := os.open(const.ERROR_LOG_PATH, os.O_APPEND | os.O_RDWR, 0o666)
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
