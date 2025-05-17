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
import "../nlp"
import "core:strconv"
import "core:strings"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-2025 Marshall A Burns and Solitude Software Solutions LLC
Copyright (c) 2025-Present Archetype Dynamics, Inc.

File Description:
            Contains logic for handling incoming requests to the OstrichDB server.
            Currently unstable and not fully implemented.
*********************************************************/
router: ^types.Router
isRunning := true

//The isAutoServing flag is added for NLP. Auto serving will be set to true by default.
START_OSTRICH_SERVER :: proc(config: ^types.OstrichDB_Server) -> int {
	using const
	using types


	CREATE_SERVER_LOG_FILE()
	isRunning = true

	newServerSession:= CREATE_SERVER_SESSION(types.current_user)

	initializedServerStartEvent := SET_SERVER_EVENT_INFORMATION(
		"Server Session Start",
		"OstrichDB Server started",
		ServerEventType.ROUTINE,
		newServerSession.start_timestamp,
		false,
		"",
		nil,
	)

	PRINT_SERVER_EVENT_INFORMATION(initializedServerStartEvent)
	router = CREATE_NEW_ROUTER()
	defer free(router)



	//OstrichDB GET version static route and server logging
	ADD_ROUTE_TO_ROUTER(router, .GET, "/version", HANDLE_GET_REQUEST)
	versionRouteEvent := SET_SERVER_EVENT_INFORMATION(
		"Add Route",
		"Added '/version' static GET route to router",
		ServerEventType.ROUTINE,
		time.now(),
		false,
		"",
		nil,
	)
	PRINT_SERVER_EVENT_INFORMATION(versionRouteEvent)

	// HEAD, POST, GET, DELETE dynamic routes for collections as well as server logging
	ADD_ROUTE_TO_ROUTER(router, .HEAD, C_DYNAMIC_BASE, HANDLE_HEAD_REQUEST)
	addHeadColRoute := SET_SERVER_EVENT_INFORMATION(
		"Add Route",
		give_description("HEAD",C_DYNAMIC_BASE),
		ServerEventType.ROUTINE,
		time.now(),
		false,
		"",
		nil,
	)
	PRINT_SERVER_EVENT_INFORMATION(addHeadColRoute)

	ADD_ROUTE_TO_ROUTER(router, .POST, C_DYNAMIC_BASE, HANDLE_POST_REQUEST)
	addPostColRoute := SET_SERVER_EVENT_INFORMATION(
		"Add Route",
		give_description(methodString[.POST],C_DYNAMIC_BASE),
		ServerEventType.ROUTINE,
		time.now(),
		false,
		"",
		nil,
	)
	PRINT_SERVER_EVENT_INFORMATION(addPostColRoute)

	ADD_ROUTE_TO_ROUTER(router, .GET, C_DYNAMIC_BASE, HANDLE_GET_REQUEST)
	addGetColRoute := SET_SERVER_EVENT_INFORMATION(
		"Add Route",
		give_description(methodString[.GET],C_DYNAMIC_BASE),
		ServerEventType.ROUTINE,
		time.now(),
		false,
		"",
		nil,
	)
	PRINT_SERVER_EVENT_INFORMATION(addGetColRoute)

	ADD_ROUTE_TO_ROUTER(router, .DELETE, C_DYNAMIC_BASE, HANDLE_DELETE_REQUEST)
	addDeleteColRoute := SET_SERVER_EVENT_INFORMATION(
		"Add Route",
		give_description(methodString[.DELETE],C_DYNAMIC_BASE),
		ServerEventType.ROUTINE,
		time.now(),
		false,
		"",
		nil,
	)
	PRINT_SERVER_EVENT_INFORMATION(addDeleteColRoute)


	// HEAD, POST, GET, DELETE dynamic routes for clusters as well as server logging
	ADD_ROUTE_TO_ROUTER(router, .HEAD, CL_DYNAMIC_BASE, HANDLE_HEAD_REQUEST)
	addHeadCluRoute := SET_SERVER_EVENT_INFORMATION(
		"Add Route",
		give_description(methodString[.HEAD],CL_DYNAMIC_BASE),
		ServerEventType.ROUTINE,
		time.now(),
		false,
		"",
		nil,
	)
	PRINT_SERVER_EVENT_INFORMATION(addHeadCluRoute)

	ADD_ROUTE_TO_ROUTER(router, .POST, CL_DYNAMIC_BASE, HANDLE_POST_REQUEST)
	addPostCluRoute := SET_SERVER_EVENT_INFORMATION(
		"Add Route",
		give_description(methodString[.POST],CL_DYNAMIC_BASE),
		ServerEventType.ROUTINE,
		time.now(),
		false,
		"",
		nil,
	)
	PRINT_SERVER_EVENT_INFORMATION(addPostCluRoute)

	ADD_ROUTE_TO_ROUTER(router, .GET, CL_DYNAMIC_BASE, HANDLE_GET_REQUEST)
	addGetCluRoute := SET_SERVER_EVENT_INFORMATION(
		"Add Route",
		give_description(methodString[.GET],CL_DYNAMIC_BASE),
		ServerEventType.ROUTINE,
		time.now(),
		false,
		"",
		nil,
	)
	PRINT_SERVER_EVENT_INFORMATION(addGetCluRoute)

	ADD_ROUTE_TO_ROUTER(router, .DELETE, CL_DYNAMIC_BASE, HANDLE_DELETE_REQUEST)
	addDeleteCluRoute := SET_SERVER_EVENT_INFORMATION(
		"Add Route",
		give_description(methodString[.DELETE],CL_DYNAMIC_BASE),
		ServerEventType.ROUTINE,
		time.now(),
		false,
		"",
		nil,
	)
	PRINT_SERVER_EVENT_INFORMATION(addDeleteCluRoute)


	// HEAD, POST, GET, DELETE dynamic routes for clusters as well as server logging
	ADD_ROUTE_TO_ROUTER(router, .HEAD, R_DYNAMIC_BASE, HANDLE_HEAD_REQUEST)
	addHeadRecRoute := SET_SERVER_EVENT_INFORMATION(
		"Add Route",
		give_description(methodString[.HEAD],R_DYNAMIC_BASE),
		ServerEventType.ROUTINE,
		time.now(),
		false,
		"",
		nil,
	)
	PRINT_SERVER_EVENT_INFORMATION(addHeadRecRoute)

	ADD_ROUTE_TO_ROUTER(router, .POST, R_DYNAMIC_TYPE_QUERY, HANDLE_POST_REQUEST)
	addPostRecRoute := SET_SERVER_EVENT_INFORMATION(
		"Add Route",
		give_description(methodString[.POST],R_DYNAMIC_TYPE_QUERY),
		ServerEventType.ROUTINE,
		time.now(),
		false,
		"",
		nil,
	)
	PRINT_SERVER_EVENT_INFORMATION(addPostRecRoute)

	ADD_ROUTE_TO_ROUTER(router, .PUT, R_DYNAMIC_TYPE_VALUE_QUERY, HANDLE_PUT_REQUEST)
	addPutRecRoute := SET_SERVER_EVENT_INFORMATION(
		"Add Route",
		give_description(methodString[.PUT],R_DYNAMIC_TYPE_VALUE_QUERY),
		ServerEventType.ROUTINE,
		time.now(),
		false,
		"",
		nil,
	)
	PRINT_SERVER_EVENT_INFORMATION(addPutRecRoute)

	ADD_ROUTE_TO_ROUTER(router, .GET, R_DYNAMIC_BASE, HANDLE_GET_REQUEST)
	addGetRecRoute := SET_SERVER_EVENT_INFORMATION(
		"Add Route",
		give_description(methodString[.GET],R_DYNAMIC_BASE),
		ServerEventType.ROUTINE,
		time.now(),
		false,
		"",
		nil,
	)
	PRINT_SERVER_EVENT_INFORMATION(addGetRecRoute)

	ADD_ROUTE_TO_ROUTER(router, .DELETE, R_DYNAMIC_BASE, HANDLE_DELETE_REQUEST)
	addDeleteRecRoute := SET_SERVER_EVENT_INFORMATION(
		"Add Route",
		give_description(methodString[.DELETE],R_DYNAMIC_BASE),
		ServerEventType.ROUTINE,
		time.now(),
		false,
		"",
		nil,
	)
	PRINT_SERVER_EVENT_INFORMATION(addDeleteRecRoute)



	// POST & GET dynamic routes for collections, clusters and records
	ADD_ROUTE_TO_ROUTER(router, .POST, BATCH_C_DYNAMIC_BASE, HANDLE_POST_REQUEST)
	   addBatchColPostRoute:= SET_SERVER_EVENT_INFORMATION("Add Route",
				give_description(methodString[.POST],BATCH_C_DYNAMIC_BASE),
				ServerEventType.ROUTINE,
			    time.now(),
				false,
				"",
				nil
		)
	PRINT_SERVER_EVENT_INFORMATION(addBatchColPostRoute)

	ADD_ROUTE_TO_ROUTER(router, .POST, BATCH_CL_DYNAMIC_BASE, HANDLE_POST_REQUEST)
	   addBatchCluPostRoute:= SET_SERVER_EVENT_INFORMATION("Add Route",
				give_description(methodString[.POST],BATCH_CL_DYNAMIC_BASE),
				ServerEventType.ROUTINE,
			    time.now(),
				false,
				"",
				nil
		)
	PRINT_SERVER_EVENT_INFORMATION(addBatchCluPostRoute)

	ADD_ROUTE_TO_ROUTER(router, .POST, BATCH_R_DYNAMIC_BASE, HANDLE_POST_REQUEST)
	   addBatchRPostRoute:= SET_SERVER_EVENT_INFORMATION("Add Route",
				give_description(methodString[.POST],BATCH_R_DYNAMIC_BASE),
				ServerEventType.ROUTINE,
			    time.now(),
				false,
				"",
				nil
		)
	PRINT_SERVER_EVENT_INFORMATION(addBatchRPostRoute)

	ADD_ROUTE_TO_ROUTER(router, .GET, BATCH_C_DYNAMIC_BASE, HANDLE_POST_REQUEST)
	   addBatchColGetRoute:= SET_SERVER_EVENT_INFORMATION("Add Route",
				give_description(methodString[.GET],BATCH_C_DYNAMIC_BASE),
				ServerEventType.ROUTINE,
			    time.now(),
				false,
				"",
				nil
		)
	PRINT_SERVER_EVENT_INFORMATION(addBatchColGetRoute)


	ADD_ROUTE_TO_ROUTER(router, .GET, BATCH_CL_DYNAMIC_BASE, HANDLE_POST_REQUEST)
	   addBatchCluGetRoute:= SET_SERVER_EVENT_INFORMATION("Add Route",
				give_description(methodString[.GET],BATCH_CL_DYNAMIC_BASE),
				ServerEventType.ROUTINE,
			    time.now(),
				false,
				"",
				nil
		)
	PRINT_SERVER_EVENT_INFORMATION(addBatchCluGetRoute)

	ADD_ROUTE_TO_ROUTER(router, .GET, BATCH_R_DYNAMIC_BASE, HANDLE_POST_REQUEST)
	   addBatchRecGetRoute:= SET_SERVER_EVENT_INFORMATION("Add Route",
				give_description(methodString[.GET],BATCH_R_DYNAMIC_BASE),
				ServerEventType.ROUTINE,
			    time.now(),
				false,
				"",
				nil
		)
	PRINT_SERVER_EVENT_INFORMATION(addBatchRecGetRoute)





	//TODO: Need to come back to batch requests...
	// ADD_ROUTE_TO_ROUTER(
	// 	router,
	// 	.POST,
	// 	"/batch/c/foo/cl/foo&bar&baz&goob",
	// 	HANDLE_POST_REQUEST,
	// )
	// ADD_ROUTE_TO_ROUTER(router, .POST, "/batch/c/foo&bar/cl/foo&bar", HANDLE_POST_REQUEST)


	//Assign the first usable OstrichDB port. Default is set to 8042 but might be taken
	usablePort:= CHECK_IF_PORT_IS_FREE(const.Server_Ports)
    for p in const.Server_Ports {
        if p != usablePort{
                config.port = usablePort
                break
        }
    }

	//Create a new endpoint to listen on
	endpoint := net.Endpoint{net.IP4_Address{0, 0, 0, 0}, config.port} //listen on all interfaces


	// Creates and listens on a TCP socket
	listen_socket, listen_err := net.listen_tcp(endpoint, 5)
	if listen_err != nil {
		fmt.println("Error listening on socket: ", listen_err)
		return -1
	}


	//Start a thread to handle user input for killing the server
	thread.run(HANDLE_SERVER_KILL_SWITCH)
	defer net.close(net.TCP_Socket(listen_socket))

	fmt.printf(
		"OstrichDB server listening on port: %s%d%s\n",
		utils.BOLD_UNDERLINE,
		config.port,
		utils.RESET,
	)
	//Main server loop
	for isRunning {
		//update the session runtime periodically to check against the limit
		newServerSession.end_timestamp = time.now()
		newServerSession.total_runtime = time.diff(newServerSession.start_timestamp, newServerSession.end_timestamp)
		result:=SERVER_SESSION_LIMIT_MET(newServerSession)
		if result  {
		    fmt.printfln("%sWARNING:%s Maximum server session time of 24 hours reached. Shutting down server...", utils.YELLOW, utils.RESET)
		    isRunning = false
		    // Ping each possible OstrichDB port and if its running kill it
		    for port in const.Server_Ports {
		        portCString := strings.clone_to_cstring(fmt.tprintf("nc -zv localhost %d", port))
		        libc.system(portCString)
		    }
		    break
		}

		fmt.println("Waiting for new connection...")
		client_socket, remote_endpoint, accept_err := net.accept_tcp(listen_socket)

		if accept_err != nil {
			fmt.println("Error accepting connection: ", accept_err)
			return -1
		}
		handle_connection(client_socket)
	}
	newServerSession.end_timestamp = time.now()
	newServerSession.total_runtime = time.diff(newServerSession.start_timestamp, newServerSession.end_timestamp)
	fmt.println("Server stopped successfully")
	fmt.println("Total server session runtime time was: ", newServerSession.total_runtime)
	//Destroy the session
	free(newServerSession)
	return 0
}

