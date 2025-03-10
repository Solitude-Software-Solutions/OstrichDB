package main

import "../src/core/client"
import "../src/core/const"
import "../src/core/engine"
import "../src/core/engine/config"
import "../src/core/engine/data"
import "../src/core/engine/data/metadata"
import "../src/core/engine/security"
import "../src/core/server"
import "../src/core/types"
import "../src/utils"
import "core:fmt"
import "core:os"
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
	using security

	Config := Server_Config {
		port = 8083,
	}

	data.main()
	utils.main()


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
	fmt.println(fmt.tprintf(ostrich_art, BLUE, version, RESET))

	//Check if the config collection is already encrypted
	isEncrypted, _ := OST_ENCRYPT_COLLECTION(
		"",
		.CONFIG_PRIVATE,
		types.system_user.m_k.valAsBytes,
		true,
	)

	if isEncrypted == 2 {
		OST_DECRYPT_COLLECTION("", .CONFIG_PRIVATE, types.system_user.m_k.valAsBytes)
	}


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
	OST_DECRYPT_COLLECTION("", .CONFIG_PRIVATE, types.system_user.m_k.valAsBytes)
	fmt.println("Starting OstrichDB DBMS")
	engine.OST_START_ENGINE()

}
