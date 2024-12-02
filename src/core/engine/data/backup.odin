package data

import "../../../utils"
import "../../const"
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

OST_CREATE_BACKUP_DIR :: proc() {
	os.make_directory("./backups")
}



OST_CREATE_BACKUP_COLLECTION :: proc(dest: string, src: string) -> bool {
	using utils
	//retirve the data from the src collection file
	srcNameAndPath := fmt.tprintf("%s%s", const.OST_COLLECTION_PATH, src)
	srcFullPath := fmt.tprintf("%s%s", srcNameAndPath, const.OST_FILE_EXTENSION)
	f, readSuccess := os.read_entire_file(srcFullPath)
	if !readSuccess {
		error1 := new_err(.CANNOT_READ_FILE, get_err_msg(.CANNOT_READ_FILE), #procedure)
		throw_custom_err(error1, "Could not read collection file for backup")
		utils.log_err("Could not read collection file for backup", #procedure)
		return false
	}

	data := f
	defer delete(data)

	//create a backup file dest and write the src content to it
	destNameAndPath := fmt.tprintf("%s%s", const.OST_BACKUP_PATH, dest)
	destFullPath := fmt.tprintf("%s%s", destNameAndPath, const.OST_FILE_EXTENSION)

	c, creationSuccess := os.open(destFullPath, os.O_CREATE | os.O_RDWR, 0o666)
	defer os.close(c)
	if creationSuccess != 0 {
		error1 := new_err(.CANNOT_CREATE_FILE, get_err_msg(.CANNOT_CREATE_FILE), #procedure)
		throw_custom_err(error1, "Could not create collection file for backup")
		utils.log_err("Could not create backup collection file", #procedure)
		return false
	}
	w, writeSuccess := os.write(c, data)
	if writeSuccess != 0 {
		error1 := new_err(.CANNOT_WRITE_TO_FILE, get_err_msg(.CANNOT_WRITE_TO_FILE), #procedure)
		throw_custom_err(error1, "Could not write to collection file for backup")
		utils.log_err("Could not write to collection file for backup", #procedure)
		return false
	}

	return true
}

OST_CHOOSE_BACKUP_NAME :: proc() -> string {
	buf: [1024]byte
	fmt.printfln("What would you like to name your collection backup?")
	n, inputSuccess := os.read(os.stdin, buf[:])

	if inputSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_READ_INPUT,
			utils.get_err_msg(.CANNOT_READ_INPUT),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Error reading input for backup collection name", #procedure)
	}
	str := strings.trim_right(string(buf[:n]), "\r\n")

	return strings.clone(str)
}