//Tells the server what to do when upon accepting a connection
handle_connection :: proc(socket: net.TCP_Socket) {
	defer net.close(socket)
	buf: [1024]byte
	fmt.println("Connection handler started")

	for {
		fmt.println("Waiting to receive data...")
		bytesRead, read_err := net.recv(socket, buf[:])

		if read_err != nil {
			fmt.println("Error reading from socket:", read_err)
			return
		}
		if bytesRead == 0 {
			fmt.println("Connection closed by client")
			return
		}


		// Parse incoming request
		method, path, headers := PARSE_HTTP_REQUEST(buf[:bytesRead])

		// Create response headers
		responseHeaders := make(map[string]string)
		responseHeaders["Content-Type"] = "text/plain"
		responseHeaders["Server"] = "OstrichDB"

        defer delete(responseHeaders)

        m:types.HttpMethod

        switch(method) {
        case "HEAD":
            m = .HEAD
            break
        case "GET":
            m = .GET
            break
        case "POST":
            m = .POST
            break
        case "PUT":
            m = .PUT
            break
        case "DELETE":
            m = .DELETE
            break
        }

        // Handle the request using router
        status, responseBody := HANDLE_HTTP_REQUEST(router, method, path, headers)
        handleRequestEvent := SET_SERVER_EVENT_INFORMATION(
            "Attempt Request",
            "Attempting to handle request made over the server",
            types.ServerEventType.ROUTINE,
            time.now(),
            true,
            path,
            m,
        )

        PRINT_SERVER_EVENT_INFORMATION(handleRequestEvent)
        LOG_SERVER_EVENT(handleRequestEvent)


        // Build and send response
        response := BUILD_HTTP_RESPONSE(status, responseHeaders, responseBody)
        buildResponseEvent := SET_SERVER_EVENT_INFORMATION(
            "Build Response",
            "Attempting to build a response for the request",
            types.ServerEventType.ROUTINE,
            time.now(),
            false,
            path,
            m,
        )
        PRINT_SERVER_EVENT_INFORMATION(buildResponseEvent)
        LOG_SERVER_EVENT(buildResponseEvent)

        if len(response) == 0 {
            buildResponseFailEvent := SET_SERVER_EVENT_INFORMATION(
                "Failed Reponse Build",
                "Failed to build a response",
                types.ServerEventType.WARNING,
                time.now(),
                false,
                path,
                m,
            )
            PRINT_SERVER_EVENT_INFORMATION(buildResponseFailEvent)
            LOG_SERVER_EVENT(buildResponseFailEvent)
        }

        _, write_err := net.send(socket, response)
        writeResponseToSocket := SET_SERVER_EVENT_INFORMATION(
            "Write Respone To Socket",
            "Attempting to write a response to the socket",
            types.ServerEventType.ROUTINE,
            time.now(),
            false,
            path,
            m,
        )

        PRINT_SERVER_EVENT_INFORMATION(writeResponseToSocket)
        LOG_SERVER_EVENT(writeResponseToSocket)

        if write_err != nil {
            writeResponseToSocketFail := SET_SERVER_EVENT_INFORMATION(
                "Failed To Write To Socket",
                "Failed to write a response to the socket",
                types.ServerEventType.CRITICAL_ERROR,
                time.now(),
                false,
                path,
                m,
            )
            PRINT_SERVER_EVENT_INFORMATION(writeResponseToSocketFail)
            LOG_SERVER_EVENT(writeResponseToSocketFail)

            fmt.println("Error writing to socket:", write_err)
            return
        }

        fmt.println("Response sent successfully")
    }

    fmt.println("Connection handler stopping due to server shutdown")
}

