package engine

import "../../utils"
import "../benchmark"
import "../const"
import "../engine/transfer"
import "../help"
import "../server"
import "../types"
import "./config"
import "./data"
import "./data/metadata"
import "./security"
import "core:c/libc"
import "core:fmt"
import "core:os"
import "core:strings"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
*********************************************************/


OST_EXECUTE_COMMAND :: proc(cmd: ^types.Command) -> int {
	using metadata
	using const
	using utils
	// using data //cant use this when using utils namespace

	//TODO: not even using these...
	incompleteCommandErr := new_err(
		.INCOMPLETE_COMMAND,
		get_err_msg(.INCOMPLETE_COMMAND),
		#procedure,
	)

	invalidCommandErr := new_err(.INVALID_COMMAND, get_err_msg(.INVALID_COMMAND), #procedure)

	//Semi global Server shit
	ServerConfig := types.Server_Config {
		port = 8082,
	}
	defer delete(cmd.l_token)


	switch (cmd.c_token) 
	{
	//=======================<SINGLE-TOKEN COMMANDS>=======================//

	case VERSION:
		log_runtime_event("Used VERSION command", "User requested version information.")
		fmt.printfln("Using OstrichDB Version: %s%s%s", BOLD, get_ost_version(), RESET)
		break
	case EXIT:
		//logout then exit the program
		log_runtime_event("Used EXIT command", "User requested to exit the program.")
		OST_USER_LOGOUT(1)
	case LOGOUT:
		//only returns user to signin.
		log_runtime_event("Used LOGOUT command", "User requested to logout.")
		fmt.printfln("Logging out...")
		OST_USER_LOGOUT(0)
		return 0
	case RESTART:
		log_runtime_event("Used RESTART command", "User requested to restart OstrichDB.")
		OST_RESTART()
	case REBUILD:
		log_runtime_event("Used REBUILD command", "User requested to rebuild OstrichDB")
		OST_REBUILD()
	case DESTROY:
		log_runtime_event("Used DESTROY command", "User requested to destroy OstrichDB.")
		OST_DESTROY()
	case CLEAR:
		log_runtime_event("Used CLEAR command", "User requested to clear the screen.")
		libc.system("clear")
		break
	case TREE:
		log_runtime_event("Used TREE command", "User requested to view a tree of the database.")
		data.OST_GET_DATABASE_TREE()

	//COMMAND HISTORY CLUSTER FUCK START :(
	case HISTORY:
		log_runtime_event("Used HISTORY command", "User requested to view the command history.")
		commandHistory := data.OST_PUSH_RECORDS_TO_ARRAY(types.current_user.username.Value)

		for cmd, index in commandHistory {
			fmt.printfln("%d: %s", index + 1, cmd)
		}
		fmt.println("Enter command to repeat: \nTo exit,press enter.")

		// Get index of command to re-execute from user
		inputNumber: [1024]byte
		n, inputSuccess := os.read(os.stdin, inputNumber[:])
		if inputSuccess != 0 {
			error := new_err(.CANNOT_READ_INPUT, get_err_msg(.CANNOT_READ_INPUT), #procedure)
			throw_err(error)
			log_err("Cannot read user input for HISTORY command.", #procedure)
		}

		// convert string to index
		commandIndex := libc.atol(strings.clone_to_cstring(string(inputNumber[:n]))) - 1 // subtract one to fix indexing ability
		// check boundaries
		if commandIndex >= i64(len(commandHistory)) || commandIndex < 0 {
			fmt.printfln("Command number %d not found", commandIndex + 1) // add one to make it reflect what the user sees
			break
		}
		// parses the command that has been stored in the most recent command history index. Crucial for the HISTORY command
		cmd := OST_PARSE_COMMAND(commandHistory[commandIndex])
		OST_EXECUTE_COMMAND(&cmd)
		break
	//HISTORY CLUSTER FUCK END :)
	//=======================<SINGLE OR MULTI-TOKEN COMMANDS>=======================//
	case HELP:
		log_runtime_event("Used HELP command", "User requested help information.")
		if len(cmd.t_token) == 0 {
			log_runtime_event("Used HELP command", "User requested general help information.")
			help.OST_GET_GENERAL_HELP()
		} else if cmd.t_token == CLP || cmd.t_token == CLPS {
			log_runtime_event("Used HELP command", "User requested atom help information.")
			help.OST_GET_CLPS_HELP()
		} else {
			log_runtime_event("Used HELP command", "User requested specific help information.")
			help.OST_GET_SPECIFIC_HELP(cmd.t_token)
		}
		break
	//=======================<MULTI-TOKEN COMMANDS>=======================//

	//WHERE: Used to search for a specific object within the DBMS
	case WHERE:
		log_runtime_event("Used WHERE command", "User requested to search for a specific object.")
		switch (cmd.t_token) {
		case CLUSTER, RECORD:
			found := data.OST_WHERE_OBJECT(cmd.t_token, cmd.l_token[0])
			if !found {
				fmt.printfln(
					"No %s%s%s with name: %s%s%s found within OstrichDB.",
					BOLD_UNDERLINE,
					cmd.t_token,
					RESET,
					BOLD,
					cmd.l_token[0],
					RESET,
				)
			}
		case:
			break
		}
		if len(cmd.l_token) == 0 {
			found := data.OST_WHERE_ANY(cmd.t_token)
			if !found {
				fmt.printfln(
					"No data with name: %s%s%s found within OstrichDB.",
					BOLD_UNDERLINE,
					cmd.t_token,
					RESET,
				)
			}
		} else {
			fmt.println(
				"Incomplete command. Correct Usage: WHERE <target> <target_name> or WHERE <target_name>",
			)
			log_runtime_event(
				"Incomplete WHERE command",
				"User did not provide a target name to search for.",
			)
		}
		break
	//BACKUP: Used in conjuction with COLLECTION to create a duplicate of all data within a collection
	case BACKUP:
		log_runtime_event("Used BACKUP command", "User requested to backup data.")
		switch (len(cmd.l_token)) {
		case 1:
			name := data.OST_CHOOSE_BACKUP_NAME()
			checks := data.OST_HANDLE_INTEGRITY_CHECK_RESULT(cmd.l_token[0])
			switch (checks) 
			{
			case -1:
				return -1
			}
			success := data.OST_CREATE_BACKUP_COLLECTION(name, cmd.l_token[0])
			if success {
				fmt.printfln(
					"Successfully backed up collection: %s%s%s.",
					BOLD,
					cmd.l_token[0],
					RESET,
				)
			} else {
				fmt.println("Backup failed. Please try again.")
				log_err("Failed to backup collection.", #procedure)
				return -1
			}

			break
		case:
			fmt.println("Invalid command. Correct Usage: BACKUP <collection_name>")
			fmt.println(
				"Backing up a cluster or record is not currently support in OstrichDB. Try backing up a collection instead.",
			)
			log_runtime_event("Invalid BACKUP command", "User did not provide a valid target.")
		}
		break
	//NEW: Allows for the creation of new records, clusters, or collections
	case NEW:
		log_runtime_event("Used NEW command", "")
		switch (len(cmd.l_token)) {
		case 1:
			exists := data.OST_CHECK_IF_COLLECTION_EXISTS(cmd.l_token[0], 0)
			switch (exists) {
			case false:
				fmt.printf("Creating collection: %s%s%s\n", BOLD_UNDERLINE, cmd.l_token[0], RESET)
				success := data.OST_CREATE_COLLECTION(cmd.l_token[0], 0)
				if success {
					fmt.printf(
						"Collection: %s%s%s created successfully.\n",
						BOLD_UNDERLINE,
						cmd.l_token[0],
						RESET,
					)
					fileName := concat_collection_name(cmd.l_token[0])
					OST_UPDATE_METADATA_ON_CREATE(fileName)
				} else {
					fmt.printf(
						"Failed to create collection %s%s%s.\n",
						BOLD_UNDERLINE,
						cmd.l_token[0],
						RESET,
					)
					log_runtime_event(
						"Failed to create collection",
						"User tried to create a collection but failed.",
					)
					log_err("Failed to create new collection", #procedure)
				}
				break
			case true:
				fmt.printf(
					"Collection: %s%s%s already exists. Please choose a different name.\n",
					BOLD_UNDERLINE,
					cmd.l_token[0],
					RESET,
				)
				log_runtime_event(
					"Duplicate collection name",
					"User tried to create a collection with a name that already exists.",
				)
				break
			}
			break
		case 2:
			cluster_name: string
			collection_name: string
			if cmd.isUsingDotNotation == true {
				collection_name = cmd.l_token[0]
				cluster_name = cmd.l_token[1]
				fmt.printf(
					"Creating cluster: %s%s%s within collection: %s%s%s\n",
					BOLD_UNDERLINE,
					cluster_name,
					RESET,
					BOLD_UNDERLINE,
					collection_name,
					RESET,
				)
				// checks := data.OST_HANDLE_INTEGRITY_CHECK_RESULT(collection_name)
				// switch (checks)
				// {
				// case -1:
				// 	return -1
				// }

				id := data.OST_GENERATE_ID(true)
				result := data.OST_CREATE_CLUSTER(collection_name, cluster_name, id)
				data.OST_APPEND_ID_TO_COLLECTION(fmt.tprintf("%d", id), 0)

				switch (result) 
				{
				case -1:
					fmt.printfln(
						"Cluster with name: %s%s%s already exists within collection %s%s%s. Failed to create cluster.",
						BOLD_UNDERLINE,
						cluster_name,
						RESET,
						BOLD_UNDERLINE,
						collection_name,
						RESET,
					)
					break
				case 1, 2, 3:
					error1 := new_err(
						.CANNOT_CREATE_CLUSTER,
						get_err_msg(.CANNOT_CREATE_CLUSTER),
						#procedure,
					)
					throw_custom_err(
						error1,
						"Failed to create cluster due to internal OstrichDB error.\n Check logs for more information.",
					)
					log_err("Failed to create new cluster.", #procedure)
					break
				}
				fn := concat_collection_name(collection_name)
				OST_UPDATE_METADATA_VALUE(fn, 2)
				OST_UPDATE_METADATA_VALUE(fn, 3)
				OST_UPDATE_METADATA_VALUE(fn, 5)
			} else {
				fmt.printfln(
					"Invalid command. Correct Usage: NEW <collection_name>.<cluster_name>",
				)
				log_runtime_event(
					"Incomplete NEW command",
					"User did not provide a cluster name to create.",
				)
			}

			break
		case 3:
			log_runtime_event("Used NEW RECORD command", "User requested to create a new record.")
			collectionName := cmd.l_token[0]
			clusterName := cmd.l_token[1]
			recordName := cmd.l_token[2]
			if len(recordName) > 128 {
				fmt.printfln(
					"Record name: %s%s%s is too long. Please choose a name less than 128 characters.",
					BOLD_UNDERLINE,
					recordName,
					RESET,
				)
				return -1
			}
			filePath := fmt.tprintf(
				"%s%s%s",
				OST_COLLECTION_PATH,
				collectionName,
				OST_FILE_EXTENSION,
			)

			if OF_TYPE in cmd.p_token && cmd.isUsingDotNotation == true {
				rType, typeSuccess := data.OST_SET_RECORD_TYPE(cmd.p_token[OF_TYPE])

				if typeSuccess == 0 {
					fmt.printfln(
						"Creating record: %s%s%s of type: %s%s%s",
						BOLD_UNDERLINE,
						recordName,
						RESET,
						BOLD_UNDERLINE,
						rType,
						RESET,
					)

					appendSuccess := data.OST_APPEND_RECORD_TO_CLUSTER(
						filePath,
						clusterName,
						recordName,
						"",
						rType,
					)
					switch (appendSuccess) 
					{
					case 0:
						fmt.printfln(
							"Record: %s%s%s of type: %s%s%s created successfully",
							BOLD_UNDERLINE,
							recordName,
							RESET,
							BOLD_UNDERLINE,
							rType,
							RESET,
						)

						//IF a records type is NULL, technically it cant hold a value, the word NULL in the value slot
						// of a record is mostly a placeholder
						if rType == NULL {
							data.OST_SET_RECORD_VALUE(filePath, clusterName, recordName, NULL)
						}

						fn := concat_collection_name(collectionName)
						OST_UPDATE_METADATA_VALUE(fn, 2)
						OST_UPDATE_METADATA_VALUE(fn, 3)
						OST_UPDATE_METADATA_VALUE(fn, 5)

						break
					case -1, 1:
						fmt.printfln(
							"Failed to create record: %s%s%s of type: %s%s%s",
							BOLD_UNDERLINE,
							recordName,
							RESET,
							BOLD_UNDERLINE,
							rType,
							RESET,
						)
						log_runtime_event(
							"Failed to create record",
							"User requested to create a record but failed.",
						)
						log_err("Failed to create a new record.", #procedure)
						break
					}
				} else {
					fmt.printfln(
						"Failed to create record: %s%s%s of type: %s%s%s. Please try again.",
						BOLD_UNDERLINE,
						recordName,
						RESET,
						BOLD_UNDERLINE,
						rType,
						RESET,
					)
				}

			} else {
				fmt.printfln(
					"Incomplete command. Correct Usage: NEW <collection_name>.<cluster_name>.<record_name> OF_TYPE <record_type>",
				)
				log_runtime_event(
					"Incomplete NEW RECORD command",
					"User did not provide a record name or type to create.",
				)
			}
			break
		case:
			fmt.printfln("Invalid command structure. Correct Usage: NEW <Location> <Parameters>")
			log_runtime_event(
				"Invalid NEW command",
				"User did not provide a valid target to create.",
			)
			break
		}

		// case USER:
		// 	log_runtime_event(
		// 		"Used NEW USER command",
		// 		"User chose to create a new user account",
		// 	)
		// 	if len(cmd.l_token) >= 0 {
		// 		result := security.OST_CREATE_NEW_USER()
		// 		return result
		// 	}
		// case:
		// 	fmt.printfln("Invalid command structure. Correct Usage: NEW <Target> <Targets_name>")
		// 	log_runtime_event(
		// 		"Invalid NEW command",
		// 		"User did not provide a valid target to create.",
		// 	)
		break
	//RENAME: Allows for the renaming of collections, clusters, or individual record names
	case RENAME:
		log_runtime_event("Used RENAME command", "")
		switch (len(cmd.l_token)) 
		{
		case 1:
			if TO in cmd.p_token {
				oldName := cmd.l_token[0]
				newName := cmd.p_token[TO]

				fmt.printf(
					"Renaming collection: %s%s%s to %s%s%s\n",
					BOLD_UNDERLINE,
					oldName,
					RESET,
					BOLD_UNDERLINE,
					newName,
					RESET,
				)
				success := data.OST_RENAME_COLLECTION(oldName, newName)
				switch (success) 
				{
				case true:
					fmt.printf(
						"Successfully renamed collection: %s%s%s to %s%s%s\n",
						BOLD_UNDERLINE,
						oldName,
						RESET,
						BOLD_UNDERLINE,
						newName,
						RESET,
					)
					log_runtime_event(
						"Successfully renamed collection",
						"User successfully renamed a collection.",
					)
					break
				case:
					fmt.printfln(
						"Failed to rename collection: %s%s%s to %s%s%s",
						BOLD_UNDERLINE,
						oldName,
						RESET,
						BOLD_UNDERLINE,
						newName,
						RESET,
					)
					log_runtime_event(
						"Failed to rename collection",
						"User requested to rename a collection but failed.",
					)
					log_err("Failed to rename collection.", #procedure)
					break
				}

			} else {
				fmt.println("Incomplete command. Correct Usage: RENAME <old_name> TO <new_name>")
			}
			break
		case 2:
			clusterName: string
			collectionName: string

			if TO in cmd.p_token && cmd.isUsingDotNotation == true {
				oldName := cmd.l_token[1]
				collectionName := cmd.l_token[0]
				newName := cmd.p_token[TO]

				// checks := data.OST_HANDLE_INTEGRITY_CHECK_RESULT(collection_name)
				// switch (checks)
				// {
				// case -1:
				// 	fmt.printfln(
				// 		"Failed to rename cluster %s%s%s to %s%s%s in collection %s%s%s\n",
				// 	)
				// 	return -1
				// }

				success := data.OST_RENAME_CLUSTER(collectionName, oldName, newName)
				if success {
					fmt.printf(
						"Successfully renamed cluster %s%s%s to %s%s%s in collection %s%s%s\n",
						BOLD_UNDERLINE,
						oldName,
						RESET,
						BOLD_UNDERLINE,
						newName,
						RESET,
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					fn := concat_collection_name(collectionName)
					OST_UPDATE_METADATA_VALUE(fn, 2)
					OST_UPDATE_METADATA_VALUE(fn, 3)
					OST_UPDATE_METADATA_VALUE(fn, 5)
				} else {
					fmt.println(
						"Failed to rename cluster due to internal error. Please check error logs.",
					)
					log_err("Failed to rename cluster.", #procedure)
				}
			} else {
				fmt.println(
					"Incomplete command. Correct Usage: RENAME <collection_name>.<old_name> TO <new_name>",
				)
				log_runtime_event(
					"Incomplete RENAME command",
					"User did not provide a valid cluster name to rename.",
				)
			}
			break
		case 3:
			oldRName: string
			newRName: string
			collectionName: string //only here if using dot notation
			clusterName: string //only here if using dot notation
			if TO in cmd.p_token || cmd.isUsingDotNotation == true {
				if cmd.isUsingDotNotation == true {
					oldRName = cmd.l_token[2]
					newRName = cmd.p_token[TO]
					collectionName = cmd.l_token[0]
					clusterName = cmd.l_token[1]
				} else {
					oldRName = cmd.l_token[0]
					newRName = cmd.p_token[TO]
				}
				result := data.OST_RENAME_RECORD(
					strings.clone(collectionName),
					strings.clone(clusterName),
					oldRName,
					newRName,
				)
				switch (result) 
				{
				case 0:
					fmt.printfln(
						"Record: %s%s%s successfully renamed to %s%s%s",
						BOLD_UNDERLINE,
						oldRName,
						RESET,
						BOLD_UNDERLINE,
						newRName,
						RESET,
					)
					log_runtime_event(
						"Successfully renamed record",
						"User successfully renamed a record.",
					)
					break
				case:
					fmt.printfln(
						"Failed to rename record: %s%s%s to %s%s%s",
						BOLD_UNDERLINE,
						oldRName,
						RESET,
						BOLD_UNDERLINE,
						newRName,
						RESET,
					)
					log_runtime_event(
						"Failed to rename record",
						"User requested to rename a record but failed.",
					)
					log_err("Failed to rename record.", #procedure)
					break
				}

			} else {
				fmt.println(
					"Incomplete command. Correct Usage: RENAME <collection_name>.<cluster_name>.<old_name> TO <new_name>",
				)
				log_runtime_event(
					"Incomplete RENAME command",
					"User did not provide a valid record name to rename.",
				)
			}
			break
		}
		break

	// // ERASE: Allows for the deletion of collections, specific clusters, or individual records within a cluster
	case ERASE:
		log_runtime_event("Used ERASE command", "")
		switch (len(cmd.l_token)) 
		{
		case 1:
			if data.OST_ERASE_COLLECTION(cmd.l_token[0]) == true {
				fmt.printfln(
					"Collection: %s%s%s erased successfully",
					BOLD_UNDERLINE,
					cmd.l_token[0],
					RESET,
				)
			} else {
				fmt.printfln(
					"Failed to erase collection: %s%s%s",
					BOLD_UNDERLINE,
					cmd.l_token[0],
					RESET,
				)
			}
			break
		case 2:
			collection_name: string
			cluster_name: string

			if cmd.isUsingDotNotation == true {
				collection_name := cmd.l_token[0]
				cluster := cmd.l_token[1]
				clusterID := data.OST_GET_CLUSTER_ID(collection_name, cluster)
				checks := data.OST_HANDLE_INTEGRITY_CHECK_RESULT(collection_name)
				switch (checks) 
				{
				case -1:
					return -1
				}

				if data.OST_ERASE_CLUSTER(collection_name, cluster) == true {
					fmt.printfln(
						"Cluster: %s%s%s successfully erased from collection: %s%s%s",
						BOLD_UNDERLINE,
						cluster,
						RESET,
						BOLD_UNDERLINE,
						collection_name,
						RESET,
					)
					data.OST_REMOVE_ID_FROM_CLUSTER(fmt.tprintf("%d", clusterID), false)
				} else {
					fmt.printfln(
						"Failed to erase cluster: %s%s%s from collection: %s%s%s",
						BOLD_UNDERLINE,
						cluster,
						RESET,
						BOLD_UNDERLINE,
						collection_name,
						RESET,
					)
				}
				fn := concat_collection_name(collection_name)
				OST_UPDATE_METADATA_VALUE(fn, 2)
				OST_UPDATE_METADATA_VALUE(fn, 3)
				OST_UPDATE_METADATA_VALUE(fn, 5)
			} else {
				fmt.println(
					"Incomplete command. Correct Usage: ERASE <collection_name>.<cluster_name>",
				)
				log_runtime_event(
					"Incomplete ERASE command",
					"User did not provide a valid cluster name to erase.",
				)
			}
			break
		case 3:
			collectionName: string
			clusterName: string
			recordName: string

			if cmd.isUsingDotNotation == true {
				collectionName := cmd.l_token[0]
				clusterName := cmd.l_token[1]
				recordName := cmd.l_token[2]

				clusterID := data.OST_GET_CLUSTER_ID(collectionName, clusterName)
				checks := data.OST_HANDLE_INTEGRITY_CHECK_RESULT(collectionName)
				switch (checks) 
				{
				case -1:
					return -1
				}
				if data.OST_ERASE_RECORD(collectionName, clusterName, recordName) == true {
					fmt.printfln(
						"Record: %s%s%s successfully erased from cluster: %s%s%s within collection: %s%s%s",
						BOLD_UNDERLINE,
						recordName,
						RESET,
						BOLD_UNDERLINE,
						clusterName,
						RESET,
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
				} else {
					fmt.printfln(
						"Failed to erase record: %s%s%s from cluster: %s%s%s within collection: %s%s%s",
						BOLD_UNDERLINE,
						recordName,
						RESET,
						BOLD_UNDERLINE,
						clusterName,
						RESET,
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
				}
			}
			break
		// case USER:
		// 	secColPath := fmt.tprintf(
		// 		"%ssecure_%s%s",
		// 		OST_SECURE_COLLECTION_PATH,
		// 		types.current_user.username.Value,
		// 		OST_FILE_EXTENSION,
		// 	)
		// 	result: bool
		// 	if len(cmd.l_token) == 1 {
		// 		//evaluate current logged in users role
		// 		if data.OST_READ_RECORD_VALUE(
		// 			   secColPath,
		// 			   types.current_user.username.Value,
		// 			   "identifier",
		// 			   "role",
		// 		   ) ==
		// 		   "admin" {
		// 			result := security.OST_DELETE_USER(cmd.l_token[0])
		// 			if result {
		// 				fmt.printfln(
		// 					"User: %s%s%s successfully deleted.",
		// 					BOLD_UNDERLINE,
		// 					cmd.l_token[0],
		// 					RESET,
		// 				)
		// 			} else {
		// 				fmt.printfln(
		// 					"Failed to delete user: %s%s%s",
		// 					BOLD_UNDERLINE,
		// 					cmd.l_token[0],
		// 					RESET,
		// 				)
		// 			}
		// 		} else {
		// 			fmt.printfln(
		// 				"User: %s%s%s does not have permission to delete users.",
		// 				BOLD_UNDERLINE,
		// 				types.current_user.username.Value,
		// 				RESET,
		// 			)
		// 			result = false
		// 		}
		// 		if result == true {
		// 			return 0
		// 		} else {
		// 			return -1
		// 		}
		// 	} else {
		// 		fmt.printfln("Incomplete command. Correct Usage: ERASE USER <username>")
		// 	}
		// 	break
		case:
			fmt.printfln(
				"Invalid command structure. Correct Usage: ERASE <collection_name>.<cluster_name>.<record_name>",
			)
			log_runtime_event("Invalid ERASE command", "User did not provide a valid target.")
		}
		break
	// // FETCH: Allows for the retrieval and displaying of collections, clusters, or individual records
	case FETCH:
		log_runtime_event("Used FETCH command", "")
		switch (len(cmd.l_token)) 
		{
		case 1:
			if len(cmd.l_token) > 0 {
				collection := cmd.l_token[0]
				str := data.OST_FETCH_COLLECTION(collection)
				fmt.println(str)
			} else {
				fmt.println("Incomplete command. Correct Usage: FETCH <collection_name>")
				log_runtime_event(
					"Incomplete FETCH command",
					"User did not provide a valid collection name to fetch.",
				)
			}
			break
		case 2:
			if cmd.isUsingDotNotation == true {
				collection := cmd.l_token[0]
				cluster := cmd.l_token[1]
				clusterContent := data.OST_FETCH_CLUSTER(collection, cluster)
				fmt.printfln(clusterContent)
			} else {
				fmt.println(
					"Incomplete command. Correct Usage: FETCH <collection_name>.<cluster_name>",
				)
				log_runtime_event(
					"Incomplete FETCH command",
					"User did not provide a valid cluster name to fetch.",
				)
			}
			break
		case 3:
			collectionName: string
			clusterName: string
			recordName: string

			if len(cmd.l_token) == 3 && cmd.isUsingDotNotation == true {
				collectionName := cmd.l_token[0]
				clusterName := cmd.l_token[1]
				recordName := cmd.l_token[2]

				checks := data.OST_HANDLE_INTEGRITY_CHECK_RESULT(collectionName)
				switch (checks) 
				{
				case -1:
					return -1
				}
				record, found := data.OST_FETCH_RECORD(collectionName, clusterName, recordName)
				fmt.printfln(
					"Succesfully retrieved record: %s%s%s from cluster: %s%s%s within collection: %s%s%s\n\n",
					BOLD_UNDERLINE,
					recordName,
					RESET,
					BOLD_UNDERLINE,
					clusterName,
					RESET,
					BOLD_UNDERLINE,
					collectionName,
					RESET,
				)
				if found {
					fmt.printfln("\t%s :%s: %s\n", record.name, record.type, record.value)
					fmt.println("\t^^^\t^^^\t^^^")
					fmt.println("\tName\tType\tValue\n\n")
				}
			} else {
				fmt.printfln(
					"Incomplete command. Correct Usage: FETCH <collection_name>.<cluster_name>.<record_name>",
				)
				log_runtime_event(
					"Incomplete FETCH command",
					"User did not provide a valid record name to fetch.",
				)
			}
			break
		case:
			fmt.printfln("Invalid command structure. Correct Usage: FETCH <Targets_name>")
			log_runtime_event("Invalid FETCH command", "User did not provide a valid target.")
		}
		break
	case SET:
		//set can only be used on RECORDS and CONFIGS
		switch (len(cmd.l_token)) 
		{
		case 3:
			if TO in cmd.p_token && cmd.isUsingDotNotation {
				collectionName := cmd.l_token[0]
				clusterName := cmd.l_token[1]
				recordName := cmd.l_token[2]
				value := cmd.p_token[TO] // Get the full string value that was collected by the parser
				fmt.printfln(
					"Setting record: %s%s%s to %s%s%s",
					BOLD_UNDERLINE,
					recordName,
					RESET,
					BOLD_UNDERLINE,
					value,
					RESET,
				)

				file := utils.concat_collection_name(collectionName)

				setValueSuccess := data.OST_SET_RECORD_VALUE(
					file,
					clusterName,
					recordName,
					strings.clone(value),
				)

				//if that records type is one of the following 'special' arrays:
				// []CHAR, []DATE, []TIME, []DATETIME,etc scan for that type and remove the "" that
				// each value will have(THANKS ODIN...)
				rType, _ := data.OST_GET_RECORD_TYPE(file, clusterName, recordName)

				if rType == NULL {
					fmt.printfln(
						"Cannot a value ssign to record: %s%s%s of type %sNULL%s",
						BOLD_UNDERLINE,
						recordName,
						RESET,
						BOLD_UNDERLINE,
						RESET,
					)

					return 0
				}

				if rType == CHAR_ARRAY ||
				   rType == DATE_ARRAY ||
				   rType == TIME_ARRAY ||
				   rType == DATETIME_ARRAY ||
				   rType == UUID_ARRAY {
					data.OST_MODIFY_ARRAY_VALUES(file, clusterName, recordName, rType)
				}

				if setValueSuccess {
					fmt.printfln(
						"Successfully set record: %s%s%s to %s%s%s",
						BOLD_UNDERLINE,
						recordName,
						RESET,
						BOLD_UNDERLINE,
						value,
						RESET,
					)
				} else {
					fmt.printfln(
						"Failed to set record: %s%s%s to %s%s%s",
						BOLD_UNDERLINE,
						recordName,
						RESET,
						BOLD_UNDERLINE,
						value,
						RESET,
					)
				}

				fn := concat_collection_name(collectionName)
				OST_UPDATE_METADATA_VALUE(fn, 2)
				OST_UPDATE_METADATA_VALUE(fn, 3)
				OST_UPDATE_METADATA_VALUE(fn, 5)
			}
			break
		case 0:
			switch (cmd.t_token) {
			case CONFIG:
				log_runtime_event("Used SET command", "")
				if TO in cmd.p_token {
					configName := cmd.l_token[0]
					value: string
					for key, val in cmd.p_token {
						value = val
					}
					switch (configName) 
					{
					case "HELP":
						if value != "VERBOSE" || value != "SIMPLE" {
							fmt.println(
								"Invalid value. Valid values for config help are: 'verbose' or 'simple'",
							)
							return 1
						}

						fmt.printfln(
							"Setting config: %s%s%s to %s%s%s",
							BOLD_UNDERLINE,
							configName,
							RESET,
							BOLD_UNDERLINE,
							value,
							RESET,
						)
						success := config.OST_UPDATE_CONFIG_VALUE(
							CONFIG_FOUR,
							append_qoutations(value),
						)
						if success == false {
							fmt.printfln("Failed to set HELP config to %s", value)
						} else {
							OST_UPDATE_METADATA_VALUE(OST_CONFIG_PATH, 2)
							OST_UPDATE_METADATA_VALUE(OST_CONFIG_PATH, 3)
							fmt.printfln("Successfully set HELP config to %s", value)
						}
						help.OST_SET_HELP_MODE()
					case "SERVER":
						if value != "TRUE" || value != "FALSE" {
							fmt.println(
								"Invalid value. Valid values for config server are: 'true' or 'false'",
							)
							return 1
						}

						fmt.printfln(
							"Setting config: %s%s%s to %s%s%s",
							BOLD_UNDERLINE,
							configName,
							RESET,
							BOLD_UNDERLINE,
							value,
							RESET,
						)


						success := config.OST_UPDATE_CONFIG_VALUE(CONFIG_FIVE, value)
						if success == false {
							fmt.printfln("Failed to set SERVER config to %s", value)
						} else {
							fmt.printfln("Successfully set SERVER config to %s", value)
							OST_UPDATE_METADATA_VALUE(OST_CONFIG_PATH, 2)
							OST_UPDATE_METADATA_VALUE(OST_CONFIG_PATH, 3)
							if data.OST_READ_RECORD_VALUE(
								   OST_CONFIG_PATH,
								   CONFIG_CLUSTER,
								   BOOLEAN,
								   CONFIG_FIVE,
							   ) ==
							   "true" {
								fmt.printfln("Server Mode is now ON")
								server.OST_START_SERVER(ServerConfig)
							} else {
								fmt.printfln("Server is now OFF")
							}
						}
					case:
						fmt.printfln("Invalid config name. Valid config names are: 'HELP'")
					}
				} else {
					fmt.printfln(
						"Incomplete command. Correct Usage: SET CONFIG <config_name> TO <value>",
					)
				}
				break
			}
		case:
			//if the length of the token is not 3 or 0
			fmt.printfln(
				"Invalid command structure. Correct Usage: SET <collection_name>.<cluster_name>.<record_name> TO <value>",
			)
			fmt.printfln("The SET command can only be used on RECORDS and CONFIGS")
		}
	case COUNT:
		log_runtime_event("Used COUNT command", "")
		switch (cmd.t_token) 
		{
		case COLLECTIONS:
			result := data.OST_COUNT_COLLECTIONS()
			switch (result) {
			case -1:
				fmt.printfln("Failed to count collections")
				break
			case 0:
				fmt.printfln("No collections found.")
				break
			case 1:
				fmt.println("1 collection found.")
				break
			case:
				fmt.printfln("%d collections found.", result)
				break
			}
			break
		case CLUSTERS:
			if len(cmd.l_token) == 1 {
				collection_name := cmd.l_token[0]
				result := data.OST_COUNT_CLUSTERS(collection_name)
				switch (result) 
				{
				case -1:
					fmt.printfln(
						"Failed to count clusters in collection %s%s%s",
						BOLD_UNDERLINE,
						collection_name,
						RESET,
					)
					break
				case 0:
					fmt.printfln(
						"There are no clusters in the collection %s%s%s",
						BOLD_UNDERLINE,
						collection_name,
						RESET,
					)
					break
				case 1:
					fmt.printfln(
						"There is %d cluster in the collection %s%s%s",
						result,
						BOLD_UNDERLINE,
						collection_name,
						RESET,
					)
					break
				case:
					fmt.printfln(
						"There are %d clusters in the collection %s%s%s",
						result,
						BOLD_UNDERLINE,
						collection_name,
						RESET,
					)
					break
				}
			} else {
				fmt.printfln(
					"Invalid command structure. Correct Usage: COUNT CLUSTERS <collection_name>",
				)
				log_runtime_event(
					"Invalid COUNT command",
					"User did not provide a valid collection name to count clusters.",
				)
			}

			break
		case RECORDS:
			//in the event the users is counting the records in a specific cluster
			if (len(cmd.l_token) >= 2 || cmd.isUsingDotNotation == true) {
				collectionName := cmd.l_token[0]
				clusterName := cmd.l_token[1]
				result := data.OST_COUNT_RECORDS_IN_CLUSTER(
					strings.clone(collectionName),
					strings.clone(clusterName),
					true,
				)
				switch result {
				case -1:
					fmt.printfln(
						"Error counting records in the cluster %s%s%s collection %s%s%s",
						BOLD_UNDERLINE,
						clusterName,
						RESET,
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
				case 0:
					fmt.printfln(
						"There are no records in the cluster %s%s%s in the collection %s%s%s",
						BOLD_UNDERLINE,
						clusterName,
						RESET,
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					break
				case 1:
					fmt.printfln(
						"There is %d record in the cluster %s%s%s in the collection %s%s%s",
						result,
						BOLD_UNDERLINE,
						clusterName,
						RESET,
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					break
				case:
					fmt.printfln(
						"There are %d records in the cluster %s%s%s in the collection %s%s%s",
						result,
						BOLD_UNDERLINE,
						clusterName,
						RESET,
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					break
				}
			} else if len(cmd.l_token) == 1 || cmd.isUsingDotNotation == true {
				//in the event the user is counting all records in a collection
				collection_name := cmd.l_token[0]
				result := data.OST_COUNT_RECORDS_IN_COLLECTION(collection_name)

				switch result 
				{
				case -1:
					fmt.printfln(
						"Error counting records in the collection %s%s%s",
						BOLD_UNDERLINE,
						collection_name,
						RESET,
					)
					break
				case 0:
					fmt.printfln(
						"There are no records in collection %s%s%s",
						BOLD,
						collection_name,
						RESET,
					)
					break
				case 1:
					fmt.printfln(
						"There is %d record in the collection %s%s%s",
						result,
						BOLD_UNDERLINE,
						collection_name,
						RESET,
					)
					break
				case:
					fmt.printfln(
						"There are %d records in the collection %s%s%s",
						result,
						BOLD_UNDERLINE,
						collection_name,
						RESET,
					)
				}

			} else {
				fmt.printfln(
					"Invalid command structure. Correct Usage: COUNT RECORDS <collection_name>.<cluster_name>",
				)
				log_runtime_event(
					"Invalid COUNT command",
					"User did not provide a valid cluster name to count records.",
				)
			}
			break
		}
		break
	// //PURGE command
	case PURGE:
		log_runtime_event("Used PURGE command", "")
		switch (len(cmd.l_token)) 
		{
		case 1:
			collection_name := cmd.l_token[0]
			exists := data.OST_CHECK_IF_COLLECTION_EXISTS(collection_name, 0)
			switch exists 
			{
			case true:
				result := data.OST_PURGE_COLLECTION(cmd.l_token[0])
				switch result 
				{
				case true:
					fmt.printfln(
						"Successfully purged collection: %s%s%s",
						BOLD_UNDERLINE,
						cmd.l_token[0],
						RESET,
					)
					OST_UPDATE_METADATA_VALUE(collection_name, 3)
					break
				case false:
					fmt.printfln("Failed to purge collection: %s%s%s", BOLD, cmd.l_token[0], RESET)
					break
				}
			case false:
				fmt.printfln(
					"Collection: %s%s%s not found in OstrichDB.",
					BOLD,
					cmd.l_token[0],
					RESET,
				)
				log_runtime_event(
					"Invalid PURGE command",
					"User tried to purge a collection that does not exist.",
				)
				break
			}
			break
		case 2:
			collectionName := cmd.l_token[0]
			clusterName := cmd.l_token[1]
			if len(cmd.l_token) >= 2 && cmd.isUsingDotNotation == true {
				result := data.OST_PURGE_CLUSTER(collectionName, clusterName)
				switch result {
				case true:
					fmt.printfln(
						"Successfully purged cluster: %s%s%s in collection: %s%s%s",
						BOLD_UNDERLINE,
						clusterName,
						RESET,
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					break
				case false:
					fmt.printfln(
						"Failed to purge cluster: %s%s%s in collection: %s%s%s",
						BOLD,
						clusterName,
						RESET,
						BOLD,
						collectionName,
						RESET,
					)
					break
				}
			}
			break
		case 3:
			collectionName := cmd.l_token[0]
			clusterName := cmd.l_token[1]
			recordName := cmd.l_token[2]
			result := data.OST_PURGE_RECORD(collectionName, clusterName, recordName)
			switch result {
			case true:
				fmt.printfln(
					"Successfully purged record: %s%s%s in cluster: %s%s%s in collection: %s%s%s",
					BOLD_UNDERLINE,
					recordName,
					RESET,
					BOLD_UNDERLINE,
					clusterName,
					RESET,
					BOLD_UNDERLINE,
					collectionName,
					RESET,
				)
				break
			case false:
				fmt.printfln(
					"Failed to purge record: %s%s%s in cluster: %s%s%s in collection: %s%s%s",
					BOLD,
					recordName,
					RESET,
					BOLD,
					clusterName,
					RESET,
					BOLD,
					collectionName,
					RESET,
				)
				break
			}
			break
		}

		break
	//SIZE_OF command
	case SIZE_OF:
		log_runtime_event("Used SIZE_OF command", "")
		switch (len(cmd.l_token)) {
		case 1:
			collection_name := cmd.l_token[0]
			file_path := fmt.tprintf(
				"%s%s%s",
				OST_COLLECTION_PATH,
				collection_name,
				OST_FILE_EXTENSION,
			)
			actual_size, metadata_size := OST_SUBTRACT_METADATA_SIZE(file_path)
			if actual_size != -1 {
				fmt.printf(
					"Size of collection %s: %d bytes (excluding %d bytes of metadata)\n",
					collection_name,
					actual_size,
					metadata_size,
				)
			} else {
				fmt.printf("Failed to get size of collection %s\n", collection_name)
			}
		case 2:
			if cmd.isUsingDotNotation {
				collectionName := cmd.l_token[0]
				clusterName := cmd.l_token[1]
				size, success := data.OST_GET_CLUSTER_SIZE(collectionName, clusterName)
				if success {
					fmt.printf(
						"Size of cluster %s.%s: %d bytes\n",
						collectionName,
						clusterName,
						size,
					)
				} else {
					fmt.printf(
						"Failed to get size of cluster %s.%s\n",
						collectionName,
						clusterName,
					)
				}
			} else {
				fmt.println(
					"Invalid command. Use dot notation for clusters: SIZE_OF CLUSTER collection_name.cluster_name",
				)
			}
		case 3:
			if cmd.isUsingDotNotation {
				collectionName := cmd.l_token[0]
				clusterName := cmd.l_token[1]
				recordName := cmd.l_token[2]
				size, success := data.OST_GET_RECORD_SIZE(collectionName, clusterName, recordName)
				if success {
					fmt.printf(
						"Size of record %s.%s.%s: %d bytes\n",
						collectionName,
						clusterName,
						recordName,
						size,
					)
				} else {
					fmt.printf(
						"Failed to get size of record %s.%s.%s\n",
						collectionName,
						clusterName,
						recordName,
					)
				}
			} else {
				fmt.println(
					"Invalid command. Use dot notation for records: SIZE_OF RECORD collection_name.cluster_name.record_name",
				)
			}
		case:
			fmt.println(
				"Invalid SIZE_OF command. Use SIZE_OF COLLECTION, SIZE_OF CLUSTER, or SIZE_OF RECORD.",
			)
		}
		break
	case TYPE_OF:
		//only works on records
		if len(cmd.l_token) == 3 && cmd.isUsingDotNotation == true {
			collectionName := cmd.l_token[0]
			clusterName := cmd.l_token[1]
			recordName := cmd.l_token[2]
			colPath := fmt.tprintf(
				"%s%s%s",
				OST_COLLECTION_PATH,
				collectionName,
				OST_FILE_EXTENSION,
			)
			rType, success := data.OST_GET_RECORD_TYPE(colPath, clusterName, recordName)
			if !success {
				fmt.printfln(
					"Failed to get record %s.%s.%s's type",
					collectionName,
					clusterName,
					recordName,
				)
				return 1
			} else {
				fmt.printfln(
					"Record: %s%s%s->%s%s%s->%s%s%s Type: %s%s%s",
					BOLD_UNDERLINE,
					collectionName,
					RESET,
					BOLD_UNDERLINE,
					clusterName,
					RESET,
					BOLD_UNDERLINE,
					recordName,
					RESET,
					BOLD_UNDERLINE,
					rType,
					RESET,
				)
			}
		} else {
			fmt.printfln(
				"Incomplete command. Correct Usage: TYPE_OF <collection_name>.<cluster_name>.<record_name>",
			)

		}
		log_runtime_event("Used TYPE_OF command", "")
		break
	case CHANGE_TYPE:
		//only works on records
		switch (len(cmd.l_token)) {
		case 3:
			if TO in cmd.p_token && cmd.isUsingDotNotation == true {
				collectionName := cmd.l_token[0]
				clusterName := cmd.l_token[1]
				recordName := cmd.l_token[2]
				newType := cmd.p_token[TO]
				colPath := fmt.tprintf(
					"%s%s%s",
					OST_COLLECTION_PATH,
					collectionName,
					OST_FILE_EXTENSION,
				)

				type_is_valid := false
				for type in VALID_RECORD_TYPES {
					if strings.to_upper(newType) == type {
						type_is_valid = true
						break
					}
				}

				if !type_is_valid {
					fmt.printfln("Invalid type provided")
					return 1
				}
				//super fucking bad code but tbh its christmas eve and im tired - Marshall
				if newType == INT || newType == INTEGER {
					newType = INTEGER
				} else if newType == STR || newType == STRING {
					newType = STRING
				} else if newType == BOOL || newType == BOOLEAN {
					newType = BOOLEAN
				} else if newType == FLT || newType == FLOAT {
					newType = FLOAT
				} else if newType == STRING_ARRAY || newType == STR_ARRAY {
					newType = STRING_ARRAY
					fmt.println("THIS SHOULD BE HAPPENING")
				} else if newType == INT_ARRAY || newType == INTEGER_ARRAY {
					newType = INTEGER_ARRAY
				} else if newType == BOOL_ARRAY || newType == BOOLEAN_ARRAY {
					newType = BOOLEAN_ARRAY
				} else if newType == FLOAT_ARRAY || newType == FLT_ARRAY {
					newType = FLOAT_ARRAY
				}

				success := data.OST_HANDLE_TYPE_CHANGE(colPath, clusterName, recordName, newType)

				if success {
					fmt.printfln(
						"Successfully changed record %s.%s.%s's type to %s",
						collectionName,
						clusterName,
						recordName,
						newType,
					)
				} else {
					fmt.printfln(
						"Failed to change record %s.%s.%s's type to %s",
						collectionName,
						clusterName,
						recordName,
						newType,
					)
				}
			} else {
				fmt.printfln(
					"Incomplete command. Correct Usage: CHANGE_TYPE <collection_name>.<cluster_name>.<record_name> TO <new_type>",
				)
			}
		case:
			fmt.printfln(
				"Invalid command. Correct Usage: CHANGE_TYPE <collection_name>.<cluster_name>.<record_name> TO <new_type>",
			)
			log_runtime_event(
				"Invalid CHANGE_TYPE command",
				"User did not provide a valid record name to change type.",
			)
			break
		}
	case ISOLATE:
		log_runtime_event("Used ISOLATE command", "")
		switch (len(cmd.l_token)) {
		case 1:
			collection_name := cmd.l_token[0]
			result := data.OST_PERFORM_ISOLATION(collection_name)
			switch result {
			case 0:
				fmt.printfln(
					"Successfully isolated collection: %s%s%s",
					BOLD_UNDERLINE,
					collection_name,
					RESET,
				)
				break
			case:
				fmt.printfln(
					"Failed to isolate collection: %s%s%s",
					BOLD_UNDERLINE,
					collection_name,
					RESET,
				)
				break
			}
			break
		case:
			fmt.printfln("Incomplete command. Correct Usage: ISOLATE <collection_name>")
			log_runtime_event(
				"Incomplete ISOLATE command",
				"User did not provide a valid collection name to isolate.",
			)
			break
		}
		break
	//VALIDATE command
	case VALIDATE:
		switch (len(cmd.l_token)) {
		case 1:
			collectionName := cmd.l_token[0]

			result := data.OST_HANDLE_INTEGRITY_CHECK_RESULT(collectionName)

			if result == 0 {
				fmt.printfln(
					"Collection: %s%s%s data integrity status: %svalid%s",
					BOLD_UNDERLINE,
					collectionName,
					RESET,
					GREEN,
					RESET,
				)
			} else {
				fmt.printfln(
					"Collection: %s%s%s data integrity status: %sinvalid%s",
					BOLD_UNDERLINE,
					collectionName,
					RESET,
					RED,
					RESET,
				)
			}
		}

	case BENCHMARK:
		benchmark.main()
		break
	case IMPORT:
		transfer._import_("csv_test_file") //TODO: chang this to user input
		// transfer.OST_CONVERT_DATE("13-14-2024")

		break
	case EXPORT:
		fmt.println("NOT YET IMPLEMENTED")
		break

	//END OF COMMAND TOKEN EVALUATION
	case:
		fmt.printfln(
			"Invalid command: %s%s%s. Please enter a valid OstrichDB command. Enter 'HELP' for more information.",
			BOLD_UNDERLINE,
			cmd.c_token,
			RESET,
		)
		log_runtime_event("Invalid command", "User entered an invalid command.")

	}
	return 1
}
