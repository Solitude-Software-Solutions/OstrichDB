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
	using const
	using types
	using utils

	value := data.OST_READ_RECORD_VALUE(OST_CONFIG_PATH, CONFIG_CLUSTER, STRING, CONFIG_FOUR)

	switch (value) 
	{
	case "VERBOSE":
		help_mode.verbose = true
		break
	case "SIMPLE":
		help_mode.verbose = false
		break
	case:
		fmt.println(
			"Invalid value detected in config file.\n Please delete the config file and restart OstrichDB.",
		)
	}

	return help_mode.verbose
}

//checks if the token that the user wants help with is valid
OST_CHECK_HELP_EXISTS :: proc(cmd: string) -> bool {
	cmdUpper := strings.to_upper(cmd)
	for validCmd in validCommands {
		if cmdUpper == validCmd {
			return true
		}
	}
	return false
}

//Returns a specific portion of the help file based on the subject passed. can be simple or verbose
OST_GET_SPECIFIC_HELP :: proc(subject: string) -> string {
	using const
	using utils

	helpMode := OST_SET_HELP_MODE()
	helpText: string
	data: []byte
	ok: bool

	validCommnad := OST_CHECK_HELP_EXISTS(subject)
	if !validCommnad {
		fmt.printfln(
			"Cannot get help with %s%s%s as it is not a valid command.\nPlease try valid OstrichDB commmand\nor enter 'HELP' with no trailing arguments",
			BOLD_UNDERLINE,
			subject,
			RESET,
		)
		return ""
	}
	switch (helpMode) 
	{
	case true:
		data, ok = os.read_entire_file(VERBOSE_HELP_FILE)
		break
	case false:
		data, ok = os.read_entire_file(SIMPLE_HELP_FILE)
	}
	if !ok {
		return ""
	}
	defer delete(data)

	content := string(data)
	helpSectionStart := fmt.tprintf("### %s START", subject)
	helpSectionEnd := fmt.tprintf("### %s END", subject)

	start_index := strings.index(content, helpSectionStart)
	if start_index == -1 {
		return fmt.tprintf("No help found for %s%s%s", BOLD_UNDERLINE, subject, RESET)
	}

	start_index += len(helpSectionStart)
	end_index := strings.index(content[start_index:], helpSectionEnd)
	if end_index == -1 {
		return fmt.tprintf("Malformed help section for %s%s%s", BOLD_UNDERLINE, subject, RESET)
	}

	helpText = strings.trim_space(content[start_index:][:end_index])
	fmt.printfln("\n")
	fmt.printfln(helpText)
	fmt.printfln("\n")
	return strings.clone(helpText)
}

//ready and returns everything from the general help file
OST_GET_GENERAL_HELP :: proc() -> string {
	using const

	data, ok := os.read_entire_file(GENERAL_HELP_FILE)
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
	using const

	data, ok := os.read_entire_file(ATOMS_HELP_FILE)
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
