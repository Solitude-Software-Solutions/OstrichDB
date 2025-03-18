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
		pathMatch := is_path_match(route.p, path)
		if pathMatch {
			return route.h(method, path, headers)
		}
	}

	fmt.println("Method: ", method) //debugging
	fmt.println("Path: ", path) //debugging
	fmt.println("Headers: ", headers) //debugging

	return types.HttpStatus{code = .NOT_FOUND, text = types.HttpStatusText[.NOT_FOUND]},
		"404 Not Found\n"
}


//Helper proc used to match routes with dynamic paths
// is_path_match :: proc(routePath: string, requestPath: string) -> bool {
// 	// Split the route and request paths into segments
// 	routeSegments := strings.split(strings.trim_prefix(routePath, "/"), "/")
// 	requestSegments := strings.split(strings.trim_prefix(requestPath, "/"), "/")
// 	// fmt.println("len(requestSegments): ", len(requestSegments)) //debugging
// 	for segment, i in requestSegments {
// 		fmt.println("Request Segment: ", segment) //debugging
// 		// fmt.println("Request Segment Index: ", i) //debugging
// 	}


// 	//If a query parameter is present in the last segment, split it off so that
// 	//it is not included in the comparison
// 	if len(requestSegments) == 6 && strings.contains(requestSegments[5], "?") {
// 		requestSegments[5] = strings.split(requestSegments[5], "?")[0]
// 	}

// 	fmt.println("Request Segments: ", requestSegments) //debugging
// 	defer delete(routeSegments)
// 	defer delete(requestSegments)

// 	//if the length of the route and request segments are not equal, return false
// 	if len(routeSegments) != len(requestSegments) do return false


// 	// Iterate through the segments and compare them
// 	for segment, i in routeSegments {
// 		if segment == "*" do continue // Skip wildcard segments. This is allows for dynamic paths
// 		if segment == "?" do continue //skip segments with query parameters
// 		if segment != requestSegments[i] do return false // If the segments don't match, return false
// 	}
// 	return true
// }


is_path_match :: proc(routePath: string, requestPath: string) -> bool {
	// Split the route and request paths into segments
	routeSegments := strings.split(strings.trim_prefix(routePath, "/"), "/")
	requestSegments := strings.split(strings.trim_prefix(requestPath, "/"), "/")

	// Handle query parameters in both route and request paths
	lastRouteSegment := routeSegments[len(routeSegments) - 1]
	lastRequestSegment := requestSegments[len(requestSegments) - 1]

	// Extract base paths (without query parameters)
	if strings.contains(lastRouteSegment, "?") {
		routeSegments[len(routeSegments) - 1] = strings.split(lastRouteSegment, "?")[0]
	}
	if strings.contains(lastRequestSegment, "?") {
		requestSegments[len(requestSegments) - 1] = strings.split(lastRequestSegment, "?")[0]
	}

	defer delete(routeSegments)
	defer delete(requestSegments)

	// If the length of the route and request segments are not equal, return false
	if len(routeSegments) != len(requestSegments) do return false

	// Iterate through the segments and compare them
	for segment, i in routeSegments {
		if segment == "*" do continue // Skip wildcard segments
		if segment != requestSegments[i] do return false
	}

	// If we have query parameters in the route, verify they exist in the request
	if strings.contains(lastRouteSegment, "?") {
		routeQuery := strings.split(lastRouteSegment, "?")[1]
		requestQuery := strings.split(lastRequestSegment, "?")[1]

		// Split query parameters
		route_params := strings.split(routeQuery, "&")
		request_params := strings.split(requestQuery, "&")
		defer delete(route_params)
		defer delete(request_params)

		// Check each required parameter exists
		for param in route_params {
			if param == "*" do continue // Skip wildcard parameters
			param_found := false
			for req_param in request_params {
				if strings.has_prefix(req_param, strings.split(param, "=")[0]) {
					param_found = true
					break
				}
			}
			if !param_found do return false
		}
	}

	return true
}
