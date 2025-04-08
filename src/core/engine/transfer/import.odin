package transfer

import "../../../utils"
import "../../const"
import "../../types"
import "../data"
import "../data/metadata"
import "../security"
import "core:encoding/csv"
import "core:fmt"
import "core:os"
import "core:strings"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            This file contains the logic for importing data from external sources
            into OstrichDB. Currently, only .csv files are supported.
*********************************************************/


//looks over the root directory to see if there any .csv or .json files
// Returns:
// detected - if a atleast 1 file was auto detected in the executables root dir
// autoImportSuccess - if the auto import is confirmed by the user AND successful
OST_AUTO_DETECT_AND_HANLE_IMPORT_FILES :: proc() -> (detected: bool, autoImportSuccess: bool) {
	detected = false
	autoImportSuccess = false
	detectedCount := 0
	fileNames := make([dynamic]string)
	defer delete(fileNames)

	dir, dirOpenErr := os.open(const.ROOT_PATH)
	if dirOpenErr != nil {
		fmt.println("ERROR: Unable to open root directory")
		return detected, autoImportSuccess //none detected and thus no auto import could happen
	}

	files, readDirErr := os.read_dir(dir, 0)
	if readDirErr != nil {
		fmt.println("ERROR: Unable to read over root directory")
		return detected, autoImportSuccess //none detected and thus no auto import could happen
	}

	for file in files {
		if strings.contains(file.name, ".csv") || strings.contains(file.name, ".json") {
			detectedCount += 1
			append(&fileNames, file.name)
		}
	}

	if detectedCount != 0 {
		detected = true
		fmt.printfln(
			"OstrichDB detected %d possible import files in its root directory.",
			detectedCount,
		)
		for f in fileNames {
			fmt.printfln("Name: %s ", f)
		}
		fmt.println("Would you like to import one of these files into OstrichDB? [Y/N]")

		confirmation := utils.get_input(false)
		if confirmation == "Y" || confirmation == "y" {
			autoImportSuccess = OST_SELECT_IMPORT_FROM_ROOT(fileNames)
			return detected, autoImportSuccess //Files were detected AND user auto imported successfully

		} else if confirmation == "N" || confirmation == "n" {
			fmt.println("Ok, Please continue manually importing")
			return detected, autoImportSuccess //Files were detected but user chose to manually import
		} else {
			fmt.println("Please enter a valid input...[Y/N]")
			OST_AUTO_DETECT_AND_HANLE_IMPORT_FILES()

		}
	} else {
		fmt.printfln(
			"%sWARNING:%s OstrichDB was unable to detect any import files in its root directory",
			utils.YELLOW,
			utils.RESET,
		)
	}
	return false, false //none detected and thus no auto import could happen
}

//helper for above proc
OST_SELECT_IMPORT_FROM_ROOT :: proc(fileNames: [dynamic]string) -> bool {
	importSuccess := false

	fmt.println("Please enter the name of the file you would like to import...")
	fmt.println("To cancel this operation enter: 'cancel' or 'quit' ")
	input := utils.get_input(false)

	if input == "cancel" || input == "quit" {
		fmt.println("Canceling operation")
		return importSuccess
	}

	for name in fileNames {
		if input != name {
			fmt.println("The provided name does not match any of the detected files.")
			fmt.println("Please try again...")
			OST_SELECT_IMPORT_FROM_ROOT(fileNames)
		} else if input == name {
			//since the program detects this in root of the executable, just append the name to the './' prefix :) - Marshall
			pathConcat := fmt.tprintf("./%s", name)
			fmt.printfln(
				"Importing file: %s%s%s into OstrichDB",
				utils.BOLD_UNDERLINE,
				name,
				utils.RESET,
			)
			importSuccess = OST_IMPORT_CSV_FILE(name, pathConcat)
		}
	}
	return importSuccess
}

OST_HANDLE_IMPORT :: proc() -> (success: bool) {
	success = false
	name, fullPath, size, importType := OST_GET_IMPORT_FILE_INFO()
	if OST_CONFIRM_IMPORT_EXISTS(fullPath) {
		//now ensure the file is not empty.
		if OST_IMPORT_CSV_FILE(name, fullPath) {
			success = true
		} else {
			fmt.println("Import operation could not be completed. Please try again.")
		}
	}
	return success
}

