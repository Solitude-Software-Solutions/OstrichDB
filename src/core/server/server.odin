package server

import "../../utils"
import "../types"
import "core:fmt"
import "core:net"

//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//

OST_START_SERVER :: proc(config: types.Server_Config) -> int {

	//Create a new endpoint to listen on
	endpoint := net.Endpoint{net.IP4_Address{0, 0, 0, 0}, config.port} //listen on all interfaces


	// Creates and listens on a TCP socket
	listen_socket, listen_err := net.listen_tcp(endpoint, 5)
	if listen_err != nil {
		fmt.println("Error listening on socket: ", listen_err)
		return -1
	}

	//Seems like using net.listen_tcp() already binds the socket to the endpoint - Marshall Burns aka SchoolyB
	defer net.close(net.TCP_Socket(listen_socket))

	fmt.printf("Server listening on port %d\n", config.port)

	//Main server loop
	for {
		fmt.println("Waiting for new connection...")
		client_socket, remote_endpoint, accept_err := net.accept_tcp(listen_socket)

		if accept_err != nil {
			fmt.println("Error accepting connection: ", accept_err)
			return -1
		}

		fmt.printf("New connection accepted from %v\n", remote_endpoint)
		handle_connection(client_socket)
	}
	return 0
}

//Tells the server what to do when upon accepting a connection
handle_connection :: proc(socket: net.TCP_Socket) {
	defer net.close(socket)

	// Use fixed buffer instead of dynamic
	buf: [1024]byte

	fmt.println("Connection handler started")

	for {
		fmt.println("Waiting to receive data...")
		bytes_read, read_err := net.recv(socket, buf[:])

		if read_err != nil {
			fmt.println("Error reading from socket: ", read_err)
			return
		}
		if bytes_read == 0 {
			fmt.println("Connection closed by client")
			return
		}

		fmt.printf("Received %d bytes: %s\n", bytes_read, string(buf[:bytes_read]))

		response := "Hello From The OstrichDB Server!\n"
		response_bytes := transmute([]byte)response

		fmt.printf("Sending response: %s\n", response)
		writeSuccess, write_err := net.send(socket, response_bytes)

		if write_err != nil {
			fmt.println("Error writing to socket: ", write_err)
			return
		}

		fmt.printf("Response sent successfully: %d bytes\n", writeSuccess)
	}
}
