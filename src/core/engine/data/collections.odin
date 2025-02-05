package data
import "../../../utils"
import "../../const"
import "../../types"
import "./metadata"
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

MAX_FILE_NAME_LENGTH: [512]byte


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
		utils.log_err("Error reading user input", #procedure)
	}
	name := strings.trim_right(string(buf[:n]), "\n")
	_ = OST_CREATE_COLLECTION(strings.clone(name), 0)
}

/*
Creates a new collection file with metadata within the DB
0 standard
1 secure
2 history file
3 config file
4 id cache file
*/

OST_CREATE_COLLECTION :: proc(fn: string, collectionType: int) -> bool {
	// concat the path and the file name into a string depending on the type of file to create
	pathAndName: string
	switch (collectionType) 
	{
	case 0:
		//standard cluster file
		if OST_PERFORM_COLLECTION_NAME_CHECK(fn) == 1 {
			return false
		}
		collectionPath := utils.concat_collection_name(fn)
		createFile, createSuccess := os.open(collectionPath, os.O_CREATE, 0o666)
		metadata.OST_APPEND_METADATA_HEADER(collectionPath)
		if createSuccess != 0 {
			error1 := utils.new_err(
				.CANNOT_CREATE_FILE,
				utils.get_err_msg(.CANNOT_CREATE_FILE),
				#procedure,
			)
			utils.throw_err(error1)
			utils.log_err("Error creating new collection file", #procedure)
			return false
		}
		metadata.OST_UPDATE_METADATA_ON_CREATE(collectionPath)
		defer os.close(createFile)
		return true
	case 1:
		//secure file
		if OST_PERFORM_COLLECTION_NAME_CHECK(fn) == 1 {
			return false
		}
		collectionPath := fmt.tprintf(
			"%s%s%s",
			const.OST_SECURE_COLLECTION_PATH,
			fn,
			const.OST_FILE_EXTENSION,
		)
		createFile, createSuccess := os.open(collectionPath, os.O_CREATE, 0o644)
		metadata.OST_APPEND_METADATA_HEADER(collectionPath)
		if createSuccess != 0 {
			error1 := utils.new_err(
				.CANNOT_CREATE_FILE,
				utils.get_err_msg(.CANNOT_CREATE_FILE),
				#procedure,
			)
			utils.throw_err(error1)
			utils.log_err("Error creating .ost file", #procedure)
			return false
		}
		metadata.OST_UPDATE_METADATA_ON_CREATE(collectionPath)
		defer os.close(createFile)
		return true
	case 2, 3, 4:
		collectionPath := fmt.tprintf("%s%s%s", const.OST_CORE_PATH, fn, const.OST_FILE_EXTENSION)
		createFile, createSuccess := os.open(collectionPath, os.O_CREATE, 0o644)
		metadata.OST_APPEND_METADATA_HEADER(collectionPath)
		if createSuccess != 0 {
			error1 := utils.new_err(
				.CANNOT_CREATE_FILE,
				utils.get_err_msg(.CANNOT_CREATE_FILE),
				#procedure,
			)
			utils.throw_err(error1)
			utils.log_err("Error creating .ost file", #procedure)
			return false
		}
		metadata.OST_UPDATE_METADATA_ON_CREATE(collectionPath)
		defer os.close(createFile)
		return true
	}
	return false
}


OST_ERASE_COLLECTION :: proc(fn: string) -> bool {
	using utils

	buf: [64]byte
	fileWithExt := strings.concatenate([]string{fn, const.OST_FILE_EXTENSION})
	if !OST_CHECK_IF_COLLECTION_EXISTS(fn, 0) {
		return false
	}

	// Skip confirmation if in testing mode
	if !types.TESTING {
		fmt.printfln(
			"Are you sure that you want to delete Collection: %s%s%s?\nThis action can not be undone.",
			BOLD_UNDERLINE,
			fn,
			RESET,
		)
		fmt.printfln("Type 'yes' to confirm or 'no' to cancel.")
		n, inputSuccess := os.read(os.stdin, buf[:])
		if inputSuccess != 0 {
			error1 := new_err(.CANNOT_READ_INPUT, get_err_msg(.CANNOT_READ_INPUT), #procedure)
			throw_err(error1)
			log_err("Error reading user input", #procedure)
		}

		confirmation := strings.trim_right(string(buf[:n]), "\r\n")
		cap := strings.to_upper(confirmation)

		switch (cap) {
		case const.NO:
			log_runtime_event("User canceled deletion", "User canceled deletion of collection")
			return false
		case const.YES:
		// Continue with deletion
		case:
			log_runtime_event(
				"User entered invalid input",
				"User entered invalid input when trying to delete collection",
			)
			error2 := new_err(.INVALID_INPUT, get_err_msg(.INVALID_INPUT), #procedure)
			throw_custom_err(error2, "Invalid input. Please type 'yes' or 'no'.")
			return false
		}
	}

	collectionPath := concat_collection_name(fn)

	// Delete the file
	deleteSuccess := os.remove(collectionPath)
	if deleteSuccess != 0 {
		error1 := new_err(.CANNOT_DELETE_FILE, get_err_msg(.CANNOT_DELETE_FILE), #procedure)
		throw_err(error1)
		log_err("Error deleting .ost file", #procedure)
		return false
	}

	log_runtime_event(
		"Collection deleted",
		"User confirmed deletion of collection and it was successfully deleted .",
	)
	return true
}

//Checks if the passed in collection name is valid
OST_PERFORM_COLLECTION_NAME_CHECK :: proc(fn: string) -> int {
	using utils

	nameAsBytes := transmute([]byte)fn
	if len(nameAsBytes) > len(MAX_FILE_NAME_LENGTH) {
		fmt.printfln("Given file name is too long, Cannot exceed 512 bytes")
		return 1
	}
	//CHECK#2: check if the file already exists
	existenceCheck, readSuccess := os.read_entire_file_from_filename(fn)
	if readSuccess {
		error1 := new_err(.FILE_ALREADY_EXISTS, get_err_msg(.FILE_ALREADY_EXISTS), #procedure)
		throw_err(error1)
		log_err("collection file already exists", #procedure)
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


//checks if the passed in ost file exists in "./collections". see usage in OST_CHOOSE_COLLECTION()
//type 0 is for standard collection files, type 1 is for secure files
OST_CHECK_IF_COLLECTION_EXISTS :: proc(fn: string, type: int) -> bool {
	switch (type) {
	case 0:
		colPath, openSuccess := os.open(const.OST_COLLECTION_PATH)
		collections, readSuccess := os.read_dir(colPath, -1)

		for collection in collections {
			if collection.name == fmt.tprintf("%s%s", fn, const.OST_FILE_EXTENSION) {
				return true
			}
		}
		break
	case 1:
		secColPath, openSuccess := os.open(const.OST_SECURE_COLLECTION_PATH)
		secureCollections, readSuccess := os.read_dir(secColPath, -1)

		for collection in secureCollections {
			if collection.name == fmt.tprintf("%s%s", fn, const.OST_FILE_EXTENSION) {
				return true
			}
		}
		break
	}


	return false
}


OST_RENAME_COLLECTION :: proc(old: string, new: string) -> bool {
	colPath := fmt.tprintf("%s%s%s", const.OST_COLLECTION_PATH, old, const.OST_FILE_EXTENSION)

	file, readSuccess := os.read_entire_file_from_filename(colPath)
	if !readSuccess {
		error1 := utils.new_err(
			.CANNOT_READ_FILE,
			utils.get_err_msg(.CANNOT_READ_FILE),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Error reading provided .ost file", #procedure)
		return false
	}

	name := utils.concat_collection_name(new)
	renamed := os.rename(colPath, name)

	when ODIN_OS == .Linux {
		if renamed != os.ERROR_NONE {
			utils.log_err("Error renaming .ost file", #procedure)
			return false
		}
	}
	when ODIN_OS == .Darwin {
		if renamed != true {
			utils.log_err("Error renaming .ost file", #procedure)
			return false
		}
	}

	return true
}

//reads and returns the body of a collection file
OST_FETCH_COLLECTION :: proc(fn: string) -> string {
	fileStart := -1
	startingPoint := "BTM@@@@@@@@@@@@@@@" //has to be half of the metadata header end mark and not the full thing..IDK why - Marshall
	collectionPath := utils.concat_collection_name(fn)
	data, readSuccess := os.read_entire_file(collectionPath)
	if !readSuccess {
		error1 := utils.new_err(
			.CANNOT_READ_FILE,
			utils.get_err_msg(.CANNOT_READ_FILE),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Error reading .ost file", #procedure)
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

//Returns an array of all public collections
OST_GET_ALL_COLLECTION_NAMES :: proc(showRecords: bool) -> [dynamic]string {
	using const

	collectionsDir, errOpen := os.open(OST_COLLECTION_PATH)
	defer os.close(collectionsDir)
	foundFiles, dirReadSuccess := os.read_dir(collectionsDir, -1)
	collectionNames := make([dynamic]string)
	defer delete(collectionNames)

	result: string


	//only did this to get the length of the collection names
	for file in foundFiles {
		if strings.contains(file.name, OST_FILE_EXTENSION) {
			append(&collectionNames, file.name)
		}
	}
	fmt.printf("\n")
	fmt.printf("\n")
	if len(foundFiles) == 1 {
		fmt.println("Found 1 collection\n--------------------------------", len(collectionNames))
	} else {
		fmt.printfln(
			"Found %d collections\n--------------------------------",
			len(collectionNames),
		)}

	if len(collectionNames) > MAX_COLLECTION_TO_DISPLAY {
		fmt.printf("There is %d collections to display, display all? (y/N) ", len(collectionNames))
		buf: [1024]byte
		n, inputSuccess := os.read(os.stdin, buf[:])
		if inputSuccess != 0 {
			error := utils.new_err(
				.CANNOT_READ_INPUT,
				utils.get_err_msg(.CANNOT_READ_INPUT),
				#procedure,
			)
			utils.throw_err(error)
			utils.log_err("Error reading user input", #procedure)
		}
		if buf[0] != 'y' {
			return collectionNames
		}
	}

	for file in foundFiles {
		if strings.contains(file.name, OST_FILE_EXTENSION) {
			append(&collectionNames, file.name)
			withoutExt := strings.split(file.name, OST_FILE_EXTENSION)
			fmt.println(withoutExt[0])
			OST_LIST_CLUSTERS_IN_FILE(withoutExt[0], showRecords)
		}
	}

	return collectionNames
}


OST_FIND_SEC_COLLECTION :: proc(fn: string) -> (found: bool, name: string) {
	secDir, e := os.open(const.OST_SECURE_COLLECTION_PATH)
	files, readDirSuccess := os.read_dir(secDir, -1)
	found = false
	for file in files {
		if strings.contains(file.name, fn) {
			found = true
			return found, file.name
		}

	}
	return found, ""
}

//gets the number of public collections
OST_COUNT_COLLECTIONS :: proc() -> int {
	using const

	collectionsDir, errOpen := os.open(OST_COLLECTION_PATH)
	defer os.close(collectionsDir)
	foundFiles, dirReadSuccess := os.read_dir(collectionsDir, -1)
	collectionNames := make([dynamic]string)
	defer delete(collectionNames)

	for file in foundFiles {
		if strings.contains(file.name, OST_FILE_EXTENSION) {
			append(&collectionNames, file.name)
		}
	}
	return len(collectionNames)
}

//deletes all data from a collection file but keeps the metadata header
OST_PURGE_COLLECTION :: proc(fn: string) -> bool {
	using utils

	collectionPath := utils.concat_collection_name(fn)

	// Read the entire file
	data, readSuccess := os.read_entire_file(collectionPath)
	if !readSuccess {
		throw_err(new_err(.CANNOT_READ_FILE, get_err_msg(.CANNOT_READ_FILE), #procedure))
		log_err("Error reading collection file", #procedure)
		return false
	}
	defer delete(data)

	// Find the end of the metadata header
	content := string(data)
	headerEndIndex := strings.index(content, "}")
	if headerEndIndex == -1 {
		throw_err(new_err(.FILE_FORMAT_NOT_VALID, "Metadata header not found", #procedure))
		log_err("Invalid collection file format", #procedure)
		return false
	}

	// Extract the metadata header
	header := content[:headerEndIndex + 1]

	// Write back only the header
	writeSuccess := os.write_entire_file(collectionPath, transmute([]byte)header)
	if !writeSuccess {
		throw_err(new_err(.CANNOT_WRITE_TO_FILE, get_err_msg(.CANNOT_WRITE_TO_FILE), #procedure))
		log_err("Error writing purged collection file", #procedure)
		return false
	}
	log_runtime_event("Collection purged", fmt.tprintf("User purged collection: %s", fn))

	return true
}