// returns the file import name, size, and type
// type: 0 = .csv, 1 = .json , -1 = error
OST_GET_IMPORT_FILE_INFO :: proc(
) -> (
	name: string,
	fullPath: string,
	size: i64,
	importType: int,
) {
	using utils

	name = ""
	fullPath = ""
	size = -1
	importType = -1

	fmt.println("Please enter the full path of the file you would like to import.")
	fmt.println("Note: This must be relative to the root of your OstrichDB install")
	fmt.println("Enter 'cancel' or 'quit' to terminate this operation.")
	input := utils.get_input(false)

	if input == "cancel" ||
	   input == "quit" ||
	   input == strings.to_upper("cancel") ||
	   input == strings.to_upper("quit") {
		fmt.println("Operation canceled")
		return name, fullPath, size, importType
	}

	fileFound := OST_CONFIRM_IMPORT_EXISTS(input)
	if !fileFound {
		if !strings.ends_with(input, ".csv") || !strings.ends_with(input, ".json") {
			fmt.printfln(
				"%sInvalid file type provided.%s\nSupported file types:\n.csv\n.json",
				RED,
				RESET,
			)
		} else {
			fmt.printfln(
				"%sUnable to find the file:%s %s%s%s",
				RED,
				RESET,
				BOLD_UNDERLINE,
				input,
				RESET,
			)
			fmt.println("Ensure the file exists in the path provided and try again.")
		}
		return name, fullPath, size, importType
	} else if fileFound {
		fmt.printfln(
			"%sSuccessfully found file:%s %s%s%s",
			GREEN,
			RESET,
			BOLD_UNDERLINE,
			input,
			RESET,
		)
	}

	info := metadata.GET_FS(input)
	size = info.size
	name = info.name
	fullPath = info.fullpath

	if strings.ends_with(input, ".csv") {
		importType = 0

	} else if strings.ends_with(input, ".json") {
		importType = 1
	}

	return name, fullPath, size, importType
}

//USed to make sure the file the user wants to import exists
OST_CONFIRM_IMPORT_EXISTS :: proc(importFilePath: string) -> bool {
	fileExists := false

	file, openSuccess := os.open(importFilePath, os.O_RDWR)
	if openSuccess == 0 {
		fileExists = true
	}
	os.close(file)

	return fileExists
}


//Handles all logic for importing the passed in .csv file into OstrichDB as a new foriegn collection
OST_IMPORT_CSV_FILE :: proc(name: string, fullPath: ..string) -> (success: bool) {
	using data
	success = false

	fmt.println("Please enter the desired name for the new OstrichDB collection.")
	desiredColName := utils.get_input(false)

	fmt.printfln(
		"Is the name %s%s%s correct?[Y/N]",
		utils.BOLD_UNDERLINE,
		desiredColName,
		utils.RESET,
	)
	colNameConfirmation := utils.get_input(false)


	if colNameConfirmation == "y" || colNameConfirmation == "Y" {
		//just continue on with procedure
	} else if colNameConfirmation == "n" || colNameConfirmation == "N" {
		fmt.println("Please try again")
		OST_IMPORT_CSV_FILE(name, fullPath[0])
	} else {
		fmt.println("Invalid repsonse given. Please try again")
		OST_IMPORT_CSV_FILE(name, fullPath[0])
	}

	csvClusterName := strings.to_upper(desiredColName)
	head, body, recordCount := OST_GET_CSV_DATA(fullPath[0])
	inferSucces, csvTypes := OST_INFER_CSV_RECORD_TYPES(head, recordCount)
	if !inferSucces {
		fmt.printfln("Failed to infer record types")
		return success
	}

	collectionPath := utils.concat_standard_collection_name(desiredColName)
	colCreationSuccess := CREATE_COLLECTION(strings.to_upper(desiredColName), .STANDARD_PUBLIC)
	if !colCreationSuccess {
		fmt.println("Failed to create collection for import file")
		return success
	}

	id := GENERATE_ID(true)
	cluCreationSuccess := CREATE_CLUSTER(strings.to_upper(desiredColName), csvClusterName, id)
	if cluCreationSuccess != 0 {
		fmt.println("Failed to create cluster within new import collection")
		return success
	}

	cols := OST_ORGANIZE_CSV_INTO_COLUMNS(body, len(head))

	for colIndex := 0; colIndex < len(cols) && colIndex < len(head); colIndex += 1 {
		columnName := head[colIndex]
		columnType := csvTypes[columnName]
		columnValues := (fmt.tprintf("%v", cols[colIndex]))

		if OST_APPEND_CSV_RECORD_INTO_OSTRICH(
			   collectionPath,
			   csvClusterName,
			   strings.to_upper(columnName),
			   columnType,
			   columnValues,
		   ) !=
		   0 {
			fmt.println(
				"Failed to append a CSV record into OstrichDB collection. Canceling operation",
			)
			return success
		}
	}

	metadata.UPDATE_METADATA_UPON_CREATION(collectionPath)
	encryptSuccess, _ := security.ENCRYPT_COLLECTION(
		desiredColName,
		.STANDARD_PUBLIC,
		types.current_user.m_k.valAsBytes,
		false,
	)

	if encryptSuccess != 0 {
		fmt.println("Failed to encrypt CSV import collection")
		return success
	}

	success = true
	delete(head)
	delete(body)
	delete(csvTypes)
	delete(cols)

	return success
}

