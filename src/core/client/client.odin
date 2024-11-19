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


	message := "Test message from client\n"
	message_bytes := transmute([]byte)message

	fmt.println("Sending message to server...")
	_, send_err := net.send(client_socket, message_bytes)
	if send_err != nil {
		fmt.println("Error sending message:", send_err)
		return -1
	}

	// Receive response
	buf: [1024]byte
	fmt.println("Waiting for server response...")
	bytes_read, recv_err := net.recv(client_socket, buf[:])
	if recv_err != nil {
		fmt.println("Error receiving response:", recv_err)
		return -1
	}

	fmt.printf("Server response: %s\n", string(buf[:bytes_read]))
	return 0
}
