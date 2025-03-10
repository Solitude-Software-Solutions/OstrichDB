package server
import "../types"
import "core:fmt"
import "core:strings"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            Contains logic for handling HTTP requests and responses.
            Unstable and not fully implemented.
*********************************************************/

//Create a new router
OST_NEW_ROUTER :: proc() -> ^types.Router {
	router := new(types.Router)
	router.routes = make([dynamic]types.Route)

	return router
}

//Adds a route to the newly created router
OST_ADD_ROUTE :: proc(
	router: ^types.Router,
	method: types.HttpMethod,
	path: string,
	handler: types.RouteHandler,
) {

	route := types.Route {
		m = method,
		p = path,
		h = handler,
	}
	append(&router.routes, route)
}

//This finds the route that matches the path and calls appropriate handler
OST_HANDLE_REQUEST :: proc(
	router: ^types.Router,
	method: string,
	path: string,
	headers: map[string]string,
) -> (
	status: types.HttpStatus,
	response: string,
) {
	// fmt.println("router being passed to handle request proc: ", router) //debugging
	// fmt.println("method being passed to handle request proc: ", method) //debugging
	// fmt.println("path being passed to handle request proc: ", path) //debugging
	// fmt.println("headers being passed to handle request proc: ", headers) //debugging
	for route in router.routes {
		if strings.compare(path, route.p) == 0 {
			return route.h(method, path, headers)
		}
	}

	return types.HttpStatus{code = .NOT_FOUND, text = types.HttpStatusText[.NOT_FOUND]},
		"404 Not Found\n"
}