// Gets all data from a .csv file and returns the "head"(first row) and "body"(everything else) respectively
// as well as the number of records in the .csv file
OST_GET_CSV_DATA :: proc(fn: string) -> ([dynamic]string, [dynamic]string, int) {
	csvRecordCount := 0
	head, body: [dynamic]string

	data, ok := utils.read_file(fn, #procedure)
	defer delete(data)
	if ok {
		lines := strings.split_lines(string(data))
		for line, i in lines {
			if len(line) == 0 {continue}

			// Process each line as a complete record
			if i == 0 {
				// Handle head line
				fields := strings.split(line, ",")
				for field in fields {
					append(&head, strings.clone(strings.trim_space(field)))
				}
				csvRecordCount = len(fields)
			} else {
				// Handle body lines
				fields := strings.split(line, ",")
				// Ensure each line has the same number of fields as header
				for j := 0; j < len(head); j += 1 {
					if j < len(fields) {
						append(&body, strings.clone(strings.trim_space(fields[j])))
					} else {
						append(&body, "")
					}
				}
			}
		}
	}
	return head, body, csvRecordCount
}

//handles the actual logic for moving csv data into the OstrichDB collection file
OST_APPEND_CSV_RECORD_INTO_OSTRICH :: proc(fn, cn, rn, rType, rd: string) -> int {
	// csvCollectionFile := fmt.tprintf("./collections/%s.ost", fn)
	data, readSuccess := utils.read_file(fn, #procedure)
	defer delete(data)
	if !readSuccess {
		return -1
	}

	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)

	clusterStart := -1
	closingBrace := -1

	// Find the cluster and its closing brace
	for i := 0; i < len(lines); i += 1 {
		if strings.contains(lines[i], cn) {
			clusterStart = i
		}
		if clusterStart != -1 && strings.contains(lines[i], "}") {
			closingBrace = i
			break
		}
	}

	//removed the check for if the record exists, since this procedure is called automatically for
	// each record in the .csv file i'd rather it not bug out if there is duplicate data while storing into
	// a cluster, will justt add a scan or something to check for duplicates later

	//if the cluster is not found or the structure is invalid, return
	if clusterStart == -1 || closingBrace == -1 {
		error2 := utils.new_err(
			.CANNOT_FIND_CLUSTER,
			utils.get_err_msg(.CANNOT_FIND_CLUSTER),
			#file,
			#procedure,
			#line,
		)
		utils.throw_err(error2)
		utils.log_err("Unable to find cluster/valid structure", #procedure)
		return -1
	}

	// Create the new line
	new_line := fmt.tprintf("\t%s :%s: %s", rn, rType, rd)

	// Insert the new line and adjust the closing brace
	new_lines := make([dynamic]string, len(lines) + 1)
	copy(new_lines[:closingBrace], lines[:closingBrace])
	new_lines[closingBrace] = new_line
	new_lines[closingBrace + 1] = "},"
	if closingBrace + 1 < len(lines) {
		copy(new_lines[closingBrace + 2:], lines[closingBrace + 1:])
	}

	new_content := strings.join(new_lines[:], "\n")
	writeSuccess := utils.write_to_file(fn, transmute([]byte)new_content, #procedure)
	if !writeSuccess {
		return -1
	}
	return 0
}


//Takes fields of each record in a .csv file and organizes them into "columns"
//This helps with the inferance of record types, but could be used for other things I guess
OST_ORGANIZE_CSV_INTO_COLUMNS :: proc(
	body: [dynamic]string,
	num_fields: int,
) -> [dynamic][dynamic]string {
	if num_fields <= 0 {
		return make([dynamic][dynamic]string)
	}

	result := make([dynamic][dynamic]string, num_fields)
	for i := 0; i < num_fields; i += 1 {
		result[i] = make([dynamic]string)
	}

	// Process one row at a time
	num_rows := len(body) / num_fields
	for row := 0; row < num_rows; row += 1 {
		for col := 0; col < num_fields; col += 1 {
			value_index := row * num_fields + col
			if value_index < len(body) {
				append(&result[col], body[value_index])
			}
		}
	}

	return result
}


//Unused but helpful UTILS
//enusre that that each line(record) of the passed in .csv file has the same number of fields
ensure_csv_record_length :: proc(fn: string, reader: ^csv.Reader) -> (bool, int) {
	recordLen: int
	lenIsSame := true

	data, ok := os.read_entire_file(fn)
	if ok {
		csv.reader_init_with_string(reader, string(data))
	} else {
		//TODO: uhhhh do something with this error
	}
	defer delete(data)

	for r, i, err in csv.iterator_next(reader) {
		if err != nil { /*TODO: Do something with error */}
		recordLen = len(r)
		for r in r {
			if len(r) != recordLen {
				fmt.printfln("Record Lengths do not match")
				return false, recordLen
			} else {
				continue
			}
		}
	}
	return true, recordLen
}

//almost the same as above but doesnt do anything but return the length of the record
get_csv_record_length :: proc(csvRecord: []string) -> int {
	recordLen := len(csvRecord)
	return recordLen
}

//extracts a single field from a .csv file
extract_csv_field :: proc(csvRecords: [dynamic]string, iterations: int) -> [dynamic]string {
	field: []string
	arr: [dynamic]string
	for rec in csvRecords {
		field = strings.split_n(rec, ",", iterations)
		for f in field {
			append(&arr, strings.clone(f))
		}
	}

	return arr
}
