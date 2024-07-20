package main

import "../core/config"
import "../core/data"
import "../core/data/metadata"
import "../core/engine"
import "../core/security"
import "../core/types"
import "../errors"
import "../logging"
import "../misc"
import "core:fmt"
//=========================================================//
//Author: Marshall Burns aka @SchoolyB
//Desc: The main entry point for the Ostrich Database Engine
//=========================================================//

main :: proc() {
	//Create /bin dir and start the logging system
	logging.main()
	//Create the cluster id cache file and clusters directory
	data.main()


	//Print the Ostrich logo and version
	fmt.printfln(misc.ostrich_art)
	version := transmute(string)misc.get_ost_version()
	fmt.printfln("%sVersion: %s%s%s", misc.BOLD, misc.GREEN, version, misc.RESET)

	if config.OST_READ_CONFIG_VALUE("ENGINE_INIT") == "true" {
		types.engine.Initialized = true
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
			engine.OST_ENGINE_COMMAND_LINE()

		case false:
			//to stuff
			break
		}
	}

}
