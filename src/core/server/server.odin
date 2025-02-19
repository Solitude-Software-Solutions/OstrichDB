package server
import "../../utils"
import "../types"
import "core:fmt"
import "core:net"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright 2024 - Present Marshall A Burns & Solitude Software Solutions LLC
*********************************************************/
router: ^types.Router

OST_START_SERVER :: proc(config: types.Server_Config) -> int {
	router = OST_NEW_ROUTER()

	//test routes
	//todo: all these are test routes. will end up linking with SDK and allowing user to define routes
	//todo: seems like only one route can be added at a time. If more than one is added we
	// get "Method Not Found"...idk why - Marshall Burns aka SchoolyB

	// OST_ADD_ROUTE(router, .GET, "/version", OST_HANDLE_GET_REQ)
	// OST_ADD_ROUTE(router, .HEAD, "/collection/foo/cluster/bar", OST_HANDLE_HEAD_REQ)
	// OST_ADD_ROUTE(router, .GET, "/collection/foo/cluster/bar", OST_HANDLE_GET_REQ)
	// OST_ADD_ROUTE(
	// 	router,
	// 	.PUT,
	// 	"/collection/foo/cluster/bar/record/baz?type=string&value=goodbye",
	// 	OST_HANDLE_PUT_REQ,
	// )
	// OST_ADD_ROUTE(router, .DELETE, "/collection/foo", OST_HANDLE_DELETE_REQ)
	OST_ADD_ROUTE(
		router,
		.POST,
		"/batch/collection/foo/cluster/foo&bar&baz&goob",
		OST_HANDLE_POST_REQ,
	)
	// OST_ADD_ROUTE(router, .POST, "/batch/collection/foo&bar/cluster/foo&bar", OST_HANDLE_POST_REQ)
	// fmt.println("Routes after adding: ", router.routes) //debugging

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
		// fmt.println("Received %d bytes from client", bytes_read) //debugging
		// fmt.println("Data received: ", string(buf[:bytes_read])) //debugging
		// Parse incoming request
		method, path, headers := OST_PARSE_REQUEST(buf[:bytes_read])
		fmt.printf("Parsed request - Method: %s, Path: %s\n", method, path) //debuggging

		// Create response headers
		response_headers := make(map[string]string)
		response_headers["Content-Type"] = "text/plain"
		response_headers["Server"] = "OstrichDB"


		// fmt.println("Headers From Server: ", headers) //debugging
		// fmt.println("Router From Server: ", router) //debugging
		// fmt.println("Method From Server: ", method) //debugging
		// fmt.println("Path From Server: ", path) //debugging

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
