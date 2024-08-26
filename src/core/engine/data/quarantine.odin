package data

import "../../../utils"
import "../../const"
import "../../types"
import "/metadata"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//

//moves the passed in collection file from the collections dir to the quarantine dir
OST_QURANTINE_COLLECTION :: proc(fn: string) -> int {
	collectionFile := fmt.tprintf(
		"%s%s%s",
		const.OST_COLLECTION_PATH,
		fn,
		const.OST_FILE_EXTENSION,
	)

	// Generate a unique filename for the quarantined file
	timestamp := time.now()
	quarantineFilename := fmt.tprintf(
		"%s_%v%s",
		strings.trim_suffix(fn, const.OST_FILE_EXTENSION),
		timestamp,
		const.OST_FILE_EXTENSION,
	)
	quarantine_path := fmt.tprintf("%s/%s", const.OST_QUARANTINE_PATH, quarantineFilename)
	fmt.printfln("Quarantine path: %s\n", quarantine_path)
	// Move the file to quarantine
	err := os.rename(collectionFile, quarantine_path)
	if err != os.ERROR_NONE {
		return -1
	}
	OST_APPEND_QUARANTINE_LINE(quarantine_path)
	return 0
}

OST_APPEND_QUARANTINE_LINE :: proc(qFile: string) -> int {
	file, err := os.open(qFile, os.O_RDWR)
	if err != os.ERROR_NONE {
		return -1
	}
	defer os.close(file)

	// Seek to the end of the file
	_, seek_err := os.seek(file, 0, os.SEEK_END)
	if seek_err != os.ERROR_NONE {
		fmt.printf("Error seeking to end of file: %v\n", seek_err)
		return -1
	}

	qStr := transmute([]u8)const.QuarintineStr


	// Write the quarantine string
	_, write_err := os.write(file, qStr)
	if write_err != os.ERROR_NONE {
		fmt.printf("Error writing to file: %v\n", write_err)
		return -1
	}

	return 0
}
