package data
import "../../../utils"
import "../../const"
import "../../types"
import "/metadata"
import "core:fmt"
import "core:os"
import "core:strings"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-2025 Marshall A Burns and Solitude Software Solutions LLC
Copyright (c) 2025-Present Archetype Dynamics, Inc.

File Description:
            Contains logic for performing data integrity checks on collections.
            This includes checking for valid cluster IDs, file size, collection
            format, and checksum.
*********************************************************/


//perform cluster_id compliancy check on the passed collection
VALIDATE_IDS :: proc(fn: string) -> bool {
	types.data_integrity_checks.Cluster_IDs.Compliant = true // Assume compliant initially

	//See GitHub issue #199 for more information about why this is commented out

	// idsFoundInCollection, idsAsStringArray := GET_ALL_CLUSTER_IDS(fn)
	// defer delete(idsFoundInCollection)
	// defer delete(idsAsStringArray)

	// for id in idsFoundInCollection {
	// 	idFoundInCache := CHECK_IF_CLUSTER_ID_EXISTS(id)
	// 	if !idFoundInCache {
	// 		log_err(fmt.tprintf("Cluster ID %v not found in cache", id), #procedure)
	// 		types.data_integrity_checks.Cluster_IDs.Compliant = false
	// 		break
	// 	}
	// }
	return types.data_integrity_checks.Cluster_IDs.Compliant
}

