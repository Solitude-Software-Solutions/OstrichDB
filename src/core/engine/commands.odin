package engine

import "../nlp"
import "../../utils"
import "../benchmark"
import "../const"
import "../engine/transfer/importing"
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


EXECUTE_COMMAND :: proc(cmd: ^types.Command) -> int {
	using metadata
	using const
	using utils
	using security
	using types


	//Handle command chaining
	if cmd.isChained {
		fmt.println("Executing chained commands...")

		// Split the raw input by the && operator
		commandArr := strings.split(cmd.rawInput, "&&")
		result := 1

		// Execute each command in sequence
		for command in commandArr {
			trimmedCommand := strings.trim_space(command)
			if len(trimmedCommand) > 0 {
				parsedCmd := PARSE_COMMAND(trimmedCommand)
				cmdResult := EXECUTE_COMMAND(&parsedCmd)

				// If any command fails, return that failure code
				if cmdResult <= 0 {
					result = cmdResult
					break
				}
			}
		}

		return result
	}

	defer delete(cmd.l_token)
	#partial switch (cmd.c_token)
	{
	//=======================<SINGLE-TOKEN COMMANDS>=======================//

	//Shows the current version of OstrichDB
	case .VERSION:
		log_runtime_event("Used VERSION command", "User requested version information.")
		fmt.printfln("Using OstrichDB Version: %s%s%s", BOLD, get_ost_version(), RESET)
		break
	//Safely kills the dbms
	case .EXIT:
		//logout then exit the program
		log_runtime_event("Used EXIT command", "User requested to exit the program.")
		security.RUN_USER_LOGOUT(1)
	case .LOGOUT:
		//only returns user to signin.
		log_runtime_event("Used LOGOUT command", "User requested to logout.")
		fmt.printfln("Logging out...")
		security.RUN_USER_LOGOUT(0)
		return 0
	// Runs the restart script
	case .RESTART:
		log_runtime_event("Used RESTART command", "User requested to restart OstrichDB.")
		RESTART_OSTRICHDB()
	case .REBUILD:
		log_runtime_event("Used REBUILD command", "User requested to rebuild OstrichDB")
		REBUILD_OSTRICHDB()
	case .SERVE, .SERVER:
		//first kill localhost:8042
		libc.system("stty -echo")
		libc.system("kill -9 $(lsof -ti :8042) 2>/dev/null")
		libc.system("stty echo")
		fmt.printfln("Launching OstrichDB server...")
		serverResult := server.START_OSTRICH_SERVER(&ServerConfig)
		if serverResult == 0 {
			fmt.printfln("Server stopped. Returning to OstrichDB command line...")
		} else {
			fmt.printfln("Server stopped with errors. Returning to OstrichDB command line...")
		}
		break
	case .AGENT: //Used to interact with the OstrichDB ai agent
	   nlp.main() //TODO: This wont do anything because it requires the server to be running for work to be done
	// Used to completley destroy the program and all its files, rebuilds after on macOs and Linux
	case .DESTROY:
		log_runtime_event("Used DESTROY command", "User requested to destroy OstrichDB.")
		DESTROY_EVERYTHING()
	//Clears the terminal screen
	case .CLEAR:
		log_runtime_event("Used CLEAR command", "User requested to clear the screen.")
		libc.system("clear")
		break
	//Shows a tree-like structure of the dbms
	case .TREE:
		log_runtime_event("Used TREE command", "User requested to view a tree of the database.")
		data.GET_COLLECTION_TREE()
		break
	// Shows the current users past command history
	case .HISTORY:
		log_runtime_event("Used HISTORY command", "User requested to view the command history.")
		DECRYPT_COLLECTION("", .HISTORY_PRIVATE, types.system_user.m_k.valAsBytes)
		commandHistory := push_records_to_array(types.current_user.username.Value)

		ENCRYPT_COLLECTION("", .HISTORY_PRIVATE, types.system_user.m_k.valAsBytes, false)
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
		if commandIndex + 1 == 0{
		  break
		}else{
			fmt.printfln("Command number %d not found", commandIndex + 1) // add one to make it reflect what the user sees
			break
		  }
		}
		// parses the command that has been stored in the most recent command history index. Crucial for the HISTORY command
		cmd := PARSE_COMMAND(commandHistory[commandIndex])
		EXECUTE_COMMAND(&cmd)


		delete(commandHistory)
		break
	//=======================<SINGLE OR MULTI-TOKEN COMMANDS>=======================//
	case .HELP:
		log_runtime_event("Used HELP command", "User requested help information.")
		if len(cmd.t_token) == 0 {
			log_runtime_event("Used HELP command", "User requested general help information.")
			help.GET_GENERAL_HELP_INFO()
		} else if cmd.t_token == Token[.CLP] || cmd.t_token == Token[.CLPS] {
			log_runtime_event("Used HELP command", "User requested CLP help information.")
			help.SHOW_TOKEN_HELP_TABLE()
		} else {
			help.GET_HELP_INFO_FOR_SPECIFIC_TOKEN(cmd.t_token)
			log_runtime_event("Used HELP command", "User requested specific help information.")
		}
		break
	//=======================<MULTI-TOKEN COMMANDS>=======================//
	//WHERE: Used to search for a specific object within the DBMS
	// TODO: The WHERE command is pretty useless right now.
	// it needs to be able to read collections to find a
	// specific record or cluster....but since all collections will be encrypted and no specific collection
	// is provided to search through nothing will work. Will need to re-implement this command after creating
	// some sort of DECRYPT_ALL_COLLECTIONS/ENCRYPT_ALL_COLLECTIONS command
	// case .WHERE:
	// 	log_runtime_event("Used WHERE command", "User requested to search for a specific object.")
	// 	switch (cmd.t_token) {
	// 	case CLUSTER, RECORD:
	// 		collectionName := cmd.l_token[0]

	// 		//Todo this check here seems to work sometimes and other times not. Keep an eye on it - Marshall
	// 		//--------------Permissions Security stuff Start----------------//
	// 		EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(collectionName, WHERE, .STANDARD_PUBLIC)

	// 		found := data.LOCATE_SPECIFIC_DATA_OBJECT(cmd.t_token, collectionName)
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

	// 		found, collectionName, clusterName := data.LOCATE_ANY_OBJECT_WITH_NAME(cmd.t_token)


	// 		EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(collectionName, WHERE, .STANDARD_PUBLIC)


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
	case .BACKUP:
		log_runtime_event("Used BACKUP command", "User requested to backup data.")
		switch (len(cmd.l_token)) {
		case 1:
			collectionName := cmd.l_token[0]

			if !data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
				fmt.printfln(
					"Collection: %s%s%s does not exist.",
					BOLD_UNDERLINE,
					collectionName,
					RESET,
				)
				return -1
			}

			//--------------Permissions Security stuff Start----------------//
			EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(
				collectionName,
				Token[.BACKUP],
				.STANDARD_PUBLIC,
			)

			name := data.CHOOSE_BACKUP_NAME()
			// checks := data.HANDLE_INTEGRITY_CHECK_RESULT(collectionName)
			// switch (checks)
			// {
			// case -1:
			// 	return -1
			// }
			success := data.CREATE_BACKUP_COLLECTION(name, cmd.l_token[0])
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
	case .NEW:
		log_runtime_event("Used NEW command", "")
		switch (len(cmd.l_token)) {
		case COLLECTION_TIER:
			exists := data.CHECK_IF_COLLECTION_EXISTS(cmd.l_token[0], 0)
			switch (exists) {
			case false:
				fmt.printf("Creating collection: %s%s%s\n", BOLD_UNDERLINE, cmd.l_token[0], RESET)
				success := data.CREATE_COLLECTION(cmd.l_token[0], .STANDARD_PUBLIC)
				if success {
					fmt.printf(
						"Collection: %s%s%s created successfully.\n",
						BOLD_UNDERLINE,
						cmd.l_token[0],
						RESET,
					)
					fileName := concat_standard_collection_name(cmd.l_token[0])
					UPDATE_METADATA_UPON_CREATION(fileName)

					ENCRYPT_COLLECTION(
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
		case CLUSTER_TIER:
			fn, collectionName, clusterName: string

				collectionName = cmd.l_token[0]
				clusterName = cmd.l_token[1]
				if !data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
					fmt.printfln(
						"Collection: %s%s%s does not exist.",
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					if data.confirm_auto_operation(Token[.NEW],[]string{collectionName}) == -1{
					   return -1
					}else{
					 data.AUTO_CREATE(COLLECTION_TIER, []string{collectionName})
					}
				}

				EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(
					collectionName,
					Token[.NEW],
					.STANDARD_PUBLIC,
				)

				fmt.printf(
					"Creating cluster: %s%s%s within collection: %s%s%s\n",
					BOLD_UNDERLINE,
					clusterName,
					RESET,
					BOLD_UNDERLINE,
					collectionName,
					RESET,
				)
				// checks := data.HANDLE_INTEGRITY_CHECK_RESULT(collectionName)
				// switch (checks)
				// {
				// case -1:
				// 	return -1
				// }

				id := data.GENERATE_ID(true)
				result := data.CREATE_CLUSTER(collectionName, clusterName, id)
				data.APPEND_ID_TO_ID_COLLECTION(fmt.tprintf("%d", id), 0)

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
					ENCRYPT_COLLECTION(
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
				fmt.printfln(
					"Cluster: %s%s%s created successfully.\n",
					BOLD_UNDERLINE,
					clusterName,
					RESET,
				)
				fn = concat_standard_collection_name(collectionName)
				UPDATE_METADATA_AFTER_OPERATIONS(fn)

			ENCRYPT_COLLECTION(
				cmd.l_token[0],
				.STANDARD_PUBLIC,
				types.current_user.m_k.valAsBytes,
				false,
			)
			break
		case RECORD_TIER:
			collectionName, clusterName, recordName, rValue: string
			log_runtime_event("Used NEW RECORD command", "User requested to create a new record.")
			collectionName = cmd.l_token[0]
			clusterName = cmd.l_token[1]
			recordName = cmd.l_token[2]


			if !data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
				fmt.printfln(
					"Collection: %s%s%s does not exist.",
					BOLD_UNDERLINE,
					collectionName,
					RESET,
				)
				if data.confirm_auto_operation(Token[.NEW],[]string{collectionName, clusterName}) == -1{
				   return -1
				}else{
				 data.AUTO_CREATE(COLLECTION_TIER, []string{collectionName})
				 data.AUTO_CREATE(CLUSTER_TIER, []string{collectionName, clusterName})
				}
			}

			EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(collectionName, Token[.NEW], .STANDARD_PUBLIC)


			if len(recordName) > 64 {
				fmt.printfln(
					"Record name: %s%s%s is too long. Please choose a name less than 64 characters.",
					BOLD_UNDERLINE,
					recordName,
					RESET,
				)
				return -1
			}
			colPath := concat_standard_collection_name(collectionName)

			if Token[.OF_TYPE] in cmd.p_token  {
				rType, typeSuccess := data.SET_RECORD_TYPE(cmd.p_token[Token[.OF_TYPE]])
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

					if Token[.WITH] in cmd.p_token  && len(cmd.p_token[Token[.WITH]]) != 0{
					   rValue = cmd.p_token[Token[.WITH]]
					} else if Token[.WITH] in cmd.p_token  && len(cmd.p_token[Token[.WITH]]) == 0{
					   fmt.println("%s%sWARNING%s When using the WITH token there must be a value of the assigned type after. Please try again")
						return 1
					}
					//TODO: Need to work on ensuring the value that is provided when using the WITH token is the appropriate type.
					//Just like i am doing in the SET_RECORD_VALUE() proc....

					recordCreationSuccess := data.CREATE_RECORD(
						colPath,
						clusterName,
						recordName,
						rValue,
						rType,
					)
					switch (recordCreationSuccess)
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
						if rType == Token[.NULL] {
							data.SET_RECORD_VALUE(colPath, clusterName, recordName, Token[.NULL])
						}

						fn := concat_standard_collection_name(collectionName)
						UPDATE_METADATA_AFTER_OPERATIONS(fn)
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
				ENCRYPT_COLLECTION(
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
	case .RENAME:
		log_runtime_event("Used RENAME command", "")
		switch (len(cmd.l_token))
		{
		case COLLECTION_TIER:
			if Token[.TO] in cmd.p_token {
				oldName := cmd.l_token[0]
				newName := cmd.p_token[Token[.TO]]

				if !data.CHECK_IF_COLLECTION_EXISTS(oldName, 0) {
					fmt.printfln(
						"Collection: %s%s%s does not exist.",
						BOLD_UNDERLINE,
						oldName,
						RESET,
					)
					return -1
				}


				EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(oldName, Token[.RENAME], .STANDARD_PUBLIC)

				fmt.printf(
					"Renaming collection: %s%s%s to %s%s%s\n",
					BOLD_UNDERLINE,
					oldName,
					RESET,
					BOLD_UNDERLINE,
					newName,
					RESET,
				)
				success := data.RENAME_COLLECTION(oldName, newName)
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

				ENCRYPT_COLLECTION(
					newName,
					.STANDARD_PUBLIC,
					types.current_user.m_k.valAsBytes,
					false,
				)
			} else {
				fmt.println("Incomplete command. Correct Usage: RENAME <old_name> TO <new_name>")
			}
			break
		case CLUSTER_TIER:
			collectionName: string
			if Token[.TO] in cmd.p_token  {
				oldName := cmd.l_token[1]
				collectionName = cmd.l_token[0]
				newName := cmd.p_token[Token[.TO]]

				if !data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
					fmt.printfln(
						"Collection: %s%s%s does not exist.",
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					return -1
				}

				EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(
					collectionName,
					Token[.RENAME],
					.STANDARD_PUBLIC,
				)

				// checks := data.HANDLE_INTEGRITY_CHECK_RESULT(collectionName)
				// switch (checks)
				// {
				// case -1:
				// 	fmt.printfln(
				// 		"Failed to rename cluster %s%s%s to %s%s%s in collection %s%s%s\n",
				// 	)
				// 	return -1
				// }

				success := data.RENAME_CLUSTER(collectionName, oldName, newName)
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
					fn := concat_standard_collection_name(collectionName)

					UPDATE_METADATA_AFTER_OPERATIONS(fn)
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
			ENCRYPT_COLLECTION(
				collectionName,
				.STANDARD_PUBLIC,
				types.current_user.m_k.valAsBytes,
				false,
			)
			break
		case RECORD_TIER:
			oldRName: string
			newRName: string
			collectionName: string //only here if using dot notation
			clusterName: string //only here if using dot notation
			if Token[.TO] in cmd.p_token {

					oldRName = cmd.l_token[2]
					newRName = cmd.p_token[Token[.TO]]
					collectionName = cmd.l_token[0]
					clusterName = cmd.l_token[1]


					if !data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
						fmt.printfln(
							"Collection: %s%s%s does not exist.",
							BOLD_UNDERLINE,
							collectionName,
							RESET,
						)
						return -1
					}

					DECRYPT_COLLECTION(
						collectionName,
						.STANDARD_PUBLIC,
						types.current_user.m_k.valAsBytes,
					)

					EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(
						collectionName,
						Token[.RENAME],
						.STANDARD_PUBLIC,
					)

				result := data.RENAME_RECORD(
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
			ENCRYPT_COLLECTION(
				collectionName,
				.STANDARD_PUBLIC,
				types.current_user.m_k.valAsBytes,
				false,
			)
			break
		}
		break
	// ERASE: Allows for the deletion of collections, specific clusters, or individual records within a cluster
	case .ERASE:
		log_runtime_event("Used ERASE command", "")
		switch (len(cmd.l_token))
		{
		case COLLECTION_TIER:
			collectionName := cmd.l_token[0]

			if !data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
				fmt.printfln(
					"Collection: %s%s%s does not exist.",
					BOLD_UNDERLINE,
					collectionName,
					RESET,
				)
				return -1
			}

			EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(collectionName, Token[.ERASE], .STANDARD_PUBLIC)

			if data.ERASE_COLLECTION(collectionName, false) == true {
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
		case CLUSTER_TIER:
			collectionName: string
			cluster: string

				collectionName = cmd.l_token[0]
				cluster = cmd.l_token[1]

				if !data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
					fmt.printfln(
						"Collection: %s%s%s does not exist.",
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					return -1
				}

				EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(
					collectionName,
					Token[.ERASE],
					.STANDARD_PUBLIC,
				)

				clusterID := data.GET_CLUSTER_ID(collectionName, cluster)
				// checks := data.HANDLE_INTEGRITY_CHECK_RESULT(collectionName)
				// switch (checks)
				// {
				// case -1:
				// 	return -1
				// }

				if data.ERASE_CLUSTER(collectionName, cluster, false) == true {
					fmt.printfln(
						"Cluster: %s%s%s successfully erased from collection: %s%s%s",
						BOLD_UNDERLINE,
						cluster,
						RESET,
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					DECRYPT_COLLECTION("", .ID_PRIVATE, types.system_user.m_k.valAsBytes)
					if data.REMOVE_ID_FROM_ID_COLLECTION(fmt.tprintf("%d", clusterID), false) {
						ENCRYPT_COLLECTION(
							"",
							.ID_PRIVATE,
							types.system_user.m_k.valAsBytes,
							false,
						)
					} else {
						ENCRYPT_COLLECTION(
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

				fn := concat_standard_collection_name(collectionName)
				UPDATE_METADATA_AFTER_OPERATIONS(fn)
			} else {
				fmt.println(
					"Incomplete command. Correct Usage: ERASE <collection_name>.<cluster_name>",
				)
				log_runtime_event(
					"Incomplete ERASE command",
					"User did not provide a valid cluster name to erase.",
				)
			}
			ENCRYPT_COLLECTION(
				collectionName,
				.STANDARD_PUBLIC,
				types.current_user.m_k.valAsBytes,
				false,
			)
			break
		case RECORD_TIER:
			collectionName: string
			clusterName: string
			recordName: string

				collectionName = cmd.l_token[0]
				clusterName = cmd.l_token[1]
				recordName = cmd.l_token[2]

				if !data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
					fmt.printfln(
						"Collection: %s%s%s does not exist.",
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					return -1
				}

				EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(
					collectionName,
					Token[.ERASE],
					.STANDARD_PUBLIC,
				)

				clusterID := data.GET_CLUSTER_ID(collectionName, clusterName)
				// checks := data.HANDLE_INTEGRITY_CHECK_RESULT(collectionName)
				// switch (checks)
				// {
				// case -1:
				// 	return -1
				// }
				if data.ERASE_RECORD(collectionName, clusterName, recordName, false) == true {
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

			ENCRYPT_COLLECTION(
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
	case .FETCH:
		log_runtime_event("Used FETCH command", "")
		switch (len(cmd.l_token))
		{
		case COLLECTION_TIER:
			if len(cmd.l_token) > 0 {
				collectionName := cmd.l_token[0]

				//check that the collection even exists
				if !data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
					fmt.printfln(
						"Collection: %s%s%s does not exist.",
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					return -1
				}

				EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(
					collectionName,
					Token[.FETCH],
					.STANDARD_PUBLIC,
				)

				str := data.FETCH_COLLECTION(collectionName)
				fmt.println(str)
			} else {
				fmt.println("Incomplete command. Correct Usage: FETCH <collection_name>")
				log_runtime_event(
					"Incomplete FETCH command",
					"User did not provide a valid collection name to fetch.",
				)
			}
			ENCRYPT_COLLECTION(
				cmd.l_token[0],
				.STANDARD_PUBLIC,
				types.current_user.m_k.valAsBytes,
				false,
			)
			break
		case CLUSTER_TIER:
				collectionName := cmd.l_token[0]
				clusterName := cmd.l_token[1]

				if !data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
					fmt.printfln(
						"Collection: %s%s%s does not exist.",
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					return -1
				}

				EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(
					collectionName,
					Token[.FETCH],
					.STANDARD_PUBLIC,
				)

				clusterContent := data.FETCH_CLUSTER(collectionName, clusterName)
				fmt.printfln(clusterContent)

			ENCRYPT_COLLECTION(
				cmd.l_token[0],
				.STANDARD_PUBLIC,
				types.current_user.m_k.valAsBytes,
				false,
			)
			break
		case RECORD_TIER:
			collectionName: string
			clusterName: string
			recordName: string

			if len(cmd.l_token) == 3  {
				collectionName = cmd.l_token[0]
				clusterName = cmd.l_token[1]
				recordName = cmd.l_token[2]

				if !data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
					fmt.printfln(
						"Collection: %s%s%s does not exist.",
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					return -1
				}

				EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(
					collectionName,
					Token[.FETCH],
					.STANDARD_PUBLIC,
				)

				// checks := data.HANDLE_INTEGRITY_CHECK_RESULT(collectionName)
				// switch (checks)
				// {
				// case -1:
				// 	return -1
				// }
				record, found := data.FETCH_RECORD(collectionName, clusterName, recordName)
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
			ENCRYPT_COLLECTION(
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
	case .SET:
		switch (len(cmd.l_token))
		{
		case RECORD_TIER:
			//Setting a standard records value
			if Token[.TO] in cmd.p_token {
				collectionName := cmd.l_token[0]
				clusterName := cmd.l_token[1]
				recordName := cmd.l_token[2]

				if !data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
					fmt.printfln(
						"Collection: %s%s%s does not exist.",
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					return -1
				}

				EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(
					collectionName,
					Token[.SET],
					.STANDARD_PUBLIC,
				)

				value := cmd.p_token[Token[.TO]] // Get the full string value that was collected by the parser
				fmt.printfln(
					"Setting record: %s%s%s to %s%s%s",
					BOLD_UNDERLINE,
					recordName,
					RESET,
					BOLD_UNDERLINE,
					value,
					RESET,
				)

				file := utils.concat_standard_collection_name(collectionName)

				setValueSuccess := data.SET_RECORD_VALUE(
					file,
					clusterName,
					recordName,
					strings.clone(value),
				)

				//if that records type is one of the following 'special' arrays:
				// []CHAR, []DATE, []TIME, []DATETIME,etc scan for that type and remove the "" that
				// each value will have(THANKS ODIN...)
				rType, _ := data.GET_RECORD_TYPE(file, clusterName, recordName)


				/*
			    Added this because of: https://github.com/Solitude-Software-Solutions/OstrichDB/issues/203
				I guess its not neeeded, if a user wants to have a single character string record who am I to stop them?
				Remove at any time if needed - Marshall
				*/
				if rType == Token[.STRING] && len(value) == 1 {
					conversionSuccess := data.CHANGE_RECORD_TYPE(
						file,
						clusterName,
						recordName,
						value,
						Token[.CHAR],
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


				if rType == Token[.NULL] {
					fmt.printfln(
						"Cannot a value assign to record: %s%s%s of type %sNULL%s",
						BOLD_UNDERLINE,
						recordName,
						RESET,
						BOLD_UNDERLINE,
						RESET,
					)

					return 0
				}

				if rType == Token[.CHAR_ARRAY] ||
				   rType == Token[.DATE_ARRAY] ||
				   rType == Token[.TIME_ARRAY] ||
				   rType == Token[.DATETIME_ARRAY] ||
				   rType == Token[.UUID_ARRAY] {
					data.MODIFY_ARRAY_VALUES(file, clusterName, recordName, rType)
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

				fn := concat_standard_collection_name(collectionName)
				UPDATE_METADATA_AFTER_OPERATIONS(fn)
			}
			ENCRYPT_COLLECTION(
				cmd.l_token[0],
				.STANDARD_PUBLIC,
				types.current_user.m_k.valAsBytes,
				false,
			)
			break
		case 1: //Not using the COLLECTION_TIER constant here.  Technically the value is the same but the verbage will confuse me and others :) - Marshall
			switch (cmd.t_token) {
			case Token[.CONFIG]:
				log_runtime_event("Used SET command", "")
				if Token[.TO] in cmd.p_token {
					configName := cmd.l_token[0]
					value := cmd.p_token[Token[.TO]]

					EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK("", Token[.SET], .CONFIG_PRIVATE)

					for key, val in cmd.p_token {
						value = strings.to_lower(val)
					}

					switch (configName)
					{
					case "HELP_IS_VERBOSE", "SUPPRESS_ERRORS","LIMIT_HISTORY", "AUTO_SERVE","LIMIT_SESSION_TIME":
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
						success := config.UPDATE_CONFIG_VALUE(configName, value)
						if success == false {
							fmt.printfln("%sFailed%s to set %s%s%s configuration to %s%s%s", RED, RESET, BOLD_UNDERLINE, configName, RESET, BOLD_UNDERLINE, value, RESET)
						} else {
						    AUTO_UPDATE_METADATA_VALUE(CONFIG_PATH, 4)
							AUTO_UPDATE_METADATA_VALUE(CONFIG_PATH, 5)
							fmt.printfln("%sSuccessfully%s set %s%s%s configuration to %s%s%s", GREEN, RESET, BOLD_UNDERLINE, configName, RESET, BOLD_UNDERLINE, value, RESET)
						}
						break
					} else {
						fmt.printfln("%sInvalid value provided.%s Configuration values can only be: 'true' or 'false'",RED, RESET)
					}
					break
					case:
						fmt.printfln(
							"%sInvalid configuration name provided%s Valid configuration names are:\nHELP_IS_VERBOSE\nSUPPRESS_ERRORS\nLIMIT_HISTORY\nAUTO_SERVE, LIMIT_SESSION_TIME\n",
						)
					}
				} else {
					fmt.printfln(
						"Incomplete command. Correct Usage: SET CONFIG <config_name> TO <value>",
					)
				}
				ENCRYPT_COLLECTION("", .CONFIG_PRIVATE, types.current_user.m_k.valAsBytes, false)
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
	case .COUNT:
		log_runtime_event("Used COUNT command", "")
		switch (cmd.t_token)
		{
		case Token[.COLLECTIONS]:
			result := data.GET_COLLECTION_COUNT()
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
		case Token[.CLUSTERS]:
			if len(cmd.l_token) == 1 {
				collectionName := cmd.l_token[0]

				if !data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
					fmt.printfln(
						"Collection: %s%s%s does not exist.",
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					return -1
				}

				EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(
					collectionName,
					Token[.COUNT],
					.STANDARD_PUBLIC,
				)

				result := data.COUNT_CLUSTERS(collectionName)
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
				ENCRYPT_COLLECTION(
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
		case Token[.RECORDS]:
			//in the event the users is counting the records in a specific cluster
			if (len(cmd.l_token) >= 2 ) {
				collectionName := cmd.l_token[0]
				clusterName := cmd.l_token[1]

				if !data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
					fmt.printfln(
						"Collection: %s%s%s does not exist.",
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					return -1
				}

				EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(
					collectionName,
					Token[.COUNT],
					.STANDARD_PUBLIC,
				)

				result := data.GET_RECORD_COUNT_WITHIN_CLUSTER(
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
				ENCRYPT_COLLECTION(
					collectionName,
					.STANDARD_PUBLIC,
					types.current_user.m_k.valAsBytes,
					false,
				)
			} else if len(cmd.l_token) == 1  { 	//TODO: 12 March, 2025 THIS WHOLE BLOCK IS FUCKED FOR SOME REASON - MARSHALL
				//in the event the user is counting all records in a collection
				collectionName := cmd.l_token[0]

				if !data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
					fmt.printfln(
						"Collection: %s%s%s does not exist.",
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					return -1
				}

				EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(
					collectionName,
					Token[.COUNT],
					.STANDARD_PUBLIC,
				)

				result := data.GET_RECORD_COUNT_WITHIN_COLLECTION(collectionName)

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
				ENCRYPT_COLLECTION(
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
	case .PURGE:
		collectionName, clusterName, recordName: string
		log_runtime_event("Used PURGE command", "")
		switch (len(cmd.l_token))
		{
		case COLLECTION_TIER:
			collectionName = cmd.l_token[0]

			if !data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
				fmt.printfln(
					"Collection: %s%s%s does not exist.",
					BOLD_UNDERLINE,
					collectionName,
					RESET,
				)
				return -1
			}

			EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(collectionName, Token[.PURGE], .STANDARD_PUBLIC)

			result := data.PURGE_COLLECTION(cmd.l_token[0])
			switch result
			{
			case true:
				fmt.printfln(
					"Successfully purged collection: %s%s%s",
					BOLD_UNDERLINE,
					cmd.l_token[0],
					RESET,
				)
				file := concat_standard_collection_name(collectionName)
				UPDATE_METADATA_AFTER_OPERATIONS(file)
				break
			case false:
				fmt.printfln("Failed to purge collection: %s%s%s", BOLD, cmd.l_token[0], RESET)
				break
			}
			ENCRYPT_COLLECTION(
				collectionName,
				.STANDARD_PUBLIC,
				types.current_user.m_k.valAsBytes,
				false,
			)
			break
		case CLUSTER_TIER:
			collectionName = cmd.l_token[0]
			clusterName = cmd.l_token[1]

			if !data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
				fmt.printfln(
					"Collection: %s%s%s does not exist.",
					BOLD_UNDERLINE,
					collectionName,
					RESET,
				)
				return -1
			}

			EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(collectionName, Token[.PURGE], .STANDARD_PUBLIC)

			if len(cmd.l_token) >= 2  {
				result := data.PURGE_CLUSTER(collectionName, clusterName)
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

			ENCRYPT_COLLECTION(
				collectionName,
				.STANDARD_PUBLIC,
				types.current_user.m_k.valAsBytes,
				false,
			)
			break
		case RECORD_TIER:
			collectionName = cmd.l_token[0]
			clusterName = cmd.l_token[1]
			recordName = cmd.l_token[2]

			if !data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
				fmt.printfln(
					"Collection: %s%s%s does not exist.",
					BOLD_UNDERLINE,
					collectionName,
					RESET,
				)
				return -1
			}

			EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(collectionName, Token[.PURGE], .STANDARD_PUBLIC)

			result := data.PURGE_RECORD(collectionName, clusterName, recordName)
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
			ENCRYPT_COLLECTION(
				collectionName,
				.STANDARD_PUBLIC,
				types.current_user.m_k.valAsBytes,
				false,
			)
			break
		}
		break
	//SIZE_OF: Allows for the retrieval of the size of collections, clusters, or records in bytes
	case .SIZE_OF:
		log_runtime_event("Used SIZE_OF command", "")
		switch (len(cmd.l_token)) {
		case COLLECTION_TIER:
			collectionName := cmd.l_token[0]

			if !data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
				fmt.printfln(
					"Collection: %s%s%s does not exist.",
					BOLD_UNDERLINE,
					collectionName,
					RESET,
				)
				return -1
			}

			EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(
				collectionName,
				Token[.SIZE_OF],
				.STANDARD_PUBLIC,
			)

			file_path := concat_standard_collection_name(collectionName)
			actual_size, metadata_size := SUBTRACT_METADATA_SIZE(file_path)
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
			ENCRYPT_COLLECTION(
				collectionName,
				.STANDARD_PUBLIC,
				types.current_user.m_k.valAsBytes,
				false,
			)
			break
		case CLUSTER_TIER:
				collectionName := cmd.l_token[0]
				clusterName := cmd.l_token[1]

				if !data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
					fmt.printfln(
						"Collection: %s%s%s does not exist.",
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					return -1
				}

				EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(
					collectionName,
					Token[.SIZE_OF],
					.STANDARD_PUBLIC,
				)

				//TODO: This is returning an inaccurate size, need to fix
				size, success := data.GET_CLUSTER_SIZE(collectionName, clusterName)
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

			ENCRYPT_COLLECTION(
				cmd.l_token[0],
				.STANDARD_PUBLIC,
				types.current_user.m_k.valAsBytes,
				false,
			)
			break
		case RECORD_TIER:
				collectionName := cmd.l_token[0]
				clusterName := cmd.l_token[1]
				recordName := cmd.l_token[2]

				if !data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
					fmt.printfln(
						"Collection: %s%s%s does not exist.",
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					return -1
				}

				EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(
					collectionName,
					Token[.SIZE_OF],
					.STANDARD_PUBLIC,
				)

				size, success := data.GET_RECORD_SIZE(collectionName, clusterName, recordName)
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
				ENCRYPT_COLLECTION(
					cmd.l_token[0],
					.STANDARD_PUBLIC,
					types.current_user.m_k.valAsBytes,
					false,
				)

		case:
			fmt.println(
				"Invalid SIZE_OF command. Use SIZE_OF COLLECTION, SIZE_OF CLUSTER, or SIZE_OF RECORD.",
			)
			break
		}
		break
	// TYPE_OF: Allows for the retrieval of the type of a record
	case .TYPE_OF:
		log_runtime_event("Used TYPE_OF command", "")
		//only works on records
		if len(cmd.l_token) == 3  {
			collectionName := cmd.l_token[0]
			clusterName := cmd.l_token[1]
			recordName := cmd.l_token[2]

			if !data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
				fmt.printfln(
					"Collection: %s%s%s does not exist.",
					BOLD_UNDERLINE,
					collectionName,
					RESET,
				)
				return -1
			}

			EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(
				collectionName,
				Token[.TYPE_OF],
				.STANDARD_PUBLIC,
			)

			colPath := concat_standard_collection_name(collectionName)
			rType, success := data.GET_RECORD_TYPE(colPath, clusterName, recordName)
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

			ENCRYPT_COLLECTION(
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
	case .CHANGE_TYPE:
		//only works on records
		switch (len(cmd.l_token)) {
		case RECORD_TIER:
			if Token[.TO] in cmd.p_token  {
				collectionName := cmd.l_token[0]
				clusterName := cmd.l_token[1]
				recordName := cmd.l_token[2]
				newType := cmd.p_token[Token[.TO]]

				if !data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
					fmt.printfln(
						"Collection: %s%s%s does not exist.",
						BOLD_UNDERLINE,
						collectionName,
						RESET,
					)
					return -1
				}
				colPath := concat_standard_collection_name(collectionName)

				EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(
					collectionName,
					Token[.CHANGE_TYPE],
					.STANDARD_PUBLIC,
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
				if newType == Token[.INT] || newType == Token[.INTEGER] {
					newType = Token[.INTEGER]
				} else if newType == Token[.STR] || newType == Token[.STRING] {
					newType = Token[.STRING]
				} else if newType == Token[.BOOL] || newType == Token[.BOOLEAN] {
					newType = Token[.BOOLEAN]
				} else if newType == Token[.FLT] || newType == Token[.FLOAT] {
					newType = Token[.FLOAT]
				} else if newType == Token[.STR_ARRAY] || newType == Token[.STRING_ARRAY] {
					newType = Token[.STRING_ARRAY]
				} else if newType == Token[.INT_ARRAY] || newType == Token[.INTEGER_ARRAY] {
					newType = Token[.INTEGER_ARRAY]
				} else if newType == Token[.BOOL_ARRAY] || newType == Token[.BOOLEAN_ARRAY] {
					newType = Token[.BOOLEAN_ARRAY]
				} else if newType == Token[.FLT_ARRAY] || newType == Token[.FLOAT_ARRAY] {
					newType = Token[.FLOAT_ARRAY]
				}

				success := data.HANDLE_RECORD_TYPE_CONVERSION(
					colPath,
					clusterName,
					recordName,
					newType,
				)

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
				ENCRYPT_COLLECTION(
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
	case .ISOLATE:
		log_runtime_event("Used ISOLATE command", "")
		switch (len(cmd.l_token)) {
		case COLLECTION_TIER:
			collectionName := cmd.l_token[0]

			if !data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
				fmt.printfln(
					"Collection: %s%s%s does not exist.",
					BOLD_UNDERLINE,
					collectionName,
					RESET,
				)
				return -1
			}

			EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(
				collectionName,
				Token[.ISOLATE],
				.STANDARD_PUBLIC,
			)

			result, isolatedColName := data.PERFORM_COLLECTION_ISOLATION(collectionName)
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
			ENCRYPT_COLLECTION(
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
	// case .VALIDATE:
	// 	switch (len(cmd.l_token)) {
	// 	case 1:
	// 		collectionName := cmd.l_token[0]

	// 		if !data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
	// 			fmt.printfln(
	// 				"Collection: %s%s%s does not exist.",
	// 				BOLD_UNDERLINE,
	// 				collectionName,
	// 				RESET,
	// 			)
	// 			return -1
	// 		}

	// 		EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(collectionName, VALIDATE, .STANDARD_PUBLIC)

	// 		result := data.HANDLE_INTEGRITY_CHECK_RESULT(collectionName)

	// 		if result == 0 {
	// 			fmt.printfln(
	// 				"Collection: %s%s%s data integrity status: %svalid%s",
	// 				BOLD_UNDERLINE,
	// 				collectionName,
	// 				RESET,
	// 				GREEN,
	// 				RESET,
	// 			)

	// 			ENCRYPT_COLLECTION(
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
	case .BENCHMARK:
		using benchmark
		switch (len(cmd.l_token)) {
		case 0:
			RUN_BENCHMARK([]int{0, 0, 0}, true)
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
			RUN_BENCHMARK([]int{colIteration, clusterIteration, recordIteration}, false)
			break
		case:
			fmt.printfln(
				"Incomplete command. Correct Usage: BENCHMARK or BENCHMARK <#of_collections>.<#of_clusters>.<#of_records>",
			)
		}
		break
	// //IMPORT: Imports foreign data formats into OstrichDB. Currently only supports .csv files
	case .IMPORT:
		detected, autoImportSuccess := importing.AUTO_DETECT_AND_HANDLE_IMPORT_FILES()
		fmt.println("detected: ", detected)
		fmt.println("autoImportSuccess: ", autoImportSuccess)
		if detected && autoImportSuccess == true {
			fmt.printfln("%sSuccessfully imported data!%s", GREEN, RESET)
			break
		} else if detected == true && autoImportSuccess == false { 	//files were detected but user wanted to continue manually or the import failed
			importSuccess := importing.HANDLE_IMPORT()
			if importSuccess {
				fmt.printfln("%sSuccessfully imported data!%s", GREEN, RESET)
			} else {
				fmt.printfln("%sFailed to import data%s", RED, RESET)
			}
			break
		}
		fmt.println("detected: ", detected)
		fmt.println("autoImportSuccess: ", autoImportSuccess)
	case .EXPORT:
		fmt.println("NOT YET IMPLEMENTED")
		break
	//LOCK: Locks a collection with a flag or without a flag
	case .LOCK:
		flag: string
		switch len(cmd.l_token) {
		case 1:
			//locking a collection with no flag defaults to it being inaccessable unless unlocked
			colName := cmd.l_token[0]

			if !data.CHECK_IF_COLLECTION_EXISTS(colName, 0) {
				fmt.printfln("Collection: %s%s%s does not exist.", BOLD_UNDERLINE, colName, RESET)
				return -1
			}

			DECRYPT_COLLECTION(colName, .STANDARD_PUBLIC, types.current_user.m_k.valAsBytes)

			collectionAlreadyLocked := security.GET_COLLECTION_LOCK_STATUS(colName)

			//next make sure the "locker" is an admin
			DECRYPT_COLLECTION(
				types.current_user.username.Value,
				.SECURE_PRIVATE,
				types.system_user.m_k.valAsBytes,
			)
			isAdmin := security.CHECK_ADMIN_STATUS(&types.current_user)

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
					validatedPassword := security.VALIDATE_USER_PASSWORD(password)
					switch (validatedPassword) {
					case false:
						fmt.printfln("Invalid password. Operation cancelled.")
						break
					case true:
						lockSuccess, permission := data.LOCK_COLLECTION(colName, "-N")
						if lockSuccess {
							filePath := concat_standard_collection_name(colName)
							osPermSuccess := security.SET_FILE_PERMISSIONS_ON_OS_LEVEL(filePath, permission)
							if !osPermSuccess {
								fmt.printfln(
									"%sWARNING: Failed to set OS-level permissions for collection: %s%s%s",
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

			ENCRYPT_COLLECTION(
				types.current_user.username.Value,
				.SECURE_PRIVATE,
				types.system_user.m_k.valAsBytes,
				false,
			)

			ENCRYPT_COLLECTION(colName, .STANDARD_PUBLIC, types.current_user.m_k.valAsBytes, false)
			break
		case 2:
			colName := cmd.l_token[0]
			flag := cmd.l_token[1]

			DECRYPT_COLLECTION(colName, .STANDARD_PUBLIC, types.current_user.m_k.valAsBytes)

			fmt.printfln("Locking collection: %s%s%s ", BOLD_UNDERLINE, colName, RESET)
			lockSuccess, permission := data.LOCK_COLLECTION(colName, flag)
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
		ENCRYPT_COLLECTION(
			cmd.l_token[0],
			.STANDARD_PUBLIC,
			types.current_user.m_k.valAsBytes,
			false,
		)
		break
	case .UNLOCK:
		switch (len(cmd.l_token)) {
		case 1:
			colName := cmd.l_token[0]
			//check that a collection is in fact locked

			DECRYPT_COLLECTION(colName, .STANDARD_PUBLIC, types.current_user.m_k.valAsBytes)

			DECRYPT_COLLECTION(
				types.current_user.username.Value,
				.SECURE_PRIVATE,
				types.system_user.m_k.valAsBytes,
			)
			collectionAlreadyLocked := security.GET_COLLECTION_LOCK_STATUS(colName)
			if !collectionAlreadyLocked {
				fmt.printfln("Collection: %s%s%s is not locked.", BOLD_UNDERLINE, colName, RESET)
				return 1
			} else {
				//check that current user is admin
				isAdmin := security.CHECK_ADMIN_STATUS(&types.current_user)

				if !isAdmin {
					fmt.printfln(
						"User: %s%s%s does not have permission to unlock collections.",
						BOLD_UNDERLINE,
						types.current_user.username.Value,
						RESET,
					)
					return 1
				} else {
					passwordConfirmed := security.CONFTIM_COLLECTION_UNLOCK_PASSWORD()
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
						currentPerm, err := metadata.GET_METADATA_MEMBER_VALUE(
							colName,
							"# Permission",
							.STANDARD_PUBLIC,
						)
						fmt.printfln(
							"Unlocking collection: %s%s%s",
							BOLD_UNDERLINE,
							colName,
							RESET,
						)
						unlockSuccess := data.UNLOCK_COLLECTION(colName, currentPerm)
						break
					}
				}
			}
			ENCRYPT_COLLECTION(
				types.current_user.username.Value,
				.SECURE_PRIVATE,
				types.system_user.m_k.valAsBytes,
				false,
			)

			ENCRYPT_COLLECTION(
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
	case .ENC:
		switch (len(cmd.l_token)) {
		case 1:
			colName := cmd.l_token[0]
			encSuccess, _ := ENCRYPT_COLLECTION(
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
	case .DEC:
		switch (len(cmd.l_token)) {
		case 1:
			colName := cmd.l_token[0]
			decSuccess, _ := security.DECRYPT_COLLECTION(
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
