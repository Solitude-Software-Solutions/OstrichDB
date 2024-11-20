package server

import "../../utils"
import "../types"
import "core:fmt"
import "core:strings"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//

//Mostly a test proc to see if the server is running. But also useful for checking the version using the GET method
handle_version_request :: proc(
	method: string,
	path: string,
	headers: map[string]string,
) -> (
	types.HttpStatus,
	string,
) {
	if method != "GET" {
		return types.HttpStatus{code = .BAD_REQUEST, text = types.HttpStatusText[.BAD_REQUEST]},
			"Method not allowed\n"
	}

	version := utils.get_ost_version()
	return types.HttpStatus {
		code = .OK,
		text = types.HttpStatusText[.OK],
	}, fmt.tprintf("OstrichDB Version: %s\n", version)
}
//Procedure that handles a GET request from the OstrichDB server
