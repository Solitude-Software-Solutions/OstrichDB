package data
import "../../../utils"
import "../../const"
import "../../types"
import "./metadata"
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
            Contains logic for handling collection files(databases), including
            creation, deletion, renaming, and fetching data from
            collections as a whole.
*********************************************************/


main :: proc() {
	using const

	//Create the core dirs and files OstrichDB needs to function
	metadata.CREATE_FFV_FILE()
	os.make_directory(PRIVATE_PATH)
	os.make_directory(PUBLIC_PATH)
	os.make_directory(STANDARD_COLLECTION_PATH)
	os.make_directory(USERS_PATH)
	os.make_directory(QUARANTINE_PATH)
	os.make_directory(BACKUP_PATH)
	CREATE_AND_FILL_PRIVATE_ID_COLLECTION()
}


//Displays all collections. total also shows size of the data in bytes.
//Todo: Not really a tree, was implemented before but i took it out because it was fucking up - Marshall
GET_COLLECTION_TREE :: proc() {
	dir, _ := os.open(const.STANDARD_COLLECTION_PATH)
	collections, _ := os.read_dir(dir, 1)
	totalSize: i64

	fmt.println("-----------------------------\n")
	for collection in collections {
		nameWithoutExtension := strings.trim_suffix(collection.name, const.OST_EXT)
		fmt.printfln("Name: %s       Bytes:%d", nameWithoutExtension, collection.size)
		totalSize = totalSize + collection.size
	}

	fmt.println()
	fmt.printfln("Grand Total: %d Bytes (Includes Metadata Header)", totalSize)
	fmt.println("-----------------------------\n")

}


