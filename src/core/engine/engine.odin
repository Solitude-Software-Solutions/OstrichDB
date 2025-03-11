package engine

import "../../utils"
import "../const"
import "../types"
import "./config"
import "./data"
import "./data/metadata"
import "./security"
import "core:c/libc"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            Contains logic for the OstrichDB engine, including the command line,
            session timer, and command history updating. Also contains
            logic for re-starting/re-building the engine as well as
            initializing the data integrity system.
*********************************************************/


//initialize the data integrity system
OST_INIT_INTEGRITY_CHECKS_SYSTEM :: proc(checks: ^types.Data_Integrity_Checks) -> (success: int) {
	using types

	data_integrity_checks.File_Size.Severity = .LOW
	data_integrity_checks.File_Format_Version.Severity = .MEDIUM
	data_integrity_checks.Cluster_IDs.Severity = .HIGH
	data_integrity_checks.Data_Types.Severity = .HIGH
	data_integrity_checks.File_Format.Severity = .HIGH

	data_integrity_checks.File_Size.Error_Message =
	"Collection file size is larger than the maxmimum size of 10mb"
	data_integrity_checks.File_Format.Error_Message =
	"A formatting error was found in the collection file"
	data_integrity_checks.File_Format_Version.Error_Message =
	"Collection file format version is not compliant with the current version"
	data_integrity_checks.Cluster_IDs.Error_Message = "Cluster ID(s) not found in cache"
	data_integrity_checks.Data_Types.Error_Message =
	"Data type(s) found in collection are not approved"
	return 0

}

//Starts the OstrichDB engine:
//Session timer, sign in, and command line
OST_START_ENGINE :: proc() -> int {
	//Initialize data integrity system
	OST_INIT_INTEGRITY_CHECKS_SYSTEM(&types.data_integrity_checks)
	switch (types.OstrichEngine.Initialized)
	{
	case false:
		//Continue with engine initialization
		security.OST_INIT_ADMIN_SETUP()
		break

	case true:
		for {
		security.OST_ENCRYPT_COLLECTION(
			"",
			.CONFIG_PRIVATE,
			types.system_user.m_k.valAsBytes,
			false,
		)
			userSignedIn := security.OST_RUN_SIGNIN()
			switch (userSignedIn)
			{
			case true:

				security.OST_START_SESSION_TIMER()
				utils.log_runtime_event(
					"User Signed In",
					"User successfully logged into OstrichDB",
				)
				result := OST_ENGINE_COMMAND_LINE()
				return result
			case false:
				fmt.printfln("Sign in failed. Please try again.")
				security.OST_ENCRYPT_COLLECTION(
					"",
					.CONFIG_PRIVATE,
					types.system_user.m_k.valAsBytes,
					false,
				)
				continue
			}
		}
	}
	return 0
}

//Command line loop
OST_ENGINE_COMMAND_LINE :: proc() -> int {
	result := 0
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
				#file,
				#procedure,
				#line,
			)
			utils.throw_err(error)
			utils.log_err("Could not read user input from command line", #procedure)
		}
		input := strings.trim_right(string(buf[:n]), "\r\n")
		security.OST_DECRYPT_COLLECTION("", .HISTORY_PRIVATE, types.system_user.m_k.valAsBytes)
		OST_APPEND_COMMAND_TO_HISTORY(input)
		security.OST_ENCRYPT_COLLECTION(
			"",
			.HISTORY_PRIVATE,
			types.system_user.m_k.valAsBytes,
			false,
		)
		cmd := OST_PARSE_COMMAND(input)
		// fmt.printfln("Command: %v", cmd) //debugging

		//Check to ensure that before the next command is executed, the max session time hasnt been met
		sessionDuration := security.OST_GET_SESSION_DURATION()
		maxDurationMet := security.OST_CHECK_SESSION_DURATION(sessionDuration)
		switch (maxDurationMet)
		{
		case false:
			break
		case true:
			security.OST_HANDLE_MAX_SESSION_DURATION_MET()
		}

		result = OST_EXECUTE_COMMAND(&cmd)

		//Command line end
	}
	return result

}

//Used to restart the engine
OST_RESTART :: proc() {
	if const.OST_DEV_MODE == true {
		libc.system(const.OST_RESTART_SCRIPT_PATH)
		os.exit(0)
	} else {
		fmt.println("Using the RESTART command is only available in development mode.")
	}
}

//Used to rebuild and restart the engine
OST_REBUILD :: proc() {
	if const.OST_DEV_MODE == true {
		libc.system(const.OST_BUILD_SCRIPT_PATH)
		os.exit(0)
	} else {
		fmt.println("Using the REBUILD command is only available in development mode.")
	}
}
