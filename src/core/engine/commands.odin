package engine

import "../../utils"
import "../const"
import "../types"
import "./data"
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
				utils.throw_custom_err(
					invalidCommandErr,
					"Invalid BACKUP command structure. Correct Usage: BACKUP COLLECTION <collection_name>",
				)
			}
			break
		case const.CLUSTER, const.RECORD:
			fmt.println(
				"Backing up a cluster or record is not allowed please backup a collection instead.",
			)
			break
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
				utils.throw_custom_err(
					invalidCommandErr,
					"Invalid NEW command structure. Correct Usage: NEW COLLECTION <collection_name>",
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
				success := data.OST_CREATE_CLUSTER_FROM_CL(collection_name, cluster_name, id)
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
			}
			break
		case const.RECORD:
			if len(cmd.o_token) >= 2 && const.WITHIN in cmd.m_token {
				fmt.printf(
					"Creating record '%s' within cluster '%s' in collection '%s'\n",
					cmd.o_token[0],
					cmd.o_token[1],
					cmd.o_token[2],
				)
				// data.OST_CREATE_RECORD(cmd.o_token[0], cmd.o_token[1], cmd.o_token[2], 0)
			} else {
				utils.throw_custom_err(
					invalidCommandErr,
					"Invalid NEW command structure. Correct Usage: NEW RECORD <record_name> WITHIN CLUSTER <cluster_name> IN COLLECTION <collection_name>",
				)
			}
			break
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
				utils.throw_custom_err(
					invalidCommandErr,
					"Invalid RENAME command structure. Correct Usage: RENAME COLLECTION <old_name> TO <new_name>",
				)
			}
			break
		case const.CLUSTER:
			if len(cmd.o_token) >= 2 && const.WITHIN in cmd.m_token && const.TO in cmd.m_token {
				old_name := cmd.o_token[0]
				collection := cmd.o_token[1]
				new_name := cmd.m_token[const.TO]

				success := data.OST_RENAME_CLUSTER(collection, old_name, new_name)
				if success {
					fmt.printf(
						"Successfully renamed cluster '%s' to '%s' in collection '%s'\n",
						old_name,
						new_name,
						collection,
					)
				} else {
					fmt.println("Failed to rename cluster. Please check error messages.")
				}
			}
			break
		case const.RECORD:
			if len(cmd.o_token) > 0 && const.TO in cmd.m_token {
				old_name := cmd.o_token[0]
				new_name := cmd.m_token[const.TO]
				fmt.printf("Renaming record '%s' to '%s'\n", old_name, new_name)
				// data.OST_RENAME_RECORD(old_name, new_name)
			} else {
				utils.throw_custom_err(
					invalidCommandErr,
					"Invalid RENAME command structure. Correct Usage: RENAME RECORD <old_name> TO <new_name>",
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
				collection := cmd.o_token[1]
				cluster := cmd.o_token[0]
				if data.OST_ERASE_CLUSTER(collection, cluster) {
					fmt.printfln(
						"Cluster %s%s%s successfully erased from collection %s%s%s",
						utils.BOLD,
						cluster,
						utils.RESET,
						utils.BOLD,
						collection,
						utils.RESET,
					)
				}
			} else {
				utils.throw_custom_err(
					invalidCommandErr,
					"Invalid ERASE command structure. Correct Usage: ERASE CLUSTER <cluster_name> WITHIN COLLECTION <collection_name>",
				)
			}
			break
		case const.RECORD:
			break
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
				utils.throw_custom_err(
					invalidCommandErr,
					"Invalid FETCH command structure. Correct Usage: FETCH COLLECTION <collection_name>",
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
				utils.throw_custom_err(
					invalidCommandErr,
					"Invalid FETCH command structure. Correct Usage: FETCH CLUSTER <cluster_name> WITHIN COLLECTION <collection_name>",
				)
			}
			break
		case const.RECORD:
			break
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
				utils.throw_custom_err(
					invalidCommandErr,
					"Invalid NEW command structure. Correct Usage: NEW COLLECTION <collection_name>",
				)
			}
			break
		case const.CLUSTER:
			types.focus.flag = true
			if len(cmd.o_token) >= 2 && const.WITHIN in cmd.m_token {
				cluster := cmd.o_token[0]
				collection := cmd.o_token[1]
				storedT, storedO := OST_FOCUS(collection, cluster) //storing the Target and Objec that the user wants to focus)
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
			}
			break
		case:
			fmt.printfln(
				"Invalid FOCUS command structure. Correct Usage: FOCUS <collection_name> or FOCUS <cluster_name> WITHIN COLLECTION <collection_name>",
			)
			break
		}

		break
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
			}
			break
		case const.RECORD:
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
				utils.throw_custom_err(
					invalidCommandErr,
					"Invalid FETCH command structure. Correct Usage: FETCH CLUSTER <cluster_name>",
				)
			}
			break
		case const.RECORD:
			break
		}
		break
	case const.ERASE:
		utils.log_runtime_event("Used ERASE command while in FOCUS mode", "")
		//bug: todo see https://github.com/Solitude-Software-Solutions/OstrichDB/issues/29
		switch (cmd.t_token) 
		{
		case const.COLLECTION:
			fmt.printf("Cannot erase a collection while in FOCUS mode...\n")
			break
		case const.CLUSTER:
			if len(cmd.o_token) >= 1 {
				cluster_name := cmd.o_token[0]
				collection_name := focusObject
				data.OST_ERASE_CLUSTER(collection_name, cluster_name)
			}
			break
		case const.RECORD:
			break
		}
		break
	case const.RENAME:
		utils.log_runtime_event("Used RENAME command while in FOCUS mode", "")
		switch (cmd.t_token) 
		{
		case const.COLLECTION:
			fmt.printf("Cannot rename a collection while in FOCUS mode...\n")
			break
		case const.CLUSTER:
			if len(cmd.o_token) >= 1 && const.TO in cmd.m_token {
				old_name := cmd.o_token[0]
				new_name := cmd.m_token[const.TO]
				collection := focusObject
				fmt.printfln(
					"Renaming cluster '%s' to '%s' in collection '%s'...",
					old_name,
					new_name,
					collection,
				)
				success := data.OST_RENAME_CLUSTER(collection, old_name, new_name)
				if success {
					fmt.printf(
						"Successfully renamed cluster '%s' to '%s' in collection '%s'\n",
						old_name,
						new_name,
						collection,
					)
				} else {
					fmt.println("Failed to rename cluster. Please check error messages.")
				}
				break
			}
		case const.RECORD:
			break
		}
		break

	}
	return 0
}
