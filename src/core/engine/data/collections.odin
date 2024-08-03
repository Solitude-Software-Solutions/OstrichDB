package data


import "../../../utils"
import "../../const"
import "./metadata"
import "core:fmt"
import "core:os"
import "core:strings"

MAX_FILE_NAME_LENGTH_AS_BYTES: [512]byte


//used for the command line
OST_CHOOSE_COLLECTION_NAME :: proc() {
	buf: [1024]byte
	n, inputSuccess := os.read(os.stdin, buf[:])

	if inputSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_READ_INPUT,
			utils.get_err_msg(.CANNOT_READ_INPUT),
			#procedure,
		)
		utils.throw_err(error1)
	}
	name := strings.trim_right(string(buf[:n]), "\n")
	OST_CREATE_COLLECTION(name, 0)
}


/*
Creates a new collection file with metadata within the DB
collections are "collectiions" of clusters stored in a .ost file
Params: fileName - the desired file(cluster) name
				type - the type of file to create, 0 is standard, 1 is secure
*/
OST_CREATE_COLLECTION :: proc(fileName: string, collectionType: int) -> bool {
	// concat the path and the file name into a string depending on the type of file to create
	pathAndName: string
	switch (collectionType) 
	{
	case 0:
		//standard cluster file
		pathAndName := strings.concatenate([]string{const.OST_COLLECTION_PATH, fileName})
		if OST_PREFORM_COLLECTION_NAME_CHECK(fileName) == 1 {
			return false
		}
		pathNameExtension := strings.concatenate([]string{pathAndName, const.OST_FILE_EXTENSION})
		createFile, createSuccess := os.open(pathNameExtension, os.O_CREATE, 0o666)
		metadata.OST_APPEND_METADATA_HEADER(pathNameExtension)
		if createSuccess != 0 {
			error1 := utils.new_err(
				.CANNOT_CREATE_FILE,
				utils.get_err_msg(.CANNOT_CREATE_FILE),
				#procedure,
			)
			utils.throw_err(error1)
			utils.log_err("Error creating .ost file", "OST_CREATE_COLLECTION")
			return false
		}
		metadata.OST_METADATA_ON_CREATE(pathNameExtension)
		defer os.close(createFile)
		break
	case 1:
		//secure file
		pathAndName := strings.concatenate([]string{const.OST_SECURE_CLUSTER_PATH, fileName})
		if OST_PREFORM_COLLECTION_NAME_CHECK(fileName) == 1 {
			return false
		}
		pathNameExtension := strings.concatenate([]string{pathAndName, const.OST_FILE_EXTENSION})
		createFile, createSuccess := os.open("../bin/secure/_secure_.ost", os.O_CREATE, 0o644)
		metadata.OST_APPEND_METADATA_HEADER(pathNameExtension)
		if createSuccess != 0 {
			error1 := utils.new_err(
				.CANNOT_CREATE_FILE,
				utils.get_err_msg(.CANNOT_CREATE_FILE),
				#procedure,
			)
			utils.throw_err(error1)
			utils.log_err("Error creating .ost file", "OST_CREATE_COLLECTION")
			return false
		}
		metadata.OST_METADATA_ON_CREATE(pathNameExtension)
		defer os.close(createFile)

	}
	return true
}


OST_ERASE_COLLECTION :: proc(fileName: string) -> bool {
	buf: [64]byte
	fileWithExt := strings.concatenate([]string{fileName, const.OST_FILE_EXTENSION})
	fmt.printfln("Deleting database: %s%s%s", utils.BOLD, fileWithExt, utils.RESET)
	if !OST_CHECK_IF_COLLECTION_EXISTS(fileName, 0) {
		fmt.printfln(
			"Database with name:%s%s%s does not exist",
			utils.BOLD,
			fileWithExt,
			utils.RESET,
		)
		return false
	}
	fmt.printfln(
		"Are you sure that you want to delete Collection: %s%s%s?\nThis action can not be undone.",
		utils.BOLD,
		fileName,
		utils.RESET,
	)
	fmt.printfln("Type 'yes' to confirm or 'no' to cancel.")
	n, inputSuccess := os.read(os.stdin, buf[:])
	if inputSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_READ_INPUT,
			utils.get_err_msg(.CANNOT_READ_INPUT),
			#procedure,
		)
		utils.throw_err(error1)
	}

	confirmation := strings.trim_right(string(buf[:n]), "\r\n")
	cap := strings.to_upper(confirmation)

	switch (cap) 
	{
	case const.YES:
		// /delete the file
		pathAndName := strings.concatenate([]string{const.OST_COLLECTION_PATH, fileName})
		pathNameExtension := strings.concatenate([]string{pathAndName, const.OST_FILE_EXTENSION})
		deleteSuccess := os.remove(pathNameExtension)
		if deleteSuccess != 0 {
			error1 := utils.new_err(
				.CANNOT_DELETE_FILE,
				utils.get_err_msg(.CANNOT_DELETE_FILE),
				#procedure,
			)
			utils.throw_err(error1)
			utils.log_err("Error deleting .ost file", "OST_ERASE_COLLECTION")
			return false
		}
		fmt.printfln(
			"Database with name:%s%s%s has been deleted",
			utils.BOLD,
			fileName,
			utils.RESET,
		)
		utils.log_runtime_event(
			"Database deleted",
			"User confirmed deletion of database and it was successfully deleted .",
		)
		break

	case const.NO:
		utils.log_runtime_event("User canceled deletion", "User canceled deletion of database")
		return false
	case:
		utils.log_runtime_event(
			"User entered invalid input",
			"User entered invalid input when trying to delete database",
		)
		error2 := utils.new_err(.INVALID_INPUT, utils.get_err_msg(.INVALID_INPUT), #procedure)
		utils.throw_custom_err(error2, "Invalid input. Please type 'yes' or 'no'.")
		return false
	}
	return true
}


