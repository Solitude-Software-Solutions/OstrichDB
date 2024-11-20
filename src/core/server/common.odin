package server

import "../types"
import "core:fmt"
import "core:strings"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//

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

	//split the request line into its parts
	requestLine := strings.split(lines[0], " ")

	//a request line should have 3 parts: the method, the path, and the headers
	//if the request line does not have 3 parts, return
	if len(requestLine) != 3 {
		return "", "", nil
	}

	method = requestLine[0]
	path = requestLine[1]

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
	// Start with status line
	var := types.HttpStatusText
	response := fmt.tprintf("HTTP/1.1 %d %s\r\n", int(status.code), var[status.code])

	// Add default headers
	response = strings.concatenate([]string{response, "Server: OstrichDB v0.5.0\r\n"})
	response = strings.concatenate(
		[]string{response, fmt.tprintf("Content-Length: %d\r\n", len(body))},
	)
	// Add custom headers
	for key, value in headers {
		response = strings.concatenate([]string{response, fmt.tprintf("%s: %s\r\n", key, value)})
	}

	// Add blank line to separate headers from body
	response = strings.concatenate([]string{response, "\r\n"})

	// Add body if present
	if len(body) > 0 {
		response = strings.concatenate([]string{response, body})
	}

	return transmute([]byte)response
}

//Procedure that handles a GET request from the OstrichDB server
