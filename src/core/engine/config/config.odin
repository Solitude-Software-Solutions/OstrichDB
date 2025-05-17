package config

import "../../../utils"
import "../../const"
import "../../types"
import "../data"
import "../data/metadata"
import "core:fmt"
import "core:os"
import "core:strings"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            Implements the configuration functionality for OstrichDB, allowing
            users to set and get configuration values. Also contains key
            procedures for automatically creating and updating the config file.
*********************************************************/
main :: proc() {
	using data
	CREATE_COLLECTION("", .SYSTEM_CONFIG_PRIVATE)
	id := GENERATE_ID(true)
	APPEND_ID_TO_ID_COLLECTION(fmt.tprintf("%d", id), 0)
	CREATE_CLUSTER_BLOCK(const.SYSTEM_CONFIG_PATH, id, const.SYSTEM_CONFIG_CLUSTER)
	appendSuccess := APPEND_ALL_CONFIGS_TO_CONFIG_FILE(types.CollectionType.SYSTEM_CONFIG_PRIVATE)
	if !appendSuccess {
		utils.log_err("Failed to append system configs", #procedure)
		fmt.println("ERROR: Failed to append system configs")
		fmt.println("Please rebuild OstrichDB")
	}
}

CHECK_IF_SYSTEM_CONFIG_FILE_EXISTS :: proc() -> bool {
	using utils
	configExists: bool
	binDir, e := os.open(const.PRIVATE_PATH)
	defer os.close(binDir)

	foundFiles, readDirSuccess := os.read_dir(binDir, -1)

	if readDirSuccess != 0 {
	errorLocation:= get_caller_location()
		error1 := new_err(.CANNOT_READ_DIRECTORY, get_err_msg(.CANNOT_READ_DIRECTORY),
		errorLocation)
		log_err("Error reading directory", #procedure)
	}
	for file in foundFiles {
		if file.name == "ostrich.config.ostrichdb" {
			configExists = true
		}
	}
	return configExists
}

//used to first append config records to the system config cluster when the `ostrich.config.ostrichdb` file is created
//essentially the same as data.APPEND_RECORD_TO_CLUSTER but explicitly for the config collection file and no print statements.
//Args for the fn param are only passed if we are appending to a specific users config file
APPEND_CONFIG_RECORD :: proc(configFileType: types.CollectionType, rn, rd, rType: string, fn: ..string) -> int {
	using const
	using utils

	path, clusterName:string


	#partial switch(configFileType){
	case .SYSTEM_CONFIG_PRIVATE:
	    path = SYSTEM_CONFIG_PATH
		clusterName=SYSTEM_CONFIG_CLUSTER
	    break
	case .USER_CONFIG_PRIVATE:
	    path =  concat_user_config_collection_name(fn[0])
		clusterName = concat_user_config_cluster_name(fn[0])
	    break
	}

	data, readSuccess := utils.read_file(path, #procedure)
	defer delete(data)
	if !readSuccess {
		return -1
	}

	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)

	clusterStart := -1
	closingBrace := -1

	for i := 0; i < len(lines); i += 1 {
			clusterStart = i
		if strings.contains(lines[i], clusterName) {
		}
		if clusterStart != -1 && strings.contains(lines[i], "}") {
			closingBrace = i
			break
		}
	}

	//if the cluster is not found or the structure is invalid, return
	if clusterStart == -1 || closingBrace == -1 {
	errorLocation:= get_caller_location()
		error2 := new_err(
			.CANNOT_FIND_CLUSTER,
			get_err_msg(.CANNOT_FIND_CLUSTER),
			errorLocation
		)
		throw_err(error2)
		log_err("Unable to find cluster/valid structure", #procedure)
		return -1
	}

	// Create the new line
	newLine := fmt.tprintf("\t%s :%s: %s", rn, rType, rd)

	// Insert the new line and adjust the closing brace
	newLines := make([dynamic]string, len(lines) + 1)
	defer delete(newLines)

	copy(newLines[:closingBrace], lines[:closingBrace])
	newLines[closingBrace] = newLine
	newLines[closingBrace + 1] = "},"
	if closingBrace + 1 < len(lines) {
		copy(newLines[closingBrace + 2:], lines[closingBrace + 1:])
	}

	newContent := strings.join(newLines[:], "\n")
	writeSuccess := utils.write_to_file(path, transmute([]byte)newContent, #procedure)
	if !writeSuccess {
		return -1
	}
	return 0
}

//Uses the above proc to append ALL necassary record to either the users personal config file or the sytems config file
//Args for fn are only needed if its being called for a users personal config file
APPEND_ALL_CONFIGS_TO_CONFIG_FILE :: proc(configFileType:types.CollectionType, fn: ..string) -> bool {
	using const
	using utils
	using types

	successCount := 0

	#partial switch(configFileType){
	    case .SYSTEM_CONFIG_PRIVATE:
			if APPEND_CONFIG_RECORD(configFileType, ENGINE_INIT, "false", Token[.BOOLEAN]) == 0 {
				successCount += 1
			}
			if APPEND_CONFIG_RECORD(configFileType, ENGINE_LOGGING, "false", Token[.BOOLEAN]) == 0 {
				successCount += 1
			}
			if APPEND_CONFIG_RECORD(configFileType, USER_LOGGED_IN, "false", Token[.BOOLEAN]) == 0 {
				successCount += 1
			}

			metadata.INIT_METADATA_IN_NEW_COLLECTION(SYSTEM_CONFIG_PATH)
			if successCount == 3 {
				return true
			}else{
			    break
			}
		case .USER_CONFIG_PRIVATE:
		    if APPEND_CONFIG_RECORD(configFileType,HELP_IS_VERBOSE, "false", Token[.BOOLEAN], fn[0]) == 0 {
		    successCount += 1
		    }
		    if APPEND_CONFIG_RECORD(configFileType,AUTO_SERVE, "false", Token[.BOOLEAN],fn[0]) == 0 { 	//server mode off by default
		    successCount += 1
		    }
		    if APPEND_CONFIG_RECORD(configFileType,SUPPRESS_ERRORS, "false", Token[.BOOLEAN],fn[0]) == 0 {
		    successCount += 1
		    }
		    if APPEND_CONFIG_RECORD(configFileType,LIMIT_HISTORY, "true", Token[.BOOLEAN],fn[0]) == 0 {
		    successCount += 1
		    }
		    if APPEND_CONFIG_RECORD(configFileType,LIMIT_SESSION_TIME, "true", Token[.BOOLEAN],fn[0]) == 0{ //CLI session time limit is on by defualt
		    successCount += 1
		    }
			metadata.INIT_METADATA_IN_NEW_COLLECTION(concat_user_config_collection_name(fn[0]))
			if successCount == 5 {
				return true
			}else{
			    break
			}
	}
	return false
}


//used to update a config value when a user uses the SET command
//essentially the same as the data.SET_RECORD_VALUE proc but explicitly for the config collection file.
UPDATE_CONFIG_VALUE :: proc(configFileType: types.CollectionType, rn, rValue: string, fn:..string) -> bool {
	using const
	using utils
	using types

	path, clusterName:string


	#partial switch(configFileType){
	    case .SYSTEM_CONFIG_PRIVATE:
			path = const.SYSTEM_CONFIG_PATH
			clusterName =  SYSTEM_CONFIG_CLUSTER
			break
		case .USER_CONFIG_PRIVATE:
		    path = concat_user_config_collection_name(fn[0])
			clusterName =concat_user_config_cluster_name(fn[0])
		    break
	}

	result := data.CHECK_IF_SPECIFIC_RECORD_EXISTS(path, clusterName, rn)
	if !result {
		fmt.printfln("Config: %s%s% does not exist", BOLD_UNDERLINE, rn, RESET)
		return false
	}

	// Read the collection file
	res, readSuccess := read_file(path, #procedure)
	defer delete(res)
	if !readSuccess {
		fmt.printfln("Failed to read config file")
		return false
	}

	recordType, getTypeSuccess := data.GET_RECORD_TYPE(path, clusterName, rn)
	//Standard value allocation
	valueAny: any = 0
	ok: bool

	switch (recordType) {
	case Token[.BOOLEAN]:
		valueAny, ok = data.CONVERT_RECORD_TO_BOOL(rValue)
		break
	}

	if ok != true {
	errorLocation:= get_caller_location()
		valueTypeError := new_err(
			.INVALID_VALUE_FOR_EXPECTED_TYPE,
			get_err_msg(.INVALID_VALUE_FOR_EXPECTED_TYPE),
			errorLocation
		)
		throw_custom_err(
			valueTypeError,
			fmt.tprintf(
				"%sInvalid value given. Expected a value of type: %s%s%s",
				BOLD_UNDERLINE,
				Token[.CONFIG],
				RESET,
			),
		)
		log_err("User entered a value of a different type than what was expected.", #procedure)

		return false
	}

	// Update the record in the file
	success := data.UPDATE_RECORD(path, clusterName, rn, valueAny)

	return success
}
