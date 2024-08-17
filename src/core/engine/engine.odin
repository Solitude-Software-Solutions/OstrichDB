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
// Copyright 2024 Marshall A Burns and Solitude Software Solutions
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//

main :: proc() {
	configFound := config.OST_CHECK_IF_CONFIG_FILE_EXISTS()
	switch (configFound) 
	{
	case false:
		fmt.println("Config file not found.\n Generating config file")
		config.OST_CREATE_CONFIG_FILE()
		main()
	case:
		OST_START_ENGINE()
	}


}

OST_START_ENGINE :: proc() -> int {

	switch (types.engine.Initialized) 
	{
	case false:
		config.main()
		security.OST_INIT_USER_SETUP()
		break

	case true:
		userSignedIn := OST_RUN_SIGNIN()
		switch (userSignedIn) 
		{
		case true:
			OST_START_SESSION_TIMER()
			utils.log_runtime_event("User Signed In", "User successfully logged into OstrichDB")
			OST_ENGINE_COMMAND_LINE()
			break

		case false:
			OST_START_ENGINE()
			break
		}
	}
	return 0
}


OST_ENGINE_COMMAND_LINE :: proc() {
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
		}
		input := strings.trim_right(string(buf[:n]), "\r\n")
		cmd := OST_PARSE_COMMAND(input)
		// fmt.printfln("Command: %v", cmd) //debugging
		OST_EXECUTE_COMMAND(&cmd)

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
		}
		input := strings.trim_right(string(buf[:n]), "\r\n")
		cmd := OST_PARSE_COMMAND(input)
		// fmt.printfln("Command: %v", cmd) //debugging
		EXECUTE_COMMANDS_WHILE_FOCUSED(&cmd, types.focus.t_, types.focus.o_, types.focus.p_o)
		//Command line end
	}

}
