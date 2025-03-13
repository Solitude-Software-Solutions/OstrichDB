package metadata

import "../../../../utils"
import "../../../const"
import "../../../types"
import "core:crypto"
import "core:crypto/hash"
import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            Implements the metadata functionality for OstrichDB, Contains
            procedures used for creating, updating, and validating, and reading
            the metadata header for collection files.
*********************************************************/


//Sets the files format version(FFV)
OST_SET_FFV :: proc() -> string {
	ffv := OST_GET_FILE_FORMAT_VERSION()
	str := transmute(string)ffv
	return strings.clone(str)
}

//Gets the files size
OST_GET_FS :: proc(file: string) -> os.File_Info {
	fileSize, _ := os.stat(file)
	return fileSize
}
//this will get the size of the file and then subtract the size of the metadata header
//then return the difference
OST_SUBTRACT_METADATA_SIZE :: proc(file: string) -> (int, int) {
	using const
	using utils
	fileInfo, err := os.stat(file)
	if err != 0 {
		utils.log_err("Error getting file info", #procedure)
		return -1, -1
	}

	totalSize := int(fileInfo.size)

	data, readSuccess := os.read_entire_file(file)
	if !readSuccess {
		log_err("Error reading file", #procedure)
		return -1, -1
	}
	defer delete(data)

	content := string(data)

	// Find metadata end marker
	metadataEnd := strings.index(content, METADATA_END)
	if metadataEnd == -1 {
		log_err("Metadata end marker not found", #procedure)
		return -1, -1
	}

	// Add length of end marker to get total metadata size
	metadataSize := metadataEnd + len(METADATA_END)

	// Return actual content size (total - metadata) and metadata size
	return totalSize - metadataSize, metadataSize
}

// Calculates a SHA-256 checksum for .ost files based on file content
OST_GENERATE_CHECKSUM :: proc(fn: string) -> string {
	using const
	using utils

	data, readSuccess := os.read_entire_file(fn)
	if !readSuccess {
		log_err("Could not read file for checksum calculation", #procedure)
		return ""
	}
	defer delete(data)

	content := string(data)

	//find metadata section boundaries
	metadataStart := strings.index(content, METADATA_START)
	metadataEnd := strings.index(content, METADATA_END)

	if metadataEnd == -1 {
		// For new files, generate unique initial checksum
		uniqueContent := fmt.tprintf("%s_%v", fn, time.now())
		hashedContent := hash.hash_string(hash.Algorithm.SHA256, uniqueContent)
		return strings.clone(fmt.tprintf("%x", hashedContent))
	}

	//extract content minus metadata header
	actualContent := content[metadataEnd + len(METADATA_END):]

	//hash sub metadata header content
	hashedContent := hash.hash_string(hash.Algorithm.SHA256, actualContent)

	//format hash so that its fucking readable...
	splitComma := strings.split(fmt.tprintf("%x", hashedContent), ",")
	joinedSplit := strings.join(splitComma, "")
	trimRBracket := strings.trim(joinedSplit, "]")
	trimLBRacket := strings.trim(trimRBracket, "[")
	NoWhitespace, _ := strings.replace(trimLBRacket, " ", "", -1)

	return strings.clone(NoWhitespace)
}


//!Only used when to append the meta template upon .ost file creation NOT modification
//this appends the metadata header to the file as well as sets the time of creation
OST_APPEND_METADATA_HEADER :: proc(fn: string) -> bool {
	using const
	using utils

	rawData, readSuccess := os.read_entire_file(fn)
	defer delete(rawData)
	if !readSuccess {
		error1 := new_err(
			.CANNOT_READ_FILE,
			get_err_msg(.CANNOT_READ_FILE),
			#file,
			#procedure,
			#line,
		)
		throw_err(error1)
		log_err("Error readinding collection file", #procedure)
		return false
	}

	dataAsStr := cast(string)rawData //todo: why in the hell did I use cast??? just use string() instead???
	if strings.has_prefix(dataAsStr, "@@@@@@@@@@@@@@@TOP@@@@@@@@@@@@@@@") {
		log_err("Metadata header already present", #procedure)
		return false
	}

	file, openSuccess := os.open(fn, os.O_APPEND | os.O_WRONLY, 0o666)
	defer os.close(file)

	if openSuccess != 0 {
		error1 := new_err(
			.CANNOT_OPEN_FILE,
			get_err_msg(.CANNOT_OPEN_FILE),
			#file,
			#procedure,
			#line,
		)
		throw_err(error1)
		log_err("Error opening collection file", #procedure)
		return false
	}

	blockAsBytes := transmute([]u8)strings.concatenate(METADATA_HEADER)

	writter, ok := os.write(file, blockAsBytes)
	if ok != 0 {
		error1 := new_err(
			.CANNOT_WRITE_TO_FILE,
			get_err_msg(.CANNOT_WRITE_TO_FILE),
			#file,
			#procedure,
			#line,
		)
		throw_err(error1)
		log_err("Error writing metadata header to collection file", #procedure)
		return false
	}
	return true
}


//fn = file name, param = metadata value to update.
//1 = File Format Version, 2 = Permission, 3 = Date of Creation, 4 = Date Last Modified, 5 = File Size, 6 = Checksum
AUTO_OST_UPDATE_METADATA_VALUE :: proc(fn: string, param: int) {
	using utils

	data, readSuccess := os.read_entire_file(fn)
	if !readSuccess {
		error1 := new_err(
			.CANNOT_READ_FILE,
			get_err_msg(.CANNOT_READ_FILE),
			#file,
			#procedure,
			#line,
		)
		throw_err(error1)
		return
	}
	defer delete(data)

	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)

	//not doing anything with h,m,s yet but its there if needed
	currentDate, h, m, s := utils.get_date_and_time() // sets the files date of creation(FDOC) or file date last modified(FDLM)
	fileInfo := OST_GET_FS(fn)
	fileSize := fileInfo.size

	found := false
	for line, i in lines {
		switch param {
		case 1:
			if strings.has_prefix(line, "# File Format Version:") {
				lines[i] = fmt.tprintf("# File Format Version: %s", OST_SET_FFV())
				found = true
			}
			break
		case 2:
			if strings.has_prefix(line, "# Permission:") {
				lines[i] = fmt.tprintf("# Permission: %s", "Read-Write")
				found = true
			}
		case 3:
			if strings.has_prefix(line, "# Date of Creation:") {
				lines[i] = fmt.tprintf("# Date of Creation: %s", currentDate)
				found = true
			}
			break
		case 4:
			if strings.has_prefix(line, "# Date Last Modified:") {
				lines[i] = fmt.tprintf("# Date Last Modified: %s", currentDate)
				found = true
			}
			break
		case 5:
			if strings.has_prefix(line, "# File Size:") {
				actualSize, _ := OST_SUBTRACT_METADATA_SIZE(fn)
				if actualSize != -1 {
					lines[i] = fmt.tprintf("# File Size: %d Bytes", actualSize)
					found = true
				} else {
					fmt.printfln("Error calculating file size for file %s", fn)
				}
			}
			break
		case 6:
			if strings.has_prefix(line, "# Checksum:") {
				lines[i] = fmt.tprintf("# Checksum: %s", OST_GENERATE_CHECKSUM(fn))
				found = true
			}
		}
		if found {
			break
		}
	}

	if !found {
		fmt.printfln("Metadata field not found in file. Proc: %s", #procedure)
		return
	}

	newContent := strings.join(lines, "\n")
	writeSuccess := os.write_entire_file(fn, transmute([]byte)newContent)
}

//used when creating a new collection file whether public or not
OST_UPDATE_METADATA_ON_CREATE :: proc(fn: string) {
	AUTO_OST_UPDATE_METADATA_VALUE(fn, 1)
	AUTO_OST_UPDATE_METADATA_VALUE(fn, 3)
	AUTO_OST_UPDATE_METADATA_VALUE(fn, 4)
	AUTO_OST_UPDATE_METADATA_VALUE(fn, 5)
	AUTO_OST_UPDATE_METADATA_VALUE(fn, 6)
}


//Creates the file format version file in the temp dir
OST_CREATE_FFVF :: proc() {
	using const
	using utils

	CURRENT_FFV := get_ost_version()
	os.make_directory(const.OST_TMP_PATH)

	tmpPath := OST_TMP_PATH
	pathAndName := fmt.tprintf("%s%s", tmpPath, OST_FFVF_PATH)

	file, createSuccess := os.open(pathAndName, os.O_CREATE, 0o666)
	defer os.close(file)

	if createSuccess != 0 {
		error1 := new_err(
			.CANNOT_CREATE_FILE,
			get_err_msg(.CANNOT_CREATE_FILE),
			#file,
			#procedure,
			#line,
		)
		throw_custom_err(error1, "Cannot create file format version file")
	}

	//close then open the file again to write to it
	os.close(file)

	f, openSuccess := os.open(pathAndName, os.O_WRONLY, 0o666)
	defer os.close(f)
	ffvAsBytes := transmute([]u8)CURRENT_FFV
	writter, ok := os.write(f, ffvAsBytes)
	if ok != 0 {
		error1 := utils.new_err(
			.CANNOT_WRITE_TO_FILE,
			get_err_msg(.CANNOT_WRITE_TO_FILE),
			#file,
			#procedure,
			#line,
		)
		throw_custom_err(error1, "Cannot write to file format version file")
	}
}

//Gets the file format version from the file format version file
OST_GET_FILE_FORMAT_VERSION :: proc() -> []u8 {
	using const
	using utils

	FFVF := OST_FFVF_PATH
	tmpPath := OST_TMP_PATH
	pathAndName := fmt.tprintf("%s%s", tmpPath, FFVF)

	ffvf, openSuccess := os.open(pathAndName)
	if openSuccess != 0 {
		log_err("Could not open file format version file", #procedure)
	}
	data, e := os.read_entire_file(ffvf)
	if e == false {
		log_err("Could not read file format version file", #procedure)
		return nil
	}
	os.close(ffvf)
	return data
}

//looks over the metadata header in a collection file and verifies the formatting of it
OST_SCAN_METADATA_HEADER_FORMAT :: proc(
	fn: string,
) -> (
	scanSuccess: int,
	invalidHeaderFormat: bool,
) {
	using const
	using utils

	file := concat_collection_name(fn)

	data, readSuccess := read_file(file, #procedure)
	if !readSuccess {
		return -1, true
	}

	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)

	// Check if the metadata header is present
	if !strings.has_prefix(lines[0], "@@@@@@@@@@@@@@@TOP") {
		// fmt.println("Lines[0] ", lines[0]) //debugging
		utils.log_err("Missing metadata start marker", #procedure)
		return -2, true
	}

	// Find the end of metadata section
	metadataEndIndex := -1
	for i in 0 ..< len(lines) {
		if strings.has_prefix(lines[i], "@@@@@@@@@@@@@@@BTM") {
			metadataEndIndex = i
			break
		}
	}

	if metadataEndIndex == -1 {
		log_err("Missing metadata end marker", #procedure)
		return -3, true
	}

	// Verify the header has the correct number of lines
	expectedLines := 7 // 5 metadata fields + start and end markers
	if metadataEndIndex != expectedLines - 1 {
		log_err("Invalid metadata header length", #procedure)
		return 4, true
	}

	// Check each metadata field
	for i in 1 ..< 5 {
		if !strings.has_prefix(lines[i], types.Metadata_Header_Body[i - 1]) {
			log_err(fmt.tprintf("Invalid metadata field format: %s", lines[i]), #procedure)
			return -5, true
		}
	}

	//checks if the file format verion file and the projects version file match
	versionMatch := OST_VALIDATE_FILE_FORMAT_VERSION()
	if !versionMatch {
		log_err("Invalid file format version being used", #procedure)
		return -6, true
	}

	ffv_parts := strings.split(lines[1], ": ")
	if len(ffv_parts) < 2 {
		log_err("Invalid file format version line format", #procedure)
		return -7, true
	}
	collectionVersionValue := ffv_parts[1]


	//compares the collections to the version in the FFV tmp file. Due to alreay checking if the FFV and the project file
	//match, now have to ensure the collection file matches as well.
	FFV := OST_GET_FILE_FORMAT_VERSION()
	if strings.compare(collectionVersionValue, string(FFV)) != 0 {
		log_err(
			"File format version in collection file does not match the file format version",
			#procedure,
		)
		return -8, true
	}

	return 0, false
}

//checks that the FFV tmp file matches the projects version file
OST_VALIDATE_FILE_FORMAT_VERSION :: proc() -> bool {
	FFV := string(OST_GET_FILE_FORMAT_VERSION()) //this is from the .tmp file

	if (strings.compare(FFV, string(utils.get_ost_version())) != 0) {
		utils.log_err("File format version mismatch", #procedure)
		return false
	}
	return true
}

//returns the string value of the passed metadata field
// colType: 1 = public(standard), 2 = history, 3 = config, 4 = ids
OST_GET_METADATA_VALUE :: proc(
	fn, field: string,
	colType: types.CollectionType,
) -> (
	value: string,
	err: int,
) {
	using const
	using utils

	file: string
	#partial switch (colType) {
	case .STANDARD_PUBLIC:
		file = concat_collection_name(fn)
		break
	case .CONFIG_PRIVATE:
		file = OST_CONFIG_PATH
		break
	case .HISTORY_PRIVATE:
		file = OST_HISTORY_PATH
		break
	case .ID_PRIVATE:
		file = OST_ID_PATH
		break
	}

	data, readSuccess := utils.read_file(file, #procedure)
	if !readSuccess {
		fmt.println("Error reading file: ", file)
		utils.log_err("Error reading file", #procedure)
		return "", 1
	}
	defer delete(data)

	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)

	// fmt.println("lines: ", lines)
	// Check if the metadata header is present
	if !strings.has_prefix(lines[0], "@@@@@@@@@@@@@@@TOP") {
		fmt.println("Lines[0]: ", lines[0])
		log_err("Missing metadata start marker", #procedure)
		return "", -1
	}

	// Find the end of metadata section
	metadataEndIndex := -1
	for i in 0 ..< len(lines) {
		if strings.has_prefix(lines[i], "@@@@@@@@@@@@@@@BTM") {
			metadataEndIndex = i
			break
		}
	}

	if metadataEndIndex == -1 {
		log_err("Missing metadata end marker", #procedure)
		return "", -2
	}

	// Verify the header has the correct number of lines
	expectedLines := 8 // 6 metadata fields + start and end markers
	if metadataEndIndex != expectedLines - 1 {
		log_err("Invalid metadata header length", #procedure)
		return "", -3
	}

	for i in 1 ..< 6 {
		if strings.has_prefix(lines[i], field) {
			val := strings.split(lines[i], ": ")
			return strings.clone(val[1]), 0
		}
	}


	return "", -4
}


//Similar to the UPDATE_METADATA_VALUE but updates a value wiht the passed in param
//member is the metadata field to update
//For now , only used for the "Permission" field, may add more in the future - Marshall
// 0 - public, 1 - secure, 2 - config, 3 - history, 4 - id
OST_CHANGE_METADATA_VALUE :: proc(
	fn, newValue: string,
	member: int,
	colType: types.CollectionType,
) -> bool {
	using utils
	using const

	file: string

	#partial switch (colType) {
	case .STANDARD_PUBLIC:
		file = concat_collection_name(fn)
		break
	case .SECURE_PRIVATE:
		file = fmt.tprintf("%s%s%s", OST_SECURE_COLLECTION_PATH, fn, ".ost")
		break
	case .CONFIG_PRIVATE:
		file = OST_CONFIG_PATH
		break
	case .HISTORY_PRIVATE:
		file = OST_HISTORY_PATH
		break
	case .ID_PRIVATE:
		file = OST_ID_PATH
		break
	//TODO: add case for benchmark collection

	}

	data, readSuccess := os.read_entire_file(file)
	if !readSuccess {
		fmt.printfln("Error reading file: %s", file)
		error1 := new_err(
			.CANNOT_READ_FILE,
			get_err_msg(.CANNOT_READ_FILE),
			#file,
			#procedure,
			#line,
		)
		throw_err(error1)
		return false
	}
	defer delete(data)

	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)


	fieldFound := false
	for line, i in lines {
		switch member {
		case 1:
			if strings.has_prefix(line, "# Permission:") {
				lines[i] = fmt.tprintf("# Permission: %s", newValue)
				fieldFound = true
			}
			break
		case:
			fmt.println("Invalid metadata field provided")
			break
		}
	}

	if !fieldFound {
		fmt.printfln("Metadata field not found in file. Proc: ", #procedure)
		return false
	}

	newContent := strings.join(lines, "\n")
	success := os.write_entire_file(file, transmute([]byte)newContent)
	return success
}


//Used after most operations on a collection file to update the metadata fields
OST_UPDATE_METADATA_AFTER_OPERATION :: proc(fn: string) {
	AUTO_OST_UPDATE_METADATA_VALUE(fn, 3) //updates the last time modified
	AUTO_OST_UPDATE_METADATA_VALUE(fn, 4) //updates the file format version
	AUTO_OST_UPDATE_METADATA_VALUE(fn, 5) //updates file size
	AUTO_OST_UPDATE_METADATA_VALUE(fn, 6) //updates the checksum
}
