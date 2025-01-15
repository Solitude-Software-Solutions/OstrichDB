package metadata

import "../../../../utils"
import "../../../const"
import "../../../types"
import "core:crypto/hash"
import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//


METADATA_HEADER: []string = {
	const.METADATA_START,
	"# File Format Version: %ffv\n",
	"# Date of Creation: %fdoc\n",
	"# Date Last Modified: %fdlm\n",
	"# File Size: %fs Bytes\n",
	"# Checksum: %cs\n",
	const.METADATA_END,
}


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
	fileInfo, err := os.stat(file)
	if err != 0 {
		utils.log_err("Error getting file info", #procedure)
		return -1, -1
	}

	totalSize := int(fileInfo.size)

	data, readSuccess := os.read_entire_file(file)
	if !readSuccess {
		utils.log_err("Error reading file", #procedure)
		return -1, -1
	}
	defer delete(data)

	content := string(data)

	// Find metadata end marker
	metadataEnd := strings.index(content, const.METADATA_END)
	if metadataEnd == -1 {
		utils.log_err("Metadata end marker not found", #procedure)
		return -1, -1
	}

	// Add length of end marker to get total metadata size
	metadataSize := metadataEnd + len(const.METADATA_END)

	// Return actual content size (total - metadata) and metadata size
	return totalSize - metadataSize, metadataSize
}


// Generates a random 32 char checksum for .ost files.
OST_GENERATE_CHECKSUM :: proc() -> string {
	checksum: string
	possibleNums: []string = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "0"}
	possibleChars: []string = {
		"A",
		"B",
		"C",
		"D",
		"E",
		"F",
		"G",
		"H",
		"I",
		"J",
		"K",
		"L",
		"M",
		"N",
		"O",
		"P",
		"Q",
		"R",
		"S",
		"T",
		"U",
		"V",
		"W",
		"X",
		"Y",
		"Z",
	}

	for c := 0; c < 16; c += 1 {
		randC := rand.choice(possibleChars)
		checksum = strings.concatenate([]string{checksum, randC})
	}

	for n := 0; n < 16; n += 1 {
		randN := rand.choice(possibleNums)
		checksum = strings.concatenate([]string{checksum, randN})
	}
	return strings.clone(checksum)
}


//!Only used when to append the meta template upon .ost file creation NOT modification
//this appends the metadata header to the file as well as sets the time of creation
OST_APPEND_METADATA_HEADER :: proc(fn: string) -> bool {
	rawData, readSuccess := os.read_entire_file(fn)
	defer delete(rawData)
	fmt.println(readSuccess)
	if !readSuccess {
		error1 := utils.new_err(
			.CANNOT_READ_FILE,
			utils.get_err_msg(.CANNOT_READ_FILE),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Error readinding collection file", #procedure)
	}

	dataAsStr := cast(string)rawData
	if strings.has_prefix(dataAsStr, "@@@@@@@@@@@@@@@TOP@@@@@@@@@@@@@@@") {
		return false
	}

	file, e := os.open(fn, os.O_APPEND | os.O_WRONLY, 0o666)
	defer os.close(file)

	if e != 0 {
		return false
	}

	blockAsBytes := transmute([]u8)strings.concatenate(METADATA_HEADER)

	writter, ok := os.write(file, blockAsBytes)
	return true
}


//fn = file name, param = metadata value to update.
//1 = time of creation, 2 = last time modified, 3 = file size, 4 = file format version, 5 = checksum
OST_UPDATE_METADATA_VALUE :: proc(fn: string, param: int) {
	data, readSuccess := os.read_entire_file(fn)
	if !readSuccess {
		error1 := utils.new_err(
			.CANNOT_READ_FILE,
			utils.get_err_msg(.CANNOT_READ_FILE),
			#procedure,
		)
		return
	}
	defer delete(data)

	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)

	//not doing anything with h,m,s yet but its there if needed
	current_date, h, m, s := utils.get_date_and_time() // sets the files date of creation(FDOC) or file date last modified(FDLM)
	file_info := OST_GET_FS(fn)
	file_size := file_info.size

	updated := false
	for line, i in lines {
		switch param {
		case 1:
			if strings.has_prefix(line, "# Date of Creation:") {
				lines[i] = fmt.tprintf("# Date of Creation: %s", current_date)
				updated = true
			}
			break
		case 2:
			if strings.has_prefix(line, "# Date Last Modified:") {
				lines[i] = fmt.tprintf("# Date Last Modified: %s", current_date)
				updated = true
			}
		case 3:
			if strings.has_prefix(line, "# File Size:") {
				actualSize, _ := OST_SUBTRACT_METADATA_SIZE(fn)
				if actualSize != -1 {
					lines[i] = fmt.tprintf("# File Size: %d Bytes", actualSize)
					updated = true
				} else {
					fmt.printfln("Error calculating file size for file %s", fn)
				}
			}
			break
		case 4:
			if strings.has_prefix(line, "# File Format Version:") {
				lines[i] = fmt.tprintf("# File Format Version: %s", OST_SET_FFV())
				updated = true
			}
			break
		case 5:
			if strings.has_prefix(line, "# Checksum:") {
				lines[i] = fmt.tprintf("# Checksum: %s", OST_GENERATE_CHECKSUM())
				updated = true
			}
			break
		}
		if updated {
			break
		}
	}

	if !updated {
		fmt.println("Metadata field not found in file")
		return
	}

	new_content := strings.join(lines, "\n")
	err := os.write_entire_file(fn, transmute([]byte)new_content)
}

//!Only used on .ost file creation whether secure or not
OST_METADATA_ON_CREATE :: proc(fn: string) {
	OST_UPDATE_METADATA_VALUE(fn, 1)
	OST_UPDATE_METADATA_VALUE(fn, 3)
	OST_UPDATE_METADATA_VALUE(fn, 4)
	OST_UPDATE_METADATA_VALUE(fn, 5)
}

//Creates the file format version file in the temp dir
OST_CREATE_FFVF :: proc() {
	CURRENT_FFV := utils.get_ost_version()
	os.make_directory(const.OST_TMP_PATH)

	FFVF := const.OST_FFVF
	tmpPath := const.OST_TMP_PATH
	pathAndName := fmt.tprintf("%s%s", tmpPath, FFVF)

	file, createSuccess := os.open(pathAndName, os.O_CREATE, 0o666)
	defer os.close(file)

	if createSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_CREATE_FILE,
			utils.get_err_msg(.CANNOT_CREATE_FILE),
			#procedure,
		)
		utils.throw_custom_err(error1, "Cannot create file format version file")
	}
	os.close(file)
	//close then open the file again to write to it

	f, openSuccess := os.open(pathAndName, os.O_WRONLY, 0o666)
	defer os.close(f)
	ffvAsBytes := transmute([]u8)CURRENT_FFV
	writter, ok := os.write(f, ffvAsBytes)
	if ok != 0 {
		error1 := utils.new_err(
			.CANNOT_WRITE_TO_FILE,
			utils.get_err_msg(.CANNOT_WRITE_TO_FILE),
			#procedure,
		)
		utils.throw_custom_err(error1, "Cannot write to file format version file")
	}
}

