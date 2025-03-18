package server
import "../../utils"
import "../types"
import "core:c/libc"
import "core:fmt"
import "core:net"
import "core:os"
import "core:thread"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            Contains logic for handling incoming requests to the OstrichDB server.
            Currently unstable and not fully implemented.
*********************************************************/
router: ^types.Router
isRunning := true

OST_START_SERVER :: proc(config: types.Server_Config) -> int {
	isRunning = true
	router = OST_NEW_ROUTER()


	//OstrichDB version route
	OST_ADD_ROUTE(router, .GET, "/version", OST_HANDLE_GET_REQ)
	//Collection creation route
	OST_ADD_ROUTE(router, .POST, "/c/*", OST_HANDLE_POST_REQ)
	//Collection deletion route
	OST_ADD_ROUTE(router, .DELETE, "/c/*", OST_HANDLE_DELETE_REQ)

	//Cluster creation route
	OST_ADD_ROUTE(router, .POST, "/c/*/cl/*", OST_HANDLE_POST_REQ)


	//Record creation route
	OST_ADD_ROUTE(router, .POST, "/c/*/cl/*/r/*?type=*", OST_HANDLE_POST_REQ)
	// OST_ADD_ROUTE(router, .POST, "/c/*/cl/*/r/*?type=*", OST_HANDLE_POST_REQ)
	// OST_ADD_ROUTE(router, .HEAD, "/c/foo/cl/bar", OST_HANDLE_HEAD_REQ)
	// OST_ADD_ROUTE(router, .GET, "/c/foo/cl/bar", OST_HANDLE_GET_REQ)
	// OST_ADD_ROUTE(
	// 	router,
	// 	.PUT,
	// 	"/c/foo/cl/bar/r/baz?type=string&value=goodbye",
	// 	OST_HANDLE_PUT_REQ,
	// )
	// OST_ADD_ROUTE(router, .DELETE, "/c/foo", OST_HANDLE_DELETE_REQ)
	// OST_ADD_ROUTE(
	// 	router,
	// 	.POST,
	// 	"/batch/c/foo/cl/foo&bar&baz&goob",
	// 	OST_HANDLE_POST_REQ,
	// )
	// OST_ADD_ROUTE(router, .POST, "/batch/c/foo&bar/cl/foo&bar", OST_HANDLE_POST_REQ)


	//Create a new endpoint to listen on
	endpoint := net.Endpoint{net.IP4_Address{0, 0, 0, 0}, config.port} //listen on all interfaces

	// Creates and listens on a TCP socket
	listen_socket, listen_err := net.listen_tcp(endpoint, 5)
	if listen_err != nil {
		fmt.println("Error listening on socket: ", listen_err)
		return -1
	}

	//Start a thread to handle user input for killing the server
	thread.run(OST_HANDLE_SEVER_KILL_INPUT)
	defer net.close(net.TCP_Socket(listen_socket))

	fmt.printf(
		"OstrichDB server listening on port: %s%d%s\n",
		utils.BOLD_UNDERLINE,
		config.port,
		utils.RESET,
	)
	//Main server loop
	for isRunning {
		fmt.println("Waiting for new connection...")
		client_socket, remote_endpoint, accept_err := net.accept_tcp(listen_socket)


		if accept_err != nil {
			fmt.println("Error accepting connection: ", accept_err)
			return -1
		}
		handle_connection(client_socket)
	}
	fmt.println("Server stopped successfully")
	return 0
}

//Tells the server what to do when upon accepting a connection
handle_connection :: proc(socket: net.TCP_Socket) {
	defer net.close(socket)
	buf: [1024]byte
	fmt.println("Connection handler started")

	for {
		fmt.println("Waiting to receive data...")
		bytes_read, read_err := net.recv(socket, buf[:])

		if read_err != nil {
			fmt.println("Error reading from socket:", read_err)
			return
		}
		if bytes_read == 0 {
			fmt.println("Connection closed by client")
			return
		}


		// Parse incoming request
		method, path, headers := OST_PARSE_REQUEST(buf[:bytes_read])

		// Create response headers
		response_headers := make(map[string]string)
		response_headers["Content-Type"] = "text/plain"
		response_headers["Server"] = "OstrichDB"


		// Handle the request using router
		status, response_body := OST_HANDLE_REQUEST(router, method, path, headers)

		// Build and send response
		response := OST_BUILD_RESPONSE(status, response_headers, response_body)
		_, write_err := net.send(socket, response)

		if write_err != nil {
			fmt.println("Error writing to socket:", write_err)
			return
		}

		fmt.println("Response sent successfully")
	}
}

OST_HANDLE_SEVER_KILL_INPUT :: proc() {
	fmt.println("Enter 'kill' or 'exit' to stop the server")
	input := utils.get_input(false)
	if input == "kill" || input == "exit" {
		fmt.println("Stopping OstrichDB server...")
		isRunning = false
		//ping the server to essentially refresh it to ensure it stops thus breaking the sever main loop
		libc.system("nc -zv localhost 8042")
		return
	} else {
		fmt.println("Invalid input. Enter 'kill' or 'exit' to stop the server")
		OST_HANDLE_SEVER_KILL_INPUT()
	}
}
