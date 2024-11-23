package server
import "../../utils"
import "../engine/data"
import "../types"
import "core:fmt"
import "core:strings"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//

// Note: Although some procs follow the `RouteHandler` procdure signature, they dont all use the params that are expected. But, they all MUST follow this signature
// because they are all called by the `OST_ADD_ROUTE` proc in server.odin which expects them to have this signature - Marshall A Burns aka @SchoolyB

OST_PATH_SPLITTER :: proc(p: string) -> []string {
	return strings.split(strings.trim_prefix(p, "/"), "/")
}

//Handles all GET requests from the client
OST_HANDLE_GET_REQ :: proc(m, p: string, h: map[string]string) -> (types.HttpStatus, string) {
	if m != "GET" {
		return types.HttpStatus{code = .BAD_REQUEST, text = types.HttpStatusText[.BAD_REQUEST]},
			"Method not allowed\n"
	}

	collectionName, clusterName, recordName: string

	// Split the path into segments
	pathSegments := OST_PATH_SPLITTER(p)
	segments := len(pathSegments)

	defer delete(pathSegments)
	// Handle different path GET routes patterns

	// when fetching unqueryied data the first segment will always be the word collection
	// fmt.println("Length of segments in path: %d", len(pathSegments)) //debugging

	switch (pathSegments[0]) {
	case "collection":
		if len(pathSegments) == 2 {
			// Get entire collection
			collectionName = pathSegments[1]

			return types.HttpStatus {
				code = .OK,
				text = types.HttpStatusText[.OK],
			}, data.OST_FETCH_COLLECTION(strings.to_upper(collectionName))
		} else if len(pathSegments) == 4 {
			// /collection/collectionName/cluster
			collectionName = pathSegments[1]
			clusterName = pathSegments[3]
			return types.HttpStatus {
				code = .OK,
				text = types.HttpStatusText[.OK],
			}, data.OST_FETCH_CLUSTER(strings.to_upper(collectionName), strings.to_upper(clusterName))
		} else if len(pathSegments) == 6 {
			collectionName = pathSegments[1]
			clusterName = pathSegments[3]
			recordName = pathSegments[5]

			//todo: the fetch record proc doesnt just return a string value, it returns a type AND a bool so this will need to be updated
			//had to write some filthy code to get this to work
			recordData, fetchSuccess := data.OST_FETCH_RECORD(
				strings.to_upper(collectionName),
				strings.to_upper(clusterName),
				strings.to_upper(recordName),
			)
			recordType := recordData.type
			recordValue := recordData.value

			record := fmt.tprintf("%s%s%s", recordName, recordType, recordValue)
			return types.HttpStatus{code = .OK, text = types.HttpStatusText[.OK]}, record
		}
	case "version":
		version := utils.get_ost_version()
		return types.HttpStatus {
			code = .OK,
			text = types.HttpStatusText[.OK],
		}, fmt.tprintf("OstrichDB Version: %s\n", version)

	}
	return types.HttpStatus{code = .NOT_FOUND, text = types.HttpStatusText[.NOT_FOUND]},
		"Not Found\n"
}

// Handles the HEAD request from the client
// Sends the http status code, metadata like the server name and version, content type, and content length
OST_HANDLE_HEAD_REQ :: proc(m, p: string, h: map[string]string) -> (types.HttpStatus, string) {
	// fmt.printfln("Method: %s", m) //debugging
	// fmt.printfln("Path: %s", p) //debugging
	// fmt.printfln("Headers: %s", h) //debugging
	if m != "HEAD" {
		return types.HttpStatus{code = .BAD_REQUEST, text = types.HttpStatusText[.BAD_REQUEST]},
			"Method not allowed\n"
	}
	//The responsebody is NOT returned in the HEAD request. Only used to calculate the content length
	status, responseBody := OST_HANDLE_GET_REQ("GET", p, h)
	// fmt.printfln("Status code: %s", status.code) //debugging
	// fmt.printfln("Response body: %s", responseBody) //debugging

	if status.code != .OK {
		return status, ""
	}
	pathSegments := OST_PATH_SPLITTER(p)
	// fmt.printfln("Path segments: %s", pathSegments) //debugging
	// fmt.printfln("Length of path segments: %ss", len(pathSegments)) //debugging
	//there is no path, so we are just fetching the root
	contentLength := len(responseBody)


	headers := fmt.tprintf(
		"Server: %s/%s\n" +
		"Content-Type: text/plain\n" +
		"Content-Length: %d\n" +
		"Accept-Ranges: bytes\n" +
		"Cache-Control: no-cache\n" +
		"Connection: keep-alive\n",
		"OstrichDB",
		string(utils.get_ost_version()),
		contentLength,
	)
	return types.HttpStatus{code = .OK, text = types.HttpStatusText[.OK]}, headers
}


