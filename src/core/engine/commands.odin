package engine

import "../../utils"
import "../const"
import "../types"
import "./data"
import "./data/metadata"
import "./security"
import "core:fmt"
import "core:os"
import "core:strings"
/*
EXAMPLE USAGES OF ALL COMMANDS AND ARGS:

NEW COLLECTION car companies //creates file "car_industry.ost"
NEW CLUSTER car companies WITHIN COLLECTION car companies  //creates cluster called "car_companies" within "car_industry.ost
NEW RECORD Ford OF_TYPE STRING WITHISTRING WITHIN COLLECTION car companies //creates record called "Ford" within the "car_companies" cluster in "car_industry.ost
NEW RECORD Chevy AND Ferrarri OF_TYPE STRING WITHIN COLLECTION car companies //creates records called "Chevy" and "Ferrari" within the "car_companies" cluster in "car_industry.ost
ERASE RECORD Ford WITHIN COLLECTION car companies //deletes record "Ford" within the "car_companies" cluster in "car_industry.ost
FETCH ALL RECORD WITHIN COLLECTION NAMED car companies //would return all records within ANY cluster in "car_industry.ost
ERASE CLUSTER car companies WITHIN COLLECTION car companies //deletes cluster "car_companies" within "car_industry.ost
RENAME RECORD Chevy TO Chevrolet WITHIN COLLECTION car companies //renames record "Chevy" to "Chevrolet" within "car_companies" cluster in "car_industry.ost

*/

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
		break
	case const.HELP:
		//TODO: Implement help command
		utils.log_runtime_event("Used HELP command", "User requested help information.")
		break
	case const.UNFOCUS:
		utils.log_runtime_event(
			"Improperly used UNFOCUS command",
			"User requested to unfocus while not in FOCUS mode.",
		)
		fmt.printfln("Cannot Unfocus becuase you are currently not in focus mode.")
		break
	//=======================<MULTI-TOKEN COMMANDS>=======================//
	//BACKUP: Used in conjuction with COLLECTION to create a duplicate of all data within a collection
	case const.BACKUP:
		utils.log_runtime_event("Used BACKUP command", "User requested to backup data.")
		switch (cmd.t_token) {
		case const.COLLECTION:
			if len(cmd.o_token) > 0 {
				name := data.OST_CHOOSE_BACKUP_NAME()
				data.OST_CREATE_BACKUP_COLLECTION(name, cmd.o_token[0])

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
				fmt.printf("Creating collection '%s'\n", cmd.o_token[0])
				data.OST_CREATE_COLLECTION(cmd.o_token[0], 0)
			} else {
				fmt.println("Incomplete command. Correct Usage: NEW COLLECTION <collection_name>")
				utils.log_runtime_event(
					"Incomplete NEW command",
					"User did not provide a collection name to create.",
				)
			}
			break
		case const.CLUSTER:
			if len(cmd.o_token) >= 2 && const.WITHIN in cmd.m_token {
				cluster_name := cmd.o_token[0]
				collection_name := cmd.o_token[1]
				fmt.printf(
					"Creating cluster '%s' within collection '%s'\n",
					cluster_name,
					collection_name,
				)

				id := data.OST_GENERATE_CLUSTER_ID()
				result := data.OST_CREATE_CLUSTER_FROM_CL(collection_name, cluster_name, id)
				switch (result) 
				{
				case -1:
					fmt.printfln(
						"Cluster with name: %s%s%s already exists within collection %s%s%s. Failed to create cluster.",
						utils.BOLD,
						cluster_name,
						utils.RESET,
						utils.BOLD,
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
				fmt.printfln(
					"Incomplete command. Correct Usage: NEW CLUSTER <cluster_name> WITHIN COLLECTION <collection_name>",
				)
				utils.log_runtime_event(
					"Incomplete NEW command",
					"User did not provide a cluster name to create.",
				)
			}

			break
		case const.RECORD:
			if len(cmd.o_token) >= 2 && const.WITHIN in cmd.m_token {
				record_name := cmd.o_token[0]
				cluster_name := cmd.o_token[1]
				collection_name := cmd.o_token[2]
				fmt.printf(
					"Creating record '%s' within cluster '%s' in collection '%s'\n",
					record_name,
					cluster_name,
					collection_name,
				)
				// data.OST_CREATE_RECORD(cmd.o_token[0], cmd.o_token[1], cmd.o_token[2], 0)
				fn := OST_CONCAT_OBJECT_EXT(collection_name)
				metadata.OST_UPDATE_METADATA_VALUE(fn, 2)
				metadata.OST_UPDATE_METADATA_VALUE(fn, 3)
			} else {
				fmt.printfln(
					"Incomplete command. Correct Usage: NEW RECORD <record_name> WITHIN <Target>",
				)
				utils.log_runtime_event(
					"Incomplete NEW command",
					"User did not provide a record name to create.",
				)
			}
			break
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
				fmt.printf("Renaming collection '%s' to '%s'\n", old_name, new_name)
				data.OST_RENAME_COLLECTION(old_name, new_name)
			} else {
				fmt.println(
					"Incomplete command. Correct Usage: RENAME COLLECTION <old_name> TO <new_name>",
				)
			}
			break
		case const.CLUSTER:
			if len(cmd.o_token) >= 2 && const.WITHIN in cmd.m_token && const.TO in cmd.m_token {
				old_name := cmd.o_token[0]
				collection_name := cmd.o_token[1]
				new_name := cmd.m_token[const.TO]

				success := data.OST_RENAME_CLUSTER(collection_name, old_name, new_name)
				if success {
					fmt.printf(
						"Successfully renamed cluster '%s' to '%s' in collection '%s'\n",
						old_name,
						new_name,
						collection_name,
					)
					fn := OST_CONCAT_OBJECT_EXT(collection_name)
					metadata.OST_UPDATE_METADATA_VALUE(fn, 2)
					metadata.OST_UPDATE_METADATA_VALUE(fn, 3)
				} else {
					fmt.println(
						"Failed to rename cluster due to internal error. Please check error logs.",
					)
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
			if len(cmd.o_token) > 0 && const.TO in cmd.m_token {
				old_name := cmd.o_token[0]
				new_name := cmd.m_token[const.TO]
				fmt.printf("Renaming record '%s' to '%s'\n", old_name, new_name)
				// data.OST_RENAME_RECORD(old_name, new_name)
			} else {
				fmt.println(
					"Incomplete command. Correct Usage: RENAME RECORD <old_name> WITHIN CLUSTER <cluster_name> WITHIN COLLECTION <collection_name> TO <new_name>",
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
		//bug todo see https://github.com/Solitude-Software-Solutions/OstrichDB/issues/29
		switch (cmd.t_token) 
		{
		case const.COLLECTION:
			if data.OST_ERASE_COLLECTION(cmd.o_token[0]) {
				fmt.printfln(
					"Collection %s%s%s successfully erased",
					utils.BOLD,
					cmd.o_token[0],
					utils.RESET,
				)
			}
			break
		case const.CLUSTER:
			if len(cmd.o_token) >= 2 && const.WITHIN in cmd.m_token {
				collection_name := cmd.o_token[1]
				cluster := cmd.o_token[0]
				if data.OST_ERASE_CLUSTER(collection_name, cluster) {
					fmt.printfln(
						"Cluster %s%s%s successfully erased from collection %s%s%s",
						utils.BOLD,
						cluster,
						utils.RESET,
						utils.BOLD,
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
			break
		case:
			fmt.printfln("Invalid command structure. Correct Usage: ERASE <Target> <Targets_name>")
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
				data.OST_FETCH_COLLECTION(collection)
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
			if len(cmd.o_token) >= 2 && const.WITHIN in cmd.m_token {
				collection := cmd.o_token[1]
				cluster := cmd.o_token[0]
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
			break
		case:
			fmt.printfln("Invalid command structure. Correct Usage: FETCH <Target> <Targets_name>")
			utils.log_runtime_event(
				"Invalid FETCH command",
				"User did not provide a valid target.",
			)
		}
		break
	//FOCUS and UNFOCUS: Enter at own peril.
	case const.FOCUS:
		utils.log_runtime_event("Used FOCUS command", "")

		switch (cmd.t_token) 
		{
		case const.COLLECTION:
			types.focus.flag = true
			if len(cmd.o_token) > 0 {
				collection := cmd.o_token[0]
				storedT, storedO := OST_FOCUS(const.COLLECTION, collection)
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
		case const.CLUSTER:
			types.focus.flag = true
			if len(cmd.o_token) >= 2 && const.WITHIN in cmd.m_token {
				cluster := cmd.o_token[0]
				collection := cmd.o_token[1]
				storedT, storedO := OST_FOCUS(collection, cluster) //storing the Target and Objec that the user wants to focus)
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
		//todo: come back to this..havent done enough commands to test this in focus mode yet
		case const.RECORD:
			types.focus.flag = true
			if len(cmd.o_token) >= 3 && const.WITHIN in cmd.m_token {
				record := cmd.o_token[0]
				cluster := cmd.o_token[1]
				collection := cmd.o_token[2]
				storedParentT, storedParentO, storedRO := OST_FOCUS_RECORD(
					collection,
					cluster,
					record,
				)
				fmt.printfln(
					"Focused on record %s%s%s in cluster %s%s%s within collection %s%s%s",
					utils.BOLD,
					record,
					utils.RESET,
					utils.BOLD,
					cluster,
					utils.RESET,
					utils.BOLD,
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
			utils.BOLD,
			cmd.a_token,
			utils.RESET,
		)
		utils.log_runtime_event("Invalid command", "User entered an invalid command.")
	}
	return 0
}


EXECUTE_COMMANDS_WHILE_FOCUSED :: proc(
	cmd: ^types.Command,
	focusTarget: string,
	focusObject: string,
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
	case const.HELP:
		utils.log_runtime_event(
			"Used HELP command while in FOCUS mode",
			"Displaying help menu for FOCUS mode",
		)
		//do stuff
		break
	case const.UNFOCUS:
		types.focus.flag = false
		utils.log_runtime_event("Used UNFOCUS command", "User has succesfully exited FOCUS mode")
		break
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
				success := data.OST_CREATE_CLUSTER_FROM_CL(collection_name, cluster_name, id)
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
		//bug: todo see https://github.com/Solitude-Software-Solutions/OstrichDB/issues/29
		switch (cmd.t_token) 
		{
		case const.COLLECTION:
			fmt.println("Cannot erase a collection while in FOCUS mode.")
			break
		case const.CLUSTER:
			if len(cmd.o_token) >= 1 {
				cluster_name := cmd.o_token[0]
				collection_name := focusObject
				data.OST_ERASE_CLUSTER(collection_name, cluster_name)
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
				old_name := cmd.o_token[0]
				new_name := cmd.m_token[const.TO]
				collection_name := focusObject
				fmt.printfln(
					"Renaming cluster '%s' to '%s' in collection '%s'...",
					old_name,
					new_name,
					collection_name,
				)
				success := data.OST_RENAME_CLUSTER(collection_name, old_name, new_name)
				if success {
					fmt.printf(
						"Successfully renamed cluster '%s' to '%s' in collection '%s'\n",
						old_name,
						new_name,
						collection_name,
					)
					fn := OST_CONCAT_OBJECT_EXT(collection_name)
					metadata.OST_UPDATE_METADATA_VALUE(fn, 2)
					metadata.OST_UPDATE_METADATA_VALUE(fn, 3)
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
			utils.BOLD,
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
