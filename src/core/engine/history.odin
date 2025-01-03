package engine
import "../engine/data"
import "../engine/data/metadata"
import "../types"
import "core:fmt"
import "core:strconv"
import "core:strings"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//
OST_APPEND_COMMAND_TO_HISTORY :: proc(input: string) {
	histBuf: [1024]byte
	//append the last command to the history buffer
	types.current_user.commandHistory.cHistoryCount = data.OST_COUNT_RECORDS_IN_CLUSTER(
		"history",
		types.current_user.username.Value,
		false,
	)
	// types.current_user.commandHistory.cHistoryNamePrefix = "history_" dont need this shit tbh - SchoolyB
	histCountStr := strconv.itoa(histBuf[:], types.current_user.commandHistory.cHistoryCount)
	recordName := fmt.tprintf("%s%s", "history_", histCountStr)

	//append the last command to the history file
	data.OST_APPEND_RECORD_TO_CLUSTER(
		"./history.ost",
		types.current_user.username.Value,
		strings.to_upper(recordName),
		strings.to_upper(strings.clone(input)),
		"COMMAND",
	)

	//get value of the command that was just stored as a record
	historyRecordValue := data.OST_READ_RECORD_VALUE(
		"./history.ost",
		types.current_user.username.Value,
		"COMMAND",
		strings.to_upper(recordName),
	)

	//append the command from the file to the command history buffer
	append(&types.current_user.commandHistory.cHistoryValues, strings.clone(historyRecordValue))

	//update the history file size value in the metadata
	metadata.OST_UPDATE_METADATA_VALUE("./history.ost", 3)
}
