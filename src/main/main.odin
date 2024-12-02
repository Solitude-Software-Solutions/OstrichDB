package main
import "../core/client"
import "../core/config"
import "../core/const"
import "../core/engine"
import "../core/engine/data"
import "../core/engine/data/metadata"
import "../core/engine/security"
import "../core/server"
import "../core/types"
import "../tests"
import "../utils"
import "core:fmt"
import "core:strings"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//

main :: proc() {
	Config := types.Server_Config {
		port = 8083,
	}

	utils.main()
	data.main()
	utils.log_runtime_event("OstrichDB Started", "")
	tests.OST_INIT_TESTS()
	//
	res := config.OST_READ_CONFIG_VALUE(const.configSix)
	if res == "true" {
		types.errSupression.enabled = true
	} else if res == "false" {
		types.errSupression.enabled = false
	} else {
		utils.log_err("Error reading error suppression config", #procedure)
	}
	//
	//Print the Ostrich logo and version
	version := string(utils.get_ost_version())
	fmt.printfln(fmt.tprintf(utils.ostrich_art, utils.GREEN, version, utils.RESET))

	if config.OST_READ_CONFIG_VALUE(const.configOne) == "true" {
		types.engine.Initialized = true
		utils.log_runtime_event("OstrichDB Engine Initialized", "")
	} else {
		types.engine.Initialized = false
	}
	// if config.OST_READ_CONFIG_VALUE(const.configFive) == "true" {
	// server.OST_START_SERVER(Config) //When testing the server, uncomment this line and comment out the client.OST_TEST_CLIENT(Config) line
	// }
	// client.OST_TEST_CLIENT(Config) //When testing the client, uncomment this line and comment out the server.OST_START_SERVER(Config) line

	engine.run()

}
