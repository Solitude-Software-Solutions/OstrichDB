package server
import "../../utils"
import "../const"
import "../types"
import "core:c/libc"
import "core:fmt"
import "core:net"
import "core:os"
import "core:thread"
import "core:time"
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

//The isAutoServing flag is added for NLP. Auto serving will be set to true by default.
OST_START_SERVER :: proc(config: types.Server_Config) -> int {
	using const
	using types
	OST_CREATE_SERVER_LOG_FILE()
	isRunning = true
	initializedServerStartEvent:=OST_SET_EVENT_INFORMATION("Server Start","OstrichDB Server started",ServerEventType.ROUTINE, time.now(), false, "",nil)
	OST_LOG_AND_PRINT_SERVER_EVENT(initializedServerStartEvent)
	router = OST_NEW_ROUTER()
	defer free(router)


	//OstrichDB GET version static route nad
	OST_ADD_ROUTE(router, .GET, "/version", OST_HANDLE_GET_REQ)
	versionRouteEvent:=OST_SET_EVENT_INFORMATION("Add Route","Added '/version' static GET route to router",ServerEventType.ROUTINE, time.now(), false, "",nil)
	OST_LOG_AND_PRINT_SERVER_EVENT(versionRouteEvent)

	// HEAD, POST, GET, DELETE dynamic routes for collections as well as server logging
	OST_ADD_ROUTE(router, .HEAD, C_DYNAMIC_BASE, OST_HANDLE_HEAD_REQ)
	addHeadColRoute:= OST_SET_EVENT_INFORMATION("Add Route","Added '/c/*' dynamic HEAD route to router",ServerEventType.ROUTINE, time.now(), false, "",nil)
	OST_LOG_AND_PRINT_SERVER_EVENT(addHeadColRoute)

	OST_ADD_ROUTE(router, .POST, C_DYNAMIC_BASE, OST_HANDLE_POST_REQ)
	addPostColRoute:=OST_SET_EVENT_INFORMATION("Add Route","Added '/c/*' dynamic POST route to router",ServerEventType.ROUTINE, time.now(), false, "",nil)
	OST_LOG_AND_PRINT_SERVER_EVENT(addPostColRoute)

	OST_ADD_ROUTE(router, .GET, C_DYNAMIC_BASE, OST_HANDLE_GET_REQ)
	addGetColRoute:=OST_SET_EVENT_INFORMATION("Add Route","Added '/c/*' dynamic GET route to router",ServerEventType.ROUTINE, time.now(), false, "",nil)
	OST_LOG_AND_PRINT_SERVER_EVENT(addGetColRoute)

	OST_ADD_ROUTE(router, .DELETE, C_DYNAMIC_BASE, OST_HANDLE_DELETE_REQ)
	addDeleteColRoute:=OST_SET_EVENT_INFORMATION("Add Route","Added '/c/*' dynamic DELETE route to router",ServerEventType.ROUTINE, time.now(), false, "",nil)
	OST_LOG_AND_PRINT_SERVER_EVENT(addDeleteColRoute)


	// HEAD, POST, GET, DELETE dynamic routes for clusters as well as server logging
	OST_ADD_ROUTE(router, .HEAD, CL_DYNAMIC_BASE, OST_HANDLE_HEAD_REQ)
	addHeadCluRoute:=OST_SET_EVENT_INFORMATION("Add Route","Added '/c/*/cl/*' dynamic HEAD route to router",ServerEventType.ROUTINE, time.now(), false, "",nil)
	OST_LOG_AND_PRINT_SERVER_EVENT(addHeadCluRoute)

	OST_ADD_ROUTE(router, .POST, CL_DYNAMIC_BASE, OST_HANDLE_POST_REQ)
	addPostCluRoute:=OST_SET_EVENT_INFORMATION("Add Route","Added '/c/*/cl/*' dynamic POST route to router",ServerEventType.ROUTINE, time.now(), false, "",nil)
	OST_LOG_AND_PRINT_SERVER_EVENT(addPostCluRoute)

	OST_ADD_ROUTE(router, .GET, CL_DYNAMIC_BASE, OST_HANDLE_GET_REQ)
	addGetCluRoute:=OST_SET_EVENT_INFORMATION("Add Route","Added '/c/*/cl/*' dynamic GET route to router",ServerEventType.ROUTINE, time.now(), false, "",nil)
	OST_LOG_AND_PRINT_SERVER_EVENT(addGetCluRoute)

	OST_ADD_ROUTE(router, .DELETE, CL_DYNAMIC_BASE, OST_HANDLE_DELETE_REQ)
	addDeleteCluRoute:=OST_SET_EVENT_INFORMATION("Add Route","Added '/c/*/cl/*' dynamic DELETE route to router",ServerEventType.ROUTINE, time.now(), false, "",nil)
	OST_LOG_AND_PRINT_SERVER_EVENT(addDeleteCluRoute)


		// HEAD, POST, GET, DELETE dynamic routes for clusters as well as server logging
	OST_ADD_ROUTE(router, .HEAD, R_DYNAMIC_BASE, OST_HANDLE_HEAD_REQ)
	addHeadRecRoute:=OST_SET_EVENT_INFORMATION("Add Route","Added '/c/*/cl/*/r/*' dynamic HEAD route to router",ServerEventType.ROUTINE, time.now(), false, "",nil)
	OST_LOG_AND_PRINT_SERVER_EVENT(addHeadRecRoute)

	OST_ADD_ROUTE(router, .POST, R_DYNAMIC_TYPE_QUERY, OST_HANDLE_POST_REQ)
	addPostRecRoute:=OST_SET_EVENT_INFORMATION("Add Route","Added '/c/*/cl/*/r/*?type=*' dynamic POST route to router",ServerEventType.ROUTINE, time.now(), false, "",nil)
	OST_LOG_AND_PRINT_SERVER_EVENT(addPostRecRoute)

	OST_ADD_ROUTE(router, .PUT, R_DYNAMIC_TYPE_VALUE_QUERY, OST_HANDLE_PUT_REQ)
	addPutRecRoute:=OST_SET_EVENT_INFORMATION("Add Route","Added '/c/*/cl/*/r/*?type=*&value=*' dynamic PUT route to router",ServerEventType.ROUTINE, time.now(), false, "",nil)
	OST_LOG_AND_PRINT_SERVER_EVENT(addPutRecRoute)

	OST_ADD_ROUTE(router, .GET, R_DYNAMIC_BASE, OST_HANDLE_GET_REQ)
	addGetRecRoute:=OST_SET_EVENT_INFORMATION("Add Route","Added '/c/*/cl/*/r/*' dynamic GET route to router",ServerEventType.ROUTINE, time.now(), false, "",nil)
	OST_LOG_AND_PRINT_SERVER_EVENT(addGetRecRoute)

	OST_ADD_ROUTE(router, .DELETE, R_DYNAMIC_BASE, OST_HANDLE_DELETE_REQ)
	addDeleteRecRoute:=OST_SET_EVENT_INFORMATION("Add Route","Added '/c/*/cl/*/r/*' dynamic DELETE route to router",ServerEventType.ROUTINE, time.now(), false, "",nil)
	OST_LOG_AND_PRINT_SERVER_EVENT(addDeleteRecRoute)


	//TODO: Need to come back to batch requests...
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
	thread.run(OST_HANDLE_SERVER_KILL_INPUT)
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
		fmt.printfln("passing %s router: ", #procedure, router)
		status, response_body := OST_HANDLE_REQUEST(router, method, path, headers)
		handleRequestEvent := OST_SET_EVENT_INFORMATION("Attempt Request", "Attempting handle request made on the server",types.ServerEventType.ROUTINE, time.now(), true, path,nil)
		OST_LOG_AND_PRINT_SERVER_EVENT(handleRequestEvent)


		// Build and send response
		response := OST_BUILD_RESPONSE(status, response_headers, response_body)
		buildResponseEvent := OST_SET_EVENT_INFORMATION("Build Response", "Attempting build a response for the request",types.ServerEventType.ROUTINE, time.now(), false, "",nil)
		OST_LOG_AND_PRINT_SERVER_EVENT(buildResponseEvent)

		if len(response) == 0{
		   buildResponseFailEvent := OST_SET_EVENT_INFORMATION("Failed Reponse Build", "Failed to build a response",types.ServerEventType.WARNING, time.now(), false, "",nil)
		   OST_LOG_AND_PRINT_SERVER_EVENT(buildResponseFailEvent)
		}

		_, write_err := net.send(socket, response)
		writeResponseToSocket := OST_SET_EVENT_INFORMATION("Write Respone To Socket", "Attempting to write a response to the socket",types.ServerEventType.ROUTINE, time.now(), false, "",nil)
		OST_LOG_AND_PRINT_SERVER_EVENT(writeResponseToSocket)
		if write_err != nil {
		writeResponseToSocketFail := OST_SET_EVENT_INFORMATION("Failed To Write To Socket", "Failed to write a response to the socket",types.ServerEventType.CRITICAL_ERROR, time.now(), false, "",nil)
		OST_LOG_AND_PRINT_SERVER_EVENT(writeResponseToSocketFail)

			fmt.println("Error writing to socket:", write_err)
			return
		}

		fmt.println("Response sent successfully")
	}
}

OST_HANDLE_SERVER_KILL_INPUT :: proc() {
	utils.show_server_kill_msg()
	input := utils.get_input(false)
	if input == "kill" || input == "exit" {
		fmt.println("Stopping OstrichDB server...")
		isRunning = false
		//ping the server to essentially refresh it to ensure it stops thus breaking the server main loop
		libc.system("nc -zv localhost 8042")
		return
	} else {
		fmt.printfln("Invalid input")
		OST_HANDLE_SERVER_KILL_INPUT()
	}
}