//Gets the file format version from the file format version file
OST_GET_FILE_FORMAT_VERSION :: proc() -> []u8 {
	FFVF := const.OST_FFVF
	tmpPath := const.OST_TMP_PATH
	pathAndName := fmt.tprintf("%s%s", tmpPath, FFVF)

	ffvf, openSuccess := os.open(pathAndName)
	if openSuccess != 0 {
		utils.log_err("Could not open file format version file", #procedure)
	}
	data, e := os.read_entire_file(ffvf)
	if e == false {
		utils.log_err("Could not read file format version file", #procedure)
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
	file := fmt.tprintf("%s%s%s", const.OST_COLLECTION_PATH, fn, const.OST_FILE_EXTENSION)

	types.schema.Metadata_Header_Body = [5]string {
		"# File Format Version: ",
		"# Date of Creation: ",
		"# Date Last Modified: ",
		"# File Size: ",
		"# Checksum: ",
	}
	data, readSuccess := utils.read_file(file, #procedure)
	if !readSuccess {
		return 1, true
	}

	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)

	// Check if the metadata header is present
	if !strings.has_prefix(lines[0], const.METADATA_START) {
		utils.log_err("Missing metadata start marker", #procedure)
		return 1, true
	}

	// Find the end of metadata section
	metadataEndIndex := -1
	for i in 0 ..< len(lines) {
		if strings.has_prefix(lines[i], const.METADATA_END) {
			metadataEndIndex = i
			break
		}
	}

	if metadataEndIndex == -1 {
		utils.log_err("Missing metadata end marker", #procedure)
		return 1, true
	}

	// Verify the header has the correct number of lines
	expectedLines := 7 // 5 metadata fields + start and end markers
	if metadataEndIndex != expectedLines - 1 {
		utils.log_err("Invalid metadata header length", #procedure)
		return 1, true
	}

	// Check each metadata field
	for i in 1 ..< 5 {
		if !strings.has_prefix(lines[i], types.schema.Metadata_Header_Body[i - 1]) {
			utils.log_err(fmt.tprintf("Invalid metadata field format: %s", lines[i]), #procedure)
			return 1, true
		}
	}

	//checks if the file format verion file and the projects version file match
	versionMatch := OST_VALIDATE_FILE_FORMAT_VERSION()
	if !versionMatch {
		utils.log_err("Invalid file format version being used", #procedure)
		return 1, true
	}

	ffv_parts := strings.split(lines[1], ": ")
	if len(ffv_parts) < 2 {
		utils.log_err("Invalid file format version line format", #procedure)
		return 1, true
	}
	collectionVersionValue := ffv_parts[1]


	//compares the collections to the version in the FFV tmp file. Due to alreay checking if the FFV and the project file
	//match, now have to ensure the collection file matches as well.
	FFV := OST_GET_FILE_FORMAT_VERSION()
	if strings.compare(collectionVersionValue, string(FFV)) != 0 {
		utils.log_err(
			"File format version in collection file does not match the file format version",
			#procedure,
		)
		return 1, true
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
