package engine

import "../../core/const"
import "../../utils"
import "../engine/data"
import "../engine/data/metadata"
import "../types"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            Contains logic for handling the command history.
            It also contains logic for the actual HISTORY command.
*********************************************************/
OST_APPEND_COMMAND_TO_HISTORY :: proc(input: string) {
	using types
	using metadata
	using utils
	using const

	histBuf: [1024]byte
	//append the last command to the history buffer
	current_user.commandHistory.cHistoryCount = data.OST_COUNT_RECORDS_IN_CLUSTER(
		"history",
		current_user.username.Value,
		false,
	)

	// History Collection file size limit.
	// Doesnt measure bytes of the file but instead
	// the num of records of the users command history cluster
	limitOn := data.OST_READ_RECORD_VALUE(
		const.OST_CONFIG_PATH,
		const.CONFIG_CLUSTER,
		BOOLEAN,
		const.CONFIG_SEVEN,
	)

	if limitOn == "true" {
		limitReached := OST_CHECK_HISTORY_LIMIT_MET(&current_user)
		if limitReached {
			if OST_PURGE_HIRSTORY_CLUSTER(current_user.username.Value) {
				//set the count back to 0
				current_user.commandHistory.cHistoryCount = 0
			}
		}
	}

	histCountStr := strconv.itoa(histBuf[:], current_user.commandHistory.cHistoryCount)
	recordName := fmt.tprintf("%s%s", "history_", histCountStr)

	//append the last command to the history file
	data.OST_APPEND_RECORD_TO_CLUSTER(
		const.OST_HISTORY_PATH,
		current_user.username.Value,
		strings.to_upper(recordName),
		strings.to_upper(strings.clone(input)),
		"COMMAND",
	)

	//get value of the command that was just stored as a record
	historyRecordValue := data.OST_READ_RECORD_VALUE(
		const.OST_HISTORY_PATH,
		current_user.username.Value,
		"COMMAND",
		strings.to_upper(recordName),
	)

	//append the command from the file to the command history buffer
	append(&current_user.commandHistory.cHistoryValues, strings.clone(historyRecordValue))


	//update the history file size, date last modified and checksum
	OST_UPDATE_METADATA_AFTER_OPERATION(const.OST_HISTORY_PATH)
}