//Looks over all the possible ports that OstrichDB uses. If the first is free, use it, if not use the next available port.
CHECK_IF_PORT_IS_FREE :: proc(ports: []int) -> int {
    buf := new([8]byte)
    defer free(buf)

    for potentialPort in ports {
        portAsStr := strconv.itoa(buf[:], potentialPort)
        termCommand := fmt.tprintf("lsof -i :%s > /dev/null 2>&1", portAsStr)
        cString := strings.clone_to_cstring(termCommand)
        defer delete(cString)

        result := libc.system(cString)
        portFree := result != 0
        if portFree {
            return potentialPort
        }
    }

    return 0
}


HANDLE_SERVER_KILL_SWITCH :: proc() {
	for isRunning {
		input := utils.get_input(false)
		if input == "kill" || input == "exit" {
			fmt.println("Stopping OstrichDB server...")
			isRunning = false
			//ping the server to essentially refresh it to ensure it stops thus breaking the server main loop
			for port in const.Server_Ports{
				portCString := strings.clone_to_cstring(fmt.tprintf("nc -zv localhost %d", port))
				libc.system(portCString)
			}
			return
		} else {
			fmt.printfln("Invalid input. Type 'kill' or 'exit' to stop the server.")
		}
	}
}


give_description ::proc(method:string, constant:string) -> string{
    return strings.clone(fmt.tprintf("Added %s dynamic %s route to router", method, constant),)
}