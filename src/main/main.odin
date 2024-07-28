package main

import "../core/config"
import "../core/data"
import "../core/data/metadata"
import "../core/engine"
import "../core/security"
import "../core/types"
import "../utils"
import "core:fmt"
//=========================================================//
//Author: Marshall Burns aka @SchoolyB
//Desc: The main entry point for the Ostrich Database Engine
//=========================================================//

main :: proc() {

	utils.main()
	data.main()
	utils.test()
	utils.log_runtime_event("OstrichDB Started", "")

	//Print the Ostrich logo and version
	fmt.printfln(utils.ostrich_art)
	version := transmute(string)utils.get_ost_version()
	fmt.printfln("%sVersion: %s%s%s", utils.BOLD, utils.GREEN, version, utils.RESET)

	if config.OST_READ_CONFIG_VALUE("ENGINE_INIT") == "true" {
		types.engine.Initialized = true
		utils.log_runtime_event("OstrichDB Engine Initialized", "")
	} else {
		types.engine.Initialized = false
	}

	switch (types.engine.Initialized) 
	{
	case false:
		config.main()
		security.OST_INIT_USER_SETUP()
		break

	case true:
		userSignedIn := security.OST_RUN_SIGNIN()
		switch (userSignedIn) 
		{
		case true:
			utils.log_runtime_event("User Signed In", "User successfully logged into OstrichDB")
			engine.OST_ENGINE_COMMAND_LINE()

		case false:
			//to stuff
			break
		}
	}

}
