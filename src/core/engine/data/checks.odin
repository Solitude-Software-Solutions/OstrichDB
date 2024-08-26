package data
import "../../../utils"
import "../../const"
import "../../types"
import "/metadata"
import "core:fmt"
import "core:os"
import "core:strings"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//


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

//preform file size check on the passed collection
OST_VALIDATE_FILE_SIZE :: proc(fn: string) -> bool {
	types.Severity_Code = 0
	types.data_integrity_checks.File_Size.Compliant = true
	fileInfo := metadata.OST_GET_FS(
		fmt.tprintf("%s%s%s", const.OST_COLLECTION_PATH, fn, const.OST_FILE_EXTENSION),
	)
	fileSize := fileInfo.size

	if fileSize > const.MAX_FILE_SIZE {
		types.data_integrity_checks.File_Size.Compliant = false
	}
	return types.data_integrity_checks.File_Size.Compliant
}

//preform collection format check on the passed collection
OST_VALIDATE_COLLECTION_FORMAT :: proc(fn: string) -> bool {
	types.data_integrity_checks.File_Format.Compliant = true

	clusterScanSuccess, invalidClusterFound := OST_SCAN_CLUSTER_STRUCTURE(fn)
	headerScanSuccess, invalidHeaderFound := metadata.OST_SCAN_METADATA_HEADER_FORMAT(fn)
	if clusterScanSuccess != 0 || invalidClusterFound == true {
		types.data_integrity_checks.File_Format.Compliant = false

	}
	if headerScanSuccess != 0 || invalidHeaderFound == true {
		types.data_integrity_checks.File_Format.Compliant = false
	}

	return types.data_integrity_checks.File_Format.Compliant
}


//performs all data integrity checks on the passed collection and returns the results
OST_VALIDATE_DATA_INTEGRITY :: proc(fn: string) -> [dynamic]bool {
	checks := [dynamic]bool{}
	checkOneResult := OST_VALIDATE_IDS(fn)
	checkTwoResult := OST_VALIDATE_FILE_SIZE(fn)
	checkThreeResult := OST_VALIDATE_COLLECTION_FORMAT(fn)
	//integrity check one - cluster ids
	switch checkOneResult {
	case false:
		types.Severity_Code = 2
		error1 := utils.new_err(
			.CLUSTER_IDS_NOT_VALID,
			utils.get_err_msg(.CLUSTER_IDS_NOT_VALID),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Cluster IDs in collection are not compliant", #procedure)
	}
	//integrity check two - file size
	switch checkTwoResult {
	case false:
		types.Severity_Code = 0
		error2 := utils.new_err(
			.FILE_SIZE_TOO_LARGE,
			utils.get_err_msg(.FILE_SIZE_TOO_LARGE),
			#procedure,
		)
		utils.throw_err(error2)
		utils.log_err("File size is not compliant", #procedure)
	}
	switch checkThreeResult {
	case false:
		types.Severity_Code = 2
		error3 := utils.new_err(
			.FILE_FORMAT_NOT_VALID,
			utils.get_err_msg(.FILE_FORMAT_NOT_VALID),
			#procedure,
		)
		utils.throw_err(error3)
		utils.log_err("Collection format is not compliant", #procedure)
	}
	//do more checks here


	append(&checks, checkOneResult)
	append(&checks, checkTwoResult)
	append(&checks, checkThreeResult)

	return checks
}

//handles the results of the data integrity checks...duh
OST_HANDLE_INTGRITY_CHECK_RESULT :: proc(fn: string) -> int {
	integrityResults := OST_VALIDATE_DATA_INTEGRITY(fn)
	for result in integrityResults {
		if result == false {
			if types.Severity_Code == 0 {
				types.Message_Color = utils.YELLOW
				fmt.println(utils.show_check_warning())
			} else if types.Severity_Code == 1 {
				types.Message_Color = utils.ORANGE
				fmt.println(utils.show_check_warning())
			} else if types.Severity_Code == 2 {
				types.Message_Color = utils.RED
				fmt.println(utils.show_check_warning())
			}

			fmt.printfln(
				"OstrichDB was unable to validate the integrity of collection: %s%s%s.\nThe operation has been canceled and collection: %s%s%s will now be quarintined.",
				utils.BOLD,
				fn,
				utils.RESET,
				utils.BOLD,
				fn,
				utils.RESET,
			)
			fmt.println("For more information, please see the error log file.")
			OST_QURANTINE_COLLECTION(fn)
			return -1
		}
	}
	return 0
}
