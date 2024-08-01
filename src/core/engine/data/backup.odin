package data

import "../../../utils"
import "../../const"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
//This file contains all things related tot backing up a database


OST_CREAT_BACKUP_DIR :: proc() {
	os.make_directory("../bin/backups")
}


OST_CREATE_BACKUP_COLLECTION :: proc(dest: string, src: string) -> bool {
	using utils
	//retirve the data from the src collection file
	srcNameAndPath := strings.concatenate([]string{const.OST_COLLECTION_PATH, src})
	srcFullPath := strings.concatenate([]string{srcNameAndPath, const.OST_FILE_EXTENSION})
	fmt.println("srcFullPath: ", srcFullPath)
	f, readSuccess := os.read_entire_file(srcFullPath)
	if !readSuccess {
		error1 := new_err(.CANNOT_READ_FILE, get_err_msg(.CANNOT_READ_FILE), #procedure)
		throw_custom_err(error1, "Could not read collection file for backup")
		return false
	}

	data := f
	defer delete(data)

	//create a backup file dest and write the src content to it
	destNameAndPath := strings.concatenate([]string{const.OST_BACKUP_PATH, dest})
	destFullPath := strings.concatenate([]string{destNameAndPath, const.OST_FILE_EXTENSION})

	c, creationSuccess := os.open(destFullPath, os.O_CREATE | os.O_RDWR, 0o666)
	defer os.close(c)
	if creationSuccess != 0 {
		error1 := new_err(.CANNOT_CREATE_FILE, get_err_msg(.CANNOT_CREATE_FILE), #procedure)
		throw_custom_err(error1, "Could not create collection file for backup")
		return false
	}
	w, writeSuccess := os.write(c, data)
	if writeSuccess != 0 {
		error1 := new_err(.CANNOT_WRITE_TO_FILE, get_err_msg(.CANNOT_WRITE_TO_FILE), #procedure)
		throw_custom_err(error1, "Could not write to collection file for backup")
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
	}
	str := strings.trim_right(string(buf[:n]), "\r\n")
	fmt.printfln("You chose: %s", str)

	return str
}
