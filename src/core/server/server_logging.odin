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
CREATE_SERVER_LOG_FILE :: proc() -> int {
	serverLogFile, creationSuccess := os.open(
		const.SERVER_LOG_PATH,
		os.O_CREATE | os.O_RDWR,
		0o666,
	)
	if creationSuccess != 0 {
	errorLocation:= utils.get_caller_location()
		error := utils.new_err(
			.CANNOT_CREATE_FILE,
			utils.get_err_msg(.CANNOT_CREATE_FILE),
			errorLocation
		)
		utils.throw_err(error)
		utils.log_err("Error creating server log file", #procedure)
		return -1
	}

	os.close(serverLogFile)
	return 0
}


SET_SERVER_EVENT_INFORMATION :: proc(
	name, desc: string,
	type: types.ServerEventType,
	time: time.Time,
	isRequestEvent: bool,
	path: string,
	method: types.HttpMethod,
) -> types.ServerEvent {
	newEvent := new(types.ServerEvent)
	newEvent.Name = name
	newEvent.Description = desc
	newEvent.Type = type
	newEvent.Timestamp = time
	newEvent.isRequestEvent = isRequestEvent
	newEvent.Route.p = path
	newEvent.Route.m = method
	newEvent.methodAsStr = fmt.tprintf("%d",method)

	return newEvent^
}

PRINT_SERVER_EVENT_INFORMATION :: proc(event: types.ServerEvent) {
	fmt.println("Server Event Name: ", event.Name)
	fmt.println("Server Event Description: ", event.Description)
	fmt.println("Server Event Type: ", event.Type)
	fmt.println("Server Event Timestamp: ", event.Timestamp)
	fmt.println("Server Event is a request: ", event.isRequestEvent)
	if event.isRequestEvent == true {
		fmt.println("Path used in request event: ", event.Route.p)
		fmt.println("Method used in request event: ", event.Route.m)
	}
	fmt.println("\n")
}

//Takes in an event and writes the events data to the log file
LOG_SERVER_EVENT :: proc(event: types.ServerEvent) -> int {

    eventTriggered:= fmt.tprintf("Server Event Triggered: '%s'\n",event.Name)
    eventTime:= fmt.tprintf("Server Event Time: '%v'\n", event.Timestamp)
    eventDesc:= fmt.tprintf("Server Event Description: '%s'\n", event.Description)
    eventType:= fmt.tprintf("Server Event Type: '%v'\n", event.Type,)
    eventIsReq := fmt.tprintf("Server Event is a Request Event: '%v'\n", event.isRequestEvent,)
    logMsg := strings.concatenate([]string{eventTriggered, eventTime, eventDesc, eventType, eventIsReq, })

	concatLogMsg: string
	someVar:string
	if event.isRequestEvent == true {
	    switch(event.Route.m){
		case .HEAD:
            someVar = "HEAD"
            break
	    case .GET:
			someVar = "GET"
			break
		case .DELETE:
		    someVar =  "DELETE"
			break
		case .POST:
            someVar  = "POST"
            break
		case .PUT:
            someVar = "PUT"
            break

	}
	routePath:= fmt.tprintf("Server Event Route Path: '%s'\n", event.Route.p,)
	routeMethod:= fmt.tprintf("Server Event Route Method: '%s'\n", someVar)

	concatLogMsg = strings.concatenate([]string{logMsg, routePath, routeMethod, "\n\n"})
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