OST_PREFORM_COLLECTION_NAME_CHECK :: proc(fn: string) -> int {
	nameAsBytes := transmute([]byte)fn
	if len(nameAsBytes) > len(MAX_FILE_NAME_LENGTH_AS_BYTES) {
		fmt.printfln("Given file name is too long, Cannot exceed 512 bytes")
		return 1
	}
	//CHECK#2: check if the file already exists
	existenceCheck, readSuccess := os.read_entire_file_from_filename(fn)
	if readSuccess {
		error1 := utils.new_err(
			.FILE_ALREADY_EXISTS,
			utils.get_err_msg(.FILE_ALREADY_EXISTS),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err(".ost file already exists", "OST_CREATE_COLLECTION")
		return 1
	}
	//CHECK#3: check if the file name is valid
	invalidChars := "[]{}()<>;:.,?/\\|`~!@#$%^&*+-="
	for c := 0; c < len(fn); c += 1 {
		if strings.contains_any(fn, invalidChars) {
			fmt.printfln("Invalid character(s) found in file name: %s", fn)
			return 1
		}
	}
	return 0
}


//checks if the passed in ost file exists in "../bin/clusters". see usage in OST_CHOOSE_COLLECTION()
//type 0 is for standard collection files, type 1 is for secure files
OST_CHECK_IF_COLLECTION_EXISTS :: proc(fn: string, type: int) -> bool {
	dbExists: bool
	//need to cwd into bin
	os.set_current_directory("../bin/")
	dir: string
	switch (type) 
	{
	case 0:
		dir = "collections/"
		break
	case 1:
		dir = "secure/"
		break
	}

	fileWithExt := strings.concatenate([]string{fn, const.OST_FILE_EXTENSION})
	collectionsDir, errOpen := os.open(dir)

	defer os.close(collectionsDir)
	foundFiles, dirReadSuccess := os.read_dir(collectionsDir, -1)
	for file in foundFiles {
		if (file.name == fileWithExt) {
			dbExists = true
			return dbExists
		}
	}
	return dbExists
}


OST_RENAME_COLLECTION :: proc(old: string, new: string) -> bool {
	oldPath := strings.concatenate([]string{const.OST_COLLECTION_PATH, old})
	oldPathAndExt := strings.concatenate([]string{oldPath, const.OST_FILE_EXTENSION})
	file, readSuccess := os.read_entire_file_from_filename(oldPathAndExt)
	if !readSuccess {
		error1 := utils.new_err(
			.CANNOT_READ_FILE,
			utils.get_err_msg(.CANNOT_READ_FILE),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Error reading .ost file", "OST_RENAME_COLLECTION")
		return false
	}

	newName := strings.concatenate([]string{const.OST_COLLECTION_PATH, new})
	newNameExt := strings.concatenate([]string{newName, const.OST_FILE_EXTENSION})
	renamed := os.rename(oldPathAndExt, newNameExt)
	return true
}

//reads and retuns everything below the metadata header in the .ost file
OST_FETCH_COLLECTION :: proc(fn: string) -> string {
	fileStart := -1
	startingPoint := "[Ostrich File Header End]"
	filePath := strings.concatenate([]string{const.OST_COLLECTION_PATH, fn})
	filePathAndExt := strings.concatenate([]string{filePath, const.OST_FILE_EXTENSION})
	data, readSuccess := os.read_entire_file(filePathAndExt)
	if !readSuccess {
		error1 := utils.new_err(
			.CANNOT_READ_FILE,
			utils.get_err_msg(.CANNOT_READ_FILE),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Error reading .ost file", "OST_FETCH_COLLECTION")
		return ""
	}
	defer delete(data)
	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)
	for i := 0; i < len(lines); i += 1 {
		if strings.contains(lines[i], startingPoint) {
			fileStart = i + 1 // Start from the next line after the header
			break
		}
	}
	if fileStart == -1 || fileStart >= len(lines) {
		return "No data found after header"
	}
	return strings.join(lines[fileStart:], "\n")
}