OST_ERASE_HISTORY_CLUSTER :: proc(userName: string) -> bool {
	using const
	using utils

	data, readSuccess := os.read_entire_file(OST_HISTORY_PATH)
	defer delete(data)
	if !readSuccess {
		throw_err(new_err(.CANNOT_READ_FILE, get_err_msg(.CANNOT_READ_FILE), #procedure))
		log_err("Error reading collection file", #procedure)
		return false
	}
	content := string(data)
	clusterClosingBrace := strings.split(content, "}")
	newContent := make([dynamic]u8)
	defer delete(newContent)
	clusterFound := false


	for i := 0; i < len(clusterClosingBrace); i += 1 {
		cluster := clusterClosingBrace[i] // everything in the file up to the first instance of "},"
		if strings.contains(cluster, fmt.tprintf("cluster_name :identifier: %s", userName)) {
			clusterFound = true
		} else if len(strings.trim_space(cluster)) > 0 {
			append(&newContent, ..transmute([]u8)cluster) // Add closing brace
			if i < len(clusterClosingBrace) - 1 {
				append(&newContent, "}")
			}
		}
	}

	if !clusterFound {
		throw_err(
			new_err(
				.CANNOT_FIND_CLUSTER,
				fmt.tprintf(
					"Cluster: %s%s%s not found in collection: %s%s%s",
					BOLD_UNDERLINE,
					userName,
					RESET,
					BOLD_UNDERLINE,
					userName,
					RESET,
				),
				#procedure,
			),
		)
		log_err("Error finding cluster in collection", #procedure)
		return false
	}
	writeSuccess := os.write_entire_file(OST_HISTORY_PATH, newContent[:])
	if !writeSuccess {
		throw_err(new_err(.CANNOT_WRITE_TO_FILE, get_err_msg(.CANNOT_WRITE_TO_FILE), #procedure))
		log_err("Error writing to collection file", #procedure)
		return false
	}
	log_runtime_event(
		"Database Cluster",
		"User confirmed deletion of cluster and it was successfully deleted.",
	)
	return true
}


//Used to get rid of data within a user's history cluster once the limit has been reached.
OST_PURGE_HIRSTORY_CLUSTER :: proc(cn: string) -> bool {
	using const
	using utils

	// Read the entire file
	data, readSuccess := os.read_entire_file(const.OST_HISTORY_PATH)
	if !readSuccess {
		throw_err(new_err(.CANNOT_READ_FILE, get_err_msg(.CANNOT_READ_FILE), #procedure))
		log_err("Error reading collection file", #procedure)
		return false
	}
	defer delete(data)

	//Have to make these 4 vars because transmute wont allow a non-typed string...dumb I know
	openBrace := "{"
	openBraceWithNewline := "{\n"
	closeBrace := "}"
	closeBraceWithComma := "},"

	//split the content into clusters
	content := string(data)
	clusters := strings.split(content, "{")
	newContent := make([dynamic]u8)
	defer delete(newContent)

	//check if the cluster exists
	clusterFound := false
	for i := 0; i < len(clusters); i += 1 {
		if i == 0 {
			// Preserve the metadata header and its following whitespace
			append(&newContent, ..transmute([]u8)clusters[i])
			continue
		}
		//concatenate the open brace with the cluster
		cluster := strings.concatenate([]string{openBrace, clusters[i]})
		//if the cluster name matches the one we want to purge, we need to preserve the cluster's data
		if strings.contains(cluster, fmt.tprintf("cluster_name :identifier: %s", cn)) {
			clusterFound = true
			lines := strings.split(cluster, "\n")
			append(&newContent, ..transmute([]u8)openBraceWithNewline)
			emptyLineAdded := false
			for line, lineIndex in lines {
				trimmedLine := strings.trim_space(line)
				if strings.contains(trimmedLine, "cluster_name :identifier:") ||
				   strings.contains(trimmedLine, "cluster_id :identifier:") {

					//preserves the indentation
					indent := strings.index(line, trimmedLine)
					if indent > 0 {
						append(&newContent, ..transmute([]u8)line[:indent])
					}
					//adds the line line and a newline character to the newContent array
					append(&newContent, ..transmute([]u8)strings.trim_space(line))
					append(&newContent, '\n')

					//this ensures that the cluster_id line is followed by an empty line for formatting purposes
					if strings.contains(trimmedLine, "cluster_id :identifier:") &&
					   !emptyLineAdded {
						if lineIndex + 1 < len(lines) &&
						   len(strings.trim_space(lines[lineIndex + 1])) == 0 {
							append(&newContent, '\n')
							emptyLineAdded = true
						}
					}
				}
			}
			append(&newContent, ..transmute([]u8)closeBrace)

			//this ensures that the closing brace is followed by any trailing whitespace
			if lastBrace := strings.last_index(cluster, "}"); lastBrace != -1 {
				append(&newContent, ..transmute([]u8)cluster[lastBrace + 1:])
			}
		} else {
			append(&newContent, ..transmute([]u8)cluster)
		}
	}

	if !clusterFound {
		throw_err(new_err(.CANNOT_FIND_CLUSTER, get_err_msg(.CANNOT_FIND_CLUSTER), #procedure))
		log_err("Error finding cluster in collection", #procedure)
		return false
	}
	//write the new content to the collection file
	writeSuccess := os.write_entire_file(const.OST_HISTORY_PATH, newContent[:])
	if !writeSuccess {
		throw_err(new_err(.CANNOT_WRITE_TO_FILE, get_err_msg(.CANNOT_WRITE_TO_FILE), #procedure))
		log_err("Error writing to collection file", #procedure)
		return false
	}

	return true
}


OST_CHECK_HISTORY_LIMIT_MET :: proc(currentUser: ^types.User) -> bool {
	using utils
	using const

	limitReached := false
	//Check that the history count is not greater than the limit
	if currentUser.commandHistory.cHistoryCount > const.MAX_HISTORY_COUNT {
		//remove the oldest command from the history buffer .....NOT DOING THIS...NEED TO ACTUALLY REMOVE ALL RECORDS FROM THE CLUSTER 
		historyPurgeSuccess := OST_PURGE_HIRSTORY_CLUSTER(currentUser.username.Value)
		if !historyPurgeSuccess {
			throw_err(
				new_err(
					.CANNOT_PURGE_HISTORY,
					fmt.tprintf(
						"Error purging history cluster for user: %s%s%s",
						BOLD_UNDERLINE,
						currentUser.username.Value,
						RESET,
					),
					#procedure,
				),
			)
			log_err("Error purging history cluster", #procedure)

		} else {
			limitReached = true
		}
	}
	return limitReached
}
