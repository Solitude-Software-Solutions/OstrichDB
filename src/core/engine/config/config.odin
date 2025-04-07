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

	OST_CREATE_COLLECTION("", .CONFIG_PRIVATE)
	id := OST_GENERATE_ID(true)
	OST_APPEND_ID_TO_COLLECTION(fmt.tprintf("%d", id), 0)
	CREATE_CLUSTER_BLOCK(const.CONFIG_PATH, id, const.CONFIG_CLUSTER)

	appendSuccess := APPEND_ALL_CONFIG_RECORDS()
	if !appendSuccess {
		utils.log_err("Failed to append all config records", #procedure)
		fmt.println("ERROR: Failed to append all config records")
		fmt.println("Please rebuild OstrichDB")
	}
}

//TODO NOT USING THIS
OST_CHECK_IF_CONFIG_FILE_EXISTS :: proc() -> bool {
	using utils
	configExists: bool
	binDir, e := os.open(const.PRIVATE_PATH)
	defer os.close(binDir)

	foundFiles, readDirSuccess := os.read_dir(binDir, -1)

	if readDirSuccess != 0 {
		error1 := new_err(
			.CANNOT_READ_DIRECTORY,
			get_err_msg(.CANNOT_READ_DIRECTORY),
			#file,
			#procedure,
			#line,
		)
		log_err("Error reading directory", #procedure)
	}
	for file in foundFiles {
		if file.name == "config.ost" {
			configExists = true
		}
	}
	return configExists
}

//used to first append config records to the config cluster when the config file is created
//essentially the same as data.APPEND_RECORD_TO_CLUSTER but explicitly for the config collection file and no print statements.
APPEND_CONFIG_RECORD :: proc(rn: string, rd: string, rType: string) -> int {
	using const
	using utils

	fn := CONFIG_PATH
	cn := CONFIG_CLUSTER

	data, readSuccess := utils.read_file(fn, #procedure)
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
		if strings.contains(lines[i], cn) {
			clusterStart = i
		}
		if clusterStart != -1 && strings.contains(lines[i], "}") {
			closingBrace = i
			break
		}
	}

	//if the cluster is not found or the structure is invalid, return
	if clusterStart == -1 || closingBrace == -1 {
		error2 := new_err(
			.CANNOT_FIND_CLUSTER,
			get_err_msg(.CANNOT_FIND_CLUSTER),
			#file,
			#procedure,
			#line,
		)
		throw_err(error2)
		log_err("Unable to find cluster/valid structure", #procedure)
		return -1
	}

	// Create the new line
	newLine := fmt.tprintf("\t%s :%s: %s", rn, rType, rd)

	// Insert the new line and adjust the closing brace
	newLines := make([dynamic]string, len(lines) + 1)
	copy(newLines[:closingBrace], lines[:closingBrace])
	newLines[closingBrace] = newLine
	newLines[closingBrace + 1] = "},"
	if closingBrace + 1 < len(lines) {
		copy(newLines[closingBrace + 2:], lines[closingBrace + 1:])
	}

	newContent := strings.join(newLines[:], "\n")
	writeSuccess := utils.write_to_file(fn, transmute([]byte)newContent, #procedure)
	if !writeSuccess {
		return -1
	}
	return 0
}


APPEND_ALL_CONFIG_RECORDS :: proc() -> bool {
	using const
	using utils
	using types

	bool := Token[.BOOLEAN]

	successCount := 0
	// Append all the records to the config cluster
	if APPEND_CONFIG_RECORD(ENGINE_INIT, "false", bool) == 0 {
		successCount += 1
	}
	if APPEND_CONFIG_RECORD(ENGINE_LOGGING, "false", bool) == 0 {
		successCount += 1
	}
	if APPEND_CONFIG_RECORD(USER_LOGGED_IN, "false", bool) == 0 {
		successCount += 1
	}
	if APPEND_CONFIG_RECORD(HELP_IS_VERBOSE, "false", bool) == 0 {
		successCount += 1
	}
	if APPEND_CONFIG_RECORD(AUTO_SERVE, "true", bool) == 0 { 	//server mode on by default while working on it
		successCount += 1
	}
	if APPEND_CONFIG_RECORD(ERROR_SUPPRESSION, "false", bool) == 0 {
		successCount += 1
	}
	if APPEND_CONFIG_RECORD(LIMIT_HISTORY, "true", bool) == 0 {
		successCount += 1
	}

	metadata.UPDATE_METADATA_UPON_CREATION(CONFIG_PATH)

	if successCount != 7 {
		return false
	}
	return true
}


//used to update a config value when a user uses the SET command
//essentially the same as the data.OST_SET_RECORD_VALUE proc but explicitly for the config collection file.
UPDATE_CONFIG_VALUE :: proc(rn, rValue: string) -> bool {
	using const
	using utils
	using types

	result := data.OST_CHECK_IF_RECORD_EXISTS(CONFIG_PATH, CONFIG_CLUSTER, rn)
	if !result {
		fmt.printfln("Config: %s%s% does not exist", BOLD_UNDERLINE, rn, RESET)
		return false
	}

	// Read the collection file
	res, readSuccess := read_file(CONFIG_PATH, #procedure)
	defer delete(res)
	if !readSuccess {
		fmt.printfln("Failed to read config file")
		return false
	}

	recordType, getTypeSuccess := data.OST_GET_RECORD_TYPE(CONFIG_PATH, CONFIG_CLUSTER, rn)
	//Standard value allocation
	valueAny: any = 0
	ok: bool

	switch (recordType) {
	case Token[.BOOLEAN]:
		valueAny, ok = data.OST_CONVERT_RECORD_TO_BOOL(rValue)
		break
	case Token[.STRING]:
		valueAny = rValue
		ok = true
		break
	}

	if ok != true {
		valueTypeError := new_err(
			.INVALID_VALUE_FOR_EXPECTED_TYPE,
			get_err_msg(.INVALID_VALUE_FOR_EXPECTED_TYPE),
			#file,
			#procedure,
			#line,
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
	success := data.OST_UPDATE_RECORD_IN_FILE(CONFIG_PATH, CONFIG_CLUSTER, rn, valueAny)

	return success
}
