package commands

import "../../errors"
import "../../misc"
import "../const"
import "../data"
import "../security"
import "../types"
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
	incompleteCommandErr := errors.new_err(
		.INCOMPLETE_COMMAND,
		errors.get_err_msg(.INCOMPLETE_COMMAND),
		#procedure,
	)

	invalidCommandErr := errors.new_err(
		.INVALID_COMMAND,
		errors.get_err_msg(.INVALID_COMMAND),
		#procedure,
	)
	defer delete(cmd.o_token)


	switch (cmd.a_token)
	{
	//=======================<SINGLE-TOKEN COMMANDS>=======================//
	case const.VERSION:
		fmt.printfln(
			"Using OstrichDB Version: %s%s%s",
			misc.BOLD,
			misc.get_ost_version(),
			misc.RESET,
		)
		break
	case const.EXIT:
		//logout then exit the program
		security.OST_USER_LOGOUT(1)
	case const.LOGOUT:
		//only returns user to signin.
		fmt.printfln("Logging out...")
		security.OST_USER_LOGOUT(0)
		break
	case const.HELP:
		//TODO: Implement help command
		break
	//=======================<MULTI-TOKEN COMMANDS>=======================//

	//NEW: Allows for the creation of new records, clusters, or collections
	case const.NEW:
		switch (cmd.t_token) {
		case const.COLLECTION:
			if len(cmd.o_token) > 0 {
				fmt.printf("Creating collection '%s'\n", cmd.o_token[0])
				data.OST_CREATE_COLLECTION(cmd.o_token[0], 0)
			} else {
				errors.throw_custom_err(
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
				if !success {
					fmt.println("Failed to create cluster. Please check error messages.")
				}
			} else {
				errors.throw_custom_err(
					invalidCommandErr,
					"Invalid NEW command structure. Correct Usage: NEW CLUSTER <cluster_name> WITHIN COLLECTION <collection_name>",
				)
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
				errors.throw_custom_err(
					invalidCommandErr,
					"Invalid NEW command structure. Correct Usage: NEW RECORD <record_name> WITHIN CLUSTER <cluster_name> IN COLLECTION <collection_name>",
				)
			}
			break
		}
		break
	//RENAME: Allows for the renaming of collections, clusters, or individual record names
	case const.RENAME:
		switch (cmd.t_token)
		{
		case const.COLLECTION:
			if len(cmd.o_token) > 0 && const.TO in cmd.m_token {
				old_name := cmd.o_token[0]
				new_name := cmd.m_token[const.TO]
				fmt.printf("Renaming collection '%s' to '%s'\n", old_name, new_name)
				data.OST_RENAME_COLLECTION(old_name, new_name)
			} else {
				errors.throw_custom_err(
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
				errors.throw_custom_err(
					invalidCommandErr,
					"Invalid RENAME command structure. Correct Usage: RENAME RECORD <old_name> TO <new_name>",
				)
			}
			break
		}
		break

	// ERASE: Allows for the deletion of collections, specific clusters, or individual records within a cluster
	case const.ERASE:
		switch (cmd.t_token)
		{
		case const.COLLECTION:
			if data.OST_ERASE_COLLECTION(cmd.o_token[0]) {
				fmt.printfln(
					"Collection %s%s%s successfully erased",
					misc.BOLD,
					cmd.o_token[0],
					misc.RESET,
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
						misc.BOLD,
						cluster,
						misc.RESET,
						misc.BOLD,
						collection,
						misc.RESET,
					)
				}
			} else {
				errors.throw_custom_err(
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
		switch (cmd.t_token)
		{
		case const.COLLECTION:
			if len(cmd.o_token) > 0 {
				collection := cmd.o_token[0]
				data.OST_FETCH_COLLECTION(collection)
			} else {
				errors.throw_custom_err(
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
				errors.throw_custom_err(
					invalidCommandErr,
					"Invalid FETCH command structure. Correct Usage: FETCH CLUSTER <cluster_name> WITHIN COLLECTION <collection_name>",
				)
			}
			break
		case const.RECORD:
			break
		}
		break
	//FOCUS and UNFOCUS
	//Such a cluster fuck enter at own peril
	case const.FOCUS:
	    types.focus.flag = true
		switch (cmd.t_token)
            {
            case const.COLLECTION:
                  if len(cmd.o_token) > 0 {
                      collection := cmd.o_token[0]
                      types.focus.t_ = const.COLLECTION
                      types.focus.o_ = collection
                      fmt.printf("Focus set to COLLECTION %s\n", collection)
                  } else {
                      errors.throw_custom_err(
                          invalidCommandErr,
                          "Invalid FOCUS command structure. Correct Usage: FOCUS COLLECTION <collection_name>",
                      )
            }
		break
		case const.CLUSTER:
        if len(cmd.o_token) > 0 {
            cluster := cmd.o_token[0]
            if within, exists := cmd.m_token["WITHIN"]; exists && within == const.COLLECTION {
                if collection, exists := cmd.s_token["COLLECTION"]; exists {
                    types.focus.t_ = const.CLUSTER
                    types.focus.o_ = cluster
                    types.focus.parent_t_ = const.COLLECTION
                    types.focus.parent_o_ = collection
                    fmt.printf("Focus set to CLUSTER %s WITHIN COLLECTION %s\n", cluster, collection)
                } else {
                    errors.throw_custom_err(
                        invalidCommandErr,
                        "Invalid FOCUS command structure. Missing COLLECTION name.",
                    )
                }
            } else {
                types.focus.t_ = const.CLUSTER
                types.focus.o_ = cluster
                types.focus.parent_t_ = ""
                types.focus.parent_o_ = ""
                fmt.printf("Focus set to CLUSTER %s\n", cluster)
            }
        } else {
            errors.throw_custom_err(
                invalidCommandErr,
                "Invalid FOCUS command structure. Correct Usage: FOCUS CLUSTER <cluster_name> [WITHIN COLLECTION <collection_name>]",
            )
        }
        break
	}
	break
	}
	return 0
}

//todo still working on focus and unfocus
