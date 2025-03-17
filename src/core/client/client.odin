package client
import "../types"
import "core:fmt"
import "core:net"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            This client Odin file is used to test and interact with the
            OstrichDB API
*********************************************************/

//This file is purely for testing server functionality and interaction with a client
// OST_TEST_CLIENT :: proc(config: types.Server_Config) -> int {
// 	endpoint := net.Endpoint{net.IP4_Address{127, 0, 0, 1}, config.port}

// 	fmt.println("Connecting to server...")
// 	client_socket, connect_err := net.dial_tcp(endpoint)
// 	if connect_err != nil {
// 		fmt.println("Error connecting to server:", connect_err)
// 		return -1
// 	}
// 	defer net.close(client_socket)
// 	request: string

// 	//test request to get server version on /version endpoint
// 	request = fmt.tprintf(
// 		"GET /version HTTP/1.1\r\nHost: localhost:%d\r\nConnection: close\r\n\r\n",
// 		config.port,
// 	)

//test request to get a specific cluster on /collection/foo/cluster/bar endpoint
// request = fmt.tprintf(
// 	"GET /collection/foo/cluster/bar HTTP/1.1\r\nHost: localhost:%d\r\nConnection: close\r\n\r\n",
// 	config.port,
// )

// test request to get header information using HEAD method on /collection/foo/cluster/bar endpoint
// request = fmt.tprintf(
// 	"HEAD /collection/foo/cluster/bar HTTP/1.1\r\nHost: localhost:%d\r\nConnection: close\r\n\r\n",
// 	config.port,
// )


// test request to set the value and type of a specific record on /collection/foo/cluster/bar/record/baz endpoint
// request = fmt.tprintf(
// "PUT /collection/foo/cluster/bar/record/baz?type=string&value=goodbye HTTP/1.1\r\nHost: localhost:%d\r\nConnection: close\r\n\r\n", // 	config.port,
// )

//test route for using POST method to create a batch of collections. endpoint is root when using batch
// request = fmt.tprintf(
// 	"POST /batch/collection/foo&bar HTTP/1.1\r\nHost: localhost:%d\r\nConnection: close\r\n\r\n",
// 	config.port,
// )

//test route to create a batch of 2 clusters within a batch of 2 collections
// request = fmt.tprintf(
// 	"POST /batch/collection/foo&bar/cluster/foo&bar HTTP/1.1\r\nHost: localhost:%d\r\nConnection: close\r\n\r\n",
// 	config.port,
// )

//test route to create a batch of 44 clusters in a single collection
// request = fmt.tprintf(
// 	"POST /batch/collection/foo/cluster/foo&bar&baz&goob HTTP/1.1\r\nHost: localhost:%d\r\nConnection: close\r\n\r\n",
// 	config.port,
// )


//test request to delete the cluster at the /collection/foo/cluster/bar endpoint
// request = fmt.tprintf(
// 	"DELETE /collection/foo HTTP/1.1\r\nHost: localhost:%d\r\nConnection: close\r\n\r\n",
// 	config.port,
// )

// 	request_bytes := transmute([]byte)request

// 	_, send_err := net.send(client_socket, request_bytes)
// 	if send_err != nil {
// 		fmt.println("Error sending request:", send_err)
// 		return -1
// 	}

// 	buf: [1024]byte
// 	fmt.println("Waiting for server response...")
// 	bytes_read, recv_err := net.recv(client_socket, buf[:])
// 	if recv_err != nil {
// 		fmt.println("Error receiving response:", recv_err)
// 		return -1
// 	}

// 	fmt.printf("Server response:\n%s\n", string(buf[:bytes_read]))
// 	return 0
// }
