package engine

import "../../utils"
import "../config"
import "../const"
import "../types"
import "./data"
import "./data/metadata"
import "./security"
import "core:c/libc"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//


//initialize the data integrity system
OST_INIT_INTEGRITY_CHECKS_SYSTEM :: proc(checks: ^types.Data_Integrity_Checks) -> (success: int) {
	types.data_integrity_checks.File_Size.Severity = .LOW
	types.data_integrity_checks.File_Format_Version.Severity = .MEDIUM
	types.data_integrity_checks.Cluster_IDs.Severity = .HIGH
	types.data_integrity_checks.Data_Types.Severity = .HIGH
	types.data_integrity_checks.File_Format.Severity = .HIGH

	types.data_integrity_checks.File_Size.Error_Message =
	"Collection file size is larger than the maxmimum size of 10mb"
	types.data_integrity_checks.File_Format.Error_Message =
	"A formatting error was found in the collection file"
	types.data_integrity_checks.File_Format_Version.Error_Message =
	"Collection file format version is not compliant with the current version"
	types.data_integrity_checks.Cluster_IDs.Error_Message = "Cluster ID(s) not found in cache"
	types.data_integrity_checks.Data_Types.Error_Message =
	"Data type(s) found in collection are not approved"
	return 0

}
OST_START_ENGINE :: proc() -> int {
	//Initialize data integrity system
	OST_INIT_INTEGRITY_CHECKS_SYSTEM(&types.data_integrity_checks)
	switch (types.engine.Initialized) 
	{
	case false:
		security.OST_INIT_ADMIN_SETUP()
		break

	case true:
		for {
			userSignedIn := OST_RUN_SIGNIN()
			switch (userSignedIn) 
			{
			case true:
				OST_START_SESSION_TIMER()
				utils.log_runtime_event(
					"User Signed In",
					"User successfully logged into OstrichDB",
				)
				result := OST_ENGINE_COMMAND_LINE()
				return result

			case false:
				fmt.printfln("Sign in failed. Please try again.")
				continue
			}
		}
	}
	return 0
}


OST_ENGINE_COMMAND_LINE :: proc() -> int {
	fmt.println("Welcome to the OstrichDB DBMS Command Line")
	utils.log_runtime_event("Entered DBMS command line", "")
	for {
		//Command line start
		buf: [1024]byte

		fmt.print(const.ost_carrot, "\t")
		n, inputSuccess := os.read(os.stdin, buf[:])
		if inputSuccess != 0 {
			error := utils.new_err(
				.CANNOT_READ_INPUT,
				utils.get_err_msg(.CANNOT_READ_INPUT),
				#procedure,
			)
			utils.throw_err(error)
			utils.log_err("Could not read user input from command line", #procedure)
		}
		input := strings.trim_right(string(buf[:n]), "\r\n")
		OST_APPEND_COMMAND_TO_HISTORY(input)
		cmd := OST_PARSE_COMMAND(input)
		// fmt.printfln("Command: %v", cmd) //debugging

		//Check to ensure that before the next command is executed, the max session time hasnt been met
		sessionDuration := OST_GET_SESSION_DURATION()
		maxDurationMet := OST_CHECK_SESSION_DURATION(sessionDuration)
		switch (maxDurationMet) 
		{
		case false:
			break
		case true:
			OST_HANDLE_MAX_SESSION_DURATION_MET()
		}

		result := OST_EXECUTE_COMMAND(&cmd)

		//Command line end
	}

}


OST_RESTART :: proc() {
	libc.system("../scripts/restart.sh")
	os.exit(0)
}

OST_REBUILD :: proc() {
	libc.system("../scripts/build.sh")
	os.exit(0)
}
