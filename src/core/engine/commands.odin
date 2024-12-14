package engine

import "../../tests"
import "../../utils"
import "../config"
import "../const"
import "../help"
import "../server"
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


OST_GET_RECORD_SIZE :: proc(
	collection_name: string,
	cluster_name: string,
	record_name: string,
) -> (
	size: int,
	success: bool,
) {
	collection_path := utils.concat_collection_name(collection_name)
	data, read_success := os.read_entire_file(collection_path)
	if !read_success {
		return 0, false
	}
	defer delete(data)

	content := string(data)
	clusters := strings.split(content, "},")

	for cluster in clusters {
		if strings.contains(cluster, fmt.tprintf("cluster_name :identifier: %s", cluster_name)) {
			lines := strings.split(cluster, "\n")
			for line in lines {
				if strings.has_prefix(line, record_name) {
					parts := strings.split(line, ":")
					if len(parts) >= 3 {
						record_value := strings.trim_space(strings.join(parts[2:], ":"))
						return len(record_value), true
					}
				}
			}
		}
	}

	return 0, false
}

OST_GET_CLUSTER_SIZE :: proc(
	collection_name: string,
	cluster_name: string,
) -> (
	size: int,
	success: bool,
) {
	collection_path := fmt.tprintf(
		"%s%s%s",
		const.OST_COLLECTION_PATH,
		collection_name,
		const.OST_FILE_EXTENSION,
	)
	data, read_success := os.read_entire_file(collection_path)
	if !read_success {
		return 0, false
	}
	defer delete(data)

	content := string(data)
	clusters := strings.split(content, "},")

	for cluster in clusters {
		if strings.contains(cluster, fmt.tprintf("cluster_name :identifier: %s", cluster_name)) {
			return len(cluster), true
		}
	}

	return 0, false
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

	//Semi global Server shit
	ServerConfig := types.Server_Config {
		port = 8082,
	}
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
	case const.RESTART:
		utils.log_runtime_event("Used RESTART command", "User requested to restart OstrichDB.")
		OST_RESTART()
	case const.REBUILD:
		utils.log_runtime_event("Used REBUILD command", "User requested to rebuild OstrichDB")
		OST_REBUILD()
	case const.DESTROY:
		utils.log_runtime_event("Used DESTROY command", "User requested to destroy OstrichDB.")
		OST_DESTROY()
	case const.TEST:
		utils.log_runtime_event("Used TEST command", "User requested to run tests.")
		tests.main()
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
	//WHERE: Used to search for a specific object within the DBMS
	case const.WHERE:
		utils.log_runtime_event(
			"Used WHERE command",
			"User requested to search for a specific object.",
		)
		switch (cmd.t_token) {
		case const.CLUSTER, const.RECORD:
			data.OST_WHERE_OBJECT(cmd.t_token, cmd.o_token[0])
		case:
			break
		}
		if len(cmd.o_token) == 0 {
			data.OST_WHERE_ANY(cmd.t_token)
		} else {
			fmt.println(
				"Incomplete command. Correct Usage: WHERE <target> <target_name> or WHERE <target_name>",
			)
			utils.log_runtime_event(
				"Incomplete WHERE command",
				"User did not provide a target name to search for.",
			)
		}
		break
	//BACKUP: Used in conjuction with COLLECTION to create a duplicate of all data within a collection
	case const.BACKUP:
		utils.log_runtime_event("Used BACKUP command", "User requested to backup data.")
		switch (cmd.t_token) {
		case const.COLLECTION:
			if len(cmd.o_token) > 0 {
				name := data.OST_CHOOSE_BACKUP_NAME()


				checks := data.OST_HANDLE_INTEGRITY_CHECK_RESULT(cmd.o_token[0])
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
			if len(cmd.o_token) >= 2 && cmd.isUsingDotNotation == true {
				if cmd.isUsingDotNotation == true {
					collection_name = cmd.o_token[0]
					cluster_name = cmd.o_token[1]
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
				checks := data.OST_HANDLE_INTEGRITY_CHECK_RESULT(collection_name)
				switch (checks) 
				{
				case -1:
					return -1
				}

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
				fn := utils.concat_collection_name(collection_name)
				metadata.OST_UPDATE_METADATA_VALUE(fn, 2)
				metadata.OST_UPDATE_METADATA_VALUE(fn, 3)
			} else {
				fmt.printfln(
					"Invalid command. Correct Usage: NEW CLUSTER <collection_name>.<cluster_name>",
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
			if len(cmd.o_token) == 3 &&
			   const.OF_TYPE in cmd.m_token &&
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
					//All hail the re-engineered parser - Marshall Burns aka @SchoolyB
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
						fn := utils.concat_collection_name(collection_name)
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
					"Incomplete command. Correct Usage: NEW RECORD <collection_name>.<cluster_name>.<record_name> OF_TYPE <record_type>",
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

			if len(cmd.o_token) >= 2 && const.TO in cmd.m_token && cmd.isUsingDotNotation == true {
				old_name := cmd.o_token[1]
				collection_name := cmd.o_token[0]
				new_name := cmd.m_token[const.TO]

				checks := data.OST_HANDLE_INTEGRITY_CHECK_RESULT(collection_name)
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
					fn := utils.concat_collection_name(collection_name)
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
					"Incomplete command. Correct Usage: RENAME CLUSTER <collection_name>.<old_name> TO <new_name>",
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
					"Incomplete command. Correct Usage: RENAME RECORD <collection_name>.<cluster_name>.<old_name> TO <new_name>",
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

			if len(cmd.o_token) >= 2 && cmd.isUsingDotNotation == true {
				collection_name := cmd.o_token[0]
				cluster := cmd.o_token[1]
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
						utils.BOLD_UNDERLINE,
						cluster,
						utils.RESET,
						utils.BOLD_UNDERLINE,
						collection_name,
						utils.RESET,
					)
					utils.remove_id_from_cache(clusterID)
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
				fn := utils.concat_collection_name(collection_name)
				metadata.OST_UPDATE_METADATA_VALUE(fn, 2)
				metadata.OST_UPDATE_METADATA_VALUE(fn, 3)
			} else {
				fmt.println(
					"Incomplete command. Correct Usage: ERASE CLUSTER <collection_name>.<cluster_name>",
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

			if len(cmd.o_token) == 3 && cmd.isUsingDotNotation == true {
				collection_name := cmd.o_token[0]
				cluster_name := cmd.o_token[1]
				record_name := cmd.o_token[2]

				clusterID := data.OST_GET_CLUSTER_ID(collection_name, cluster_name)
				checks := data.OST_HANDLE_INTEGRITY_CHECK_RESULT(collection_name)
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
					utils.remove_id_from_cache(clusterID)
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
				"Invalid command structure. Correct Usage: ERASE <collection_name>.<cluster_name>.<record_name>",
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
			if len(cmd.o_token) >= 2 && cmd.isUsingDotNotation == true {
				collection := cmd.o_token[0]
				cluster := cmd.o_token[1]
				checks := data.OST_HANDLE_INTEGRITY_CHECK_RESULT(collection)
				switch (checks) 
				{
				case -1:
					return -1
				}

				clusterContent := data.OST_FETCH_CLUSTER(collection, cluster)
				fmt.printfln(clusterContent)
			} else {
				fmt.println(
					"Incomplete command. Correct Usage: FETCH CLUSTER <collection_name>.<cluster_name>",
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
			if len(cmd.o_token) == 3 && cmd.isUsingDotNotation == true {
				collection_name := cmd.o_token[0]
				cluster_name := cmd.o_token[1]
				record_name := cmd.o_token[2]

				checks := data.OST_HANDLE_INTEGRITY_CHECK_RESULT(collection_name)
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
					"Incomplete command. Correct Usage: FETCH RECORD <collection_name>.<cluster_name>.<record_name>",
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
			if len(cmd.o_token) == 3 && const.TO in cmd.m_token && cmd.isUsingDotNotation {
				collectionName := cmd.o_token[0]
				clusterName := cmd.o_token[1]
				recordName := cmd.o_token[2]
				value: string
				for key, val in cmd.m_token {
					value = val
				}
				fmt.printfln(
					"Setting record: %s%s%s to %s%s%s",
					utils.BOLD_UNDERLINE,
					recordName,
					utils.RESET,
					utils.BOLD_UNDERLINE,
					value,
					utils.RESET,
				)
				ok := data.OST_SET_RECORD_VALUE(
					collectionName,
					clusterName,
					recordName,
					strings.clone(value),
				)
				fn := utils.concat_collection_name(collectionName)
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
				case "SERVER":
					success := config.OST_TOGGLE_CONFIG(const.configFive)
					if success == false {
						fmt.printfln("Failed to toggle SERVER config")
					} else {
						fmt.printfln("Successfully toggled SERVER config")
						if config.OST_READ_CONFIG_VALUE(const.configFive) == "true" {
							fmt.printfln("Server is now ON")
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
			switch (result) {
			case -1:
				fmt.printfln("Failed to count collections")
				break
			case 0:
				fmt.printfln("There are no collections in the database")
				break
			case 1:
				fmt.printfln("There is %d collection in the database", result)
				break
			case:
				fmt.printfln("There are %d collections in the database", result)
				break
			}
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
					"Invalid command structure. Correct Usage: COUNT CLUSTERS <collection_name>",
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
					"Invalid command structure. Correct Usage: COUNT RECORDS <collection_name>.<cluster_name>",
				)
				utils.log_runtime_event(
					"Invalid COUNT command",
					"User did not provide a valid cluster name to count records.",
				)
			}
			break
		}
		break
	//PURGE command
	case const.PURGE:
		utils.log_runtime_event("Used PURGE command", "")
		switch (cmd.t_token) 
		{
		case const.COLLECTION:
			collection_name := cmd.o_token[0]
			exists := data.OST_CHECK_IF_COLLECTION_EXISTS(collection_name, 0)
			switch exists 
			{
			case true:
				result := data.OST_PURGE_COLLECTION(cmd.o_token[0])
				switch result 
				{
				case true:
					fmt.printfln(
						"Successfully purged collection: %s%s%s",
						utils.BOLD_UNDERLINE,
						cmd.o_token[0],
						utils.RESET,
					)
					metadata.OST_UPDATE_METADATA_VALUE(collection_name, 3)
					break
				case false:
					fmt.printfln(
						"Failed to purge collection: %s%s%s",
						utils.BOLD,
						cmd.o_token[0],
						utils.RESET,
					)
					break
				}
			case false:
				fmt.printfln(
					"Collection: %s%s%s not found in OstrichDB.",
					utils.BOLD,
					cmd.o_token[0],
					utils.RESET,
				)
				utils.log_runtime_event(
					"Invalid PURGE command",
					"User tried to purge a collection that does not exist.",
				)
				break
			}
			break
		case const.CLUSTER:
			collection_name := cmd.o_token[0]
			cluster_name := cmd.o_token[1]
			if len(cmd.o_token) >= 2 && cmd.isUsingDotNotation == true {
				result := data.OST_PURGE_CLUSTER(collection_name, cluster_name)
				switch result {
				case true:
					fmt.printfln(
						"Successfully purged cluster: %s%s%s in collection: %s%s%s",
						utils.BOLD_UNDERLINE,
						cluster_name,
						utils.RESET,
						utils.BOLD_UNDERLINE,
						collection_name,
						utils.RESET,
					)
					break
				case false:
					fmt.printfln(
						"Failed to purge cluster: %s%s%s in collection: %s%s%s",
						utils.BOLD,
						cluster_name,
						utils.RESET,
						utils.BOLD,
						collection_name,
						utils.RESET,
					)
					break
				}
			}
			break
		case const.RECORD:
			collection_name := cmd.o_token[0]
			cluster_name := cmd.o_token[1]
			record_name := cmd.o_token[2]
			result := data.OST_PURGE_RECORD(collection_name, cluster_name, record_name)
			switch result {
			case true:
				fmt.printfln(
					"Successfully purged record: %s%s%s in cluster: %s%s%s in collection: %s%s%s",
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
				break
			case false:
				fmt.printfln(
					"Failed to purge record: %s%s%s in cluster: %s%s%s in collection: %s%s%s",
					utils.BOLD,
					record_name,
					utils.RESET,
					utils.BOLD,
					cluster_name,
					utils.RESET,
					utils.BOLD,
					collection_name,
					utils.RESET,
				)
				break
			}
			break
		}

		break
	//SIZE_OF command
	case const.SIZE_OF:
		utils.log_runtime_event("Used SIZE_OF command", "")
		if len(cmd.o_token) >= 1 {
			switch cmd.t_token {
			case const.COLLECTION:
				collection_name := cmd.o_token[0]
				file_path := fmt.tprintf(
					"%s%s%s",
					const.OST_COLLECTION_PATH,
					collection_name,
					const.OST_FILE_EXTENSION,
				)
				actual_size, metadata_size := metadata.OST_SUBTRACT_METADATA_SIZE(file_path)
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
			case const.CLUSTER:
				if cmd.isUsingDotNotation {
					collection_name := cmd.o_token[0]
					cluster_name := cmd.o_token[1]
					size, success := OST_GET_CLUSTER_SIZE(collection_name, cluster_name)
					if success {
						fmt.printf(
							"Size of cluster %s.%s: %d bytes\n",
							collection_name,
							cluster_name,
							size,
						)
					} else {
						fmt.printf(
							"Failed to get size of cluster %s.%s\n",
							collection_name,
							cluster_name,
						)
					}
				} else {
					fmt.println(
						"Invalid command. Use dot notation for clusters: SIZE_OF CLUSTER collection_name.cluster_name",
					)
				}
			case const.RECORD:
				if cmd.isUsingDotNotation && len(cmd.o_token) == 3 {
					collection_name := cmd.o_token[0]
					cluster_name := cmd.o_token[1]
					record_name := cmd.o_token[2]
					size, success := OST_GET_RECORD_SIZE(
						collection_name,
						cluster_name,
						record_name,
					)
					if success {
						fmt.printf(
							"Size of record %s.%s.%s: %d bytes\n",
							collection_name,
							cluster_name,
							record_name,
							size,
						)
					} else {
						fmt.printf(
							"Failed to get size of record %s.%s.%s\n",
							collection_name,
							cluster_name,
							record_name,
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
		} else {
			fmt.println("Incomplete SIZE_OF command. Please specify what to get the size of.")
		}
		break
	case const.ISOLATE:
		utils.log_runtime_event("Used ISOLATE command", "")
		switch cmd.t_token {
		case const.COLLECTION:
			if len(cmd.o_token) == 1 {
				collection_name := cmd.o_token[0]
				result := data.OST_PERFORM_ISOLATION(collection_name)
				switch result {
				case 0:
					fmt.printfln(
						"Successfully isolated collection: %s%s%s",
						utils.BOLD_UNDERLINE,
						collection_name,
						utils.RESET,
					)
					break
				case:
					fmt.println("Result ", result)
					fmt.printfln(
						"Failed to isolate collection: %s%s%s",
						utils.BOLD_UNDERLINE,
						collection_name,
						utils.RESET,
					)
					break
				}
			} else {
				fmt.printfln(
					"Incomplete command. Correct Usage: ISOLATE COLLECTION <collection_name>",
				)
			}
			break
		}
		break
	//END OF ACTION TOKEN EVALUATION
	case:
		fmt.printfln(
			"Invalid command: %s%s%s. Please enter a valid OstrichDB command. Enter 'HELP' for more information.",
			utils.BOLD_UNDERLINE,
			cmd.a_token,
			utils.RESET,
		)
		utils.log_runtime_event("Invalid command", "User entered an invalid command.")

	}
	return 1
}
