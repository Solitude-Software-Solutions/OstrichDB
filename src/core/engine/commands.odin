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
import "core:strconv"
import "core:strings"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            This file contains the logic that handles and executes
            commands. Results are returned to the engine that is
            running the main loop.
*********************************************************/


OST_EXECUTE_COMMAND :: proc(cmd: ^types.Command) -> int {
	using metadata
	using const
	using utils
	using security
	// using data //cant use this when using utils namespace

	//TODO: not even using these...
	incompleteCommandErr := new_err(
		.INCOMPLETE_COMMAND,
		get_err_msg(.INCOMPLETE_COMMAND),
		#file,
		#procedure,
		#line,
	)

	invalidCommandErr := new_err(
		.INVALID_COMMAND,
		get_err_msg(.INVALID_COMMAND),
		#file,
		#procedure,
		#line,
	)

	//Semi global Server shit
	ServerConfig := types.Server_Config {
		port = 8082,
	}
	defer delete(cmd.l_token)


	switch (cmd.c_token) 
	{
	//=======================<SINGLE-TOKEN COMMANDS>=======================//

	//Shows the current version of OstrichDB
	case VERSION:
		log_runtime_event("Used VERSION command", "User requested version information.")
		fmt.printfln("Using OstrichDB Version: %s%s%s", BOLD, get_ost_version(), RESET)
		break
	//Safely kills the dbms
	case EXIT:
		//logout then exit the program
		log_runtime_event("Used EXIT command", "User requested to exit the program.")
		security.OST_USER_LOGOUT(1)
	case LOGOUT:
		//only returns user to signin.
		log_runtime_event("Used LOGOUT command", "User requested to logout.")
		fmt.printfln("Logging out...")
		security.OST_USER_LOGOUT(0)
		return 0
	// Runs the restart script
	case RESTART:
		log_runtime_event("Used RESTART command", "User requested to restart OstrichDB.")
		OST_RESTART()
	case REBUILD:
		log_runtime_event("Used REBUILD command", "User requested to rebuild OstrichDB")
		OST_REBUILD()
	// Used to completley destroy the program and all its files, rebuilds after on macOs and Linux
	case DESTROY:
		log_runtime_event("Used DESTROY command", "User requested to destroy OstrichDB.")
		OST_DESTROY()
	//Clears the terminal screen
	case CLEAR:
		log_runtime_event("Used CLEAR command", "User requested to clear the screen.")
		libc.system("clear")
		break
	//Shows a tree-like structure of the dbms
	case TREE:
		log_runtime_event("Used TREE command", "User requested to view a tree of the database.")
		data.OST_GET_DATABASE_TREE()
		break
	// Shows the current users past command history
	case HISTORY:
		log_runtime_event("Used HISTORY command", "User requested to view the command history.")
		OST_DECRYPT_COLLECTION("", .HISTORY_PRIVATE, types.system_user.m_k.valAsBytes)
		commandHistory := data.OST_PUSH_RECORDS_TO_ARRAY(types.current_user.username.Value)

		OST_ENCRYPT_COLLECTION("", .HISTORY_PRIVATE, types.system_user.m_k.valAsBytes, false)
		for cmd, index in commandHistory {
			fmt.printfln("%d: %s", index + 1, cmd)
		}
		fmt.println("Enter command to repeat: \nTo exit,press enter.")

		// Get index of command to re-execute from user
		inputNumber: [1024]byte
		n, inputSuccess := os.read(os.stdin, inputNumber[:])
		if inputSuccess != 0 {
			error := new_err(
				.CANNOT_READ_INPUT,
				get_err_msg(.CANNOT_READ_INPUT),
				#file,
				#procedure,
				#line,
			)
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


		delete(commandHistory)
		break
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
	// TODO: The WHERE command is pretty useless right now.
	// it needs to be able to read collections to find a
	// specific record or cluster....but since all collections will be encrypted and no specific collection
	// is provided to search through nothing will work. Will need to re-implement this command after creating
	// some sort of DECRYPT_ALL_COLLECTIONS/ENCRYPT_ALL_COLLECTIONS command
	// case WHERE:
	// 	log_runtime_event("Used WHERE command", "User requested to search for a specific object.")
	// 	switch (cmd.t_token) {
	// 	case CLUSTER, RECORD:
	// 		collectionName := cmd.l_token[0]

	// 		//Todo this check here seems to work sometimes and other times not. Keep an eye on it - Marshall
	// 		//--------------Permissions Security stuff Start----------------//
	// 		OST_EXEC_CMD_LINE_PERM_CHECK(collectionName, WHERE, .STANDARD_PUBLIC)

	// 		found := data.OST_WHERE_OBJECT(cmd.t_token, collectionName)
	// 		if !found {
	// 			fmt.printfln(
	// 				"No %s%s%s with name: %s%s%s found within OstrichDB.",
	// 				BOLD_UNDERLINE,
	// 				cmd.t_token,
	// 				RESET,
	// 				BOLD,
	// 				cmd.l_token[0],
	// 				RESET,
	// 			)
	// 		}
	// 		break
	// 	}
	// 	if len(cmd.l_token) == 0 {

	// 		found, collectionName, clusterName := data.OST_WHERE_ANY(cmd.t_token)


	// 		OST_EXEC_CMD_LINE_PERM_CHECK(collectionName, WHERE, .STANDARD_PUBLIC)


	// 		if !found {
	// 			fmt.printfln(
	// 				"No data with name: %s%s%s found within OstrichDB.",
	// 				BOLD_UNDERLINE,
	// 				cmd.t_token,
	// 				RESET,
	// 			)
	// 		}

	// 		if found && clusterName == "" { 	//if the cluster is found
	// 			fmt.printfln(
	// 				"Cluster: %s%s%s -> Collection: %s%s%s",
	// 				BOLD_UNDERLINE,
	// 				clusterName,
	// 				RESET,
	// 				BOLD_UNDERLINE,
	// 				collectionName,
	// 				RESET,
	// 			)
	// 		} else if found && clusterName != "" { 	//If the record is found
	// 			fmt.printfln(
	// 				"Record: %s%s%s -> Cluster: %s%s%s -> Collection: %s%s%s",
	// 				BOLD_UNDERLINE,
	// 				cmd.t_token,
	// 				RESET,
	// 				BOLD_UNDERLINE,
	// 				clusterName,
	// 				RESET,
	// 				BOLD_UNDERLINE,
	// 				collectionName,
	// 				RESET,
	// 			)
	// 		}
	// 	} else {
	// 		fmt.println(
	// 			"Incomplete command. Correct Usage: WHERE <target> <target_name> or WHERE <target_name>",
	// 		)
	// 		log_runtime_event(
	// 			"Incomplete WHERE command",
	// 			"User did not provide a target name to search for.",
	// 		)
	// 	}
	// 	break
	//BACKUP: Used in conjuction with COLLECTION to create a duplicate of all data within a collection
	case BACKUP:
		log_runtime_event("Used BACKUP command", "User requested to backup data.")
		switch (len(cmd.l_token)) {
		case 1:
			collectionName := cmd.l_token[0]

			if !data.OST_CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
				fmt.printfln(
					"Collection: %s%s%s does not exist.",
					BOLD_UNDERLINE,
					collectionName,
					RESET,
				)
				return -1
			}

			//--------------Permissions Security stuff Start----------------//
			OST_EXEC_CMD_LINE_PERM_CHECK(collectionName, BACKUP, .STANDARD_PUBLIC)

			name := data.OST_CHOOSE_BACKUP_NAME()
			// checks := data.OST_HANDLE_INTEGRITY_CHECK_RESULT(collectionName)
			// switch (checks)
			// {
			// case -1:
			// 	return -1
			// }
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
				success := data.OST_CREATE_COLLECTION(cmd.l_token[0], .STANDARD_PUBLIC)
				if success {
					fmt.printf(
						"Collection: %s%s%s created successfully.\n",
						BOLD_UNDERLINE,
						cmd.l_token[0],
						RESET,
					)
					fileName := concat_collection_name(cmd.l_token[0])
					OST_UPDATE_METADATA_ON_CREATE(fileName)

					OST_ENCRYPT_COLLECTION(
						cmd.l_token[0],
						.STANDARD_PUBLIC,
						types.current_user.m_k.valAsBytes,
						false,
					)
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
			clusterName: string
			collectionName: string
			fn: string
			if cmd.isUsingDotNotation == true {
				collectionName = cmd.l_token[0]
				clusterName = cmd.l_token[1]
				if !data.OST_CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
					fmt.printfln(
						"Collection: %s%s%s does not exist.",
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					return -1
				}

				OST_EXEC_CMD_LINE_PERM_CHECK(collectionName, NEW, .STANDARD_PUBLIC)

				fmt.printf(
					"Creating cluster: %s%s%s within collection: %s%s%s\n",
					BOLD_UNDERLINE,
					clusterName,
					RESET,
					BOLD_UNDERLINE,
					collectionName,
					RESET,
				)
				// checks := data.OST_HANDLE_INTEGRITY_CHECK_RESULT(collectionName)
				// switch (checks)
				// {
				// case -1:
				// 	return -1
				// }

				id := data.OST_GENERATE_ID(true)
				result := data.OST_CREATE_CLUSTER(collectionName, clusterName, id)
				data.OST_APPEND_ID_TO_COLLECTION(fmt.tprintf("%d", id), 0)

				switch (result) 
				{
				case -1:
					fmt.printfln(
						"Cluster with name: %s%s%s already exists within collection %s%s%s. Failed to create cluster.",
						BOLD_UNDERLINE,
						clusterName,
						RESET,
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					OST_ENCRYPT_COLLECTION(
						cmd.l_token[0],
						.STANDARD_PUBLIC,
						types.current_user.m_k.valAsBytes,
						false,
					)
					break
				case 1, 2, 3:
					error1 := new_err(
						.CANNOT_CREATE_CLUSTER,
						get_err_msg(.CANNOT_CREATE_CLUSTER),
						#file,
						#procedure,
						#line,
					)
					throw_custom_err(
						error1,
						"Failed to create cluster due to internal OstrichDB error.\n Check logs for more information.",
					)
					log_err("Failed to create new cluster.", #procedure)
					break
				}
				fn = concat_collection_name(collectionName)
				OST_UPDATE_METADATA_AFTER_OPERATION(fn)
			} else {
				fmt.printfln(
					"Invalid command. Correct Usage: NEW <collection_name>.<cluster_name>",
				)
				log_runtime_event(
					"Incomplete NEW command",
					"User did not provide a cluster name to create.",
				)
			}
			OST_ENCRYPT_COLLECTION(
				cmd.l_token[0],
				.STANDARD_PUBLIC,
				types.current_user.m_k.valAsBytes,
				false,
			)
			break
		case 3:
			collectionName, clusterName, recordName: string
			log_runtime_event("Used NEW RECORD command", "User requested to create a new record.")
			collectionName = cmd.l_token[0]
			clusterName = cmd.l_token[1]
			recordName = cmd.l_token[2]

			if !data.OST_CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
				fmt.printfln(
					"Collection: %s%s%s does not exist.",
					BOLD_UNDERLINE,
					collectionName,
					RESET,
				)
				return -1
			}

			OST_EXEC_CMD_LINE_PERM_CHECK(collectionName, NEW, .STANDARD_PUBLIC)

			if len(recordName) > 64 {
				fmt.printfln(
					"Record name: %s%s%s is too long. Please choose a name less than 128 characters.",
					BOLD_UNDERLINE,
					recordName,
					RESET,
				)
				return -1
			}
			colPath := concat_collection_name(collectionName)

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
						colPath,
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
							data.OST_SET_RECORD_VALUE(colPath, clusterName, recordName, NULL)
						}

						fn := concat_collection_name(collectionName)
						OST_UPDATE_METADATA_AFTER_OPERATION(fn)
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
				OST_ENCRYPT_COLLECTION(
					cmd.l_token[0],
					.STANDARD_PUBLIC,
					types.current_user.m_k.valAsBytes,
					false,
				)
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

				if !data.OST_CHECK_IF_COLLECTION_EXISTS(oldName, 0) {
					fmt.printfln(
						"Collection: %s%s%s does not exist.",
						BOLD_UNDERLINE,
						oldName,
						RESET,
					)
					return -1
				}


				OST_EXEC_CMD_LINE_PERM_CHECK(oldName, RENAME, .STANDARD_PUBLIC)

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

				OST_ENCRYPT_COLLECTION(
					newName,
					.STANDARD_PUBLIC,
					types.current_user.m_k.valAsBytes,
					false,
				)
			} else {
				fmt.println("Incomplete command. Correct Usage: RENAME <old_name> TO <new_name>")
			}
			break
		case 2:
			collectionName: string
			if TO in cmd.p_token && cmd.isUsingDotNotation == true {
				oldName := cmd.l_token[1]
				collectionName = cmd.l_token[0]
				newName := cmd.p_token[TO]

				if !data.OST_CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
					fmt.printfln(
						"Collection: %s%s%s does not exist.",
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					return -1
				}

				OST_EXEC_CMD_LINE_PERM_CHECK(collectionName, RENAME, .STANDARD_PUBLIC)

				// checks := data.OST_HANDLE_INTEGRITY_CHECK_RESULT(collectionName)
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

					OST_UPDATE_METADATA_AFTER_OPERATION(fn)
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
			OST_ENCRYPT_COLLECTION(
				collectionName,
				.STANDARD_PUBLIC,
				types.current_user.m_k.valAsBytes,
				false,
			)
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


					if !data.OST_CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
						fmt.printfln(
							"Collection: %s%s%s does not exist.",
							BOLD_UNDERLINE,
							collectionName,
							RESET,
						)
						return -1
					}

					OST_DECRYPT_COLLECTION(
						collectionName,
						.STANDARD_PUBLIC,
						types.current_user.m_k.valAsBytes,
					)

					OST_EXEC_CMD_LINE_PERM_CHECK(collectionName, RENAME, .STANDARD_PUBLIC)

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
			OST_ENCRYPT_COLLECTION(
				collectionName,
				.STANDARD_PUBLIC,
				types.current_user.m_k.valAsBytes,
				false,
			)
			break
		}
		break
	// ERASE: Allows for the deletion of collections, specific clusters, or individual records within a cluster
	case ERASE:
		log_runtime_event("Used ERASE command", "")
		switch (len(cmd.l_token)) 
		{
		case 1:
			collectionName := cmd.l_token[0]

			if !data.OST_CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
				fmt.printfln(
					"Collection: %s%s%s does not exist.",
					BOLD_UNDERLINE,
					collectionName,
					RESET,
				)
				return -1
			}

			OST_EXEC_CMD_LINE_PERM_CHECK(collectionName, ERASE, .STANDARD_PUBLIC)

			if data.OST_ERASE_COLLECTION(collectionName) == true {
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
			collectionName: string
			cluster: string

			if cmd.isUsingDotNotation == true {
				collectionName = cmd.l_token[0]
				cluster = cmd.l_token[1]

				if !data.OST_CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
					fmt.printfln(
						"Collection: %s%s%s does not exist.",
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					return -1
				}

				OST_EXEC_CMD_LINE_PERM_CHECK(collectionName, ERASE, .STANDARD_PUBLIC)

				clusterID := data.OST_GET_CLUSTER_ID(collectionName, cluster)
				// checks := data.OST_HANDLE_INTEGRITY_CHECK_RESULT(collectionName)
				// switch (checks)
				// {
				// case -1:
				// 	return -1
				// }

				if data.OST_ERASE_CLUSTER(collectionName, cluster) == true {
					fmt.printfln(
						"Cluster: %s%s%s successfully erased from collection: %s%s%s",
						BOLD_UNDERLINE,
						cluster,
						RESET,
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					OST_DECRYPT_COLLECTION("", .ID_PRIVATE, types.system_user.m_k.valAsBytes)
					if data.OST_REMOVE_ID_FROM_CLUSTER(fmt.tprintf("%d", clusterID), false) {
						OST_ENCRYPT_COLLECTION(
							"",
							.ID_PRIVATE,
							types.system_user.m_k.valAsBytes,
							false,
						)
					} else {
						OST_ENCRYPT_COLLECTION(
							"",
							.ID_PRIVATE,
							types.system_user.m_k.valAsBytes,
							false,
						)

						fmt.printfln(
							"Failed to erase cluster: %s%s%s from collection: %s%s%s",
							BOLD_UNDERLINE,
							cluster,
							RESET,
							BOLD_UNDERLINE,
							collectionName,
							RESET,
						)
					}
				} else {
					fmt.printfln(
						"Failed to erase cluster: %s%s%s from collection: %s%s%s",
						BOLD_UNDERLINE,
						cluster,
						RESET,
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
				}
				fn := concat_collection_name(collectionName)
				OST_UPDATE_METADATA_AFTER_OPERATION(fn)
			} else {
				fmt.println(
					"Incomplete command. Correct Usage: ERASE <collection_name>.<cluster_name>",
				)
				log_runtime_event(
					"Incomplete ERASE command",
					"User did not provide a valid cluster name to erase.",
				)
			}
			OST_ENCRYPT_COLLECTION(
				collectionName,
				.STANDARD_PUBLIC,
				types.current_user.m_k.valAsBytes,
				false,
			)
			break
		case 3:
			collectionName: string
			clusterName: string
			recordName: string

			if cmd.isUsingDotNotation == true {
				collectionName = cmd.l_token[0]
				clusterName = cmd.l_token[1]
				recordName = cmd.l_token[2]


				if !data.OST_CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
					fmt.printfln(
						"Collection: %s%s%s does not exist.",
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					return -1
				}

				OST_EXEC_CMD_LINE_PERM_CHECK(collectionName, ERASE, .STANDARD_PUBLIC)

				clusterID := data.OST_GET_CLUSTER_ID(collectionName, clusterName)
				// checks := data.OST_HANDLE_INTEGRITY_CHECK_RESULT(collectionName)
				// switch (checks)
				// {
				// case -1:
				// 	return -1
				// }
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
			OST_ENCRYPT_COLLECTION(
				collectionName,
				.STANDARD_PUBLIC,
				types.current_user.m_k.valAsBytes,
				false,
			)
			break
		case:
			fmt.printfln(
				"Invalid command structure. Correct Usage: ERASE <collection_name>.<cluster_name>.<record_name>",
			)
			log_runtime_event("Invalid ERASE command", "User did not provide a valid target.")
		}
		break
	// FETCH: Allows for the retrieval and displaying of collections, clusters, or individual records
	case FETCH:
		log_runtime_event("Used FETCH command", "")
		switch (len(cmd.l_token)) 
		{
		case 1:
			if len(cmd.l_token) > 0 {
				collectionName := cmd.l_token[0]

				//check that the collection even exists
				if !data.OST_CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
					fmt.printfln(
						"Collection: %s%s%s does not exist.",
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					return -1
				}

				OST_EXEC_CMD_LINE_PERM_CHECK(collectionName, FETCH, .STANDARD_PUBLIC)

				str := data.OST_FETCH_COLLECTION(collectionName)
				fmt.println(str)
			} else {
				fmt.println("Incomplete command. Correct Usage: FETCH <collection_name>")
				log_runtime_event(
					"Incomplete FETCH command",
					"User did not provide a valid collection name to fetch.",
				)
			}
			OST_ENCRYPT_COLLECTION(
				cmd.l_token[0],
				.STANDARD_PUBLIC,
				types.current_user.m_k.valAsBytes,
				false,
			)
			break
		case 2:
			if cmd.isUsingDotNotation == true {
				collectionName := cmd.l_token[0]
				clusterName := cmd.l_token[1]

				if !data.OST_CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
					fmt.printfln(
						"Collection: %s%s%s does not exist.",
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					return -1
				}

				OST_EXEC_CMD_LINE_PERM_CHECK(collectionName, FETCH, .STANDARD_PUBLIC)

				clusterContent := data.OST_FETCH_CLUSTER(collectionName, clusterName)
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
			OST_ENCRYPT_COLLECTION(
				cmd.l_token[0],
				.STANDARD_PUBLIC,
				types.current_user.m_k.valAsBytes,
				false,
			)
			break
		case 3:
			collectionName: string
			clusterName: string
			recordName: string

			if len(cmd.l_token) == 3 && cmd.isUsingDotNotation == true {
				collectionName = cmd.l_token[0]
				clusterName = cmd.l_token[1]
				recordName = cmd.l_token[2]

				if !data.OST_CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
					fmt.printfln(
						"Collection: %s%s%s does not exist.",
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					return -1
				}

				OST_EXEC_CMD_LINE_PERM_CHECK(collectionName, FETCH, .STANDARD_PUBLIC)

				// checks := data.OST_HANDLE_INTEGRITY_CHECK_RESULT(collectionName)
				// switch (checks)
				// {
				// case -1:
				// 	return -1
				// }
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
			OST_ENCRYPT_COLLECTION(
				cmd.l_token[0],
				.STANDARD_PUBLIC,
				types.current_user.m_k.valAsBytes,
				false,
			)
			break
		case:
			fmt.printfln("Invalid command structure. Correct Usage: FETCH <Targets_name>")
			log_runtime_event("Invalid FETCH command", "User did not provide a valid target.")
		}
		break
	// SET: Allows for the setting of values within records or configs
	case SET:
		switch (len(cmd.l_token)) 
		{
		case 3:
			//Setting a standard records value
			if TO in cmd.p_token && cmd.isUsingDotNotation {
				collectionName := cmd.l_token[0]
				clusterName := cmd.l_token[1]
				recordName := cmd.l_token[2]

				if !data.OST_CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
					fmt.printfln(
						"Collection: %s%s%s does not exist.",
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					return -1
				}

				OST_EXEC_CMD_LINE_PERM_CHECK(collectionName, SET, .STANDARD_PUBLIC)

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


				/*
			    Added this because of: https://github.com/Solitude-Software-Solutions/OstrichDB/issues/203
				I guess its not neeeded, if a user wants to have a single character string record who am I to stop them?
				Remove at any time if needed - Marshall
				*/
				if rType == STRING && len(value) == 1 {
					conversionSuccess := data.OST_CHANGE_RECORD_TYPE(
						file,
						clusterName,
						recordName,
						value,
						CHAR,
					)
					if conversionSuccess {
						fmt.printfln(
							"Record with name: %s%s%s converted to type: %sCHAR%s",
							BOLD_UNDERLINE,
							recordName,
							RESET,
							BOLD_UNDERLINE,
							RESET,
						)
					}
				}


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
				OST_UPDATE_METADATA_AFTER_OPERATION(fn)
			}
			OST_ENCRYPT_COLLECTION(
				cmd.l_token[0],
				.STANDARD_PUBLIC,
				types.current_user.m_k.valAsBytes,
				false,
			)
			break
		case 1:
			switch (cmd.t_token) {
			case CONFIG:
				log_runtime_event("Used SET command", "")
				if TO in cmd.p_token {
					configName := cmd.l_token[0]
					value := cmd.p_token[TO]

					OST_EXEC_CMD_LINE_PERM_CHECK("", SET, .CONFIG_PRIVATE)

					for key, val in cmd.p_token {
						value = strings.to_lower(val)
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
					switch (configName) 
					{
					case "HELP_VERBOSE":
						if value == "true" || value == "false" {
							success := config.OST_UPDATE_CONFIG_VALUE(CONFIG_FOUR, value)
							if success == false {
								fmt.printfln("Failed to set HELP config to %s", value)
							} else {
								AUTO_OST_UPDATE_METADATA_VALUE(OST_CONFIG_PATH, 4)
								AUTO_OST_UPDATE_METADATA_VALUE(OST_CONFIG_PATH, 5)
								fmt.printfln("Successfully set HELP config to %s", value)
							}
							help.OST_SET_HELP_MODE()
						} else {
							fmt.println(
								"Invalid value. Valid values for config help_verbose are: 'true' or 'false'",
							)
							return 1
						}
						break
					case "SUPPRESS_ERRORS":
						if value == "true" || value == "false" {


							fmt.printfln(
								"Setting config: %s%s%s to %s%s%s",
								BOLD_UNDERLINE,
								configName,
								RESET,
								BOLD_UNDERLINE,
								value,
								RESET,
							)
							success := config.OST_UPDATE_CONFIG_VALUE(CONFIG_SIX, value)
							if success == false {
								fmt.printfln("Failed to set SUPPRESS_ERRORS config to %s", value)
							} else {
								fmt.printfln(
									"Successfully set SUPPRESS_ERRORS config to %s",
									value,
								)
							}
							break
						} else {
							fmt.println(
								"Invalid value. Valid values for config suppress_errors are: 'true' or 'false'",
							)
							return 1
						}
						break
					case "LIMIT_HISTORY":
						if value == "true" || value == "false" {
							fmt.printfln(
								"Setting config: %s%s%s to %s%s%s",
								BOLD_UNDERLINE,
								configName,
								RESET,
								BOLD_UNDERLINE,
								value,
								RESET,
							)
							success := config.OST_UPDATE_CONFIG_VALUE(CONFIG_SEVEN, value)
							if success == false {
								fmt.printfln("Failed to set LIMIT_HISTORY config to %s", value)
							} else {
								fmt.printfln("Successfully set LIMIT_HISTORY config to %s", value)
							}
							break
						} else {
							fmt.println(
								"Invalid value. Valid values for config limit_history are: 'true' or 'false'",
							)
							return 1
						}
						break
					case "SERVER_ON":
						if value == "true" || value == "false" {
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
								AUTO_OST_UPDATE_METADATA_VALUE(OST_CONFIG_PATH, 4)
								AUTO_OST_UPDATE_METADATA_VALUE(OST_CONFIG_PATH, 5)
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
						} else {
							fmt.println(
								"Invalid value. Valid values for config server are: 'true' or 'false'",
							)
						}
						break
					case:
						fmt.printfln(
							"Invalid config name provided. Valid config names are:\nHELP_VERBOSE\nSUPPRESS_ERRORS\nLIMIT_HISTORY\nSERVER_ON\n",
						)
					}
				} else {
					fmt.printfln(
						"Incomplete command. Correct Usage: SET CONFIG <config_name> TO <value>",
					)
				}
				OST_ENCRYPT_COLLECTION(
					"",
					.CONFIG_PRIVATE,
					types.current_user.m_k.valAsBytes,
					false,
				)
				break
			}
		case:
			//if the length of the token is not 3 or 1, then the SET command is invalid
			fmt.printfln(
				"Invalid command structure. Correct Usage: SET <collection_name>.<cluster_name>.<record_name> TO <value> or SET CONFIG <config_name> TO <value>",
			)
			fmt.printfln("Note: The SET command can only be used on RECORDS and CONFIGS")
		}
	// COUNT: Allows for the counting of collections, clusters, or records
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
				collectionName := cmd.l_token[0]

				if !data.OST_CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
					fmt.printfln(
						"Collection: %s%s%s does not exist.",
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					return -1
				}

				OST_EXEC_CMD_LINE_PERM_CHECK(collectionName, COUNT, .STANDARD_PUBLIC)

				result := data.OST_COUNT_CLUSTERS(collectionName)
				switch (result) 
				{
				case -1:
					fmt.printfln(
						"Failed to count clusters in collection %s%s%s",
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					break
				case 0:
					fmt.printfln(
						"There are no clusters in the collection %s%s%s",
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					break
				case 1:
					fmt.printfln(
						"There is %d cluster in the collection %s%s%s",
						result,
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					break
				case:
					fmt.printfln(
						"There are %d clusters in the collection %s%s%s",
						result,
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					break
				}
				OST_ENCRYPT_COLLECTION(
					cmd.l_token[0],
					.STANDARD_PUBLIC,
					types.current_user.m_k.valAsBytes,
					false,
				)
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

				if !data.OST_CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
					fmt.printfln(
						"Collection: %s%s%s does not exist.",
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					return -1
				}

				OST_EXEC_CMD_LINE_PERM_CHECK(collectionName, COUNT, .STANDARD_PUBLIC)

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
				OST_ENCRYPT_COLLECTION(
					collectionName,
					.STANDARD_PUBLIC,
					types.current_user.m_k.valAsBytes,
					false,
				)
			} else if len(cmd.l_token) == 1 || cmd.isUsingDotNotation == true { 	//TODO: 12 March, 2025 THIS WHOLE BLOCK IS FUCKED FOR SOME REASON - MARSHALL
				//in the event the user is counting all records in a collection
				collectionName := cmd.l_token[0]

				if !data.OST_CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
					fmt.printfln(
						"Collection: %s%s%s does not exist.",
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					return -1
				}

				OST_EXEC_CMD_LINE_PERM_CHECK(collectionName, COUNT, .STANDARD_PUBLIC)

				result := data.OST_COUNT_RECORDS_IN_COLLECTION(collectionName)

				switch result 
				{
				case -1:
					fmt.printfln(
						"Error counting records in the collection %s%s%s",
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					break
				case 0:
					fmt.printfln(
						"There are no records in collection %s%s%s",
						BOLD,
						collectionName,
						RESET,
					)
					break
				case 1:
					fmt.printfln(
						"There is %d record in the collection %s%s%s",
						result,
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					break
				case:
					fmt.printfln(
						"There are %d records in the collection %s%s%s",
						result,
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
				}
				OST_ENCRYPT_COLLECTION(
					cmd.l_token[0],
					.STANDARD_PUBLIC,
					types.current_user.m_k.valAsBytes,
					false,
				)
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
	//PURGE: Removes all data from the provided collection, cluster, or record but maintains the structure
	case PURGE:
		collectionName, clusterName, recordName: string
		log_runtime_event("Used PURGE command", "")
		switch (len(cmd.l_token)) 
		{
		case 1:
			collectionName = cmd.l_token[0]

			if !data.OST_CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
				fmt.printfln(
					"Collection: %s%s%s does not exist.",
					BOLD_UNDERLINE,
					collectionName,
					RESET,
				)
				return -1
			}

			OST_EXEC_CMD_LINE_PERM_CHECK(collectionName, PURGE, .STANDARD_PUBLIC)

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
				file := concat_collection_name(collectionName)
				OST_UPDATE_METADATA_AFTER_OPERATION(file)
				break
			case false:
				fmt.printfln("Failed to purge collection: %s%s%s", BOLD, cmd.l_token[0], RESET)
				break
			}
			OST_ENCRYPT_COLLECTION(
				collectionName,
				.STANDARD_PUBLIC,
				types.current_user.m_k.valAsBytes,
				false,
			)
			break
		case 2:
			collectionName = cmd.l_token[0]
			clusterName = cmd.l_token[1]

			if !data.OST_CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
				fmt.printfln(
					"Collection: %s%s%s does not exist.",
					BOLD_UNDERLINE,
					collectionName,
					RESET,
				)
				return -1
			}

			OST_EXEC_CMD_LINE_PERM_CHECK(collectionName, PURGE, .STANDARD_PUBLIC)

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

			OST_ENCRYPT_COLLECTION(
				collectionName,
				.STANDARD_PUBLIC,
				types.current_user.m_k.valAsBytes,
				false,
			)
			break
		case 3:
			collectionName = cmd.l_token[0]
			clusterName = cmd.l_token[1]
			recordName = cmd.l_token[2]

			if !data.OST_CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
				fmt.printfln(
					"Collection: %s%s%s does not exist.",
					BOLD_UNDERLINE,
					collectionName,
					RESET,
				)
				return -1
			}

			OST_EXEC_CMD_LINE_PERM_CHECK(collectionName, PURGE, .STANDARD_PUBLIC)

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
			OST_ENCRYPT_COLLECTION(
				collectionName,
				.STANDARD_PUBLIC,
				types.current_user.m_k.valAsBytes,
				false,
			)
			break
		}
		break
	//SIZE_OF: Allows for the retrieval of the size of collections, clusters, or records in bytes
	case SIZE_OF:
		log_runtime_event("Used SIZE_OF command", "")
		switch (len(cmd.l_token)) {
		case 1:
			collectionName := cmd.l_token[0]

			if !data.OST_CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
				fmt.printfln(
					"Collection: %s%s%s does not exist.",
					BOLD_UNDERLINE,
					collectionName,
					RESET,
				)
				return -1
			}

			OST_EXEC_CMD_LINE_PERM_CHECK(collectionName, SIZE_OF, .STANDARD_PUBLIC)

			file_path := concat_collection_name(collectionName)
			actual_size, metadata_size := OST_SUBTRACT_METADATA_SIZE(file_path)
			if actual_size != -1 {
				fmt.printf(
					"Size of collection %s: %d bytes (excluding %d bytes of metadata)\n",
					collectionName,
					actual_size,
					metadata_size,
				)
			} else {
				fmt.printf("Failed to get size of collection %s\n", collectionName)
			}
			OST_ENCRYPT_COLLECTION(
				collectionName,
				.STANDARD_PUBLIC,
				types.current_user.m_k.valAsBytes,
				false,
			)
			break
		case 2:
			if cmd.isUsingDotNotation {
				collectionName := cmd.l_token[0]
				clusterName := cmd.l_token[1]

				if !data.OST_CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
					fmt.printfln(
						"Collection: %s%s%s does not exist.",
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					return -1
				}

				OST_EXEC_CMD_LINE_PERM_CHECK(collectionName, SIZE_OF, .STANDARD_PUBLIC)

				//TODO: This is returning an inaccurate size, need to fix
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
			OST_ENCRYPT_COLLECTION(
				cmd.l_token[0],
				.STANDARD_PUBLIC,
				types.current_user.m_k.valAsBytes,
				false,
			)
			break
		case 3:
			if cmd.isUsingDotNotation {
				collectionName := cmd.l_token[0]
				clusterName := cmd.l_token[1]
				recordName := cmd.l_token[2]


				if !data.OST_CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
					fmt.printfln(
						"Collection: %s%s%s does not exist.",
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					return -1
				}

				OST_EXEC_CMD_LINE_PERM_CHECK(collectionName, SIZE_OF, .STANDARD_PUBLIC)

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
				OST_ENCRYPT_COLLECTION(
					cmd.l_token[0],
					.STANDARD_PUBLIC,
					types.current_user.m_k.valAsBytes,
					false,
				)
			} else {
				fmt.println(
					"Invalid command. Use dot notation for records: SIZE_OF RECORD collection_name.cluster_name.record_name",
				)
			}
		case:
			fmt.println(
				"Invalid SIZE_OF command. Use SIZE_OF COLLECTION, SIZE_OF CLUSTER, or SIZE_OF RECORD.",
			)
			break
		}
		break
	// TYPE_OF: Allows for the retrieval of the type of a record
	case TYPE_OF:
		log_runtime_event("Used TYPE_OF command", "")
		//only works on records
		if len(cmd.l_token) == 3 && cmd.isUsingDotNotation == true {
			collectionName := cmd.l_token[0]
			clusterName := cmd.l_token[1]
			recordName := cmd.l_token[2]

			if !data.OST_CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
				fmt.printfln(
					"Collection: %s%s%s does not exist.",
					BOLD_UNDERLINE,
					collectionName,
					RESET,
				)
				return -1
			}

			OST_EXEC_CMD_LINE_PERM_CHECK(collectionName, TYPE_OF, .STANDARD_PUBLIC)

			colPath := concat_collection_name(collectionName)
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

			OST_ENCRYPT_COLLECTION(
				collectionName,
				.STANDARD_PUBLIC,
				types.current_user.m_k.valAsBytes,
				false,
			)

		} else {
			fmt.printfln(
				"Incomplete command. Correct Usage: TYPE_OF <collection_name>.<cluster_name>.<record_name>",
			)

		}
		break
	// CHANGE_TYPE: Allows for the changing of a record's type
	case CHANGE_TYPE:
		//only works on records
		switch (len(cmd.l_token)) {
		case 3:
			if TO in cmd.p_token && cmd.isUsingDotNotation == true {
				collectionName := cmd.l_token[0]
				clusterName := cmd.l_token[1]
				recordName := cmd.l_token[2]
				newType := cmd.p_token[TO]

				if !data.OST_CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
					fmt.printfln(
						"Collection: %s%s%s does not exist.",
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					return -1
				}
				colPath := concat_collection_name(collectionName)

				OST_EXEC_CMD_LINE_PERM_CHECK(collectionName, CHANGE_TYPE, .STANDARD_PUBLIC)

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
				OST_ENCRYPT_COLLECTION(
					collectionName,
					.STANDARD_PUBLIC,
					types.current_user.m_k.valAsBytes,
					false,
				)
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
	// // ISOLATE: Allows for the isolation of a collection so that it cannot be accessed via the CLI
	case ISOLATE:
		log_runtime_event("Used ISOLATE command", "")
		switch (len(cmd.l_token)) {
		case 1:
			collectionName := cmd.l_token[0]


			if !data.OST_CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
				fmt.printfln(
					"Collection: %s%s%s does not exist.",
					BOLD_UNDERLINE,
					collectionName,
					RESET,
				)
				return -1
			}

			OST_EXEC_CMD_LINE_PERM_CHECK(collectionName, ISOLATE, .STANDARD_PUBLIC)

			result, isolatedColName := data.OST_PERFORM_ISOLATION(collectionName)
			fmt.println("isolatedNAme: ", isolatedColName)
			switch result {
			case 0:
				fmt.printfln(
					"Successfully isolated collection: %s%s%s",
					BOLD_UNDERLINE,
					collectionName,
					RESET,
				)
				break
			case:
				fmt.printfln(
					"Failed to isolate collection: %s%s%s",
					BOLD_UNDERLINE,
					collectionName,
					RESET,
				)
				break
			}
			OST_ENCRYPT_COLLECTION(
				isolatedColName,
				.ISOLATE_PUBLIC,
				types.current_user.m_k.valAsBytes,
				false,
			)
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
	//VALIDATE: Runs the data integrity check on a collection, if it passes GTG, if the the collection is isolated
	// case VALIDATE:
	// 	switch (len(cmd.l_token)) {
	// 	case 1:
	// 		collectionName := cmd.l_token[0]

	// 		if !data.OST_CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
	// 			fmt.printfln(
	// 				"Collection: %s%s%s does not exist.",
	// 				BOLD_UNDERLINE,
	// 				collectionName,
	// 				RESET,
	// 			)
	// 			return -1
	// 		}

	// 		OST_EXEC_CMD_LINE_PERM_CHECK(collectionName, VALIDATE, .STANDARD_PUBLIC)

	// 		result := data.OST_HANDLE_INTEGRITY_CHECK_RESULT(collectionName)

	// 		if result == 0 {
	// 			fmt.printfln(
	// 				"Collection: %s%s%s data integrity status: %svalid%s",
	// 				BOLD_UNDERLINE,
	// 				collectionName,
	// 				RESET,
	// 				GREEN,
	// 				RESET,
	// 			)

	// 			OST_ENCRYPT_COLLECTION(
	// 				collectionName,
	// 				.STANDARD_PUBLIC,
	// 				types.current_user.m_k.valAsBytes,
	// 				false,
	// 			)
	// 		} else {
	// 			fmt.printfln(
	// 				"Collection: %s%s%s data integrity status: %sinvalid%s",
	// 				BOLD_UNDERLINE,
	// 				collectionName,
	// 				RESET,
	// 				RED,
	// 				RESET,
	// 			)
	// 			//No need to encrypt because file will be isolated
	// 		}

	// 	}
	// 	break
	//BENCHMARK: Runs the benchmarking suite with or without parameters
	case BENCHMARK:
		switch (len(cmd.l_token)) {
		case 0:
			benchmark.OST_RUN_BENCHMARK([]int{0, 0, 0}, true)
			break
		case 3:
			for token, i in cmd.l_token {
				if !utils.string_is_int(token) {
					fmt.printfln(
						"Error: When passing parameters to the BENCHMARK command, all values must be integers. Example: BENCHMARK 10.10.10",
					)
					return 1
				}
			}
			colIteration := strconv.atoi(cmd.l_token[0])
			clusterIteration := strconv.atoi(cmd.l_token[1])
			recordIteration := strconv.atoi(cmd.l_token[2])
			benchmark.OST_RUN_BENCHMARK(
				[]int{colIteration, clusterIteration, recordIteration},
				false,
			)
			break
		case:
			fmt.printfln(
				"Incomplete command. Correct Usage: BENCHMARK or BENCHMARK <#of_collections>.<#of_clusters>.<#of_records>",
			)
		}
		break
	// //IMPORT: Imports foreign data into OstrichDB
	case IMPORT:
		transfer.__import_csv__("CSV_FILE") //TODO: chang this to user input
		break
	case EXPORT:
		fmt.println("NOT YET IMPLEMENTED")
		break
	//LOCK: Locks a collection with a flag or without a flag
	case LOCK:
		flag: string
		switch len(cmd.l_token) {
		case 1:
			//locking a collection with no flag defaults to it being inaccessable unless unlocked
			colName := cmd.l_token[0]

			if !data.OST_CHECK_IF_COLLECTION_EXISTS(colName, 0) {
				fmt.printfln("Collection: %s%s%s does not exist.", BOLD_UNDERLINE, colName, RESET)
				return -1
			}

			OST_DECRYPT_COLLECTION(colName, .STANDARD_PUBLIC, types.current_user.m_k.valAsBytes)

			collectionAlreadyLocked := security.OST_GET_COLLECTION_LOCK_STATUS(colName)

			//next make sure the "locker" is an admin
			OST_DECRYPT_COLLECTION(
				types.current_user.username.Value,
				.SECURE_PRIVATE,
				types.system_user.m_k.valAsBytes,
			)
			isAdmin := security.OST_CHECK_ADMIN_STATUS(&types.current_user)

			if !isAdmin {
				fmt.printfln(
					"User: %s%s%s does not have permission to lock collections.",
					BOLD_UNDERLINE,
					types.current_user.username.Value,
					RESET,
				)
				return 1
			} else {
				if collectionAlreadyLocked {
					fmt.printfln(
						"Collection: %s%s%s already has a lock status. Please use the UNLOCK command to unlock it, then try again.",
						BOLD_UNDERLINE,
						colName,
						RESET,
					)
					return 1
				} else {
					fmt.printfln(
						"Please enter your password to confirm locking collection: %s%s%s",
						BOLD_UNDERLINE,
						colName,
						RESET,
					)
					input := utils.get_input(true)
					password := string(input)
					validatedPassword := security.OST_VALIDATE_USER_PASSWORD(password)
					switch (validatedPassword) {
					case false:
						fmt.printfln("Invalid password. Operation cancelled.")
						break
					case true:
						lockSuccess, permission := data.OST_LOCK_COLLECTION(colName, "-N")
						if lockSuccess {
							filePath := concat_collection_name(colName)
							osPermSuccess := security.OST_SET_OS_PERMISSIONS(filePath, permission)
							if !osPermSuccess {
								fmt.printfln(
									"%sWarning: Failed to set OS-level permissions for collection: %s%s%s",
									YELLOW,
									BOLD_UNDERLINE,
									colName,
									RESET,
								)
							}

							fmt.printfln(
								"Collection: %s%s%s is now in %s%s%s mode.",
								BOLD_UNDERLINE,
								colName,
								RESET,
								BOLD,
								permission,
								RESET,
							)
						} else {
							fmt.printfln(
								"Failed to lock collection: %s%s%s",
								BOLD_UNDERLINE,
								colName,
								RESET,
							)
							return 1
						}
					}
				}
			}

			OST_ENCRYPT_COLLECTION(
				types.current_user.username.Value,
				.SECURE_PRIVATE,
				types.system_user.m_k.valAsBytes,
				false,
			)

			OST_ENCRYPT_COLLECTION(
				colName,
				.STANDARD_PUBLIC,
				types.current_user.m_k.valAsBytes,
				false,
			)
			break
		case 2:
			colName := cmd.l_token[0]
			flag := cmd.l_token[1]

			OST_DECRYPT_COLLECTION(colName, .STANDARD_PUBLIC, types.current_user.m_k.valAsBytes)

			fmt.printfln("Locking collection: %s%s%s ", BOLD_UNDERLINE, colName, RESET)
			lockSuccess, permission := data.OST_LOCK_COLLECTION(colName, flag)
			if lockSuccess {
				fmt.printfln(
					"Collection: %s%s%s now now in %s%s%s mode.",
					BOLD_UNDERLINE,
					colName,
					RESET,
					BOLD,
					permission,
					RESET,
				)
			} else {
				fmt.printfln("Failed to lock collection: %s%s%s", BOLD_UNDERLINE, colName, RESET)
				return 1
			}
			break
		case:
			fmt.printfln(
				"Incomplete command. Correct Usage: LOCK <collection_name> or LOCK <collection_name> -{flag}",
			)
		}
		OST_ENCRYPT_COLLECTION(
			cmd.l_token[0],
			.STANDARD_PUBLIC,
			types.current_user.m_k.valAsBytes,
			false,
		)
		break
	case UNLOCK:
		//TODO: only admin users can use the UNLOCK command, this may change in the future but for now it is locked to admin users
		switch (len(cmd.l_token)) {
		case 1:
			colName := cmd.l_token[0]
			//check that a collection is in fact locked

			OST_DECRYPT_COLLECTION(colName, .STANDARD_PUBLIC, types.current_user.m_k.valAsBytes)

			OST_DECRYPT_COLLECTION(
				types.current_user.username.Value,
				.SECURE_PRIVATE,
				types.system_user.m_k.valAsBytes,
			)
			collectionAlreadyLocked := security.OST_GET_COLLECTION_LOCK_STATUS(colName)
			if !collectionAlreadyLocked {
				fmt.printfln("Collection: %s%s%s is not locked.", BOLD_UNDERLINE, colName, RESET)
				return 1
			} else {
				//check that current user is admin
				isAdmin := security.OST_CHECK_ADMIN_STATUS(&types.current_user)

				if !isAdmin {
					fmt.printfln(
						"User: %s%s%s does not have permission to unlock collections.",
						BOLD_UNDERLINE,
						types.current_user.username.Value,
						RESET,
					)
					return 1
				} else {
					passwordConfirmed := security.OST_CONFIRM_COLLECECTION_UNLOCK()
					switch (passwordConfirmed) 
					{
					case false:
						fmt.printfln(
							"Failed to unlock collection: %s%s%s",
							BOLD_UNDERLINE,
							colName,
							RESET,
						)
						return 1
					case true:
						currentPerm, err := metadata.OST_GET_METADATA_VALUE(
							colName,
							"# Permission",
							1,
						)
						fmt.printfln(
							"Unlocking collection: %s%s%s",
							BOLD_UNDERLINE,
							colName,
							RESET,
						)
						// fmt.printfln("Current permission: %s%s%s", BOLD, currentPerm, RESET) //debugging
						unlockSuccess := data.OST_UNLOCK_COLLECTION(colName, currentPerm)
						break
					}
				}
			}
			OST_ENCRYPT_COLLECTION(
				types.current_user.username.Value,
				.SECURE_PRIVATE,
				types.system_user.m_k.valAsBytes,
				false,
			)

			OST_ENCRYPT_COLLECTION(
				cmd.l_token[0],
				.STANDARD_PUBLIC,
				types.current_user.m_k.valAsBytes,
				false,
			)
			break
		case:
			fmt.printfln("Incomplete command. Correct Usage: UNLOCK <collection_name>")
		}
		//unlock is the only way to re-enable Read-Write access to a collection unless user deletes then creates a new one
		break
	case ENC:
		switch (len(cmd.l_token)) {
		case 1:
			colName := cmd.l_token[0]
			encSuccess, _ := OST_ENCRYPT_COLLECTION(
				colName,
				.STANDARD_PUBLIC,
				types.current_user.m_k.valAsBytes,
				false,
			)
			if encSuccess == 0 {
				fmt.printfln(
					"Successfully encrypted collection: %s%s%s",
					BOLD_UNDERLINE,
					colName,
					RESET,
				)
			} else {
				fmt.printfln(
					"Failed to encrypt collection: %s%s%s",
					BOLD_UNDERLINE,
					colName,
					RESET,
				)
			}
			break
		}
		break
	case DEC:
		switch (len(cmd.l_token)) {
		case 1:
			colName := cmd.l_token[0]
			decSuccess, _ := security.OST_DECRYPT_COLLECTION(
				colName,
				.STANDARD_PUBLIC,
				types.current_user.m_k.valAsBytes,
			)

			if decSuccess == 0 {
				fmt.printfln(
					"Successfully decrypted collection: %s%s%s",
					BOLD_UNDERLINE,
					colName,
					RESET,
				)
			} else {
				fmt.printfln(
					"Failed to decrypt collection: %s%s%s",
					BOLD_UNDERLINE,
					colName,
					RESET,
				)
			}
			break
		}

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
