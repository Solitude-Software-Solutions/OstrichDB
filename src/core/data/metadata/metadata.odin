package metadata

import "../../../errors"
import "../../../logging"
import "../../../misc"
import "core:crypto/hash"
import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"
//=========================================================//
//Author: Marshall Burns aka @SchoolyB
//Desc: This file handles the metadata for .ost files within
//      the Ostrich database engine.
//=========================================================//


@(private = "file")
METADATA_HEADER: []string = {
	"[Ostrich File Header Start]\n\n",
	"#File Format Version: %ffv\n",
	"#Time of Creation: %ftoc\n",
	"#Last Time Modified: %fltm\n",
	"#File Size: %fs Bytes\n",
	"#Checksum: %cs\n\n[Ostrich File Header End]\n\n\n\n",
}

// sets the files time of creation(FTOC) or last time modified(FLTM)
OST_SET_TIME :: proc() -> string {
	buf: [256]byte

	y, m, d := time.date(time.now())

	Y := transmute(i64)y
	M := transmute(i64)m
	D := transmute(i64)d

	Year := strconv.append_int(buf[:], Y, 10)
	Month := strconv.append_int(buf[:], M, 10)
	Day := strconv.append_int(buf[:], D, 10)

	timeCreated := strings.concatenate([]string{Day, "/", Month, "/", Year})
	return timeCreated
}


//sets the files format version(FFV)
OST_SET_FFV :: proc() -> string {
	fileVersion := "0.0.0_dev" //todo see issue #20
	return fileVersion
}

//sets the files size(FS)
//this will be called when a file is read or modified through the engine to ensure the file size is accurate
OST_GET_FS :: proc(file: string) -> os.File_Info {
	//get the file size
	fileSize, _ := os.stat(file)
	return fileSize
}


// Generate a random 32 char checksum for .ost files.
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
	return checksum
}


//!Only used when to append the meta template upon .ost file creation NOT modification
//this appends the metadata header to the file as well as sets the time of creation
OST_APPEND_METADATA_HEADER :: proc(fn: string) -> bool {

	//ppreform check that sees if the file already has the metadata header
	//if it does then return false
	//if it does not then append the metadata header to the file

	rawData, readSuccess := os.read_entire_file(fn)

	if !readSuccess {
		error1 := errors.new_err(
			.CANNOT_READ_FILE,
			errors.get_err_msg(.CANNOT_READ_FILE),
			#procedure,
		)
		errors.throw_err(error1)
	}

	dataAsStr := cast(string)rawData
	if strings.has_prefix(dataAsStr, "[Ostrich File Header Start]") {
		return false
	}

	file, e := os.open(fn, os.O_APPEND | os.O_WRONLY, 0o666)
	defer os.close(file)

	if e != 0 {
		// errors.throw_utilty_error(1,"Error opening file" ,"OST_APPEND_METADATA_HEADER")
	}

	blockAsBytes := transmute([]u8)strings.concatenate(METADATA_HEADER)

	writter, ok := os.write(file, blockAsBytes)
	return true
}


//fn = file name, param = distiguish between which metadata value to set 1 = time of creation, 2 = last time modified, 3 = file size, 4 = file format version, 5 = checksum
OST_UPDATE_METADATA_VALUE :: proc(fn: string, param: int) {
	data, readSuccess := os.read_entire_file(fn)
	if !readSuccess {
		error1 := errors.new_err(
			.CANNOT_READ_FILE,
			errors.get_err_msg(.CANNOT_READ_FILE),
			#procedure,
		)
		return
	}
	defer delete(data)

	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)

	current_time := OST_SET_TIME()
	file_info := OST_GET_FS(fn)
	file_size := file_info.size

	updated := false
	for line, i in lines {
		switch param {
		case 1:
			if strings.has_prefix(line, "#Time of Creation:") {
				lines[i] = fmt.tprintf("#Time of Creation: %s", current_time)
				updated = true
			}
			break
		case 2:
			if strings.has_prefix(line, "#Last Time Modified:") {
				lines[i] = fmt.tprintf("#Last Time Modified: %s", current_time)
				updated = true
			}
		case 3:
			if strings.has_prefix(line, "#File Size:") {
				lines[i] = fmt.tprintf("#File Size: %d Bytes", file_size)
				updated = true
			}
			break
		case 4:
			if strings.has_prefix(line, "#File Format Version:") {
				lines[i] = fmt.tprintf("#File Format Version: %s", OST_SET_FFV())
				updated = true
			}
			break
		case 5:
			if strings.has_prefix(line, "#Checksum:") {
				lines[i] = fmt.tprintf("#Checksum: %s", OST_GENERATE_CHECKSUM())
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