//Handles PUT requests from the client
//PUT allows the client to update/overwrite a collection, cluster or record in the database or create a new one if none exists
OST_HANDLE_PUT_REQ :: proc(
	m, p: string,
	h: map[string]string,
	params: ..string,
) -> (
	types.HttpStatus,
	string,
) {
	if m != "PUT" {
		return types.HttpStatus{code = .BAD_REQUEST, text = types.HttpStatusText[.BAD_REQUEST]},
			"Method not allowed\n"
	}

	pathAndQuery := strings.split(p, "?")
	if len(pathAndQuery) != 2 {
		return types.HttpStatus{code = .BAD_REQUEST, text = types.HttpStatusText[.BAD_REQUEST]},
			"Query parameters required\n"
	}

	query := pathAndQuery[1]
	queryParams := parse_query_string(query) //found below this proc

	recordType, typeExists := queryParams["type"]
	if !typeExists {
		return types.HttpStatus{code = .BAD_REQUEST, text = types.HttpStatusText[.BAD_REQUEST]},
			"Record type required\n"
	}
	//TODO: This one is gonna fuckin suck.
	// Need to do several things for each data object/layer
	// First ensure the data layer exists
	// Second need to gather what the user is trying to 'PUT' from the client side
	// Third need to perform the PUT request. These steps need to be done for each data object as well as the following non-destructive DB operations:
	// NEW, RENAME, and mayeb PURGE???
	collectionName, clusterName, recordName: string
	colExists, cluExists, recExists: bool

	pathSegments := OST_PATH_SPLITTER(p)
	segments := len(pathSegments)

	defer delete(pathSegments)

	switch (pathSegments[0]) 
	{
	case "collection":
		// In the event of something like: /collection/collecion_name
		if segments == 2 {
			colExists = data.OST_CHECK_IF_COLLECTION_EXISTS(pathSegments[1], 0)
			if !colExists {
				data.OST_CREATE_COLLECTION(pathSegments[1], 0)
				return types.HttpStatus {
					code = .OK,
					text = types.HttpStatusText[.OK],
				}, fmt.tprintf("New COLLECTION: %s created sucessfully", pathSegments[1])
			} else {
				return types.HttpStatus {
					code = .BAD_REQUEST,
					text = types.HttpStatusText[.BAD_REQUEST],
				}, fmt.tprintf("COLLECTION: %s already exists", pathSegments[1])
			}
			//TODO: What about if the user wants to rename a collection???
		} else if segments == 4 { 	// In the event of something like: /collection/collection_name/cluster_name
			colExists = data.OST_CHECK_IF_COLLECTION_EXISTS(pathSegments[1], 0)
			if !colExists {
				return types.HttpStatus {
					code = .NOT_FOUND,
					text = types.HttpStatusText[.NOT_FOUND],
				}, fmt.tprintf("COLLECTION: %s not found", pathSegments[1])
			}
			cluExists = data.OST_CHECK_IF_CLUSTER_EXISTS(pathSegments[1], pathSegments[3])
			if !cluExists {
				id := data.OST_GENERATE_CLUSTER_ID()
				data.OST_CREATE_CLUSTER_FROM_CL(pathSegments[1], pathSegments[3], id)
				return types.HttpStatus {
					code = .OK,
					text = types.HttpStatusText[.OK],
				}, fmt.tprintf("New CLUSTER: %s created sucessfully", pathSegments[3])
			}
		} else if segments == 6 { 	// in the event of something like: /collection/collection_name/cluster/cluster_name/record/record_name
			colExists = data.OST_CHECK_IF_COLLECTION_EXISTS(pathSegments[1], 0)
			if !colExists {
				return types.HttpStatus {
					code = .NOT_FOUND,
					text = types.HttpStatusText[.NOT_FOUND],
				}, fmt.tprintf("COLLECTION: %s not found", pathSegments[1])
			}
			cluExists = data.OST_CHECK_IF_CLUSTER_EXISTS(pathSegments[1], pathSegments[3])
			if !cluExists {
				return types.HttpStatus {
					code = .NOT_FOUND,
					text = types.HttpStatusText[.NOT_FOUND],
				}, fmt.tprintf("CLUSTER: %s not found", pathSegments[3])
			}

			recExists = data.OST_CHECK_IF_RECORD_EXISTS(
				pathSegments[1],
				pathSegments[3],
				pathSegments[5],
			)
			if !recExists {
				//using query parameters to get/set the record data
				// Example: /collection/collection_name/cluster/cluster_name/record/record_name?type=string&value=hello
				data.OST_APPEND_RECORD_TO_CLUSTER(
					pathSegments[1],
					pathSegments[3],
					pathSegments[5],
					queryParams["value"],
					recordType,
				)
				return types.HttpStatus {
					code = .OK,
					text = types.HttpStatusText[.OK],
				}, fmt.tprintf("New RECORD: %s created sucessfully", pathSegments[5])
			} else {
				return types.HttpStatus {
					code = .BAD_REQUEST,
					text = types.HttpStatusText[.BAD_REQUEST],
				}, fmt.tprintf("RECORD: %s already exists", pathSegments[5])
			}

		}

	}

}


parse_query_string :: proc(query: string) -> map[string]string {
	params := make(map[string]string)
	pairs := strings.split(query, "&")
	for pair in pairs {
		kv := strings.split(pair, "=")
		if len(kv) == 2 {
			params[kv[0]] = kv[1]
		}
	}
	return params
}
