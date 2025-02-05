package config

import "../../utils"
import "../const"
import "../engine/data"
import "../engine/data/metadata"
import "../types"
import "core:fmt"
import "core:os"
import "core:strings"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//
main :: proc() {
	using data

	OST_CREATE_COLLECTION("config", 3)
	id := OST_GENERATE_ID(true)
	OST_APPEND_ID_TO_COLLECTION(fmt.tprintf("%d", id), 0)
	OST_CREATE_CLUSTER_BLOCK("./core/config.ost", id, const.CONFIG_CLUSTER)

	appendSuccess := OST_APPEND_ALL_CONFIG_RECORDS()
	if !appendSuccess {
		utils.log_err("Failed to append all config records", #procedure)
		fmt.println("ERROR: Failed to append all config records")
		fmt.println("Please rebuild OstrichDB")
	}
}

OST_CHECK_IF_CONFIG_FILE_EXISTS :: proc() -> bool {
	using utils
	configExists: bool
	binDir, e := os.open("./core/")
	defer os.close(binDir)

	foundFiles, readDirSuccess := os.read_dir(binDir, -1)

	if readDirSuccess != 0 {
		error1 := new_err(.CANNOT_READ_DIRECTORY, get_err_msg(.CANNOT_READ_DIRECTORY), #procedure)
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
OST_APPEND_CONFIG_RECORD :: proc(rn: string, rd: string, rType: string) -> int {
	using const
	using utils

	fn := OST_CONFIG_PATH
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
		error2 := new_err(.CANNOT_FIND_CLUSTER, get_err_msg(.CANNOT_FIND_CLUSTER), #procedure)
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


OST_APPEND_ALL_CONFIG_RECORDS :: proc() -> bool {
	using const
	using utils

	successCount := 0
	// Append all the records to the config cluster
	if OST_APPEND_CONFIG_RECORD(CONFIG_ONE, "false", BOOLEAN) == 0 {
		successCount += 1
	}
	if OST_APPEND_CONFIG_RECORD(CONFIG_TWO, "false", BOOLEAN) == 0 {
		successCount += 1
	}
	if OST_APPEND_CONFIG_RECORD(CONFIG_THREE, "false", BOOLEAN) == 0 {
		successCount += 1
	}
	if OST_APPEND_CONFIG_RECORD(CONFIG_FOUR, append_qoutations("SIMPLE"), STRING) == 0 {
		successCount += 1
	}
	if OST_APPEND_CONFIG_RECORD(CONFIG_FIVE, "false", BOOLEAN) == 0 {
		successCount += 1
	}
	if OST_APPEND_CONFIG_RECORD(CONFIG_SIX, "false", BOOLEAN) == 0 {
		successCount += 1
	}

	metadata.OST_UPDATE_METADATA_ON_CREATE(OST_CONFIG_PATH)

	if successCount != 6 {
		return false
	}
	return true
}


//used to update a config value when a user uses the SET command
//essentially the same as the data.OST_SET_RECORD_VALUE proc but explicitly for the config collection file.
OST_UPDATE_CONFIG_VALUE :: proc(rn, rValue: string) -> bool {
	using const
	using utils

	file := OST_CONFIG_PATH
	cn := CONFIG_CLUSTER

	result := data.OST_CHECK_IF_RECORD_EXISTS(file, CONFIG_CLUSTER, rn)
	if !result {
		fmt.printfln("Config: %s%s% does not exist", BOLD_UNDERLINE, rn, RESET)
		return false
	}

	// Read the collection file
	res, readSuccess := read_file(file, #procedure)
	defer delete(res)
	if !readSuccess {
		fmt.printfln("Failed to read config file")
		return false
	}

	recordType, getTypeSuccess := data.OST_GET_RECORD_TYPE(file, cn, rn)
	//Standard value allocation
	valueAny: any = 0
	ok: bool
	switch (recordType) {
	case BOOLEAN:
		valueAny, ok = data.OST_CONVERT_RECORD_TO_BOOL(rValue)
		break
	case STRING:
		valueAny = rValue
		ok = true
		break

	}

	if ok != true {
		valueTypeError := new_err(
			.INVALID_VALUE_FOR_EXPECTED_TYPE,
			get_err_msg(.INVALID_VALUE_FOR_EXPECTED_TYPE),
			#procedure,
		)
		throw_custom_err(
			valueTypeError,
			fmt.tprintf(
				"%sInvalid value given. Expected a value of type: %s%s%s",
				BOLD_UNDERLINE,
				CONFIG,
				RESET,
			),
		)
		log_err("User entered a value of a different type than what was expected.", #procedure)

		return false
	}

	// Update the record in the file
	success := data.OST_UPDATE_RECORD_IN_FILE(file, cn, rn, valueAny)


	return success
}
