package main

import "../core/config"
import "../core/data"
import "../core/data/metadata"
import "../core/engine"
import "../core/security"
import "../utils/errors"
import "../utils/logging"
import "../utils/misc"
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
		engine.ost_engine.Initialized = true
	} else {
		engine.ost_engine.Initialized = false
	}

	switch (engine.ost_engine.Initialized) 
	{
	case false:
		config.main()
		security.main()
		break

	case true:
		security.signin()
		break
	}

}
