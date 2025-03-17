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
	// for route in router.routes {
	// 	if strings.compare(path, route.p) == 0 {
	// 		return route.h(method, path, headers)
	// 	}
	// }


	for route in router.routes {
		// if strings.compare(method, route.m) != 0 do continue
		// Use dynamic path matching
		if is_path_match(route.p, path) {
			return route.h(method, path, headers)
		}
	}

	fmt.println("Method: ", method)
	fmt.println("Path: ", path)
	fmt.println("Headers: ", headers)

	return types.HttpStatus{code = .NOT_FOUND, text = types.HttpStatusText[.NOT_FOUND]},
		"404 Not Found\n"
}


//Helper proc used to match routes with dynamic paths
is_path_match :: proc(routePath: string, requestPath: string) -> bool {
	// Split the route and request paths into segments
	routeSegments := strings.split(strings.trim_prefix(routePath, "/"), "/")
	requestSegments := strings.split(strings.trim_prefix(requestPath, "/"), "/")
	defer delete(routeSegments)
	defer delete(requestSegments)

	//if the length of the route and request segments are not equal, return false
	if len(routeSegments) != len(requestSegments) do return false


	// Iterate through the segments and compare them
	for segment, i in routeSegments {
		if segment == "*" do continue // Skip wildcard segments. This is allows for dynamic paths
		if segment != requestSegments[i] do return false // If the segments don't match, return false
	}
	return true
}
