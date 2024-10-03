package engine

import "../../utils"
import "../config"
import "../const"
import "../types"
import "./data"
import "./security"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//

run :: proc() {
	configFound := config.OST_CHECK_IF_CONFIG_FILE_EXISTS()
	switch (configFound) 
	{
	case false:
		fmt.println("Config file not found.\n Generating config file")
		config.OST_CREATE_CONFIG_FILE()
		run()
	case:
		fmt.println("Starting OstrichDB")
		result := OST_START_ENGINE()
		switch (result) 
		{
		case 1:
			fmt.println("OstrichDB Engine started successfully")
			break
		case 0:

		}
	}
}


//initialize the data integrity system
OST_INIT_INEGRITY_CHECKS_SYSTEM :: proc(checks: ^types.Data_Integrity_Checks) -> (success: int) {
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
	OST_INIT_INEGRITY_CHECKS_SYSTEM(&types.data_integrity_checks)

	switch (types.engine.Initialized) 
	{
	case false:
		config.main()
		security.OST_INIT_ADMIN_SETUP()
		break

	case true:
		userSignedIn := OST_RUN_SIGNIN()
		switch (userSignedIn) 
		{
		case true:
			OST_START_SESSION_TIMER()
			utils.log_runtime_event("User Signed In", "User successfully logged into OstrichDB")
			result := OST_ENGINE_COMMAND_LINE()
			return result

		case false:
			OST_START_ENGINE()
			break
		}
	}
	return 0
}


OST_ENGINE_COMMAND_LINE :: proc() -> int {
	fmt.println("Welcome to the OstrichDB Command Line")
	utils.log_runtime_event("Entered command line", "")
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

		append(&const.CommandHistory, strings.clone(input))

		cmd := OST_PARSE_COMMAND(input)
		fmt.printfln("Command: %v", cmd) //debugging
		result := OST_EXECUTE_COMMAND(&cmd)
		switch (result) 
		{
		case 0:
			return 0
		}
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

		switch (types.focus.flag) 
		{
		case true:
			fmt.printfln("Focus mode is on")
			OST_FOCUSED_COMMAND_LINE()
			break
		}

		//Command line end
	}

}

OST_FOCUSED_COMMAND_LINE :: proc() {
	fmt.println("NOW USING FOCUS MODE")
	for types.focus.flag == true {
		//Command line start
		buf: [1024]byte
		fmt.printf(
			"%sFOCUSING: %v%s | %s%v%s>>> ",
			utils.BOLD,
			types.focus.p_o,
			utils.RESET,
			utils.BOLD,
			types.focus.o_,
			utils.RESET,
		)
		n, inputSuccess := os.read(os.stdin, buf[:])
		if inputSuccess != 0 {
			error := utils.new_err(
				.CANNOT_READ_INPUT,
				utils.get_err_msg(.CANNOT_READ_INPUT),
				#procedure,
			)
			utils.throw_err(error)
			utils.log_err("Could not read user input from foucs mode command line", #procedure)
		}
		input := strings.trim_right(string(buf[:n]), "\r\n")
		cmd := OST_PARSE_COMMAND(input)
		// fmt.printfln("Command: %v", cmd) //debugging
		EXECUTE_COMMANDS_WHILE_FOCUSED(&cmd, types.focus.t_, types.focus.o_, types.focus.p_o)
		//Command line end
	}

}
