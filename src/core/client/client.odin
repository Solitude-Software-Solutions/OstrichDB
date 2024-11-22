package client
import "../types"
import "core:fmt"
import "core:net"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//

//This file is purely for testing server functionality and interaction with a client
OST_TEST_CLIENT :: proc(config: types.Server_Config) -> int {
	endpoint := net.Endpoint{net.IP4_Address{127, 0, 0, 1}, config.port}

	fmt.println("Connecting to server...")
	client_socket, connect_err := net.dial_tcp(endpoint)
	if connect_err != nil {
		fmt.println("Error connecting to server:", connect_err)
		return -1
	}
	defer net.close(client_socket)

	//test request to get server version on /version endpoint
	request := fmt.tprintf(
		"GET /version HTTP/1.1\r\nHost: localhost:%d\r\nConnection: close\r\n\r\n",
		config.port,
	)
	//test request to get a specific cluster on /collection/foo/cluster/bar endpoint
	// request := fmt.tprintf(
	// 	"GET /collection/foo/cluster/bar HTTP/1.1\r\nHost: localhost:%d\r\nConnection: close\r\n\r\n",
	// 	config.port,
	// )
	request_bytes := transmute([]byte)request

	fmt.println("Sending HTTP GET request to /version...")
	_, send_err := net.send(client_socket, request_bytes)
	if send_err != nil {
		fmt.println("Error sending request:", send_err)
		return -1
	}

	buf: [1024]byte
	fmt.println("Waiting for server response...")
	bytes_read, recv_err := net.recv(client_socket, buf[:])
	if recv_err != nil {
		fmt.println("Error receiving response:", recv_err)
		return -1
	}

	fmt.printf("Server response:\n%s\n", string(buf[:bytes_read]))
	return 0
}
