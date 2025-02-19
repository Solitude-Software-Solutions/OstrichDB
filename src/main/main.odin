package main

import "../core/client"
import "../core/const"
import "../core/engine"
import "../core/engine/config"
import "../core/engine/data"
import "../core/engine/data/metadata"
import "../core/engine/security"
import "../core/server"
import "../core/types"
import "../utils"
import "core:fmt"
import "core:strings"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            The the main entry point for the OstrichDB DBMS.
*********************************************************/

main :: proc() {
	using const
	using utils
	using types

	Config := Server_Config {
		port = 8083,
	}


	data.main()

	configFound := config.OST_CHECK_IF_CONFIG_FILE_EXISTS()
	switch (configFound) 
	{
	case false:
		fmt.println("Config file not found.\n Generating config file")
		config.main()
	}
	log_runtime_event("OstrichDB Started", "")

	//Print the Ostrich logo and version
	version := string(get_ost_version())
	fmt.println(fmt.tprintf(ostrich_art, GREEN, version, RESET))
	if data.OST_READ_RECORD_VALUE(OST_CONFIG_PATH, CONFIG_CLUSTER, BOOLEAN, CONFIG_ONE) == "true" {
		OstrichEngine.Initialized = true
		log_runtime_event("OstrichDB Engine Initialized", "")
	} else {
		OstrichEngine.Initialized = false
	}
	// if config.OST_READ_CONFIG_VALUE(CONFIG_FIVE) == "true" {
	// server.OST_START_SERVER(Config) //When testing the server, uncomment this line and comment out the client.OST_TEST_CLIENT(Config) line
	// }
	// client.OST_TEST_CLIENT(Config) //When testing the client, uncomment this line and comment out the server.OST_START_SERVER(Config) line
	fmt.println("Starting OstrichDB DBMS")
	engine.OST_START_ENGINE()

}
