package utils

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
// This file contains miscellaneous entities that are used throughout the program
ostrich_version: string
ostrich_art := `  _______               __                __             __
  /       \             /  |              /  |           /  |
  /$$$$$$  |  _______  _$$ |_     ______  $$/   _______ $$ |____
  $$ |  $$ | /       |/ $$   |   /      \ /  | /       |$$      \
  $$ |  $$ |/$$$$$$$/ $$$$$$/   /$$$$$$  |$$ |/$$$$$$$/ $$$$$$$  |
  $$ |  $$ |$$      \   $$ | __ $$ |  $$/ $$ |$$ |      $$ |  $$ |
  $$ \__$$ | $$$$$$  |  $$ |/  |$$ |      $$ |$$ \_____ $$ |  $$ |
  $$    $$/ /     $$/   $$  $$/ $$ |      $$ |$$       |$$ |  $$ |
   $$$$$$/  $$$$$$$/     $$$$/  $$/       $$/  $$$$$$$/ $$/   $$/
  ===============================================================`

//Constants for text colors and styles
RED :: "\033[31m"
BLUE :: "\033[34m"
GREEN :: "\033[32m"
YELLOW :: "\033[33m"

BOLD :: "\033[1m"
ITALIC :: "\033[3m"
UNDERLINE :: "\033[4m"
RESET :: "\033[0m"


get_ost_version :: proc() -> []u8 {
	version_file, openSuccess := os.open("../version")
	if openSuccess != 0 {
		log_err("Could not open version file", "get_ost_version")
	}
	data, e := os.read_entire_file(version_file)
	if e == false {
	}
	os.close(version_file)
	return data
}

//n- name of step, c- current step, t- total steps of current process
show_current_step :: proc(n: string, c: string, t: string) {
	fmt.printfln("Step %s/%s:\n%s%s%s\n", c, t, BOLD, n, RESET)
}


get_input :: proc() -> string {
	buf: [1024]byte
	n, err := os.read(os.stdin, buf[:])
	// fmt.printf("Debug: Read %d bytes, err = %v\n", n, err)
	if err != 0 {
		fmt.println("Debug: Error occurred")
		return ""
	}
	result := strings.trim_right(string(buf[:n]), "\r\n")
	// fmt.printf("Debug: Returning result: '%s'\n", result)
	return result
}
