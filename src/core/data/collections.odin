package data


import "../../errors"
import "../../logging"
import "../../misc"
import "../const"
import "./metadata"
import "core:fmt"
import "core:os"
import "core:strings"

MAX_FILE_NAME_LENGTH_AS_BYTES: [512]byte


//used for the commnad line
OST_CHOOSE_COLLECTION_NAME :: proc() {
	buf: [1024]byte
	n, inputSuccess := os.read(os.stdin, buf[:])

	if inputSuccess != 0 {
		error1 := errors.new_err(
			.CANNOT_READ_INPUT,
			errors.get_err_msg(.CANNOT_READ_INPUT),
			#procedure,
		)
		errors.throw_err(error1)
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
			error1 := errors.new_err(
				.CANNOT_CREATE_FILE,
				errors.get_err_msg(.CANNOT_CREATE_FILE),
				#procedure,
			)
			errors.throw_err(error1)
			logging.log_utils_error("Error creating .ost file", "OST_CREATE_COLLECTION")
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
			error1 := errors.new_err(
				.CANNOT_CREATE_FILE,
				errors.get_err_msg(.CANNOT_CREATE_FILE),
				#procedure,
			)
			errors.throw_err(error1)
			logging.log_utils_error("Error creating .ost file", "OST_CREATE_COLLECTION")
			return false
		}
		metadata.OST_METADATA_ON_CREATE(pathNameExtension)
		defer os.close(createFile)

	}
	return true
}


OST_ERASE_COLLECTION :: proc(fileName: string) -> bool {
	//check if the file exists
	fileWithExt := strings.concatenate([]string{fileName, const.OST_FILE_EXTENSION})
	fmt.printfln("Deleting database: %s%s%s", misc.BOLD, fileWithExt, misc.RESET)
	if !OST_CHECK_IF_COLLECTION_EXISTS(fileName, 0) {
		fmt.printfln(
			"Database with name:%s%s%s does not exist",
			misc.BOLD,
			fileWithExt,
			misc.RESET,
		)
		return false
	}
	//delete the file
	pathAndName := strings.concatenate([]string{const.OST_COLLECTION_PATH, fileName})
	pathNameExtension := strings.concatenate([]string{pathAndName, const.OST_FILE_EXTENSION})
	deleteSuccess := os.remove(pathNameExtension)
	if deleteSuccess != 0 {
		error1 := errors.new_err(
			.CANNOT_DELETE_FILE,
			errors.get_err_msg(.CANNOT_DELETE_FILE),
			#procedure,
		)
		errors.throw_err(error1)
		logging.log_utils_error("Error deleting .ost file", "OST_ERASE_COLLECTION")
		return false
	}
	fmt.printfln("Database with name:%s%s%s has been deleted", misc.BOLD, fileName, misc.RESET)
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
		error1 := errors.new_err(
			.FILE_ALREADY_EXISTS,
			errors.get_err_msg(.FILE_ALREADY_EXISTS),
			#procedure,
		)
		errors.throw_err(error1)
		logging.log_utils_error(".ost file already exists", "OST_CREATE_COLLECTION")
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


//handle logic for choosing which .ost file the user wants to interact with
OST_CHOOSE_COLLECTION :: proc() {
	buf: [256]byte
	input: string
	ext := ".ost" //concat this to end of input to prevent user from having to type it each time

	fmt.printfln("Enter the name of database that you would like to interact with")

	n, inputSuccess := os.read(os.stdin, buf[:])
	if inputSuccess != 0 {
		error1 := errors.new_err(
			.CANNOT_READ_INPUT,
			errors.get_err_msg(.CANNOT_READ_INPUT),
			#procedure,
		)
		errors.throw_err(error1)
	}
	if n > 0 {
		//todo add option for user to enter a command that lists current dbs
		input := string(buf[:n])
		//trim the string of any whitespace or newline characters

		//Shoutout to the OdinLang Discord for helping me with this...
		input = strings.trim_right_proc(input, proc(r: rune) -> bool {
			return r == '\r' || r == '\n'
		})
		dbName := strings.concatenate([]string{input, ext})
		dbExists := OST_CHECK_IF_COLLECTION_EXISTS(dbName, 1)
		switch (dbExists) 
		{
		case true:
			fmt.printfln(
				"%sFound database%s: %s%s%s",
				misc.GREEN,
				misc.RESET,
				misc.BOLD,
				input,
				misc.RESET,
			)
			//do stuff
			//todo what would the user like to do with this database?
			break
		case false:
			fmt.printfln("Database with name:%s%s%s does not exist", misc.BOLD, input, misc.RESET)
			fmt.printfln("please try again")
			OST_CHOOSE_COLLECTION()
			break
		}
	}
}
