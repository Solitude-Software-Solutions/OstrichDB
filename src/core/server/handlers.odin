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


//Mostly a test proc to see if the server is running. But also useful for checking the version using the GET method
OST_HANDLE_VERSION_REQ :: proc(m, p: string, h: map[string]string) -> (types.HttpStatus, string) {
	if m != "GET" {
		return types.HttpStatus{code = .BAD_REQUEST, text = types.HttpStatusText[.BAD_REQUEST]},
			"Method not allowed\n"
	}

	version := utils.get_ost_version()
	return types.HttpStatus {
		code = .OK,
		text = types.HttpStatusText[.OK],
	}, fmt.tprintf("OstrichDB Version: %s\n", version)
}


//Procedure that handles a GET request from the OstrichDB server
OST_HANDLE_GET_REQ :: proc(m, p: string, h: map[string]string) -> (types.HttpStatus, string) {
	if m != "GET" {
		return types.HttpStatus{code = .BAD_REQUEST, text = types.HttpStatusText[.BAD_REQUEST]},
			"Method not allowed\n"
	}

	collectionName, clusterName, recordName: string

	// Split the path into segments
	pathSegments := strings.split(strings.trim_prefix(p, "/"), "/")
	segments := len(pathSegments)

	defer delete(pathSegments)
	// Handle different path GET routes patterns

	// when fetching unqueryied data the first segment will always be the word collection
	switch (pathSegments[0]) {
	case "collection":
		if len(pathSegments) == 2 {
			// Get entire collection
			collectionName = pathSegments[1]

			return types.HttpStatus {
				code = .OK,
				text = types.HttpStatusText[.OK],
			}, data.OST_FETCH_COLLECTION(collectionName)
		} else if len(pathSegments) == 4 {
			// /collection/collectionName/cluster
			collectionName = pathSegments[1]
			clusterName = pathSegments[3]

			return types.HttpStatus {
				code = .OK,
				text = types.HttpStatusText[.OK],
			}, data.OST_FETCH_CLUSTER(collectionName, clusterName)
		} else if len(pathSegments) == 6 {
			collectionName = pathSegments[1]
			clusterName = pathSegments[3]
			recordName = pathSegments[5]

			//todo: the fetch record proc doesnt just return a string value, it returns a type AND a bool so this will need to be updated
			//had to write some filthy code to get this to work
			recordData, fetchSuccess := data.OST_FETCH_RECORD(
				collectionName,
				clusterName,
				recordName,
			)
			recordType := recordData.type
			recordValue := recordData.value

			record := fmt.tprintf("%s%s%s", recordName, recordType, recordValue)
			return types.HttpStatus{code = .OK, text = types.HttpStatusText[.OK]}, record
		}
	}


}
