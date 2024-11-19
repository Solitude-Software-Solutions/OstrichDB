package config

import "../../utils"
import "../const"
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
	if (OST_CHECK_IF_CONFIG_FILE_EXISTS() == false) {
		OST_CREATE_CONFIG_FILE()
	}
}

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
		if file.name == "ostrich.config" {
			configExists = true
		}
	}
	return configExists
}

//the config file will contain info like: has the initial user setup been done, engine settings, etc
OST_CREATE_CONFIG_FILE :: proc() -> bool {
	configPath := const.OST_CONFIG_PATH
	file, createSuccess := os.open(configPath, os.O_CREATE, 0o666)
	defer os.close(file)
	os.close(file)
	if createSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_CREATE_FILE,
			utils.get_err_msg(.CANNOT_CREATE_FILE),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Error creating ostrich.config file", #procedure)
		return false
	}
	msg := transmute([]u8)const.ConfigHeader
	nFile, openSuccess := os.open(configPath, os.O_APPEND | os.O_WRONLY, 0o666)
	defer os.close(nFile)
	writter, writeSuccess := os.write(nFile, msg)
	if writeSuccess != 0 {
		error2 := utils.new_err(
			.CANNOT_WRITE_TO_FILE,
			utils.get_err_msg(.CANNOT_WRITE_TO_FILE),
			#procedure,
		)
		utils.throw_err(error2)
		utils.log_err("Error writing to ostrich.config file", #procedure)
		return false
	}

	configsFound := OST_FIND_ALL_CONFIGS(
		const.configOne,
		const.configTwo,
		const.configThree,
		const.configFour,
		const.configFive,
	)
	if !configsFound {
		OST_APPEND_AND_SET_CONFIG(const.configOne, "false")
		OST_APPEND_AND_SET_CONFIG(const.configTwo, "simple")
		OST_APPEND_AND_SET_CONFIG(const.configThree, "false")
		OST_APPEND_AND_SET_CONFIG(const.configFour, "verbose")
		OST_APPEND_AND_SET_CONFIG(const.configFive, "false")
	}
	return true
}

// Searches the config file for a specific config name that is passed in as a string
// Returns true if found, false if not found
OST_FIND_CONFIG :: proc(c: string) -> bool {
	data, readSuccess := os.read_entire_file(const.OST_CONFIG_PATH)
	if readSuccess != false {
		error1 := utils.new_err(
			.CANNOT_READ_FILE,
			utils.get_err_msg(.CANNOT_READ_FILE),
			#procedure,
		)
		utils.log_err("Error ostrich.config file", #procedure)
		return false
	}
	defer delete(data)

	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)

	for line in lines {
		if strings.contains(line, c) {
			return true
		}
	}
	return false
}

// Ensures that all config names are found in the config file
OST_FIND_ALL_CONFIGS :: proc(configs: ..string) -> bool {
	for config in configs {
		if !OST_FIND_CONFIG(config) {
			return false
		}
	}
	return true
}

OST_APPEND_AND_SET_CONFIG :: proc(c: string, value: string) -> int {
	file, openSuccess := os.open(const.OST_CONFIG_PATH, os.O_APPEND | os.O_WRONLY, 0o666)
	if openSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_OPEN_FILE,
			utils.get_err_msg(.CANNOT_OPEN_FILE),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Error opening ostrich.config file", #procedure)
		return 1
	}
	defer os.close(file)
	concat := strings.concatenate([]string{c, " : ", value, "\n"})
	str := transmute([]u8)concat
	writter, writeSuccess := os.write(file, str)

	if writeSuccess != 0 {
		error2 := utils.new_err(
			.CANNOT_WRITE_TO_FILE,
			utils.get_err_msg(.CANNOT_WRITE_TO_FILE),
			#procedure,
		)
		utils.throw_err(error2)
		utils.log_err("Error writing to ostrich.config file", #procedure)
		return 1
	}

	return 0
}


OST_READ_CONFIG_VALUE :: proc(config: string) -> string {
	value := ""
	data, readSuccess := os.read_entire_file(const.OST_CONFIG_PATH)
	if !readSuccess {
		error1 := utils.new_err(
			.CANNOT_READ_FILE,
			utils.get_err_msg(.CANNOT_READ_FILE),
			#procedure,
		)
		utils.log_err("Error reading ostrich.config file", #procedure)
		return value
	}
	defer delete(data)

	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)

	for line in lines {
		if strings.contains(line, config) {
			parts := strings.split(line, " : ")
			if len(parts) >= 2 {
				value = strings.trim_space(parts[1])
				return strings.clone(value)
			}
			break // Found the config, but it's malformed
		}
	}

	return value // Config not found
}


OST_TOGGLE_CONFIG :: proc(config: string) -> bool {
	updated := false
	replaced: bool
	data, readSuccess := os.read_entire_file(const.OST_CONFIG_PATH)
	if !readSuccess {
		error1 := utils.new_err(
			.CANNOT_READ_FILE,
			utils.get_err_msg(.CANNOT_READ_FILE),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Error reading ostrich.config file", #procedure)
		return false
	}

	defer delete(data)

	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)

	new_lines := make([dynamic]string, 0, len(lines))
	defer delete(new_lines)


	for line in lines {
		new_line := line
		if config == const.configFour {
			if strings.contains(line, config) {
				if strings.contains(line, "verbose") {
					new_line, replaced = strings.replace(line, "verbose", "simple", 1)
					updated = true
				} else if strings.contains(line, "simple") {
					new_line, replaced = strings.replace(line, "simple", "verbose", 1)
					updated = true
				}
			}
		} else {
			if strings.contains(line, config) {
				if strings.contains(line, "true") {
					new_line, replaced = strings.replace(line, "true", "false", 1)
					updated = true
				} else if strings.contains(line, "false") {
					new_line, replaced = strings.replace(line, "false", "true", 1)
					updated = true
				}
			}
		}
		append(&new_lines, new_line)

	}

	if updated {
		new_content := strings.join(new_lines[:], "\n")
		os.write_entire_file(const.OST_CONFIG_PATH, transmute([]byte)new_content)
	}

	return updated
}
