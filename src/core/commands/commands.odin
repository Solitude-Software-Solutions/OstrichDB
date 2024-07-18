package commands

import "../../errors"
import "../../misc"
import "../data"
import "../security"
import "../types"
import "core:fmt"
import "core:os"
import "core:strings"


//Standard Command Tokens
VERSION :: "VERSION"
HELP :: "HELP"
EXIT :: "EXIT"
LOGOUT :: "LOGOUT"

//Action Tokens-- Require a space before and after the prefix and atleast one argument
NEW :: "NEW" //used to create a new record, cluster, or collection
ERASE :: "ERASE" //used to delete a record, cluster, or collection
FETCH :: "FETCH" //used to get the data from a record, cluster, or collection
RENAME :: "RENAME" //used to change the name of a record, cluster, or collection

//Target Tokens -- Require a data to be used
COLLECTION :: "COLLECTION" //Targets a collection to be manupulated
CLUSTER :: "CLUSTER" //Targets a cluster to be manipulated
RECORD :: "RECORD" //Targets a record to be manipulated
ALL :: "ALL" //Targets all records, clusters, or collections that are specified

//Modifier Tokens
AND :: "AND" //used to specify that there is another record, cluster, or collection to be created
OF_TYPE :: "OF_TYPE" //ONLY used to specify the type of data that is going to be stored in a record...see types below
ALL_OF :: "ALL_OF" //ONLY used with FETCH and ERASE.
TO :: "TO" //ONLY used with RENAME

//Scope Tokens
WITHIN :: "WITHIN" //used to specify where the record, cluster, or collection is going to be created


//Type Tokens -- Requires a special datas as a prefix
STRING :: "STRING"
INT :: "INT"
FLOAT :: "FLOAT"
BOOL :: "BOOL"
//might add more...doubtful though

/*
EXAMPLE USAGES OF ALL COMMANDS AND ARGS:

NEW COLLECTION car companies //creates file "car_industry.ost"
NEW CLUSTER car companies WITHIN COLLECTION car companies  //creates cluster called "car_companies" within "car_industry.ost
NEW RECORD Ford OF_TYPE STRING WITHIN COLLECTION car companies //creates record called "Ford" within the "car_companies" cluster in "car_industry.ost
NEW RECORD Chevy AND Ferrarri OF_TYPE STRING WITHIN COLLECTION car companies //creates records called "Chevy" and "Ferrari" within the "car_companies" cluster in "car_industry.ost
ERASE RECORD Ford WITHIN COLLECTION car companies //deletes record "Ford" within the "car_companies" cluster in "car_industry.ost
FETCH ALL RECORD WITHIN COLLECTION NAMED car companies //would return all records within ANY cluster in "car_industry.ost
ERASE CLUSTER car companies WITHIN COLLECTION car companies //deletes cluster "car_companies" within "car_industry.ost
RENAME RECORD Chevy TO Chevrolet WITHIN COLLECTION car companies //renames record "Chevy" to "Chevrolet" within "car_companies" cluster in "car_industry.ost

*/


OST_EXECUTE_COMMAND :: proc(cmd: ^types.OST_Command) -> int {
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
	case VERSION:
		fmt.printfln(
			"Using OstrichDB Version: %s%s%s",
			misc.BOLD,
			misc.get_ost_version(),
			misc.RESET,
		)
		break
	case EXIT:
		//logout then exit the program
		security.OST_USER_LOGOUT(1)
	case LOGOUT:
		//only returns user to signin.
		fmt.printfln("Logging out...")
		security.OST_USER_LOGOUT(0)
		break
	case HELP:
		//TODO: Implement help command
		break
	//=======================<MULTI-TOKEN COMMANDS>=======================//

	//NEW: Allows for the creation of new records, clusters, or collections
	case NEW:
		switch (cmd.t_token) {
		case COLLECTION:
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
		case CLUSTER:
			if len(cmd.o_token) >= 2 && WITHIN in cmd.m_token {
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
		case RECORD:
			if len(cmd.o_token) >= 2 && WITHIN in cmd.m_token {
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
	case RENAME:
		switch (cmd.t_token) 
		{
		case COLLECTION:
			if len(cmd.o_token) > 0 && TO in cmd.m_token {
				old_name := cmd.o_token[0]
				new_name := cmd.m_token[TO]
				fmt.printf("Renaming collection '%s' to '%s'\n", old_name, new_name)
				data.OST_RENAME_COLLECTION(old_name, new_name)
			} else {
				errors.throw_custom_err(
					invalidCommandErr,
					"Invalid RENAME command structure. Correct Usage: RENAME COLLECTION <old_name> TO <new_name>",
				)
			}
			break
		case CLUSTER:
			if len(cmd.o_token) >= 2 && WITHIN in cmd.m_token && TO in cmd.m_token {
				old_name := cmd.o_token[0]
				collection := cmd.o_token[1]
				new_name := cmd.m_token[TO]

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
		case RECORD:
			if len(cmd.o_token) > 0 && TO in cmd.m_token {
				old_name := cmd.o_token[0]
				new_name := cmd.m_token[TO]
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
	//ERASE: Allows for the deletion of collections, specific clusters, or individual records within a cluster

	// case ERASE:
	//    switch(cmd.t_token)
	// 			{

	// 			}

	}
	return 0
}
