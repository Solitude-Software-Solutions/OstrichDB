package help

import "../../utils"
import "../config"
import "../const"
import "../engine/data"
import "../types"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//


validCommands := []string {
	"HELP",
	"LOGOUT",
	"EXIT",
	"VERSION",
	"CLEAR",
	"BACKUP",
	"COLLECTION",
	"CLUSTER",
	"RECORD",
	"NEW",
	"ERASE",
	"RENAME",
	"FETCH",
	"TO",
	"COUNT",
	"SET",
	"PURGE",
	"SIZE_OF",
	"TYPE_OF",
	"CHANGE_TYPE",
	"DESTROY",
	"ISOLATE", //formerly known as "QUARANTINE"
}
//called when user only enters the "HELP" command without any arguments
// will take in the value from the config file. if verbose is true then show data from verbose help file, and vice versa
OST_SET_HELP_MODE :: proc() -> bool {
	value := data.OST_READ_RECORD_VALUE(
		const.OST_CONFIG_PATH,
		const.CONFIG_CLUSTER,
		const.STRING,
		const.configFour,
	)

	switch (value) 
	{
	case "VERBOSE":
		types.help_mode.verbose = true
		break
	case "SIMPLE":
		types.help_mode.verbose = false
		break
	case:
		fmt.println(
			"Invalid value detected in config file.\n Please delete the config file and restart OstrichDB.",
		)
	}

	return types.help_mode.verbose
}

OST_CHECK_HELP_EXISTS :: proc(cmd: string) -> bool {
	cmdUpper := strings.to_upper(cmd)
	for validCmd in validCommands {
		if cmdUpper == validCmd {
			return true
		}
	}
	return false
}

OST_GET_SPECIFIC_HELP :: proc(subject: string) -> string {
	helpMode := OST_SET_HELP_MODE()
	help_text: string
	data: []byte
	ok: bool

	validCommnad := OST_CHECK_HELP_EXISTS(subject)
	if !validCommnad {
		fmt.printfln(
			"Cannot get help with %s%s%s as it is not a valid command.\nPlease try valid OstrichDB commmand\nor enter 'HELP' with no trailing arguments",
			utils.BOLD_UNDERLINE,
			subject,
			utils.RESET,
		)
		return ""
	}
	switch (helpMode) 
	{
	case true:
		data, ok = os.read_entire_file(const.VERBOSE_HELP_FILE)
		break
	case false:
		data, ok = os.read_entire_file(const.SIMPLE_HELP_FILE)
	}
	if !ok {
		return ""
	}
	defer delete(data)

	content := string(data)
	help_section_start := fmt.tprintf("### %s START", subject)
	help_section_end := fmt.tprintf("### %s END", subject)

	start_index := strings.index(content, help_section_start)
	if start_index == -1 {
		return fmt.tprintf("No help found for %s%s%s", utils.BOLD_UNDERLINE, subject, utils.RESET)
	}

	start_index += len(help_section_start)
	end_index := strings.index(content[start_index:], help_section_end)
	if end_index == -1 {
		return fmt.tprintf(
			"Malformed help section for %s%s%s",
			utils.BOLD_UNDERLINE,
			subject,
			utils.RESET,
		)
	}

	help_text = strings.trim_space(content[start_index:][:end_index])
	fmt.printfln("\n")
	fmt.printfln(help_text)
	fmt.printfln("\n")
	return strings.clone(help_text)
}

//ready and returns everything from the general help file
OST_GET_GENERAL_HELP :: proc() -> string {
	data, ok := os.read_entire_file(const.GENERAL_HELP_FILE)
	if !ok {
		return ""
	}
	defer delete(data)
	content := string(data)
	fmt.printfln("\n")
	fmt.printfln(content)
	fmt.printfln("\n")
	return strings.clone(content)
}

//shows a table of explaining atoms
OST_GET_ATOMS_HELP :: proc() -> string {
	data, ok := os.read_entire_file(const.ATOMS_HELP_FILE)
	if !ok {
		return ""
	}
	defer delete(data)
	content := string(data)
	fmt.printfln("\nHere is a helpful table containing information about ATOMs in OstrichDB:")
	fmt.printfln(
		"--------------------------------------------------------------------------------------------------------------------",
	)
	fmt.println(content)
	fmt.printfln("\n")
	return strings.clone(content)
}
