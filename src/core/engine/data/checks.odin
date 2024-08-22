package data
import "../../../utils"
import "../../const"
import "../../types"
import "core:fmt"
import "core:os"
import "core:strings"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//

//performs all data integrity checks on the passed collection and returns the results
OST_VALIDATE_DATA_INTEGRITY :: proc(fn: string) -> [dynamic]bool {
	checks := [dynamic]bool{}
	checkOneResult := OST_VALIDATE_IDS(fn)

	//integrity check one - cluster ids
	switch checkOneResult {
	case true:
		fmt.println("Cluster IDs in collection are compliant")
	case false:
		error1 := utils.new_err(
			.CLUSTER_IDS_NOT_VALID,
			utils.get_err_msg(.CLUSTER_IDS_NOT_VALID),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Cluster IDs in collection are not compliant", #procedure)
	}
	//do more checks here


	append(&checks, checkOneResult)
	return checks
}

//preform cluster_id compliancy check on the passed collection
OST_VALIDATE_IDS :: proc(fn: string) -> bool {
	types.data_integrity_checks.Cluster_IDs.Compliant = false
	idsFoundInCollection, idsAsStringArray := OST_GET_ALL_CLUSTER_IDS(fn)
	defer delete(idsFoundInCollection)
	defer delete(idsAsStringArray)

	for id in idsFoundInCollection {
		idFoundInCache := OST_CHECK_CACHE_FOR_ID(id)
		if idFoundInCache == true {
			types.data_integrity_checks.Cluster_IDs.Compliant = true
		} else {
			types.data_integrity_checks.Cluster_IDs.Compliant = false
			break
		}
	}
	return types.data_integrity_checks.Cluster_IDs.Compliant
}


//used on command line
OST_HANDLE_INTGRITY_CHECK_RESULT :: proc(fn: string) -> int {
	integrityResults := OST_VALIDATE_DATA_INTEGRITY(fn)
	for result in integrityResults {
		if result == false {
			fmt.printfln("%s%s[WARNING] [WARNING] [WARNING]%s", utils.BOLD, utils.RED, utils.RESET)
			fmt.printfln(
				"The Integrity of collection: %s%s%s was not validated.\nThe operation has been canceled and collection: %s%s%s will now be quarintined.",
				utils.BOLD,
				fn,
				utils.RESET,
				utils.BOLD,
				fn,
				utils.RESET,
			)
			fmt.println("For more information, please see the error log file.")
			return -1
		}
	}
	return 0
}
