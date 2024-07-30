package engine

import "../../utils"
import "../commands"
import "../config"
import "../const"
import "../data"
import "../parser"
import "../security"
import "../types"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"
//=========================================================//
//Author: Marshall Burns aka @SchoolyB
//Desc: This file handles the main engine of the db
//=========================================================//


// ost_engine: Ost_Engine


main :: proc() {
	configFound := config.OST_CHECK_IF_CONFIG_FILE_EXISTS()
	switch (configFound) 
	{
	case true:
		//do stuff
		break
	case false:
		fmt.println("Config file not found.\n Generating config file")
		config.OST_CREATE_CONFIG_FILE()
		break
	}

}

//todo wtf is this lol
OST_GET_ENGINE_STATUS :: proc() -> int {
	switch (types.engine.Status) 
	{
	case 0:
		types.engine.StatusName = "Idle"
		break
	case 1:
		types.engine.StatusName = "Running"
		break
	case 2:
		types.engine.StatusName = "Stopped"
		break
	}

	return types.engine.Status
}


OST_START_ENGINE :: proc() -> int {
	engineStatus := OST_GET_ENGINE_STATUS()
	switch (engineStatus) {
	case 0, 2:
		types.engine.Status = 1
		types.engine.StatusName = "Running"
		break
	case 1:
		fmt.println("Engine is already running")
		break
	}
	return 0
}


OST_ENGINE_COMMAND_LINE :: proc() {
	//used to constantly evaluate if the user is signed in
	if security.USER_SIGNIN_STATUS == false {
		fmt.println("Please sign in to use the command line")
		return
	}

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
		cmd := parser.OST_PARSE_COMMAND(input)
		// fmt.printfln("Command: %v", cmd) //debugging
		commands.OST_EXECUTE_COMMAND(&cmd)

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
			"%v %s%v: %v%s\t",
			const.ost_carrot,
			utils.BOLD,
			types.focus.t_,
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
		cmd := parser.OST_PARSE_COMMAND(input)
		fmt.printfln("Command: %v", cmd) //debugging
		commands.EXECUTE_COMMANDS_WHILE_FOCUSED(&cmd, types.focus.t_, types.focus.o_)
		//Command line end
	}

}
