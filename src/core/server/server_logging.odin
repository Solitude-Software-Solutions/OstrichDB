package server
import "../../utils"
import "../const"
import "../types"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            This file contains all functions related to
            event logging on the server.
*********************************************************/
//creates a new server log file
OST_CREATE_SERVER_LOG_FILE :: proc() -> int {
	serverLogFile, creationSuccess := os.open(
		const.SERVER_LOG_PATH,
		os.O_CREATE | os.O_RDWR,
		0o666,
	)
	if creationSuccess != 0 {
		error := utils.new_err(
			.CANNOT_CREATE_FILE,
			utils.get_err_msg(.CANNOT_CREATE_FILE),
			#file,
			#procedure,
			#line,
		)
		utils.throw_err(error)
		utils.log_err("Error creating server log file", #procedure)
		return -1
	}

	os.close(serverLogFile)
	return 0
}


OST_SET_EVENT_INFORMATION :: proc(
	name, desc: string,
	type: types.ServerEventType,
	time: time.Time,
	isRequestEvent: bool,
	path: string,
	method: types.HttpMethod,
) ->
    types.ServerEvent {
    newEvent := new(types.ServerEvent)
	newEvent.Name = name
	newEvent.Description = desc
	newEvent.Type = type
	newEvent.Timestamp = time
	newEvent.isRequestEvent = isRequestEvent
	newEvent.Route.p = path
	newEvent.Route.m = method

	return newEvent^
}

OST_PRINT_EVENT_INFORMATION :: proc(event: types.ServerEvent) {
	fmt.println("Event Name: ", event.Name)
	fmt.println("Event Description: ", event.Description)
	fmt.println("Event Type: ", event.Type)
	fmt.println("Event Timestamp: ", event.Timestamp)
	fmt.println("Event is a request: ", event.isRequestEvent)
	if event.isRequestEvent == true {
		fmt.println("Path used in request event: ", event.Route.p)
		fmt.println("Method used in request event: ", event.Route.m)
	}
	fmt.println("\n")
}

//Takes in an event and writes the events data to the log file
OST_LOG_AND_PRINT_SERVER_EVENT :: proc(event: types.ServerEvent) -> int {
    OST_PRINT_EVENT_INFORMATION(event)

    //Logging shit
	logMsg := fmt.tprintf(
		"Server Event Triggered: ",
		event.Name,
		"\n",
		"Server Event Time: ",
		event.Timestamp,
		"\n",
		"Server Event Description: ",
		event.Description,
		"\n",
		"Server Event Type: ",
		event.Type,
		"\n",
		"Server Event is a Request Event: ",
		event.isRequestEvent,
		"\n",
	)
	concatLogMsg: string
	if event.isRequestEvent == true {
		routeInfo := fmt.tprintf(
			"Server Event Route Path: ",
			event.Route.p,
			"\n",
			"Server Event Route Method: ",
			event.Route.m,
		)
		concatLogMsg = strings.concatenate([]string{logMsg, routeInfo})
	}

	LogMessage := transmute([]u8)concatLogMsg

	serverEventLogFile, openSuccess := os.open(
		const.SERVER_LOG_PATH,
		os.O_APPEND | os.O_RDWR,
		0o666,
	)
	defer os.close(serverEventLogFile)
	if openSuccess != 0 {
		utils.log_err("Error opening runtime log file", "log_runtime_event")
		return -1
	}


	_, writeSuccess := os.write(serverEventLogFile, LogMessage)
	if writeSuccess != 0 {
		utils.log_err("Error writing to runtime log file", "log_runtime_event")
		return -2
	}

	return 0

}


