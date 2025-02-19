package server
import "../../utils"
import "../types"
import "core:fmt"
import "core:strings"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright 2024 - Present Marshall A Burns & Solitude Software Solutions LLC
*********************************************************/

//Parse the incoming request from the OstrichDB server
OST_PARSE_REQUEST :: proc(
	requestData: []byte,
) -> (
	method: string,
	path: string,
	headers: map[string]string,
) {


	requestAsStr := string(requestData)

	lines := strings.split(requestAsStr, "\r\n")

	//  if the request is empty, return
	if len(lines) < 1 {
		fmt.println("Error: Request is empty")
		return "", "", nil
	}

	// Split on whitespace and trim each part
	requestParts := strings.fields(lines[0])

	if len(requestParts) != 3 {
		fmt.println("Error: Request line does not have exactly 3 parts")
		return "", "", nil
	}

	method = strings.trim_space(requestParts[0])
	path = strings.trim_space(requestParts[1])
	// protocol would be requestParts[2] if needed

	//Create a map to store the headers
	headers = make(map[string]string)
	headerEnd := 1

	//Iterate through the lines of the request
	for i := 1; i < len(lines); i += 1 {
		if lines[i] == "" { 	//if the line is empty, the headers are done and set the headerEnd to the current index
			headerEnd = i
			break
		}

		//split the line into key and value
		headerParts := strings.split(lines[i], ": ")
		//if theline has 2 parts, add it to the headers map
		if len(headerParts) == 2 {
			headers[headerParts[0]] = headerParts[1]
		}

	}

	return method, path, headers
}


//builds an HTTP respons with the passed in status code, headers, and body.
//returns the response as a byte array
OST_BUILD_RESPONSE :: proc(
	status: types.HttpStatus,
	headers: map[string]string,
	body: string,
) -> []byte {

	var := types.HttpStatusText
	dbversion := fmt.tprintf("Server: %s\r\n", string(utils.get_ost_version()))
	response := fmt.tprintf("HTTP/1.1 %d %s\r\n", int(status.code), var[status.code])

	// Add default headers
	response = strings.concatenate([]string{response, dbversion})
	response = strings.concatenate(
		[]string{response, fmt.tprintf("Content-Length: %d\r\n", len(body))},
	)
	// Add custom headers
	for key, value in headers {
		response = strings.concatenate([]string{response, fmt.tprintf("%s: %s\r\n", key, value)})
	}


	response = strings.concatenate([]string{response, "\r\n"})

	//if theres a body, add it to the response
	if len(body) > 0 {
		response = strings.concatenate([]string{response, body})
	}

	return transmute([]byte)response
}
