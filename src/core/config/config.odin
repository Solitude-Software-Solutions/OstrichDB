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
	data.OST_CREATE_COLLECTION("ostrich.config", 3)
	id := data.OST_GENERATE_ID(true)
	data.OST_CREATE_CLUSTER_BLOCK("ostrich.config.ost", id, const.CONFIG_CLUSTER)

	appendSuccess := OST_APPEND_ALL_CONFIG_RECORDS()
	if !appendSuccess {
		utils.log_err("Failed to append all config records", #procedure)
		fmt.println("ERROR: Failed to append all config records")
		fmt.println("Please rebuild OstrichDB")
	}
}
//self explanatory :D - Marshall
OST_CHECK_IF_CONFIG_FILE_EXISTS :: proc() -> bool {
	configExists: bool
	binDir, e := os.open(".")
	defer os.close(binDir)

	foundFiles, readDirSuccess := os.read_dir(binDir, -1)

	if readDirSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_READ_DIRECTORY,
			utils.get_err_msg(.CANNOT_READ_DIRECTORY),
			#procedure,
		)
		utils.log_err("Error reading directory", #procedure)
	}
	for file in foundFiles {
		if file.name == const.OST_CONFIG_FILE {
			configExists = true
		}
	}
	return configExists
}

//used to first append config records to the config cluster when the config file is created
//essentially the same as data.APPEND_RECORD_TO_CLUSTER but explicitly for the config collection file and no print statements.
OST_APPEND_CONFIG_RECORD :: proc(rn: string, rd: string, rType: string) -> int {
	fn := const.OST_CONFIG_PATH
	cn := const.CONFIG_CLUSTER

	data, readSuccess := utils.read_file(fn, #procedure)
	defer delete(data)
	if !readSuccess {
		return -1
	}

	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)

	cluster_start := -1
	closing_brace := -1

	for i := 0; i < len(lines); i += 1 {
		if strings.contains(lines[i], cn) {
			cluster_start = i
		}
		if cluster_start != -1 && strings.contains(lines[i], "}") {
			closing_brace = i
			break
		}
	}

	//if the cluster is not found or the structure is invalid, return
	if cluster_start == -1 || closing_brace == -1 {
		error2 := utils.new_err(
			.CANNOT_FIND_CLUSTER,
			utils.get_err_msg(.CANNOT_FIND_CLUSTER),
			#procedure,
		)
		utils.throw_err(error2)
		utils.log_err("Unable to find cluster/valid structure", #procedure)
		return -1
	}

	// Create the new line
	new_line := fmt.tprintf("\t%s :%s: %s", rn, rType, rd)

	// Insert the new line and adjust the closing brace
	new_lines := make([dynamic]string, len(lines) + 1)
	copy(new_lines[:closing_brace], lines[:closing_brace])
	new_lines[closing_brace] = new_line
	new_lines[closing_brace + 1] = "},"
	if closing_brace + 1 < len(lines) {
		copy(new_lines[closing_brace + 2:], lines[closing_brace + 1:])
	}

	new_content := strings.join(new_lines[:], "\n")
	writeSuccess := utils.write_to_file(fn, transmute([]byte)new_content, #procedure)
	if !writeSuccess {
		return -1
	}
	return 0
}


OST_APPEND_ALL_CONFIG_RECORDS :: proc() -> bool {
	successCount := 0
	// Append all the records to the config cluster
	if OST_APPEND_CONFIG_RECORD(const.configOne, "false", const.BOOLEAN) == 0 {
		successCount += 1
	}
	if OST_APPEND_CONFIG_RECORD(const.configTwo, "false", const.BOOLEAN) == 0 {
		successCount += 1
	}
	if OST_APPEND_CONFIG_RECORD(const.configThree, "false", const.BOOLEAN) == 0 {
		successCount += 1
	}
	if OST_APPEND_CONFIG_RECORD(
		   const.configFour,
		   utils.append_qoutations("SIMPLE"),
		   const.STRING,
	   ) ==
	   0 {
		successCount += 1
	}
	if OST_APPEND_CONFIG_RECORD(const.configFive, "false", const.BOOLEAN) == 0 {
		successCount += 1
	}
	if OST_APPEND_CONFIG_RECORD(const.configSix, "false", const.BOOLEAN) == 0 {
		successCount += 1
	}

	metadata.OST_UPDATE_METADATA_VALUE(const.OST_CONFIG_PATH, 2)
	metadata.OST_UPDATE_METADATA_VALUE(const.OST_CONFIG_PATH, 3)

	if successCount != 6 {
		return false
	}
	return true
}


//used to update a config value when a user uses the SET command
//essentially the same as the data.OST_SET_RECORD_VALUE proc but explicitly for the config collection file.
OST_UPDATE_CONFIG_VALUE :: proc(rn, rValue: string) -> bool {
	file := const.OST_CONFIG_PATH
	cn := const.CONFIG_CLUSTER

	result := data.OST_CHECK_IF_RECORD_EXISTS(file, const.CONFIG_CLUSTER, rn)
	if !result {
		fmt.printfln("Config: %s%s% does not exist", utils.BOLD_UNDERLINE, rn, utils.RESET)
		return false
	}

	// Read the collection file
	res, readSuccess := utils.read_file(file, #procedure)
	defer delete(res)
	if !readSuccess {
		fmt.printfln("Failed to read config file")
		return false
	}

	//todo: update this call to include the cluster name as well
	recordType, getTypeSuccess := data.OST_GET_RECORD_TYPE(file, cn, rn)
	//Standard value allocation
	valueAny: any = 0
	ok: bool
	switch (recordType) {
	case const.BOOLEAN:
		valueAny, ok = data.OST_CONVERT_RECORD_TO_BOOL(rValue)
		break
	case const.STRING:
		valueAny = rValue
		ok = true
		break

	}

	if ok != true {
		valueTypeError := utils.new_err(
			.INVALID_VALUE_FOR_EXPECTED_TYPE,
			utils.get_err_msg(.INVALID_VALUE_FOR_EXPECTED_TYPE),
			#procedure,
		)
		utils.throw_custom_err(
			valueTypeError,
			fmt.tprintf(
				"%sInvalid value given. Expected a value of type: %s%s%s",
				utils.BOLD_UNDERLINE,
				const.CONFIG,
				utils.RESET,
			),
		)
		utils.log_err(
			"User entered a value of a different type than what was expected.",
			#procedure,
		)

		return false
	}

	// Update the record in the file
	success := data.OST_UPDATE_RECORD_IN_FILE(file, cn, rn, valueAny)


	return success
}
