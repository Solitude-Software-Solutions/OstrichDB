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
SET_FFV :: proc() -> string {
	ffv := GET_FILE_FORMAT_VERSION()
	str := transmute(string)ffv
	return strings.clone(str)
}

//Creates the file format version file in the temp dir
CREATE_FFV_FILE :: proc() {
	using const
	using utils

	CURRENT_FFV := get_ost_version()
	os.make_directory(const.TMP_PATH)

	tmpPath := TMP_PATH
	pathAndName := fmt.tprintf("%s%s", tmpPath, FFVF_PATH)

	file, createSuccess := os.open(pathAndName, os.O_CREATE, 0o666)
	defer os.close(file)

	if createSuccess != 0 {
	errorLocation:= get_caller_location()
		error1 := new_err(
			.CANNOT_CREATE_FILE,
			get_err_msg(.CANNOT_CREATE_FILE),
			errorLocation
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
	errorLocation:= get_caller_location()
		error1 := utils.new_err(
			.CANNOT_WRITE_TO_FILE,
			get_err_msg(.CANNOT_WRITE_TO_FILE),
			errorLocation
		)
		throw_custom_err(error1, "Cannot write to file format version file")
	}
}

//Gets the file format version from the file format version file
GET_FILE_FORMAT_VERSION :: proc() -> []u8 {
	using const
	using utils

	FFVF := FFVF_PATH
	tmpPath := TMP_PATH
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

//checks that the FFV tmp file matches the projects version file
VALIDATE_FILE_FORMAT_VERSION :: proc() -> bool {
	FFV := string(GET_FILE_FORMAT_VERSION()) //this is from the .tmp file

	if (strings.compare(FFV, string(utils.get_ost_version())) != 0) {
		utils.log_err("File format version mismatch", #procedure)
		return false
	}
	return true
}

GET_FILE_INFO :: proc(file: string) -> os.File_Info {
	info, _ := os.stat(file)
	return info
}

//this will get the size of the file and then subtract the size of the metadata header
//then return the difference
SUBTRACT_METADATA_SIZE :: proc(file: string) -> (int, int) {
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
		return -2, -2
	}
	defer delete(data)

	content := string(data)

	// Find metadata end marker
	metadataEnd := strings.index(content, METADATA_END)
	if metadataEnd == -1 {
		log_err("Metadata end marker not found", #procedure)
		return -3, -3
	}

	// Add length of end marker to get total metadata size
	metadataSize := metadataEnd + len(METADATA_END)

	// Return actual content size (total - metadata) and metadata size
	return totalSize - metadataSize, metadataSize
}

// Calculates a SHA-256 checksum for .ostrichdb files based on file content
GENERATE_CHECKSUM :: proc(fn: string) -> string {
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

//!Only used when to append the meta template upon .ostrichdb file creation NOT modification
//this appends the metadata header to the file as well as sets the time of creation
APPEND_METADATA_HEADER_TO_COLLECTION :: proc(fn: string) -> bool {
	using const
	using utils

	rawData, readSuccess := os.read_entire_file(fn)
	defer delete(rawData)
	if !readSuccess {
	errorLocation:= get_caller_location()
		error1 := new_err(
			.CANNOT_READ_FILE,
			get_err_msg(.CANNOT_READ_FILE),
			errorLocation
		)
		throw_err(error1)
		log_err("Error readinding collection file", #procedure)
		return false
	}

	dataAsStr := cast(string)rawData
	if strings.has_prefix(dataAsStr, METADATA_START) {
		log_err("Metadata header already present", #procedure)
		return false
	}

	file, openSuccess := os.open(fn, os.O_APPEND | os.O_WRONLY, 0o666)
	defer os.close(file)

	if openSuccess != 0 {
	errorLocation:= get_caller_location()
		error1 := new_err(
			.CANNOT_OPEN_FILE,
			get_err_msg(.CANNOT_OPEN_FILE),
			errorLocation
		)
		throw_err(error1)
		log_err("Error opening collection file", #procedure)
		return false
	}

	blockAsBytes := transmute([]u8)strings.concatenate(METADATA_HEADER)

	writter, ok := os.write(file, blockAsBytes)
	if ok != 0 {
	errorLocation:= get_caller_location()
		error1 := new_err(
			.CANNOT_WRITE_TO_FILE,
			get_err_msg(.CANNOT_WRITE_TO_FILE),
			errorLocation
		)
		throw_err(error1)
		log_err("Error writing metadata header to collection file", #procedure)
		return false
	}
	return true
}


// Sets the passed in metadata field with an explicit value that is defined within this procedure
// 0 = Encryption state, 1 = File Format Version, 2 = Permission, 3 = Date of Creation, 4 = Date Last Modified, 5 = File Size, 6 = Checksum
ASSIGN_EXPLICIT_METADATA_VALUE :: proc(fn: string, field: types.MetadataField, value: string = "") {
	using utils

	data, readSuccess := os.read_entire_file(fn)
	if !readSuccess {
	errorLocation:= get_caller_location()
		error1 := new_err(
			.CANNOT_READ_FILE,
			get_err_msg(.CANNOT_READ_FILE),
			errorLocation
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
	fileInfo := GET_FILE_INFO(fn)
	fileSize := fileInfo.size

	found := false
	for line, i in lines {
		switch field {
		case .ENCRYPTION_STATE:
			if strings.has_prefix(line, "# Encryption State:") {
				if value != "" {
					lines[i] = fmt.tprintf("# Encryption State: %s", value)
				} else {
					lines[i] = fmt.tprintf("# Encryption State: %d", 0 ) // Default to 0 if no value provided
				}
				found = true
			}
			break
		case .FILE_FORMAT_VERSION:
			if strings.has_prefix(line, "# File Format Version:") {
				lines[i] = fmt.tprintf("# File Format Version: %s", SET_FFV())
				found = true
			}
			break
		case .PERMISSION:
			if strings.has_prefix(line, "# Permission:") {
				lines[i] = fmt.tprintf("# Permission: %s", "Read-Write")
				found = true
			}
		case .DATE_CREATION:
			if strings.has_prefix(line, "# Date of Creation:") {
				lines[i] = fmt.tprintf("# Date of Creation: %s", currentDate)
				found = true
			}
			break
		case .DATE_MODIFIED:
			if strings.has_prefix(line, "# Date Last Modified:") {
				lines[i] = fmt.tprintf("# Date Last Modified: %s", currentDate)
				found = true
			}
			break
		case .FILE_SIZE:
			if strings.has_prefix(line, "# File Size:") {
				actualSize, _ := SUBTRACT_METADATA_SIZE(fn)
				if actualSize != -1 {
					lines[i] = fmt.tprintf("# File Size: %d Bytes", actualSize)
					found = true
				} else {
					fmt.printfln("Error calculating file size for file %s", fn)
				}
			}
			break
		case .CHECKSUM:
			if strings.has_prefix(line, "# Checksum:") {
				lines[i] = fmt.tprintf("# Checksum: %s", GENERATE_CHECKSUM(fn))
				found = true
			}
		}
		if found {
			break
		}
	}

	if !found {
		fmt.printfln("Metadata field not found in file: ", fn)
		return
	}

	newContent := strings.join(lines, "\n")
	writeSuccess := os.write_entire_file(fn, transmute([]byte)newContent)
}


//returns the string value of the passed metadata field
// colType: 1 = public(standard), 2 = history, 3 = config, 4 = ids
GET_METADATA_FIELD_VALUE :: proc(
	fn, field: string,
	colType: types.CollectionType, d: ..[]byte
) -> (
	value: string,
	err: int,
) {
	using const
	using utils

	file: string
	#partial switch (colType) {
	case .STANDARD_PUBLIC:
		file = concat_standard_collection_name(fn)
		break
	case .USER_CONFIG_PRIVATE:
	    file = concat_user_config_collection_name(fn)
	case .SYSTEM_CONFIG_PRIVATE:
		file = SYSTEM_CONFIG_PATH
		break
	case .USER_HISTORY_PRIVATE:
		file = utils.concat_user_history_path(types.current_user.username.Value)
		break
	case .SYSTEM_ID_PRIVATE:
		file = ID_PATH
		break
	}

	data, readSuccess := utils.read_file(file, #procedure)

	if len(d) != 0{
	    if len(d[0])> 0{ //if there is a passed in d(data) arg then data is equal to that
            data= d[0]
		}
	}

	if !readSuccess {
		fmt.println("Error reading file: ", file)
		utils.log_err("Error reading file", #procedure)
		return "", 1
	}
	defer delete(data)

	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)

	// Check if the metadata header is present
	if !strings.has_prefix(lines[0], "@@@@@@@@@@@@@@@TOP") {
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
	expectedLines := 9 // 7 metadata fields + start and end markers
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


//Similar to the ASSIGN_EXPLICIT_METADATA_VALUE  but updates a fields value the passed in newValue
UPDATE_METADATA_MEMBER_VALUE :: proc(fn, newValue: string,field: types.MetadataField,colType: types.CollectionType, username:..string) -> bool {
	using utils
	using const

	file: string

	#partial switch (colType) {
	case .STANDARD_PUBLIC:
		file = concat_standard_collection_name(fn)
		break
	case .USER_CONFIG_PRIVATE:
	    file = concat_user_config_collection_name(fn)
	case .USER_CREDENTIALS_PRIVATE:
		file = utils.concat_user_credential_path(fn)
		break
	case .SYSTEM_CONFIG_PRIVATE:
		file = SYSTEM_CONFIG_PATH
		break
	case .USER_HISTORY_PRIVATE:
	if len(types.current_user.username.Value) == 0 && len(types.user.username.Value) != 0  {
		file = utils.concat_user_history_path(types.user.username.Value)
	}else{
	    file = utils.concat_user_history_path(types.current_user.username.Value)
	}
	break
	case .SYSTEM_ID_PRIVATE:
		file = ID_PATH
		break
	//TODO: add case for benchmark collection

	}

	data, readSuccess := os.read_entire_file(file)
	if !readSuccess {
		errorLocation:= get_caller_location()
		error1 := new_err(
			.CANNOT_READ_FILE,
			get_err_msg(.CANNOT_READ_FILE),
			errorLocation
		)
		fmt.println("Cannot read file: ", file)
		throw_err(error1)
		return false
	}
	defer delete(data)

	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)


	fieldFound := false
	for line, i in lines {
		#partial switch(field) {
		case .ENCRYPTION_STATE:
		if strings.has_prefix(line, "# Encryption State:") {
			lines[i] = fmt.tprintf("# Encryption State: %s", newValue)
			fieldFound = true
		break
		}
		case .PERMISSION:
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


//Assigns all neccesary metadata field values after a collection has been made
INIT_METADATA_IN_NEW_COLLECTION :: proc(fn: string) {
    ASSIGN_EXPLICIT_METADATA_VALUE(fn, .ENCRYPTION_STATE)
	ASSIGN_EXPLICIT_METADATA_VALUE(fn, .FILE_FORMAT_VERSION)
	ASSIGN_EXPLICIT_METADATA_VALUE(fn, .DATE_CREATION)
	ASSIGN_EXPLICIT_METADATA_VALUE(fn, .DATE_MODIFIED)
	ASSIGN_EXPLICIT_METADATA_VALUE(fn, .FILE_SIZE)
	ASSIGN_EXPLICIT_METADATA_VALUE(fn, .CHECKSUM)
}


//Used after most operations on a collection file to update the metadata fields
UPDATE_METADATA_FIELD_AFTER_OPERATION :: proc(fn: string) {
	ASSIGN_EXPLICIT_METADATA_VALUE(fn, .DATE_MODIFIED)
	ASSIGN_EXPLICIT_METADATA_VALUE(fn, .FILE_FORMAT_VERSION)
	ASSIGN_EXPLICIT_METADATA_VALUE(fn, .FILE_SIZE)
	ASSIGN_EXPLICIT_METADATA_VALUE(fn, .CHECKSUM)
}
