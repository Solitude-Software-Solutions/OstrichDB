package main

import "../core/config"
import "../core/engine"
import "../core/engine/data"
import "../core/engine/data/metadata"
import "../core/engine/security"
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
	engine.main()

}
