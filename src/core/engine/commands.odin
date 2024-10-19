package engine

import "../../utils"
import "../config"
import "../const"
import "../help"
import "../types"
import "./data"
import "./data/metadata"
import "./security"
import "core:c/libc"
import "core:fmt"
import "core:os"
import "core:strings"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//

//used to concatenate an object name with an extension this will be used for updating collection file metadata from the command line
OST_CONCAT_OBJECT_EXT :: proc(obj: string) -> string {
	path := strings.concatenate([]string{const.OST_COLLECTION_PATH, obj})
	return strings.concatenate([]string{path, const.OST_FILE_EXTENSION})
}

OST_EXECUTE_COMMAND :: proc(cmd: ^types.Command) -> int {
	incompleteCommandErr := utils.new_err(
		.INCOMPLETE_COMMAND,
		utils.get_err_msg(.INCOMPLETE_COMMAND),
		#procedure,
	)

	invalidCommandErr := utils.new_err(
		.INVALID_COMMAND,
		utils.get_err_msg(.INVALID_COMMAND),
		#procedure,
	)
	defer delete(cmd.o_token)


	switch (cmd.a_token) 
	{
	//=======================<SINGLE-TOKEN COMMANDS>=======================//

	case const.VERSION:
		utils.log_runtime_event("Used VERSION command", "User requested version information.")
		fmt.printfln(
			"Using OstrichDB Version: %s%s%s",
			utils.BOLD,
			utils.get_ost_version(),
			utils.RESET,
		)
		break
	case const.EXIT:
		//logout then exit the program
		utils.log_runtime_event("Used EXIT command", "User requested to exit the program.")
		OST_USER_LOGOUT(1)
	case const.LOGOUT:
		//only returns user to signin.
		utils.log_runtime_event("Used LOGOUT command", "User requested to logout.")
		fmt.printfln("Logging out...")
		OST_USER_LOGOUT(0)
		return 0

	case const.UNFOCUS:
		utils.log_runtime_event(
			"Improperly used UNFOCUS command",
			"User requested to unfocus while not in FOCUS mode.",
		)
		fmt.printfln("Cannot Unfocus becuase you are currently not in focus mode.")
		break
	case const.CLEAR:
		utils.log_runtime_event("Used CLEAR command", "User requested to clear the screen.")
		libc.system("clear")
		break
	case const.TREE:
		utils.log_runtime_event(
			"Used TREE command",
			"User requested to view a tree of the database.",
		)
		data.OST_GET_DATABASE_TREE()

	//COMMAND HISTORY CLUSTER FUCK START :(
	case const.HISTORY:
		utils.log_runtime_event(
			"Used HISTORY command",
			"User requested to view the command history.",
		)
		commandHistory := data.OST_PUSH_RECORDS_TO_ARRAY(types.current_user.username.Value)

		for cmd, index in commandHistory {
			fmt.printfln("%d: %s", index + 1, cmd)
		}
		fmt.println("Enter command to repeat: \nTo exit,press enter.")

		// Get index of command to re-execute from user
		inputNumber: [1024]byte
		n, inputSuccess := os.read(os.stdin, inputNumber[:])
		if inputSuccess != 0 {
			error := utils.new_err(
				.CANNOT_READ_INPUT,
				utils.get_err_msg(.CANNOT_READ_INPUT),
				#procedure,
			)
			utils.throw_err(error)
			utils.log_err("Cannot read user input for HISTORY command.", #procedure)
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
	case const.HELP:
		utils.log_runtime_event("Used HELP command", "User requested help information.")
		if len(cmd.t_token) == 0 {
			utils.log_runtime_event(
				"Used HELP command",
				"User requested general help information.",
			)
			help.OST_GET_GENERAL_HELP()
		} else if cmd.t_token == const.ATOM || cmd.t_token == const.ATOMS {
			utils.log_runtime_event("Used HELP command", "User requested atom help information.")
			help.OST_GET_ATOMS_HELP()
		} else {
			utils.log_runtime_event(
				"Used HELP command",
				"User requested specific help information.",
			)
			help.OST_GET_SPECIFIC_HELP(cmd.t_token)
		}
		break
	//=======================<MULTI-TOKEN COMMANDS>=======================//
	//BACKUP: Used in conjuction with COLLECTION to create a duplicate of all data within a collection
	case const.BACKUP:
		utils.log_runtime_event("Used BACKUP command", "User requested to backup data.")
		switch (cmd.t_token) {
		case const.COLLECTION:
			if len(cmd.o_token) > 0 {
				name := data.OST_CHOOSE_BACKUP_NAME()


				checks := data.OST_HANDLE_INTGRITY_CHECK_RESULT(cmd.o_token[0])
				switch (checks) 
				{
				case -1:
					return -1
				}
				success := data.OST_CREATE_BACKUP_COLLECTION(name, cmd.o_token[0])
				if success {
					fmt.printfln(
						"Successfully backed up collection: %s%s%s.",
						utils.BOLD,
						cmd.o_token[0],
						utils.RESET,
					)
				} else {
					fmt.println("Backup failed. Please try again.")
				}

			} else {
				fmt.println(
					"Incomplete command. Correct Usage: BACKUP COLLECTION <collection_name>",
				)
				utils.log_runtime_event(
					"Incomplete BACKUP command",
					"User did not provide a collection name to backup.",
				)
			}
			break
		case const.CLUSTER, const.RECORD:
			fmt.println(
				"Backing up a cluster or record is not currently support in OstrichDB. Try backing up a collection instead.",
			)
			break
		case:
			fmt.println("Invalid command. Correct Usage: BACKUP COLLECTION <collection_name>")
			utils.log_runtime_event(
				"Invalid BACKUP command",
				"User did not provide a valid target.",
			)
		}
		break
	//NEW: Allows for the creation of new records, clusters, or collections
	case const.NEW:
		utils.log_runtime_event("Used NEW command", "")
		switch (cmd.t_token) {
		case const.COLLECTION:
			if len(cmd.o_token) > 0 {
				exists := data.OST_CHECK_IF_COLLECTION_EXISTS(cmd.o_token[0], 0)
				switch (exists) {
				case false:
					fmt.printf(
						"Creating collection: %s%s%s\n",
						utils.BOLD_UNDERLINE,
						cmd.o_token[0],
						utils.RESET,
					)
					success := data.OST_CREATE_COLLECTION(cmd.o_token[0], 0)
					if success {
						fmt.printf(
							"Collection: %s%s%s created successfully.\n",
							utils.BOLD_UNDERLINE,
							cmd.o_token[0],
							utils.RESET,
						)
					} else {
						fmt.printf(
							"Failed to create collection %s%s%s.\n",
							utils.BOLD_UNDERLINE,
							cmd.o_token[0],
							utils.RESET,
						)
						utils.log_runtime_event(
							"Failed to create collection",
							"User tried to create a collection but failed.",
						)
						utils.log_err("Failed to create new collection", #procedure)
					}
					break
				case true:
					fmt.printf(
						"Collection: %s%s%s already exists. Please choose a different name.\n",
						utils.BOLD_UNDERLINE,
						cmd.o_token[0],
						utils.RESET,
					)
					utils.log_runtime_event(
						"Duplicate collection name",
						"User tried to create a collection with a name that already exists.",
					)
					break
				}
			} else {
				fmt.println("Incomplete command. Correct Usage: NEW COLLECTION <collection_name>")
				utils.log_runtime_event(
					"Incomplete NEW command",
					"User did not provide a collection name to create.",
				)
			}
			break
		case const.CLUSTER:
			cluster_name: string
			collection_name: string
			if len(cmd.o_token) >= 2 && const.WITHIN in cmd.m_token ||
			   cmd.isUsingDotNotation == true {
				//using dot notation
				if cmd.isUsingDotNotation == true {
					collection_name = cmd.o_token[0]
					cluster_name = cmd.o_token[1]
				} else { 	//using within
					cluster_name = cmd.o_token[0]
					collection_name = cmd.o_token[1]
				}
				fmt.printf(
					"Creating cluster: %s%s%s within collection: %s%s%s\n",
					utils.BOLD_UNDERLINE,
					cluster_name,
					utils.RESET,
					utils.BOLD_UNDERLINE,
					collection_name,
					utils.RESET,
				)
				// checks := data.OST_HANDLE_INTGRITY_CHECK_RESULT(collection_name) todo this is pretty bugged - SchoolyB
				// switch (checks)
				// {
				// case -1:
				// 	return -1
				// }

				id := data.OST_GENERATE_CLUSTER_ID()
				result := data.OST_CREATE_CLUSTER_FROM_CL(collection_name, cluster_name, id)
				switch (result) 
				{
				case -1:
					fmt.printfln(
						"Cluster with name: %s%s%s already exists within collection %s%s%s. Failed to create cluster.",
						utils.BOLD_UNDERLINE,
						cluster_name,
						utils.RESET,
						utils.BOLD_UNDERLINE,
						collection_name,
						utils.RESET,
					)
					break
				case 1, 2, 3:
					error1 := utils.new_err(
						.CANNOT_CREATE_CLUSTER,
						utils.get_err_msg(.CANNOT_CREATE_CLUSTER),
						#procedure,
					)
					utils.throw_custom_err(
						error1,
						"Failed to create cluster due to internal OstrichDB error.\n Check logs for more information.",
					)
					utils.log_err("Failed to create new cluster.", #procedure)
					break
				}
				fn := OST_CONCAT_OBJECT_EXT(collection_name)
				metadata.OST_UPDATE_METADATA_VALUE(fn, 2)
				metadata.OST_UPDATE_METADATA_VALUE(fn, 3)
			} else {
				fmt.printfln(
					"Incomplete command. Correct Usage: NEW CLUSTER <cluster_name> WITHIN COLLECTION <collection_name> \nAlternatively, you can use dot notation: NEW CLUSTER <collection_name>.<cluster_name>",
				)
				utils.log_runtime_event(
					"Incomplete NEW command",
					"User did not provide a cluster name to create.",
				)
			}

			break
		case const.RECORD:
			utils.log_runtime_event(
				"Used NEW RECORD command",
				"User requested to create a new record.",
			)
			collection_name: string
			cluster_name: string
			if len(cmd.o_token) == 1 && const.OF_TYPE in cmd.m_token ||
			   cmd.isUsingDotNotation == true {
				rName, nameSuccess := data.OST_SET_RECORD_NAME(cmd.o_token[2])
				rType, typeSuccess := data.OST_SET_RECORD_TYPE(cmd.m_token[const.OF_TYPE])
				if nameSuccess == 0 && typeSuccess == 0 {
					fmt.printfln(
						"Creating record: %s%s%s of type: %s%s%s",
						utils.BOLD_UNDERLINE,
						rName,
						utils.RESET,
						utils.BOLD_UNDERLINE,
						rType,
						utils.RESET,
					)
					//All hail the re-engineered paser - Marshall Burns aka @SchoolyB
					if cmd.isUsingDotNotation == true {
						collection_name = cmd.o_token[0]
						cluster_name = cmd.o_token[1]
						filePath := fmt.tprintf(
							"%s%s%s",
							const.OST_COLLECTION_PATH,
							collection_name,
							const.OST_FILE_EXTENSION,
						)
						appendSuccess := data.OST_APPEND_RECORD_TO_CLUSTER(
							filePath,
							cluster_name,
							rName,
							"",
							rType,
						)
						if appendSuccess == 0 {
							break
						}
					}

					//using within and all that other lame old v0.2 stuff ROFL - Marshall Burns aka @SchoolyB
					data.OST_GET_ALL_COLLECTION_NAMES(false)
					collection_name, cluster_name := data.OST_CHOOSE_RECORD_LOCATION(rName, rType)
					filePath := fmt.tprintf(
						"%s%s%s",
						const.OST_COLLECTION_PATH,
						collection_name,
						const.OST_FILE_EXTENSION,
					)

					appendSuccess := data.OST_APPEND_RECORD_TO_CLUSTER(
						filePath,
						cluster_name,
						rName,
						"",
						rType,
					)
					switch (appendSuccess) 
					{
					case 0:
						fmt.printfln(
							"Record: %s%s%s of type: %s%s%s created successfully",
							utils.BOLD_UNDERLINE,
							rName,
							utils.RESET,
							utils.BOLD_UNDERLINE,
							rType,
							utils.RESET,
						)
						fn := OST_CONCAT_OBJECT_EXT(collection_name)
						metadata.OST_UPDATE_METADATA_VALUE(fn, 2)
						metadata.OST_UPDATE_METADATA_VALUE(fn, 3)

						break
					case -1, 1:
						fmt.printfln(
							"Failed to create record: %s%s%s of type: %s%s%s",
							utils.BOLD_UNDERLINE,
							rName,
							utils.RESET,
							utils.BOLD_UNDERLINE,
							rType,
							utils.RESET,
						)
						utils.log_runtime_event(
							"Failed to create record",
							"User requested to create a record but failed.",
						)
						utils.log_err("Failed to create a new record.", #procedure)
						break
					}
				} else {
					fmt.printfln(
						"Failed to create record: %s%s%s of type: %s%s%s. Please try again.",
						utils.BOLD_UNDERLINE,
						rName,
						utils.RESET,
						utils.BOLD_UNDERLINE,
						rType,
						utils.RESET,
					)
				}

			} else {
				fmt.printfln(
					"Incomplete command. Correct Usage: NEW RECORD <record_name> OF_TYPE <record_type>\nAlternatively, you can use dot notation: NEW RECORD <collection_name>.<cluster_name>.<record_name> OF_TYPE <record_type>",
				)
				utils.log_runtime_event(
					"Incomplete NEW RECORD command",
					"User did not provide a record name or type to create.",
				)
			}
			break
		case const.USER:
			utils.log_runtime_event(
				"Used NEW USER command",
				"User chose to create a new user account",
			)
			if len(cmd.o_token) >= 0 {
				result := security.OST_CREATE_NEW_USER()
				return result
			}
		case:
			fmt.printfln("Invalid command structure. Correct Usage: NEW <Target> <Targets_name>")
			utils.log_runtime_event(
				"Invalid NEW command",
				"User did not provide a valid target to create.",
			)
		}
		break
	//RENAME: Allows for the renaming of collections, clusters, or individual record names
	case const.RENAME:
		utils.log_runtime_event("Used RENAME command", "")
		switch (cmd.t_token) 
		{
		case const.COLLECTION:
			if len(cmd.o_token) > 0 && const.TO in cmd.m_token {
				old_name := cmd.o_token[0]
				new_name := cmd.m_token[const.TO]

				fmt.printf(
					"Renaming collection: %s%s%s to %s%s%s\n",
					utils.BOLD_UNDERLINE,
					old_name,
					utils.RESET,
					utils.BOLD_UNDERLINE,
					new_name,
					utils.RESET,
				)
				success := data.OST_RENAME_COLLECTION(old_name, new_name)
				switch (success) 
				{
				case true:
					fmt.printf(
						"Successfully renamed collection: %s%s%s to %s%s%s\n",
						utils.BOLD_UNDERLINE,
						old_name,
						utils.RESET,
						utils.BOLD_UNDERLINE,
						new_name,
						utils.RESET,
					)
					utils.log_runtime_event(
						"Successfully renamed collection",
						"User successfully renamed a collection.",
					)
					break
				case:
					fmt.printfln(
						"Failed to rename collection: %s%s%s to %s%s%s",
						utils.BOLD_UNDERLINE,
						old_name,
						utils.RESET,
						utils.BOLD_UNDERLINE,
						new_name,
						utils.RESET,
					)
					utils.log_runtime_event(
						"Failed to rename collection",
						"User requested to rename a collection but failed.",
					)
					utils.log_err("Failed to rename collection.", #procedure)
					break
				}

			} else {
				fmt.println(
					"Incomplete command. Correct Usage: RENAME COLLECTION <old_name> TO <new_name>",
				)
			}
			break
		case const.CLUSTER:
			cluster_name: string
			collection_name: string

			if len(cmd.o_token) >= 2 && const.WITHIN in cmd.m_token && const.TO in cmd.m_token ||
			   cmd.isUsingDotNotation == true {
				// if cmd.isUsingDotNotation == true {}
				old_name := cmd.o_token[1]
				collection_name := cmd.o_token[0]
				new_name := cmd.m_token[const.TO]

				checks := data.OST_HANDLE_INTGRITY_CHECK_RESULT(collection_name)
				switch (checks) 
				{
				case -1:
					fmt.printfln(
						"Failed to rename cluster %s%s%s to %s%s%s in collection %s%s%s\n",
					)
					return -1
				}

				success := data.OST_RENAME_CLUSTER(collection_name, old_name, new_name)
				if success {
					fmt.printf(
						"Successfully renamed cluster %s%s%s to %s%s%s in collection %s%s%s\n",
						utils.BOLD_UNDERLINE,
						old_name,
						utils.RESET,
						utils.BOLD_UNDERLINE,
						new_name,
						utils.RESET,
						utils.BOLD_UNDERLINE,
						collection_name,
						utils.RESET,
					)
					fn := OST_CONCAT_OBJECT_EXT(collection_name)
					metadata.OST_UPDATE_METADATA_VALUE(fn, 2)
					metadata.OST_UPDATE_METADATA_VALUE(fn, 3)
				} else {
					fmt.println(
						"Failed to rename cluster due to internal error. Please check error logs.",
					)
					utils.log_err("Failed to rename cluster.", #procedure)
				}
			} else {
				fmt.println(
					"Incomplete command. Correct Usage: RENAME CLUSTER <old_name> WITHIN <collection_name> TO <new_name>",
				)
				utils.log_runtime_event(
					"Incomplete RENAME command",
					"User did not provide a valid cluster name to rename.",
				)
			}
			break
		case const.RECORD:
			oldRName: string
			newRName: string
			collection_name: string //only here if using dot notation
			cluster_name: string //only here if using dot notation
			if len(cmd.o_token) == 1 && const.TO in cmd.m_token || cmd.isUsingDotNotation == true {
				if cmd.isUsingDotNotation == true {
					oldRName = cmd.o_token[2]
					newRName = cmd.m_token[const.TO]
					collection_name = cmd.o_token[0]
					cluster_name = cmd.o_token[1]
				} else {
					oldRName = cmd.o_token[0]
					newRName = cmd.m_token[const.TO]
				}
				//Who wrote this code?? Oh wait, it was me. I'm sorry.
				result := data.OST_RENAME_RECORD(
					oldRName,
					newRName,
					cmd.isUsingDotNotation,
					strings.clone(collection_name),
					strings.clone(cluster_name),
				)
				switch (result) 
				{
				case 0:
					fmt.printfln(
						"Record: %s%s%s successfully renamed to %s%s%s",
						utils.BOLD_UNDERLINE,
						oldRName,
						utils.RESET,
						utils.BOLD_UNDERLINE,
						newRName,
						utils.RESET,
					)
					utils.log_runtime_event(
						"Successfully renamed record",
						"User successfully renamed a record.",
					)
					break
				case:
					fmt.printfln(
						"Failed to rename record: %s%s%s to %s%s%s",
						utils.BOLD_UNDERLINE,
						oldRName,
						utils.RESET,
						utils.BOLD_UNDERLINE,
						newRName,
						utils.RESET,
					)
					utils.log_runtime_event(
						"Failed to rename record",
						"User requested to rename a record but failed.",
					)
					utils.log_err("Failed to rename record.", #procedure)
					break
				}

			} else {
				fmt.println(
					"Incomplete command. Correct Usage: RENAME RECORD <old_name> TO <new_name>\nAlternativley use dot notation: RENAME RECORD <collection_name>.<cluster_name>.<old_name> TO <new_name>",
				)
				utils.log_runtime_event(
					"Incomplete RENAME command",
					"User did not provide a valid record name to rename.",
				)
			}
			break
		}
		break

	// ERASE: Allows for the deletion of collections, specific clusters, or individual records within a cluster
	case const.ERASE:
		utils.log_runtime_event("Used ERASE command", "")
		switch (cmd.t_token) 
		{
		case const.COLLECTION:
			if data.OST_ERASE_COLLECTION(cmd.o_token[0]) == true {
				fmt.printfln(
					"Collection: %s%s%s erased successfully",
					utils.BOLD_UNDERLINE,
					cmd.o_token[0],
					utils.RESET,
				)
			} else {
				fmt.printfln(
					"Failed to erase collection: %s%s%s",
					utils.BOLD_UNDERLINE,
					cmd.o_token[0],
					utils.RESET,
				)
			}
			break
		case const.CLUSTER:
			collection_name: string
			cluster_name: string

			if len(cmd.o_token) >= 2 && const.WITHIN in cmd.m_token ||
			   cmd.isUsingDotNotation == true {
				collection_name := cmd.o_token[0]
				cluster := cmd.o_token[1]
				clusterID := data.OST_GET_CLUSTER_ID(collection_name, cluster)
				checks := data.OST_HANDLE_INTGRITY_CHECK_RESULT(collection_name)
				switch (checks) 
				{
				case -1:
					return -1
				}

				if data.OST_ERASE_CLUSTER(collection_name, cluster) == true {
					fmt.printfln(
						"Cluster: %s%s%s successfully erased from collection: %s%s%s",
						utils.BOLD_UNDERLINE,
						cluster,
						utils.RESET,
						utils.BOLD_UNDERLINE,
						collection_name,
						utils.RESET,
					)
					data.OST_REMOVE_ID_FROM_CACHE(clusterID)
				} else {
					fmt.printfln(
						"Failed to erase cluster: %s%s%s from collection: %s%s%s",
						utils.BOLD_UNDERLINE,
						cluster,
						utils.RESET,
						utils.BOLD_UNDERLINE,
						collection_name,
						utils.RESET,
					)
				}
				fn := OST_CONCAT_OBJECT_EXT(collection_name)
				metadata.OST_UPDATE_METADATA_VALUE(fn, 2)
				metadata.OST_UPDATE_METADATA_VALUE(fn, 3)
			} else {
				fmt.println(
					"Incomplete command. Correct Usage: ERASE CLUSTER <cluster_name> WITHIN COLLECTION <collection_name>",
				)
				utils.log_runtime_event(
					"Incomplete ERASE command",
					"User did not provide a valid cluster name to erase.",
				)
			}
			break
		case const.RECORD:
			collection_name: string
			cluster_name: string
			record_name: string

			if len(cmd.o_token) == 3 && const.WITHIN in cmd.m_token ||
			   cmd.isUsingDotNotation == true {
				collection_name := cmd.o_token[0]
				cluster_name := cmd.o_token[1]
				record_name := cmd.o_token[2]

				clusterID := data.OST_GET_CLUSTER_ID(collection_name, cluster_name)
				checks := data.OST_HANDLE_INTGRITY_CHECK_RESULT(collection_name)
				switch (checks) 
				{
				case -1:
					return -1
				}

				if data.OST_ERASE_RECORD(collection_name, cluster_name, record_name) == true {
					fmt.printfln(
						"Record: %s%s%s successfully erased from cluster: %s%s%s within collection: %s%s%s",
						utils.BOLD_UNDERLINE,
						record_name,
						utils.RESET,
						utils.BOLD_UNDERLINE,
						cluster_name,
						utils.RESET,
						utils.BOLD_UNDERLINE,
						collection_name,
						utils.RESET,
					)
					data.OST_REMOVE_ID_FROM_CACHE(clusterID)
				} else {
					fmt.printfln(
						"Failed to erase record: %s%s%s from cluster: %s%s%s within collection: %s%s%s",
						utils.BOLD_UNDERLINE,
						record_name,
						utils.RESET,
						utils.BOLD_UNDERLINE,
						cluster_name,
						utils.RESET,
						utils.BOLD_UNDERLINE,
						collection_name,
						utils.RESET,
					)
				}
			}
			break
		case:
			fmt.printfln(
				"Invalid command structure. Correct Usage: ERASE <Target> <Targets_name>\nAlternativley use dot notation: ERASE <collection_name>.<cluster_name>.<record_name>",
			)
			utils.log_runtime_event(
				"Invalid ERASE command",
				"User did not provide a valid target.",
			)
		}
		break
	// FETCH: Allows for the retrieval and displaying of collections, clusters, or individual records
	case const.FETCH:
		utils.log_runtime_event("Used FETCH command", "")
		switch (cmd.t_token) 
		{
		case const.COLLECTION:
			if len(cmd.o_token) > 0 {
				collection := cmd.o_token[0]
				str := data.OST_FETCH_COLLECTION(collection)
				fmt.println(str)
			} else {
				fmt.println(
					"Incomplete command. Correct Usage: FETCH COLLECTION <collection_name>",
				)
				utils.log_runtime_event(
					"Incomplete FETCH command",
					"User did not provide a valid collection name to fetch.",
				)
			}
			break
		case const.CLUSTER:
			//todo: declaring these two variables but not actually using them - Marshall Burns aka @SchoolyB 06Oct2024
			collection_name: string
			cluster_name: string
			if len(cmd.o_token) >= 2 && const.WITHIN in cmd.m_token ||
			   cmd.isUsingDotNotation == true {
				collection := cmd.o_token[0]
				cluster := cmd.o_token[1]
				checks := data.OST_HANDLE_INTGRITY_CHECK_RESULT(collection)
				switch (checks) 
				{
				case -1:
					return -1
				}

				clusterContent := data.OST_FETCH_CLUSTER(collection, cluster)
				fmt.printfln(clusterContent)
			} else {
				fmt.println(
					"Incomplete command. Correct Usage: FETCH CLUSTER <cluster_name> WITHIN COLLECTION <collection_name>",
				)
				utils.log_runtime_event(
					"Incomplete FETCH command",
					"User did not provide a valid cluster name to fetch.",
				)
			}
			break
		case const.RECORD:
			colllection_name: string
			cluster_name: string
			record_name: string
			if len(cmd.o_token) == 3 && const.WITHIN in cmd.m_token ||
			   cmd.isUsingDotNotation == true {
				collection_name := cmd.o_token[0]
				cluster_name := cmd.o_token[1]
				record_name := cmd.o_token[2]

				checks := data.OST_HANDLE_INTGRITY_CHECK_RESULT(collection_name)
				switch (checks) 
				{
				case -1:
					return -1
				}
				record, found := data.OST_FETCH_RECORD(collection_name, cluster_name, record_name)
				fmt.printfln(
					"Succesfully retrieved record: %s%s%s from cluster: %s%s%s within collection: %s%s%s\n\n",
					utils.BOLD_UNDERLINE,
					record_name,
					utils.RESET,
					utils.BOLD_UNDERLINE,
					cluster_name,
					utils.RESET,
					utils.BOLD_UNDERLINE,
					collection_name,
					utils.RESET,
				)
				if found {
					fmt.printfln("\t%s :%s: %s\n", record.name, record.type, record.value)
					fmt.println("\t^^^\t^^^\t^^^")
					fmt.println("\tName\tType\tValue\n\n")
				}
			} else {
				fmt.printfln(
					"Incomplete command. Correct Usage: FETCH RECORD <record_name> WITHIN CLUSTER <cluster_name> WITHIN COLLECTION <collection_name>",
				)
				utils.log_runtime_event(
					"Incomplete FETCH command",
					"User did not provide a valid record name to fetch.",
				)
			}
			break
		case:
			fmt.printfln("Invalid command structure. Correct Usage: FETCH <Target> <Targets_name>")
			utils.log_runtime_event(
				"Invalid FETCH command",
				"User did not provide a valid target.",
			)
		}
		break
	case const.SET:
		//set can only be usedon RECORDS and CONFIGS
		switch cmd.t_token 
		{
		case const.RECORD:
			if len(cmd.o_token) == 1 && const.TO in cmd.m_token {
				record := cmd.o_token[0]
				value: string
				for key, val in cmd.m_token {
					value = val
				}
				fmt.printfln(
					"Setting record: %s%s%s to %s%s%s",
					utils.BOLD_UNDERLINE,
					record,
					utils.RESET,
					utils.BOLD_UNDERLINE,
					value,
					utils.RESET,
				)
				col, ok := data.OST_SET_RECORD_VALUE(record, value)
				fn := OST_CONCAT_OBJECT_EXT(col)
				metadata.OST_UPDATE_METADATA_VALUE(fn, 2)
				metadata.OST_UPDATE_METADATA_VALUE(fn, 3)

			}
			break
		case const.CONFIG:
			utils.log_runtime_event("Used SET command", "")
			if len(cmd.o_token) == 1 && const.TO in cmd.m_token {
				configName := cmd.o_token[0]
				value: string
				for key, val in cmd.m_token {
					value = val
				}
				fmt.printfln(
					"Setting config: %s%s%s to %s%s%s",
					utils.BOLD_UNDERLINE,
					configName,
					utils.RESET,
					utils.BOLD_UNDERLINE,
					value,
					utils.RESET,
				)
				switch (configName) 
				{
				case "HELP":
					success := config.OST_TOGGLE_CONFIG(const.configFour)
					if success == false {
						fmt.printfln("Failed to toggle HELP config")
					} else {
						fmt.printfln("Successfully toggled HELP config")
					}
					help.OST_SET_HELP_MODE()
				case:
					fmt.printfln("Invalid config name. Valid config names are: 'HELP'")
				}
			}
			break
		case:
			fmt.printfln(
				"Invalid command structure. Correct Usage: SET <Target> <Targets_name> TO <value>",
			)
			fmt.printfln("The SET command can only be used on RECORDS and CONFIGS")
		}
	case const.COUNT:
		utils.log_runtime_event("Used COUNT command", "")
		switch (cmd.t_token) 
		{
		case const.COLLECTIONS:
			result := data.OST_COUNT_COLLECTIONS()
			fmt.printfln("There are %d collections in the database", result)
			break
		case const.CLUSTERS:
			fmt.println("cmd,o_tokens: ", cmd.o_token)
			if len(cmd.o_token) == 1 {
				collection_name := cmd.o_token[0]
				result := data.OST_COUNT_CLUSTERS(collection_name)
				switch (result) 
				{
				case -1:
					fmt.printfln(
						"Failed to count clusters in collection %s%s%s",
						utils.BOLD_UNDERLINE,
						collection_name,
						utils.RESET,
					)
					break
				case 0:
					fmt.printfln(
						"There are no clusters in the collection %s%s%s",
						utils.BOLD_UNDERLINE,
						collection_name,
						utils.RESET,
					)
					break
				case 1:
					fmt.printfln(
						"There is %d cluster in the collection %s%s%s",
						result,
						utils.BOLD_UNDERLINE,
						collection_name,
						utils.RESET,
					)
					break
				case:
					fmt.printfln(
						"There are %d clusters in the collection %s%s%s",
						result,
						utils.BOLD_UNDERLINE,
						collection_name,
						utils.RESET,
					)
					break
				}
			} else {
				fmt.printfln(
					"Invalid command structure. Correct Usage: COUNT CLUSTERS WITHIN COLLECTION <collection_name>\nIf using dot notation: COUNT CLUSTERS <collection_name>",
				)
				utils.log_runtime_event(
					"Invalid COUNT command",
					"User did not provide a valid collection name to count clusters.",
				)
			}

			break
		case const.RECORDS:
			//in the event the users is counting the records in a specific cluster
			if (len(cmd.o_token) >= 2 || cmd.isUsingDotNotation == true) {
				collection_name := cmd.o_token[0]
				cluster_name := cmd.o_token[1]
				result := data.OST_COUNT_RECORDS_IN_CLUSTER(
					strings.clone(collection_name),
					strings.clone(cluster_name),
					true,
				)
				switch result {
				case -1:
					fmt.printfln(
						"Error counting records in the cluster %s%s%s collection %s%s%s",
						utils.BOLD_UNDERLINE,
						cluster_name,
						utils.RESET,
						utils.BOLD_UNDERLINE,
						collection_name,
						utils.RESET,
					)
				case 0:
					fmt.printfln(
						"There are no records in the cluster %s%s%s in the collection %s%s%s",
						utils.BOLD_UNDERLINE,
						cluster_name,
						utils.RESET,
						utils.BOLD_UNDERLINE,
						collection_name,
						utils.RESET,
					)
					break
				case 1:
					fmt.printfln(
						"There is %d record in the cluster %s%s%s in the collection %s%s%s",
						result,
						utils.BOLD_UNDERLINE,
						cluster_name,
						utils.RESET,
						utils.BOLD_UNDERLINE,
						collection_name,
						utils.RESET,
					)
					break
				case:
					fmt.printfln(
						"There are %d records in the cluster %s%s%s in the collection %s%s%s",
						result,
						utils.BOLD_UNDERLINE,
						cluster_name,
						utils.RESET,
						utils.BOLD_UNDERLINE,
						collection_name,
						utils.RESET,
					)
					return 0
				}
			} else if len(cmd.o_token) == 1 || cmd.isUsingDotNotation == true {
				//in the event the user is counting all records in a collection
				collection_name := cmd.o_token[0]
				result := data.OST_COUNT_RECORDS_IN_COLLECTION(collection_name)

				switch result 
				{
				case -1:
					fmt.printfln(
						"Error counting records in the collection %s%s%s",
						utils.BOLD_UNDERLINE,
						collection_name,
						utils.RESET,
					)
					break
				case 0:
					fmt.printfln(
						"There are no records in collection %s%s%s",
						utils.BOLD,
						collection_name,
						utils.RESET,
					)
					break
				case 1:
					fmt.printfln(
						"There is %d record in the collection %s%s%s",
						result,
						utils.BOLD_UNDERLINE,
						collection_name,
						utils.RESET,
					)
					break
				case:
					fmt.printfln(
						"There are %d records in the collection %s%s%s",
						result,
						utils.BOLD_UNDERLINE,
						collection_name,
						utils.RESET,
					)
				}

			} else {
				fmt.printfln(
					"Invalid command structure. Correct Usage: COUNT RECORDS WITHIN CLUSTER <cluster_name> WITHIN COLLECTION <collection_name>\nIf using dot notation: COUNT RECORDS <collection_name>.<cluster_name>",
				)
				utils.log_runtime_event(
					"Invalid COUNT command",
					"User did not provide a valid cluster name to count records.",
				)
			}
			break
		}
		break
	//FOCUS and UNFOCUS: Enter at own peril.
	case const.FOCUS:
		utils.log_runtime_event("Used FOCUS command", "")

		switch (cmd.t_token) 
		{
		case const.COLLECTION:
			exists := data.OST_CHECK_IF_COLLECTION_EXISTS(cmd.o_token[0], 0)
			fmt.println(exists)
			switch exists {
			case true:
				types.focus.flag = true
				if len(cmd.o_token) > 0 {
					collection := cmd.o_token[0]
					storedT, storedO, _ := OST_FOCUS(const.COLLECTION, collection, "[NO PARENT]")
				} else {
					fmt.println(
						invalidCommandErr,
						"Incomplete command. Correct Usage: NEW COLLECTION <collection_name>",
					)
					utils.log_runtime_event(
						"Incomplete FOCUS command",
						"User did not provide a valid collection name to focus.",
					)
				}
				break
			case false:
				fmt.printfln(
					"Collection: %s%s%s not found in OstrichDB.",
					utils.BOLD_UNDERLINE,
					cmd.o_token[0],
					utils.RESET,
				)
				utils.log_runtime_event(
					"Invalid FOCUS command",
					"User tried to focus on a collection that does not exist.",
				)
				types.focus.flag = false
				break
			}

		case const.CLUSTER:
			collectionNamePath := fmt.tprintf("%s%s", const.OST_COLLECTION_PATH, cmd.o_token[1])
			fullCollectionPath := fmt.tprintf("%s%s", collectionNamePath, const.OST_FILE_EXTENSION)

			checks := data.OST_HANDLE_INTGRITY_CHECK_RESULT(cmd.o_token[1])
			switch (checks) 
			{
			case -1:
				return -1
			}

			exists := data.OST_CHECK_IF_CLUSTER_EXISTS(fullCollectionPath, cmd.o_token[0])
			switch exists {
			case true:
				types.focus.flag = true
				if len(cmd.o_token) >= 2 && const.WITHIN in cmd.m_token {
					cluster := cmd.o_token[0]
					collection := cmd.o_token[1]
					storedT, storedO, _ := OST_FOCUS(const.CLUSTER, cluster, cmd.o_token[1]) //storing the Target and Objec that the user wants to focus)
				} else {
					fmt.println(
						"Incomplete command. Correct Usage: FOCUS CLUSTER <cluster_name> WITHIN COLLECTION <collection_name>",
					)
					utils.log_runtime_event(
						"Incomplete FOCUS command",
						"User did not provide a valid cluster name to focus.",
					)
				}
				break
			case false:
				fmt.printfln(
					"Cluster: %s%s%s does not exist within collection: %s%s%s.",
					utils.BOLD,
					cmd.o_token[0],
					utils.RESET,
					utils.BOLD,
					cmd.o_token[1],
					utils.RESET,
				)
				types.focus.flag = false
				break
			}

		//todo: come back to this..havent done enough commands to test this in focus mode yet
		case const.RECORD:
			types.focus.flag = true
			if len(cmd.o_token) >= 3 && const.WITHIN in cmd.m_token {
				record := cmd.o_token[0]
				cluster := cmd.o_token[1]
				collection := cmd.o_token[2]

				checks := data.OST_HANDLE_INTGRITY_CHECK_RESULT(collection)
				switch (checks) 
				{
				case -1:
					return -1
				}

				storedParentT, storedParentO, storedRO := OST_FOCUS_RECORD(
					collection,
					cluster,
					record,
				)
				fmt.printfln(
					"Focused on record: %s%s%s in cluster: %s%s%s within collection: %s%s%s",
					utils.BOLD_UNDERLINE,
					record,
					utils.RESET,
					utils.BOLD_UNDERLINE,
					cluster,
					utils.RESET,
					utils.BOLD_UNDERLINE,
					collection,
					utils.RESET,
				)
				//storing the Target and Objec that the user wants to focus)
			} else {
				fmt.printfln(
					"Incomplete command. Correct Usage: FOCUS RECORD <record_name> WITHIN CLUSTER <cluster_name> WITHIN COLLECTION <collection_name>",
				)
				utils.log_runtime_event(
					"Incomplete FOCUS command",
					"User did not provide a valid record name to focus.",
				)
			}
			break
		case:
			fmt.printfln("Invalid command structure. Correct Usage: FOCUS <target> <target_name>")
			utils.log_runtime_event(
				"Invalid FOCUS command",
				"User did not provide a valid target.",
			)
			break
		}
		break


	case:
		fmt.printfln(
			"Invalid command: %s%s%s. Please enter a valide OstrichDB command. Enter 'HELP' for more information.",
			utils.BOLD_UNDERLINE,
			cmd.a_token,
			utils.RESET,
		)
		utils.log_runtime_event("Invalid command", "User entered an invalid command.")
	}
	return 1
}
// =======================<FOCUS MODE>=======================//
// =======================<FOCUS MODE>=======================//
// =======================<FOCUS MODE>=======================//
EXECUTE_COMMANDS_WHILE_FOCUSED :: proc(
	cmd: ^types.Command,
	focusTarget: string,
	focusObject: string,
	focusParentObject: ..string,
) -> int {
	utils.log_runtime_event("Entered FOCUS mode", "User has succesfully entered FOCUS mode")
	incompleteCommandErr := utils.new_err(
		.INCOMPLETE_COMMAND,
		utils.get_err_msg(.INCOMPLETE_COMMAND),
		#procedure,
	)

	invalidCommandErr := utils.new_err(
		.INVALID_COMMAND,
		utils.get_err_msg(.INVALID_COMMAND),
		#procedure,
	)
	defer delete(cmd.o_token)


	switch (cmd.a_token) 
	{
	//=======================<SINGLE-TOKEN COMMANDS>=======================//
	case const.EXIT:
		utils.log_runtime_event(
			"Used EXIT command while in FOCUS mode",
			"This action cannot be performed while in FOCUS mode",
		)
		fmt.printf("Cannot Exit OStrichDB while in FOCUS mode...\n")
		break
	case const.LOGOUT:
		utils.log_runtime_event(
			"Used LOGOUT command while in FOCUS mode",
			"This action cannot be performed while in FOCUS mode",
		)
		fmt.printf("Cannot Logout while in FOCUS mode...\n")
		break
	case const.UNFOCUS:
		types.focus.flag = false
		utils.log_runtime_event("Used UNFOCUS command", "User has succesfully exited FOCUS mode")
		break
	case const.CLEAR:
		utils.log_runtime_event("Used CLEAR command while in FOCUS mode", "")
		libc.system("clear")
		break
	//=======================<SINGLE OR MULTI-TOKEN COMMANDS>=======================//
	case const.HELP:
		utils.log_runtime_event(
			"Used HELP command while in FOCUS mode",
			"Displaying help menu for FOCUS mode",
		)
		fmt.println(
			"Help mode is currently not supported in FOCUS mode.Check for updates in a future release.",
		)
	//=======================<MULTI-TOKEN COMMANDS>=======================//
	case const.NEW:
		utils.log_runtime_event("Used NEW command while in FOCUS mode", "")
		switch (cmd.t_token) 
		{
		case const.COLLECTION:
			fmt.printf("Cannot create a new collection while in FOCUS mode...\n")
			break
		case const.CLUSTER:
			if len(cmd.o_token) >= 1 {
				cluster_name := cmd.o_token[0]
				collection_name := focusObject

				id := data.OST_GENERATE_CLUSTER_ID()
				result := data.OST_CREATE_CLUSTER_FROM_CL(collection_name, cluster_name, id)
				switch (result) 
				{
				case -1:
					fmt.printfln(
						"Cluster: %s%s%s already exists within collection: %s%s%s. Failed to create cluster.",
						utils.BOLD_UNDERLINE,
						cluster_name,
						utils.RESET,
						utils.BOLD_UNDERLINE,
						collection_name,
						utils.RESET,
					)
					break
				case 1, 2, 3:
					error1 := utils.new_err(
						.CANNOT_CREATE_CLUSTER,
						utils.get_err_msg(.CANNOT_CREATE_CLUSTER),
						#procedure,
					)
					utils.throw_custom_err(
						error1,
						"Failed to create cluster due to internal OstrichDB error.\n Check logs for more information.",
					)
					break
				}

				fn := OST_CONCAT_OBJECT_EXT(collection_name)
				metadata.OST_UPDATE_METADATA_VALUE(fn, 2)
				metadata.OST_UPDATE_METADATA_VALUE(fn, 3)
			} else {
				fmt.println("Incomplete command. Correct Usage: NEW CLUSTER <collection_name>")
				utils.log_runtime_event(
					"Incomplete NEW command while in FOCUS mode",
					"User did not provide a valid cluster name.",
				)
			}
			break
		case const.RECORD:
			break
		case:
			fmt.println("Invalid command. Correct Usage: NEW <target> <target_name>")
			utils.log_runtime_event(
				"Invalid NEW command while in FOCUS mode",
				"User did not provide a valid target.",
			)
			break
		}
		break
	case const.FETCH:
		utils.log_runtime_event("Used FETCH command while in FOCUS mode", "")
		switch (cmd.t_token) 
		{
		case const.COLLECTION:
			fmt.printf("Cannot fetch a collection while in FOCUS mode...\n")
			break
		case const.CLUSTER:
			if len(cmd.o_token) >= 1 {
				cluster := cmd.o_token[0]
				collection := focusObject
				clusterContent := data.OST_FETCH_CLUSTER(collection, cluster)
				fmt.printfln(clusterContent)
			} else {
				fmt.println("Incomplete command. Correct Usage: FETCH CLUSTER <cluster_name>")
				utils.log_runtime_event(
					"Incomplete FETCH command while in FOCUS mode",
					"User did not provide a valid cluster name.",
				)
			}
			break
		case const.RECORD:
			break
		case:
			fmt.println("Invalid command. Correct Usage: FETCH <target> <target_name>")
			utils.log_runtime_event(
				"Invalid FETCH command while in FOCUS mode",
				"User did not provide a valid target.",
			)
			break
		}
		break
	case const.ERASE:
		utils.log_runtime_event("Used ERASE command while in FOCUS mode", "")
		switch (cmd.t_token) 
		{
		case const.COLLECTION:
			fmt.println("Cannot erase a collection while in FOCUS mode.")
			break
		case const.CLUSTER:
			if len(cmd.o_token) >= 1 {
				cluster_name := cmd.o_token[0]
				collection_name := focusObject
				if data.OST_ERASE_CLUSTER(collection_name, cluster_name) == true {
					fmt.printfln(
						"Cluster: %s%s%s successfully erased from collection: %s%s%s",
						utils.BOLD_UNDERLINE,
						cluster_name,
						utils.RESET,
						utils.BOLD_UNDERLINE,
						collection_name,
						utils.RESET,
					)
				} else {
					fmt.printfln(
						"Failed to erase cluster: %s%s%s from collection: %s%s%s",
						utils.BOLD_UNDERLINE,
						cluster_name,
						utils.RESET,
						utils.BOLD_UNDERLINE,
						collection_name,
						utils.RESET,
					)
				}
				fn := OST_CONCAT_OBJECT_EXT(collection_name)
				metadata.OST_UPDATE_METADATA_VALUE(fn, 2)
				metadata.OST_UPDATE_METADATA_VALUE(fn, 3)
			} else {
				fmt.println("Incomplete command. Correct Usage: ERASE CLUSTER <cluster_name>")
				utils.log_runtime_event(
					"Incomplete ERASE command while in FOCUS mode",
					"User did not provide a valid cluster name.",
				)
			}
			break
		case const.RECORD:
			break
		case:
			fmt.println("Invalid command. Correct Usage: ERASE <target> <target_name>")
			utils.log_runtime_event(
				"Invalid ERASE command while in FOCUS mode",
				"User did not provide a valid target.",
			)
			break
		}
		break
	case const.RENAME:
		utils.log_runtime_event("Used RENAME command while in FOCUS mode", "")
		switch (cmd.t_token) 
		{
		case const.COLLECTION:
			fmt.println("Cannot rename a collection while in FOCUS mode.")
			break
		case const.CLUSTER:
			if len(cmd.o_token) >= 1 && const.TO in cmd.m_token {
				old_name := focusObject
				new_name := cmd.m_token[const.TO]
				collection_name := types.focus.p_o
				fmt.printfln(
					"Renaming cluster %s%s%s to %s%s%s in collection %s%s%s",
					utils.BOLD_UNDERLINE,
					old_name,
					utils.RESET,
					utils.BOLD_UNDERLINE,
					new_name,
					utils.RESET,
					utils.BOLD_UNDERLINE,
					collection_name,
					utils.RESET,
				)
				success := data.OST_RENAME_CLUSTER(collection_name, old_name, new_name)
				if success {
					fmt.printf(
						"Successfully renamed cluster %s%s%s to %s%s%s in collection %s%s%s\n",
						utils.BOLD_UNDERLINE,
						old_name,
						utils.RESET,
						utils.BOLD_UNDERLINE,
						new_name,
						utils.RESET,
						utils.BOLD_UNDERLINE,
						collection_name,
						utils.RESET,
					)
					fn := OST_CONCAT_OBJECT_EXT(collection_name)
					metadata.OST_UPDATE_METADATA_VALUE(fn, 2)
					metadata.OST_UPDATE_METADATA_VALUE(fn, 3)

					// quickly unfocus the old object and update it to refocus on the new object
					types.focus.flag = false
					storedT, storedO, _ := OST_FOCUS(collection_name, new_name, types.focus.p_o)
					types.focus.flag = true
				} else {
					fmt.println("Failed to rename cluster. Please check error messages.")
				}
				break
			} else {
				fmt.println(
					"Incomplete command. Correct Usage: RENAME CLUSTER <cluster_name> TO <new_name>",
				)
				utils.log_runtime_event(
					"Incomplete RENAME command while in FOCUS mode",
					"User did not provide a valid cluster name or new name.",
				)
			}
			break
		case const.RECORD:
			break
		case:
			fmt.println(
				"Invalid command. Correct Usage: RENAME <target> <target_name> TO <new_name>",
			)
			utils.log_runtime_event(
				"Invalid RENAME command while in FOCUS mode",
				"User did not provide a valid target.",
			)
			break
		}
		break
	case:
		fmt.printfln(
			"Invalid command: %s%s%s. Please enter a valide OstrichDB command. Enter 'HELP' for more information.",
			utils.BOLD_UNDERLINE,
			cmd.a_token,
			utils.RESET,
		)
		utils.log_runtime_event(
			"Invalid command while in FOCUS mode",
			"User entered an invalid command.",
		)
		break
	}
	return 0
}
