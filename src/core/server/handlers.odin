package server
import "../../utils"
import "../const"
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
OST_HANDLE_GET_REQ :: proc(
	m, p: string,
	h: map[string]string,
	params: ..string,
) -> (
	types.HttpStatus,
	string,
) {
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
OST_HANDLE_HEAD_REQ :: proc(
	m, p: string,
	h: map[string]string,
	params: ..string,
) -> (
	types.HttpStatus,
	string,
) {
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
	recordType = strings.to_upper(recordType)
	colExists, cluExists, recExists: bool

	pathSegments := OST_PATH_SPLITTER(p)
	segments := len(pathSegments)

	defer delete(pathSegments)

	collectionName := strings.to_upper(pathSegments[1])
	clusterName := strings.to_upper(pathSegments[3])

	//have to do this in the event of query parmas on a record
	recordName := strings.split(pathSegments[5], "?")
	slicedRecordName := strings.to_upper(recordName[0])

	switch (pathSegments[0]) 
	{
	case "collection":
		switch (segments) 
		{
		case 2:
			// In the event of something like: /collection/collecion_name
			colExists = data.OST_CHECK_IF_COLLECTION_EXISTS(collectionName, 0)
			if !colExists {
				data.OST_CREATE_COLLECTION(collectionName, 0)
				return types.HttpStatus {
					code = .OK,
					text = types.HttpStatusText[.OK],
				}, fmt.tprintf("New COLLECTION: %s created sucessfully", collectionName)
			} else {
				return types.HttpStatus {
					code = .BAD_REQUEST,
					text = types.HttpStatusText[.BAD_REQUEST],
				}, fmt.tprintf("COLLECTION: %s already exists", collectionName)
			}
		case 4:
			// In the event of something like: /collection/collection_name/cluster_name
			colExists = data.OST_CHECK_IF_COLLECTION_EXISTS(collectionName, 0)
			if !colExists {
				return types.HttpStatus {
					code = .NOT_FOUND,
					text = types.HttpStatusText[.NOT_FOUND],
				}, fmt.tprintf("COLLECTION: %s not found", collectionName)
			}
			cluExists = data.OST_CHECK_IF_CLUSTER_EXISTS(collectionName, clusterName)
			if !cluExists {
				id := data.OST_GENERATE_CLUSTER_ID()
				data.OST_CREATE_CLUSTER_FROM_CL(collectionName, clusterName, id)
				return types.HttpStatus {
					code = .OK,
					text = types.HttpStatusText[.OK],
				}, fmt.tprintf("New CLUSTER: %s created sucessfully", clusterName)
			}
		case 6:
			// fmt.println("collectionName: ", collectionName) //debugging
			// fmt.println("clusterName: ", clusterName) //debugging
			// fmt.println("recordName: ", recordName) //debugging
			// in the event of something like: /collection/collection_name/cluster/cluster_name/record/record_name
			colExists = data.OST_CHECK_IF_COLLECTION_EXISTS(collectionName, 0)
			if !colExists {
				return types.HttpStatus {
					code = .NOT_FOUND,
					text = types.HttpStatusText[.NOT_FOUND],
				}, fmt.tprintf("COLLECTION: %s not found", collectionName)
			}
			collectionNamePath := fmt.tprintf(
				"%s%s%s",
				const.OST_COLLECTION_PATH,
				collectionName,
				const.OST_FILE_EXTENSION,
			)
			cluExists = data.OST_CHECK_IF_CLUSTER_EXISTS(collectionNamePath, clusterName)
			if !cluExists {
				return types.HttpStatus {
					code = .NOT_FOUND,
					text = types.HttpStatusText[.NOT_FOUND],
				}, fmt.tprintf("CLUSTER: %s not found", clusterName)
			}
			fmt.println("recordName: ", recordName)
			recExists = data.OST_CHECK_IF_RECORD_EXISTS(
				collectionNamePath,
				clusterName,
				slicedRecordName,
			)
			if !recExists {
				//using query parameters to set the record data
				// Example: /collection/collection_name/cluster/cluster_name/record/record_name?type=string&value=hello
				data.OST_APPEND_RECORD_TO_CLUSTER(
					collectionNamePath,
					clusterName,
					slicedRecordName,
					queryParams["value"], //So when using this proc from command line the value is an empty string but from client it is the value the user wants to set
					recordType,
				)
				return types.HttpStatus {
					code = .OK,
					text = types.HttpStatusText[.OK],
				}, fmt.tprintf("New RECORD: %s created sucessfully", slicedRecordName)
			} else if recExists {
				//if the record does exist overwrite it with the new data provided
				eraseSuccess := data.OST_ERASE_RECORD(
					collectionName,
					clusterName,
					slicedRecordName,
				)
				if eraseSuccess {
					appendSuccess := data.OST_APPEND_RECORD_TO_CLUSTER(
						collectionNamePath,
						clusterName,
						slicedRecordName,
						queryParams["value"],
						recordType,
					)
					switch (appendSuccess) {
					case 0:
						fmt.println("Record appended successfully")
					case:
						fmt.println("Record append failed")
					}
				}
			} else {
				return types.HttpStatus {
					code = .BAD_REQUEST,
					text = types.HttpStatusText[.BAD_REQUEST],
				}, fmt.tprintf("RECORD: %s already exists", slicedRecordName)
			}
		}

	}
	return types.HttpStatus{code = .BAD_REQUEST, text = types.HttpStatusText[.BAD_REQUEST]},
		"Invalid path\n"
}

// handles the DELETE request from the client
OST_HANDLE_DELETE_REQ :: proc(
	m, p: string,
	h: map[string]string,
	params: ..string,
) -> (
	types.HttpStatus,
	string,
) {

	if m != "DELETE" {
		return types.HttpStatus{code = .BAD_REQUEST, text = types.HttpStatusText[.BAD_REQUEST]},
			"Invalid method\n"
	}

	pathSegments := OST_PATH_SPLITTER(p)
	segments := len(pathSegments)
	defer delete(pathSegments)
	collectionName, clusterName, recordName: string

	collectionName = strings.to_upper(pathSegments[1])
	if len(pathSegments) == 4 {
		clusterName = strings.to_upper(pathSegments[3])
	}
	if len(pathSegments) == 6 {
		recordName = strings.to_upper(pathSegments[5])
	}

	collectionNamePath := fmt.tprintf(
		"%s%s%s",
		const.OST_COLLECTION_PATH,
		collectionName,
		const.OST_FILE_EXTENSION,
	)


	switch (segments) {
	case 2:
		// /collection/collecion_name
		data.OST_ERASE_COLLECTION(collectionName)
		return types.HttpStatus {
			code = .OK,
			text = types.HttpStatusText[.OK],
		}, fmt.tprintf("COLLECTION: %s erased successfully", collectionName)
	case 4:
		// /collection/collection_name/cluster/cluster_name
		data.OST_ERASE_CLUSTER(collectionName, clusterName)
		return types.HttpStatus {
			code = .OK,
			text = types.HttpStatusText[.OK],
		}, fmt.tprintf("CLUSTER: %s erased successfully", clusterName)
	case 6:
		// /collection/collection_name/cluster/cluster_name/record/record_name
		data.OST_ERASE_RECORD(collectionName, clusterName, recordName)
		return types.HttpStatus {
			code = .OK,
			text = types.HttpStatusText[.OK],
		}, fmt.tprintf("RECORD: %s erased successfully", recordName)
	}

	return types.HttpStatus{code = .BAD_REQUEST, text = types.HttpStatusText[.BAD_REQUEST]},
		"Invalid path\n"
}


OST_HANDLE_POST_REQ :: proc(
	m, p: string,
	h: map[string]string,
	params: ..string,
) -> (
	types.HttpStatus,
	string,
) {
	if m != "POST" {
		return types.HttpStatus{code = .BAD_REQUEST, text = types.HttpStatusText[.BAD_REQUEST]},
			"Method not allowed\n"
	}

	// fmt.println("Path: ", p) //debugging

	segments := OST_PATH_SPLITTER(p)


	//todo: move me into the batch switch case below :)
	if len(segments) < 3 {
		return types.HttpStatus{code = .BAD_REQUEST, text = types.HttpStatusText[.BAD_REQUEST]},
			"Invalid path format\n"
	}

	switch segments[0] {
	case "batch":
		if segments[1] == "collection" {
			switch (len(segments)) {
			case 3:
				// /batch/collection/foo&bar&baz
				names := strings.split(segments[2], "&")

				success, str := data.OST_HANDLE_COLLECTION_BATCH_REQ(names, .NEW)
				if success == 0 {
					return types.HttpStatus{code = .OK, text = types.HttpStatusText[.OK]},
						"Collections created successfully\n"
				} else {
					return types.HttpStatus {
							code = .SERVER_ERROR,
							text = types.HttpStatusText[.SERVER_ERROR],
						},
						"Failed to create collections\n"
				}
			case 5:
				// /batch/collection/foo/cluster/foo&bar or /batch/collection/foo&bar/cluster/foo&bar
				if strings.contains(segments[2], "&") {
					collectionNames := strings.split(segments[2], "&")
					clusternNames := strings.split(segments[4], "&")
					success, str := data.OST_HANDLE_CLUSTER_BATCH_REQ(
						collectionNames,
						clusternNames,
						.NEW,
					)
					if success == 0 {
						return types.HttpStatus{code = .OK, text = types.HttpStatusText[.OK]},
							"Clusters created successfully\n"
					} else {
						return types.HttpStatus {
								code = .SERVER_ERROR,
								text = types.HttpStatusText[.SERVER_ERROR],
							},
							"Failed to create clusters\n"
					}
				} else {
					//create a slice with a single collection name in the event the batch is for a single collection
					collectionNames := make([]string, 1)
					collectionNames[0] = segments[2]
					clusterNames := strings.split(segments[4], "&")

					success, str := data.OST_HANDLE_CLUSTER_BATCH_REQ(
						collectionNames,
						clusterNames,
						.NEW,
					)
					if success == 0 {
						return types.HttpStatus{code = .OK, text = types.HttpStatusText[.OK]},
							"Clusters created successfully\n"
					} else {
						return types.HttpStatus {
								code = .SERVER_ERROR,
								text = types.HttpStatusText[.SERVER_ERROR],
							},
							"Failed to create clusters\n"
					}
				}
			case 7:
				// Handle batch record creation with multiple possible formats:
				// Single type for all records:
				// /batch/collection/foo&bar/cluster/baz/record/name1&name2?type=string&value=hello
				// Different types per record:
				// /batch/collection/foo/cluster/bar/record/name1&name2?types=string&bool&values=hello&true


				if segments[1] != "collection" || segments[4] != "cluster" {
					return types.HttpStatus {
							code = .BAD_REQUEST,
							text = types.HttpStatusText[.BAD_REQUEST],
						},
						"Invalid path format for batch record creation\n"
				}


				collectionNames := strings.split(segments[3], "&")
				clusterNames := strings.split(segments[5], "&")

				if segments[5] != "record" {
					return types.HttpStatus {
							code = .BAD_REQUEST,
							text = types.HttpStatusText[.BAD_REQUEST],
						},
						"Invalid path format for batch record creation\n"
				}

				pathAndQuery := strings.split(p, "?")
				if len(pathAndQuery) != 2 {
					return types.HttpStatus {
							code = .BAD_REQUEST,
							text = types.HttpStatusText[.BAD_REQUEST],
						},
						"Query parameters required for batch record creation\n"
				}

				query := pathAndQuery[1]
				queryParams := parse_query_string(query)
				recordNames := strings.split(segments[6], "&")

				// Check for single type/value format
				singleType, hasSingleType := queryParams["type"]
				singleValue, hasSingleValue := queryParams["value"]

				// Check for multiple types/values format
				multiTypes, hasMultiTypes := queryParams["types"]
				multiValues, hasMultiValues := queryParams["values"]

				recordTypeArray: []string
				recordValueArray: []string

				if hasSingleType && hasSingleValue {
					// Use the same type and value for all records
					recordTypeArray = make([]string, len(recordNames))
					recordValueArray = make([]string, len(recordNames))
					for i := 0; i < len(recordNames); i += 1 {
						recordTypeArray[i] = singleType
						recordValueArray[i] = singleValue
					}
				} else if hasMultiTypes && hasMultiValues {
					// Use different types and values for each record
					recordTypeArray = strings.split(multiTypes, "&")
					recordValueArray = strings.split(multiValues, "&")

					if len(recordTypeArray) != len(recordNames) ||
					   len(recordValueArray) != len(recordNames) {
						return types.HttpStatus {
							code = .BAD_REQUEST,
							text = types.HttpStatusText[.BAD_REQUEST],
						}, fmt.tprintf("Number of types (%d) and values (%d) must match number of records (%d)\n", len(recordTypeArray), len(recordValueArray), len(recordNames))
					}
				} else {
					return types.HttpStatus {
							code = .BAD_REQUEST,
							text = types.HttpStatusText[.BAD_REQUEST],
						},
						"Must provide either 'type&value' or 'types&values' in query parameters\n"
				}

				success, str := data.OST_HANDLE_RECORD_BATCH_REQ(
					collectionNames,
					clusterNames,
					recordNames,
					recordTypeArray,
					recordValueArray,
					.NEW,
				)

				if success == 0 {
					return types.HttpStatus{code = .OK, text = types.HttpStatusText[.OK]},
						"Records created successfully\n"
				} else {
					return types.HttpStatus {
							code = .SERVER_ERROR,
							text = types.HttpStatusText[.SERVER_ERROR],
						},
						"Failed to create records\n"
				}
			}
		}
	}
	return types.HttpStatus{code = .BAD_REQUEST, text = types.HttpStatusText[.BAD_REQUEST]},
		"Invalid path\n"
}


//TODO: Move me somewhere else...possibly in a utils or helper file
//helper proc to parse query string into a map
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