/*
Creates a new collection file with metadata within the DB
standard -  CollectionType.STANDARD_PUBLIC
secure - CollectionType.SECURE_PRIVATE
config - CollectionType.CONFIG_PRIVATE
history - CollectionType.HISTORY_PRIVATE
id - CollectionType.ID_PRIVATE
*/
CREATE_COLLECTION :: proc(fn: string, colType: types.CollectionType) -> bool {
	// concat the path and the file name into a string depending on the type of file to create
	pathAndName: string
	#partial switch (colType)
	{
	case .STANDARD_PUBLIC:
		//standard cluster file
		if VALIDATE_COLLECTION_NAME(fn) == 1 {
			return false
		}
		collectionPath := utils.concat_standard_collection_name(fn)
		createFile, createSuccess := os.open(collectionPath, os.O_CREATE, 0o666)
		metadata.APPEND_METADATA_HEADER(collectionPath)
		metadata.CHANGE_METADATA_MEMBER_VALUE(fn, "Read-Write", 1, colType)
		if createSuccess != 0 {
		errorLocation:= utils.get_caller_location()
			error1 := utils.new_err(
				.CANNOT_CREATE_FILE,
				utils.get_err_msg(.CANNOT_CREATE_FILE),
				errorLocation
			)
			utils.throw_err(error1)
			utils.log_err("Error creating new collection file", #procedure)
			return false
		}
		metadata.UPDATE_METADATA_UPON_CREATION(collectionPath)
		defer os.close(createFile)
		return true
	case .SECURE_PRIVATE:
		//secure file
		if VALIDATE_COLLECTION_NAME(fn) == 1 {
			return false
		}
		collectionPath := utils.concat_user_credential_path(fn)
		createFile, createSuccess := os.open(collectionPath, os.O_CREATE, 0o644)
		metadata.APPEND_METADATA_HEADER(collectionPath)
		metadata.CHANGE_METADATA_MEMBER_VALUE(fn, "Inaccessible", 1, colType)
		if createSuccess != 0 {
		errorLocation:= utils.get_caller_location()
			error1 := utils.new_err(
				.CANNOT_CREATE_FILE,
				utils.get_err_msg(.CANNOT_CREATE_FILE),
				errorLocation
			)
			utils.throw_err(error1)
			utils.log_err("Error creating collection file", #procedure)
			return false
		}
		metadata.UPDATE_METADATA_UPON_CREATION(collectionPath)
		defer os.close(createFile)
		return true

	case .SYSTEM_CONFIG_PRIVATE:
		collectionPath := const.SYSTEM_CONFIG_PATH
		createFile, createSuccess := os.open(collectionPath, os.O_CREATE, 0o644)
		metadata.APPEND_METADATA_HEADER(collectionPath)
		metadata.CHANGE_METADATA_MEMBER_VALUE(fn, "Read-Write", 1, colType)
		if createSuccess != 0 {
		errorLocation:= utils.get_caller_location()
			error1 := utils.new_err(
				.CANNOT_CREATE_FILE,
				utils.get_err_msg(.CANNOT_CREATE_FILE),
				errorLocation
			)
			utils.throw_err(error1)
			utils.log_err("Error creating collection file", #procedure)
			return false
		}
		metadata.UPDATE_METADATA_UPON_CREATION(collectionPath)
		defer os.close(createFile)
		return true
	case .USER_CONFIG_PRIVATE:
	collectionPath := utils.concat_user_config_collection_name(fn)
	createFile, createSuccess := os.open(collectionPath, os.O_CREATE, 0o644)
	metadata.APPEND_METADATA_HEADER(collectionPath)
	metadata.CHANGE_METADATA_MEMBER_VALUE(fn, "Read-Write", 1, colType)
	if createSuccess != 0 {
	errorLocation:= utils.get_caller_location()
		error1 := utils.new_err(
			.CANNOT_CREATE_FILE,
			utils.get_err_msg(.CANNOT_CREATE_FILE),
			errorLocation
		)
		utils.throw_err(error1)
		utils.log_err("Error creating collection file", #procedure)
		return false
	}
	metadata.UPDATE_METADATA_UPON_CREATION(collectionPath)
	defer os.close(createFile)
	return true
	case .HISTORY_PRIVATE:
		collectionPath := utils.concat_user_history_path(fn)
		createFile, createSuccess := os.open(collectionPath, os.O_CREATE, 0o644)
		metadata.APPEND_METADATA_HEADER(collectionPath)
		metadata.CHANGE_METADATA_MEMBER_VALUE(fn, "Inaccessible", 1, colType)
		if createSuccess != 0 {
			errorLocation:= utils.get_caller_location()
			error1 := utils.new_err(
				.CANNOT_CREATE_FILE,
				utils.get_err_msg(.CANNOT_CREATE_FILE),
				errorLocation
			)
			utils.throw_err(error1)
			utils.log_err("Error creating collection file", #procedure)
			return false
		}
		metadata.UPDATE_METADATA_UPON_CREATION(collectionPath)
		defer os.close(createFile)
		return true

	case .ID_PRIVATE:
		collectionPath := const.ID_PATH
		createFile, createSuccess := os.open(collectionPath, os.O_CREATE, 0o644)
		metadata.APPEND_METADATA_HEADER(collectionPath)
		metadata.CHANGE_METADATA_MEMBER_VALUE(fn, "Inaccessible", 1, colType)
		if createSuccess != 0 {
		errorLocation := utils.get_caller_location()
			error1 := utils.new_err(
				.CANNOT_CREATE_FILE,
				utils.get_err_msg(.CANNOT_CREATE_FILE),
				errorLocation
			)
			utils.throw_err(error1)
			utils.log_err("Error creating collection file", #procedure)
			return false
		}
		metadata.UPDATE_METADATA_UPON_CREATION(collectionPath)
		defer os.close(createFile)
		return true
	}
	return false
}


ERASE_COLLECTION :: proc(fn: string, isOnServer: bool) -> bool {
	using utils
	using types

	buf: [64]byte
	fileWithExt := strings.concatenate([]string{fn, const.OST_EXT})
	if !CHECK_IF_COLLECTION_EXISTS(fn, 0) {
		return false
	}

	if !isOnServer {
		fmt.printfln(
			"Are you sure that you want to delete Collection: %s%s%s?\nThis action can not be undone.",
			BOLD_UNDERLINE,
			fn,
			RESET,
		)
		fmt.printfln("Type 'yes' to confirm or 'no' to cancel.")
		input := utils.get_input(false)

		cap := strings.to_upper(input)

		switch (cap) {
		case Token[.NO]:
			log_runtime_event("User canceled deletion", "User canceled deletion of collection")
			return false
		case Token[.YES]:
		// Continue with deletion
		case:
			log_runtime_event(
				"User entered invalid input",
				"User entered invalid input when trying to delete collection",
			)
			errorLocation:= get_caller_location()
			error2 := new_err(
				.INVALID_INPUT,
				get_err_msg(.INVALID_INPUT),
				errorLocation
			)
			throw_custom_err(error2, "Invalid input. Please type 'yes' or 'no'.")
			return false
		}
	}
	collectionPath := concat_standard_collection_name(fn)

	// Delete the file
	deleteSuccess := os.remove(collectionPath)
	if deleteSuccess != 0 {
	errorLocation:= get_caller_location()
		error1 := new_err(
			.CANNOT_DELETE_FILE,
			get_err_msg(.CANNOT_DELETE_FILE),
			errorLocation
		)
		throw_err(error1)
		log_err("Error deleting collection file", #procedure)
		return false
	}

	log_runtime_event(
		"Collection deleted",
		"User confirmed deletion of collection and it was successfully deleted .",
	)
	return true
}

//Checks if the passed in collection name is valid
VALIDATE_COLLECTION_NAME :: proc(fn: string) -> int {
	using utils

	nameAsBytes := transmute([]byte)fn
	if len(nameAsBytes) > len(const.MAX_COLLECTION_NAME_LENGTH) {
		fmt.printfln("Given file name is too long, Cannot exceed 512 bytes")
		return 1
	}
	//CHECK#2: check if the file already exists
	existenceCheck, readSuccess := os.read_entire_file_from_filename(fn)
	if readSuccess {
	errorLocation:= get_caller_location()
		error1 := new_err(
			.FILE_ALREADY_EXISTS,
			get_err_msg(.FILE_ALREADY_EXISTS),
			errorLocation
		)
		throw_err(error1)
		log_err("collection file already exists", #procedure)
		return 1
	}
	//CHECK#3: check if the file name is valid
	invalidChars := "[]{}()<>;:.,?/\\|`~!@#$%^&*+="
	for c := 0; c < len(fn); c += 1 {
		if strings.contains_any(fn, invalidChars) {
			fmt.printfln("Invalid character(s) found in file name: %s", fn)
			return 1
		}
	}
	return 0
}


//checks if the passed in ost file exists in "./collections". see usage in OST_CHOOSE_COLLECTION()
//type 0 is for standard collection files, type 1 is for secure files
CHECK_IF_COLLECTION_EXISTS :: proc(fn: string, type: int) -> bool {
	switch (type) {
	case 0:
		colPath, openSuccess := os.open(const.STANDARD_COLLECTION_PATH)
		collections, readSuccess := os.read_dir(colPath, -1)

		for collection in collections {
			if collection.name == fmt.tprintf("%s%s", fn, const.OST_EXT) {
				return true
			}
		}
		break
	case 1:
		secCollection, openSuccess := os.open(utils.concat_user_credential_path(types.user.username.Value))
		secureCollections, readSuccess := os.read_dir(secCollection, -1)

		for collection in secureCollections {
			if collection.name == fmt.tprintf("%s%s", fn, const.OST_EXT) {
				return true
			}
		}
		break
	}


	return false
}


RENAME_COLLECTION :: proc(old: string, new: string) -> bool {
	colPath := fmt.tprintf("%s%s%s", const.STANDARD_COLLECTION_PATH, old, const.OST_EXT)

	file, readSuccess := os.read_entire_file_from_filename(colPath)
	if !readSuccess {
	errorLocation:= utils.get_caller_location()
		error1 := utils.new_err(
			.CANNOT_READ_FILE,
			utils.get_err_msg(.CANNOT_READ_FILE),
			errorLocation
		)
		utils.throw_err(error1)
		utils.log_err("Error reading collection file", #procedure)
		return false
	}

	name := utils.concat_standard_collection_name(new)
	renamed := os.rename(colPath, name)

	when ODIN_OS == .Linux {
		if renamed != os.ERROR_NONE {
			utils.log_err("Error renaming collection file", #procedure)
			return false
		}
	}
	when ODIN_OS == .Darwin {
		if renamed != true {
			utils.log_err("Error renaming collection file", #procedure)
			return false
		}
	}

	return true
}

//reads and returns the body of a collection file
FETCH_COLLECTION :: proc(fn: string) -> string {
	fileStart := -1
	startingPoint := "BTM@@@@@@@@@@@@@@@" //has to be half of the metadata header end mark and not the full thing..IDK why - Marshall
	collectionPath := utils.concat_standard_collection_name(fn)
	data, readSuccess := os.read_entire_file(collectionPath)
	if !readSuccess {
	errorLocation:= utils.get_caller_location()
		error1 := utils.new_err(
			.CANNOT_READ_FILE,
			utils.get_err_msg(.CANNOT_READ_FILE),
			errorLocation
		)
		utils.throw_err(error1)
		utils.log_err("Error reading collection file", #procedure)
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
	str := strings.join(lines[fileStart:], "\n")
	return strings.clone(str)
}


//Searches for a secure collection file
FIND_SECURE_COLLECTION :: proc(fn: string) -> (bool, string) {
	secDir, e := os.open(utils.concat_user_credential_path(types.current_user.username.Value))
	files, readDirSuccess := os.read_dir(secDir, -1)
	found := false
	for file in files {
		if file.name == fmt.tprintf("secure_%s%s", fn, const.OST_EXT) {

			found = true
		}
	}
	return found, ""
}

//gets the number of standard collections
GET_COLLECTION_COUNT :: proc() -> int {
	using const

	collectionsDir, errOpen := os.open(STANDARD_COLLECTION_PATH)
	defer os.close(collectionsDir)
	foundFiles, dirReadSuccess := os.read_dir(collectionsDir, -1)
	collectionNames := make([dynamic]string)
	defer delete(collectionNames)

	for file in foundFiles {
		if strings.contains(file.name, OST_EXT) {
			append(&collectionNames, file.name)
		}
	}
	return len(collectionNames)
}

//deletes all data from a collection file but keeps the metadata header
PURGE_COLLECTION :: proc(fn: string) -> bool {
	using utils

	collectionPath := utils.concat_standard_collection_name(fn)

	// Read the entire file
	data, readSuccess := os.read_entire_file(collectionPath)
	if !readSuccess {
	errorLocation:= get_caller_location()
		throw_err(
			new_err(.CANNOT_READ_FILE, get_err_msg(.CANNOT_READ_FILE), errorLocation),
		)
		log_err("Error reading collection file", #procedure)
		return false
	}
	defer delete(data)

	// Find the end of the metadata header
	content := string(data)
	headerEndIndex := strings.index(content, const.METADATA_END)
	if headerEndIndex == -1 {
	errorLocation:= get_caller_location()
		throw_err(
			new_err(.FILE_FORMAT_NOT_VALID, "Metadata header not found", errorLocation),
		)
		log_err("Invalid collection file format", #procedure)
		return false
	}

	// Get the metadata header
	headerEndIndex += len(const.METADATA_END) + 1
	metaDataHeader := content[:headerEndIndex]


	// Write back only the header
	writeSuccess := os.write_entire_file(collectionPath, transmute([]byte)metaDataHeader)
	if !writeSuccess {
	errorLocation:= get_caller_location()
		throw_err(
			new_err(
				.CANNOT_WRITE_TO_FILE,
				get_err_msg(.CANNOT_WRITE_TO_FILE),
				errorLocation
			),
		)
		log_err("Error writing purged collection file", #procedure)
		return false
	}
	log_runtime_event("Collection purged", fmt.tprintf("User purged collection: %s", fn))

	return true
}

//LOCK foo -r makes the collection read only
//LOCK foo -n makes the collection inaccessible
//LOCK foo without a flag makes the collection Inaccessible by default
LOCK_COLLECTION :: proc(fn: string, flag: string) -> (result: bool, newPerm: string) {
	val: string
	if flag == "-R" {
		val = "Read-Only"
	} else if flag == "-N" {
		val = "Inaccessible"
	} else {
		fmt.printfln("Invalid flag provided")
		return false, ""
	}
	fmt.printfln("%s() is getting... fn:%s, val:%s, flag:%s ", #procedure, fn, val, flag)
	success := metadata.CHANGE_METADATA_MEMBER_VALUE(fn, val, 1, .STANDARD_PUBLIC)
	return success, val
}

//Reverts the permission status of a collection no matter if its in Read-Only or Inaccessible back to Read-Write
UNLOCK_COLLECTION :: proc(fn, currentPerm: string) -> bool {
	success := false
	if currentPerm == "Inaccessible" {
		success = metadata.CHANGE_METADATA_MEMBER_VALUE(fn, "Read-Write", 1, .STANDARD_PUBLIC)
		fmt.printfln("Collection %s%s%s unlocked", utils.BOLD_UNDERLINE, fn, utils.RESET)
	} else if currentPerm == "Read-Only" {
		success = metadata.CHANGE_METADATA_MEMBER_VALUE(fn, "Read-Write", 1, .STANDARD_PUBLIC)
		fmt.printfln("Collection %s%s%s unlocked", utils.BOLD_UNDERLINE, fn, utils.RESET)
	} else {
		fmt.printfln(
			"Invalid permission value found in collection: %s%s%s",
			utils.BOLD_UNDERLINE,
			fn,
			utils.RESET,
		)
		return false
	}
	return success
}
