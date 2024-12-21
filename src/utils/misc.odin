package utils
import "../core/const"
import "../core/types"
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

ostrich_version: string
ostrich_art := `
 $$$$$$\              $$\               $$\           $$\       $$$$$$$\  $$$$$$$\
 $$  __$$\             $$ |              \__|          $$ |      $$  __$$\ $$  __$$\
 $$ /  $$ | $$$$$$$\ $$$$$$\    $$$$$$\  $$\  $$$$$$$\ $$$$$$$\  $$ |  $$ |$$ |  $$ |
 $$ |  $$ |$$  _____|\_$$  _|  $$  __$$\ $$ |$$  _____|$$  __$$\ $$ |  $$ |$$$$$$$\ |
 $$ |  $$ |\$$$$$$\    $$ |    $$ |  \__|$$ |$$ /      $$ |  $$ |$$ |  $$ |$$  __$$\
 $$ |  $$ | \____$$\   $$ |$$\ $$ |      $$ |$$ |      $$ |  $$ |$$ |  $$ |$$ |  $$ |
  $$$$$$  |$$$$$$$  |  \$$$$  |$$ |      $$ |\$$$$$$$\ $$ |  $$ |$$$$$$$  |$$$$$$$  |
  \______/ \_______/    \____/ \__|      \__| \_______|\__|  \__|\_______/ \_______/
 ==================================================================================
 A Document-based NoSQL Database Management System: %s%s%s
 ==================================================================================`

//Constants for text colors and styles
RED :: "\033[31m"
BLUE :: "\033[34m"
GREEN :: "\033[32m"
YELLOW :: "\033[33m"
ORANGE :: "\033[38;5;208m"

BOLD :: "\033[1m"
ITALIC :: "\033[3m"
UNDERLINE :: "\033[4m"
BOLD_UNDERLINE :: "\033[4m\033[1m" //:) makes formatting even easier - SchoolyB
RESET :: "\033[0m"


get_ost_version :: proc() -> []u8 {
	data := #load("../../version")
	return data
}

//n- name of step, c- current step, t- total steps of current process
show_current_step :: proc(n: string, c: string, t: string) {
	fmt.printfln("Step %s/%s:\n%s%s%s\n", c, t, BOLD, n, RESET)
}


show_check_warning :: proc() -> string {
	return fmt.tprintf(
		"%s%s[WARNING] [WARNING] [WARNING] [WARNING]%s",
		BOLD,
		types.Message_Color,
		RESET,
	)
}


//helper that looks for the passed in id in the cache file and
// removes it. and closes the gap between the lines where the id was
// used when deleting a user or a cluster
remove_id_from_cache :: proc(id: i64) -> bool {
	buf: [32]byte
	idStr := strconv.append_int(buf[:], id, 10)


	data, readSuccess := read_file(const.OST_CLUSTER_CACHE_PATH, #procedure)
	defer delete(data)
	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)
	newLines := make([dynamic]string, 0, len(lines))
	defer delete(newLines)
	for line in lines {
		if !strings.contains(line, idStr) {
			append(&newLines, line)
		} else {
			continue
		}
	}

	new_content := strings.join(newLines[:], "\n")
	writeSuccess := write_to_file(
		const.OST_CLUSTER_CACHE_PATH,
		transmute([]byte)new_content,
		#procedure,
	)

	return writeSuccess
}

//used to help with error handling.
get_line_number :: proc(line: int) -> string {
	if line < 1 {
		return "unknown"
	}
	return fmt.tprintf("%d", line)
}

//used to help with error handling.
show_source_file :: proc(file: string) -> string {
	return fmt.tprintln("Source File: %s%s%s", BOLD, file, RESET)
}
