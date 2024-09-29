package main

import "../core/config"
import "../core/const"
import "../core/engine"
import "../core/engine/data"
import "../core/engine/data/metadata"
import "../core/engine/security"
import "../core/types"
import "../utils"
import "core:fmt"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//

main :: proc() {
	utils.main()
	data.main()
	utils.log_runtime_event("OstrichDB Started", "")

	//Print the Ostrich logo and version
	fmt.printfln(utils.ostrich_art)
	version := transmute(string)utils.get_ost_version()
	fmt.printfln("%sVersion: %s%s%s", utils.BOLD, utils.GREEN, version, utils.RESET)

	//TODO: the if statement below is return something other than the string "true" even though it is reading
	//the value from the config file correctly
	//Seems as though even though the read config proc is the string "true"  the return value
	//is coming back here as an empty string.
	foo := config.OST_READ_CONFIG_VALUE(const.configOne)

	foolen := len(foo)
	if foo == "true" {
		fmt.printfln("length of foo: %d", foolen)
		fmt.println("init is true")
		types.engine.Initialized = true
		utils.log_runtime_event("OstrichDB Engine Initialized", "")
	} else if foo == "false" {
		fmt.printfln("length of foo: %d", foolen)
		fmt.printfln("foo: %s", foo)
		fmt.println("init is false")
		types.engine.Initialized = false
	} else if foo == "" {
		fmt.println("GETTING AN EMPTY STRING")
	} else {
		fmt.println("THIS SHIT BROKE")
		fmt.printfln("foo: %s", foo)
		fmt.printfln("length of foo: %d", foolen)
	}

	engine.run()

}
