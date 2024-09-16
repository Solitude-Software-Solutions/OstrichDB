package data
import "../../../utils"
import "../../const"
import "./metadata"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//

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
		utils.log_err("Error reading user input", #procedure)
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
		if OST_PREFORM_COLLECTION_NAME_CHECK(fileName) == 1 {
			return false
		}
		pathNameExtension := fmt.tprintf(
			"%s%s%s",
			const.OST_COLLECTION_PATH,
			fileName,
			const.OST_FILE_EXTENSION,
		)
		createFile, createSuccess := os.open(pathNameExtension, os.O_CREATE, 0o666)
		metadata.OST_APPEND_METADATA_HEADER(pathNameExtension)
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
		metadata.OST_METADATA_ON_CREATE(pathNameExtension)
		defer os.close(createFile)
		break
	case 1:
		//secure file
		if OST_PREFORM_COLLECTION_NAME_CHECK(fileName) == 1 {
			return false
		}
		pathNameExtension := fmt.tprintf(
			"%s%s%s",
			const.OST_SECURE_COLLECTION_PATH,
			fileName,
			const.OST_FILE_EXTENSION,
		)
		createFile, createSuccess := os.open(pathNameExtension, os.O_CREATE, 0o644)
		metadata.OST_APPEND_METADATA_HEADER(pathNameExtension)
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
		metadata.OST_METADATA_ON_CREATE(pathNameExtension)
		defer os.close(createFile)

	}
	return true
}


OST_ERASE_COLLECTION :: proc(fileName: string) -> bool {
	buf: [64]byte
	fileWithExt := strings.concatenate([]string{fileName, const.OST_FILE_EXTENSION})
	fmt.printfln("Deleting collection: %s%s%s", utils.BOLD, fileWithExt, utils.RESET)
	if !OST_CHECK_IF_COLLECTION_EXISTS(fileName, 0) {
		fmt.printfln(
			"Collection with name:%s%s%s does not exist",
			utils.BOLD_UNDERLINE,
			fileWithExt,
			utils.RESET,
		)
		return false
	}
	fmt.printfln(
		"Are you sure that you want to delete Collection: %s%s%s?\nThis action can not be undone.",
		utils.BOLD_UNDERLINE,
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
		utils.log_err("Error reading user input", #procedure)
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
			utils.log_err("Error deleting .ost file", #procedure)
			return false
		}
		fmt.printfln(
			"Collection with name:%s%s%s has been deleted",
			utils.BOLD,
			fileName,
			utils.RESET,
		)
		utils.log_runtime_event(
			"Collection deleted",
			"User confirmed deletion of collection and it was successfully deleted .",
		)
		break

	case const.NO:
		utils.log_runtime_event("User canceled deletion", "User canceled deletion of collection")
		return false
	case:
		utils.log_runtime_event(
			"User entered invalid input",
			"User entered invalid input when trying to delete collection",
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
		utils.log_err(".ost file already exists", #procedure)
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
	oldPath := fmt.tprintf("%s%s", const.OST_COLLECTION_PATH, old)
	oldPathAndExt := fmt.tprintf("%s%s", oldPath, const.OST_FILE_EXTENSION)

	file, readSuccess := os.read_entire_file_from_filename(oldPathAndExt)
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

	newName := fmt.tprintf("%s%s", new, const.OST_FILE_EXTENSION)
	newNameExt := fmt.tprintf("%s%s", const.OST_COLLECTION_PATH, newName)
	renamed := os.rename(oldPathAndExt, newNameExt)

	if renamed != 0 {
		utils.log_err("Error renaming .ost file", #procedure)
		return false
	}
	return true
}

//reads and retuns everything below the metadata header in the .ost file
OST_FETCH_COLLECTION :: proc(fn: string) -> string {
	fileStart := -1
	startingPoint := "# [Ostrich File Header End]},"
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
	return str
}


OST_GET_ALL_COLLECTION_NAMES :: proc(showRecords: bool) -> [dynamic]string {

	collectionsDir, errOpen := os.open(const.OST_COLLECTION_PATH)
	defer os.close(collectionsDir)
	foundFiles, dirReadSuccess := os.read_dir(collectionsDir, -1)
	collectionNames := make([dynamic]string)
	defer delete(collectionNames)

	result: string


	//only did this to get the length of the collection names
	for file in foundFiles {
		if strings.contains(file.name, const.OST_FILE_EXTENSION) {
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

	// TODO: consider the clusters and records in the size as well, rather than just collections
	if len(collectionNames) > const.MAX_COLLECTION_TO_DISPLAY {
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
		if strings.contains(file.name, const.OST_FILE_EXTENSION) {
			append(&collectionNames, file.name)
			withoutExt := strings.split(file.name, const.OST_FILE_EXTENSION)
			fmt.println(withoutExt[0])
			OST_LIST_CLUSTERS_IN_FILE(withoutExt[0], showRecords)
		}
	}

	return collectionNames
}


OST_FIND_SEC_COLLECTION :: proc(fn: string) -> (found: bool, name: string) {
	secDir, e := os.open(const.OST_SECURE_COLLECTION_PATH)
	files, readDirSuccess := os.read_dir(secDir, -1)
	found= false
	for file in files {
		if strings.contains(file.name, fn) {
			found = true
			return found, file.name
		}

	}
	return found, ""
}