//perform file size check on the passed collection
VALIDATE_FILE_SIZE :: proc(fn: string) -> bool {
	using const
	using types
	using utils

	Severity_Code = 0
	data_integrity_checks.File_Size.Compliant = true
	fileInfo := metadata.GET_FILE_INFO(concat_standard_collection_name(fn))
	fileSize := fileInfo.size

	if fileSize > MAX_FILE_SIZE {
		utils.log_err("File size is too large", #procedure)
		data_integrity_checks.File_Size.Compliant = false
	}
	return data_integrity_checks.File_Size.Compliant
}

//perform collection format check on the passed collection
VALIDATE_COLLECTION_FORMAT :: proc(fn: string) -> bool {
	using types

	data_integrity_checks.File_Format.Compliant = true
	clusterScanSuccess, invalidClusterFound := SCAN_CLUSTER_STRUCTURE(fn)
	// headerScanSuccess, invalidHeaderFound := metadata.SCAN_METADATA_HEADER_FORMAT(fn)
	if clusterScanSuccess != 0 || invalidClusterFound == true {
		utils.log_err("Cluster structure is not compliant", #procedure)
		data_integrity_checks.File_Format.Compliant = false

	}
	// if headerScanSuccess != 0 || invalidHeaderFound == true {
	// 	utils.log_err("Header format is not compliant", #procedure)
	// 	data_integrity_checks.File_Format.Compliant = false
	// }
	return data_integrity_checks.File_Format.Compliant
}

VALIDATE_CHECKSUM :: proc(fn: string) -> bool {
	using types

	data_integrity_checks.Checksum.Compliant = true
	filePath := utils.concat_standard_collection_name(fn)

	data, err := utils.read_file(filePath, #procedure)
	defer delete(data)
	if err != true {
		utils.log_err("Error reading file", #procedure)
		data_integrity_checks.Checksum.Compliant = false
		return data_integrity_checks.Checksum.Compliant
	}

	content := string(data)
	lines := strings.split(content, "\n")

	defer delete(lines)

	storedChecksum := ""

	for line in lines {
		if strings.contains(line, "# Checksum:") {
			storedChecksum = strings.split(line, ": ")[1]
			break
		}
	}

	currentChecksum := metadata.GENERATE_CHECKSUM(filePath)

	if storedChecksum != currentChecksum {
		utils.log_err("Checksums do not match", #procedure)
		data_integrity_checks.Checksum.Compliant = false
	}

	return data_integrity_checks.Checksum.Compliant
}


//performs all data integrity checks on the passed collection and returns the results
VALIDATE_DATA_INTEGRITY :: proc(fn: string) -> (checkStatus: [dynamic]bool) {
	using types
	using utils

	checks := make([dynamic]bool) //gets freed in the parent calling procedure
	checkOneResult := VALIDATE_IDS(fn)
	checkTwoResult := VALIDATE_FILE_SIZE(fn)
	checkThreeResult := VALIDATE_COLLECTION_FORMAT(fn)
	checkFourResult := VALIDATE_CHECKSUM(fn)
	//integrity check one - cluster ids
	switch checkOneResult {
	case false:
		data_integrity_checks.Cluster_IDs.Severity = .MEDIUM
		Severity_Code = 1
		errorLocation:= get_caller_location()
		error1 := utils.new_err(
			.CLUSTER_IDS_NOT_VALID,
			get_err_msg(.CLUSTER_IDS_NOT_VALID),
			errorLocation
		)
		throw_err(error1)
		log_err("Cluster IDs in collection are not compliant", #procedure)
	case:
	}
	//integrity check two - file size
	switch checkTwoResult {
	case false:
		data_integrity_checks.File_Size.Severity = .LOW
		Severity_Code = 0
		errorLocation:= get_caller_location()
		error2 := utils.new_err(
			.FILE_SIZE_TOO_LARGE,
			get_err_msg(.FILE_SIZE_TOO_LARGE),
			errorLocation
		)
		throw_err(error2)
		log_err("File size is not compliant", #procedure)
	}
	//integrity check three - collection formatting
	switch checkThreeResult {
	case false:
		data_integrity_checks.File_Format.Severity = .HIGH
		Severity_Code = 2
		errorLocation:= get_caller_location()
		error3 := new_err(
			.FILE_FORMAT_NOT_VALID,
			get_err_msg(.FILE_FORMAT_NOT_VALID),
			errorLocation
		)
		throw_err(error3)
		log_err("Collection format is not compliant", #procedure)
	}
	//integrity check four - checksum
	switch checkFourResult {
	case false:
		data_integrity_checks.Checksum.Severity = .HIGH
		Severity_Code = 2
		errorLocation:= get_caller_location()
		error4 := new_err(
			.INVALID_CHECKSUM,
			utils.get_err_msg(.INVALID_CHECKSUM),
			errorLocation
		)
		throw_err(error4)
		log_err("Checksum is not compliant", #procedure)
	}

	//append other check results here
	append(&checks, checkOneResult, checkTwoResult, checkThreeResult, checkFourResult)
	return checks
}

//handles the results of the data integrity checks...duh
HANDLE_INTEGRITY_CHECK_RESULT :: proc(fn: string) -> int {
	using types
	using utils

	integrityResults := VALIDATE_DATA_INTEGRITY(fn)
	defer delete(integrityResults)
	for result in integrityResults {
		if result == false {
			if Severity_Code == 0 {
				Message_Color = YELLOW
				fmt.println(show_check_warning())
			} else if Severity_Code == 1 {
				Message_Color = ORANGE
				fmt.println(show_check_warning())
			} else if Severity_Code == 2 {
				Message_Color = RED
				fmt.println(show_check_warning())
			}

			fmt.printfln(
				"OstrichDB was unable to validate the integrity of collection: %s%s%s.\nThe operation has been canceled and collection: %s%s%s will now be quarantined.",
				BOLD_UNDERLINE,
				fn,
				RESET,
				BOLD_UNDERLINE,
				fn,
				RESET,
			)
			fmt.printfln(
				"Status of the all checks:\n%s: %v\n%s: %v\n%s: %v\n%s: %v",
				"Cluster ID Compliancy Passed",
				data_integrity_checks.Cluster_IDs.Compliant,
				"File Size Passed",
				data_integrity_checks.File_Size.Compliant,
				"Collection Format Passed",
				data_integrity_checks.File_Format.Compliant,
				"Checksum Passed",
				data_integrity_checks.Checksum.Compliant,
			)
			fmt.println("For more information, please see the error log file.")
			PERFORM_COLLECTION_ISOLATION(fn)
			return -1
		}
	}
	return 0
}
