package main

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
import "core:math/rand"
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


	data.main()
	utils.main()


	configFound := config.CHECK_IF_SYSTEM_CONFIG_FILE_EXISTS()
	switch (configFound)
	{
	case false:
		fmt.println("Config file not found.\n Generating config file")
		config.main()
	}
	log_runtime_event("OstrichDB Started", "")

	//Print the Ostrich logo and version
	version := string(get_ost_version())

	//Randomly choose which project description to display in the startup art
	chosenDescription := rand.choice(const.project_descriptions)
	fmt.println(fmt.tprintf( ostrich_art, chosenDescription, BLUE, version, RESET))

	// success, value:= data.GET_RECORD_VALUE(CONFIG_PATH, CONFIG_CLUSTER, Token[.BOOLEAN], ENGINE_INIT)
// fmt.println("GET_RECORD_VALUE result: ", success)
// 	if success ==false{ //in the event that the record cant be retireved, try decrypting the file first then try again
// 	    DECRYPT_COLLECTION("", .CONFIG_PRIVATE, types.system_user.m_k.valAsBytes)
// 			_, val:= data.GET_RECORD_VALUE(CONFIG_PATH, CONFIG_CLUSTER, Token[.BOOLEAN], ENGINE_INIT)
// 			if val == "true"{
//             ENCRYPT_COLLECTION("", .CONFIG_PRIVATE, types.system_user.m_k.valAsBytes,false,)
//             OstrichEngine.Initialized = true
//             log_runtime_event("OstrichDB Engine Initialized", "")
// 		}else{
// 		    OstrichEngine.Initialized = false
// 		}
// 	}else {
// 	        ENCRYPT_COLLECTION("", .CONFIG_PRIVATE, types.system_user.m_k.valAsBytes,false,)
// 	}

	fmt.println("Starting OstrichDB DBMS")
	engine.START_OSTRICHDB_ENGINE()

}
