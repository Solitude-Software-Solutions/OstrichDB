package client
import "../../types"
import "core:fmt"
import "core:net"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            This is an example vanilla ODIN client that demonstrates how
            to interact with the OstrichDB API layer. You can use this client in
            whole OR as a reference to create your own client if you wish.
            For more information about OstrichDB example clients see the README.md file
            in the 'client' directory.
*********************************************************/

/*
Developer Note: At the present time OstrichDBs server creates ALL routes
meant to do work on a database(collection) itself or its subcomponents dynamically.
This means that request paths need to be constructed the way they are below to work...
This might or might not change in the future. These examples are crude and do not represent
the best way to do things nor do they represent the final product of working with OstrichDBs API.


TL;DR:
Store you db information in to variables and pass them to the fetch calls, The API might change
drastically in the future so dont get to comfortable with this for now.

  - Marshall Burns
*/

// OLLECTION_NAME :: "odin_collection"
// CLUSTER_NAME :: "odin_cluster"
// RECORD_NAME :: "odin_record"
// RECORD_TYPE :: "STRING"
// RECORD_VALUE :: "Hello-World!"

// // Get the current version of OstrichDB from the server
// ost_get_version :: proc(config: types.Server_Config) -> (string, bool) {
// 	endpoint := net.Endpoint{net.IP4_Address{127, 0, 0, 1}, config.port}
// 	request := fmt.tprintf(
// 		"GET /version HTTP/1.1\r\nHost: localhost:%d\r\nConnection: close\r\n\r\n",
// 		config.port,
// 	)
// 	return send_request(endpoint, request)
// }

// // Perform actions on collections
// collection_action :: proc(config: types.Server_Config, method: string) -> (string, bool) {
// 	endpoint := net.Endpoint{net.IP4_Address{127, 0, 0, 1}, config.port}
// 	request := fmt.tprintf(
// 		"%s /c/%s HTTP/1.1\r\nHost: localhost:%d\r\nConnection: close\r\n\r\n",
// 		method,
// 		COLLECTION_NAME,
// 		config.port,
// 	)
// 	return send_request(endpoint, request)
// }

// // Perform actions on clusters
// cluster_action :: proc(config: types.Server_Config, method: string) -> (string, bool) {
// 	endpoint := net.Endpoint{net.IP4_Address{127, 0, 0, 1}, config.port}
// 	request := fmt.tprintf(
// 		"%s /c/%s/cl/%s HTTP/1.1\r\nHost: localhost:%d\r\nConnection: close\r\n\r\n",
// 		method,
// 		COLLECTION_NAME,
// 		CLUSTER_NAME,
// 		config.port,
// 	)
// 	return send_request(endpoint, request)
// }

// // Perform actions on records
// record_action :: proc(config: types.Server_Config, method: string) -> (string, bool) {
// 	endpoint := net.Endpoint{net.IP4_Address{127, 0, 0, 1}, config.port}
// 	request: string

// 	switch method {
// 	case "POST":
// 		request = fmt.tprintf(
// 			"POST /c/%s/cl/%s/r/%s?type=%s HTTP/1.1\r\nHost: localhost:%d\r\nConnection: close\r\n\r\n",
// 			COLLECTION_NAME,
// 			CLUSTER_NAME,
// 			RECORD_NAME,
// 			RECORD_TYPE,
// 			config.port,
// 		)
// 	case "PUT":
// 		request = fmt.tprintf(
// 			"PUT /c/%s/cl/%s/r/%s?type=%s&value=%s HTTP/1.1\r\nHost: localhost:%d\r\nConnection: close\r\n\r\n",
// 			COLLECTION_NAME,
// 			CLUSTER_NAME,
// 			RECORD_NAME,
// 			RECORD_TYPE,
// 			RECORD_VALUE,
// 			config.port,
// 		)
// 	case:
// 		request = fmt.tprintf(
// 			"%s /c/%s/cl/%s/r/%s HTTP/1.1\r\nHost: localhost:%d\r\nConnection: close\r\n\r\n",
// 			method,
// 			COLLECTION_NAME,
// 			CLUSTER_NAME,
// 			RECORD_NAME,
// 			config.port,
// 		)
// 	}
// 	return send_request(endpoint, request)
// }

// // Helper function to send requests and receive responses
// send_request :: proc(endpoint: net.Endpoint, request: string) -> (string, bool) {
// 	client_socket, connect_err := net.dial_tcp(endpoint)
// 	if connect_err != nil {
// 		fmt.println("Error connecting to server:", connect_err)
// 		return "", false
// 	}
// 	defer net.close(client_socket)

// 	request_bytes := transmute([]byte)request
// 	_, send_err := net.send(client_socket, request_bytes)
// 	if send_err != nil {
// 		fmt.println("Error sending request:", send_err)
// 		return "", false
// 	}

// 	buf: [1024]byte
// 	bytesRead, recv_err := net.recv(client_socket, buf[:])
// 	if recv_err != nil {
// 		fmt.println("Error receiving response:", recv_err)
// 		return "", false
// 	}

// 	return string(buf[:bytesRead]), true
// }

// // Test client demonstrating various API calls
// OST_TEST_CLIENT :: proc(config: types.Server_Config) -> int {
// 	fmt.println("\nTesting OstrichDB API...")

// 	// Test version endpoint
// 	if response, ok := ost_get_version(config); ok {
// 		fmt.printf("Version Response:\n%s\n", response)
// 	}

// 	// Test collection operations
// 	if response, ok := collection_action(config, "POST"); ok {
// 		fmt.printf("Create Collection Response:\n%s\n", response)
// 	}

// 	// Test cluster operations
// 	if response, ok := cluster_action(config, "POST"); ok {
// 		fmt.printf("Create Cluster Response:\n%s\n", response)
// 	}

// 	// Test record operations
// 	if response, ok := record_action(config, "PUT"); ok {
// 		fmt.printf("Create/Update Record Response:\n%s\n", response)
// 	}

// 	return 0
// }
