package importing

import "../../../../utils"
import "../../../const"
import "../../../types"
import "../../data"
import "../../data/metadata"
import "../../security"
import "core:encoding/csv"
import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"
import "import_formats"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-2025 Marshall A Burns and Solitude Software Solutions LLC
Copyright (c) 2025-Present Archetype Dynamics, Inc.

File Description:
            This file contains:
            - Procedures that handle user input and file selection
            - Transfer package helper procedures
*********************************************************/


//looks over the root directory to see if there any .csv or .json files
// Returns:
// detected - if a atleast 1 file was auto detected in the executables root dir
// autoImportSuccess - if the auto import is confirmed by the user AND successful
AUTO_DETECT_AND_HANDLE_IMPORT_FILES :: proc() -> (detected: bool, autoImportSuccess: bool) {
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
			autoImportSuccess = select_import_file_from_executable_root(fileNames)
			fmt.printfln("%s is returning: %v & %v ", #procedure, detected, autoImportSuccess)
			return detected, autoImportSuccess //Files were detected AND user auto imported successfully
		} else if confirmation == "N" || confirmation == "n" {
			fmt.println("Ok, Please continue manually importing")
			fmt.printfln("%s is returning: %v & %v ", #procedure, detected, autoImportSuccess)
			return detected, autoImportSuccess //Files were detected but user chose to manually import
		} else {
			fmt.println("Please enter a valid input...[Y/N]")
			AUTO_DETECT_AND_HANDLE_IMPORT_FILES()
		}
	} else {
		fmt.printfln(
			"%sWARNING:%s OstrichDB was unable to detect any import files in its root directory",
			utils.YELLOW,
			utils.RESET,
		)
	}
	return detected, autoImportSuccess //none detected and thus no auto import could happen
}



 HANDLE_IMPORT :: proc() -> (success: bool) {
    success = false
    name, fullPath, size, importType := GET_IMPORT_FILE_INFO()
    if confirm_import_exists(fullPath) {
        //Todo:  ensure the file is not empty.
        switch(importType){
        case 0:
            if import_formats.CSV__IMPORT_CSV_FILE(name, fullPath) {
                success = true
            } else {
                fmt.println("Import operation could not be completed. Please try again.")
            }
            break
        case 1:
            if import_formats.JSON__IMPORT_JSON_FILE(name, fullPath) {
                success = true
            } else {
                fmt.println("Import operation could not be completed. Please try again.")
            }
            break
        }
    }
    return success
}

// returns the file import name, size, and type
// type: 0 = .csv, 1 = .json , -1 = error
GET_IMPORT_FILE_INFO :: proc() -> (name: string, fullPath: string, size: i64, importType: int) {
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

	fileFound := confirm_import_exists(input)
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

	info := metadata.GET_FILE_INFO(input)
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


// HELPER PROCEDURES

//In the event that an import file is found in the same location as the executable this helper proc handles that logic
select_import_file_from_executable_root :: proc(fileNames: [dynamic]string) -> bool {
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
            select_import_file_from_executable_root(fileNames)
        } else if input == name {
            //since the program detects this in root of the executable, just append the name to the './' prefix :) - Marshall
            pathConcat := fmt.tprintf("./%s", name)
            fmt.printfln(
                "Importing file: %s%s%s into OstrichDB",
                utils.BOLD_UNDERLINE,
                name,
                utils.RESET,
            )

            // Check file extension and call appropriate import function
            if strings.has_suffix(name, ".csv") {
                importSuccess = import_formats.CSV__IMPORT_CSV_FILE(name, pathConcat)
            } else if strings.has_suffix(name, ".json") {
                importSuccess = import_formats.JSON__IMPORT_JSON_FILE(name, pathConcat)
            }
        }
    }
    return importSuccess
}


//Used to make sure the file the user wants to import exists
confirm_import_exists :: proc(importFilePath: string) -> bool {
	fileExists := false

	file, openSuccess := os.open(importFilePath, os.O_RDWR)
	if openSuccess == 0 {
		fileExists = true
	}
	os.close(file)

	return fileExists
}

