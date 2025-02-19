package data
import "../../../utils"
import "../../const"
import "../../types"
import "core:fmt"
import "core:os"
import "core:strings"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            Implements the WHERE command functionality for OstrichDB, allowing
            users to search for clusters and records across collections. This
            file contains the core search logic and result formatting.
*********************************************************/


//Contains all logic for the WHERE command
//where allows for quick searching where 2nd or 3rd layer data (clusters & records)
//example use case `WHERE cluster foo` would show the location of every instance of a cluster foo
//another example:
//`WHERE foo` would show the location of every 2nd or 3rd layer data object with the name foo

//handles WHERE {target} {target name}
OST_WHERE_OBJECT :: proc(target, targetName: string) -> bool {
	using const
	using utils

	// Early return for invalid target
	if target == COLLECTION {
		return false
	}

	collectionsDir, errOpen := os.open(OST_COLLECTION_PATH)
	defer os.close(collectionsDir)
	foundFiles, dirReadSuccess := os.read_dir(collectionsDir, -1)
	collectionNames := make([dynamic]string)
	defer delete(collectionNames)

	// Collect all valid collection files
	for file in foundFiles {
		if strings.contains(file.name, OST_FILE_EXTENSION) {
			append(&collectionNames, file.name)
		}
	}

	found := false // Track if we found any matches

	// Search through collections
	for collection in collectionNames {
		if target == CLUSTER {
			collectionPath := fmt.tprintf("%s%s", OST_COLLECTION_PATH, collection)
			if OST_CHECK_IF_CLUSTER_EXISTS(collectionPath, targetName) {
				fmt.printfln(
					"Cluster: %s%s%s -> Collection: %s%s%s",
					BOLD_UNDERLINE,
					targetName,
					RESET,
					BOLD_UNDERLINE,
					collection,
					RESET,
				)
				found = true
				// Remove the return here to continue searching
			}
		} else if target == RECORD {
			colName, cluName, success := OST_SCAN_COLLECTION_FOR_RECORD(collection, targetName)
			if success {
				fmt.printfln(
					"Record: %s%s%s -> Cluster: %s%s%s -> Collection: %s%s%s",
					BOLD_UNDERLINE,
					targetName,
					RESET,
					BOLD_UNDERLINE,
					cluName,
					RESET,
					BOLD_UNDERLINE,
					colName,
					RESET,
				)
				found = true

			}
		}
	}

	return found
}

//handles WHERE {target name}
OST_WHERE_ANY :: proc(targetName: string) -> bool {
	using utils
	using const

	collectionsDir, errOpen := os.open(OST_COLLECTION_PATH)
	defer os.close(collectionsDir)
	foundFiles, dirReadSuccess := os.read_dir(collectionsDir, -1)
	collectionNames := make([dynamic]string)
	defer delete(collectionNames)

	// Collect all valid collection files
	for file in foundFiles {
		if strings.contains(file.name, OST_FILE_EXTENSION) {
			append(&collectionNames, file.name)
		}
	}

	found := false // Track if we found any matches

	// Search through collections
	for collection in collectionNames {
		collectionPath := fmt.tprintf("%s%s", OST_COLLECTION_PATH, collection)

		// Check if it's a cluster name
		if OST_CHECK_IF_CLUSTER_EXISTS(collectionPath, targetName) {
			fmt.printfln(
				"Cluster: %s%s%s -> Collection: %s%s%s",
				BOLD_UNDERLINE,
				targetName,
				RESET,
				BOLD_UNDERLINE,
				collection,
				RESET,
			)
			found = true
		}

		// Check if it's a record name
		colName, cluName, success := OST_SCAN_COLLECTION_FOR_RECORD(collection, targetName)
		if success {
			fmt.printfln(
				"Record: %s%s%s -> Cluster: %s%s%s -> Collection: %s%s%s",
				BOLD_UNDERLINE,
				targetName,
				RESET,
				BOLD_UNDERLINE,
				cluName,
				RESET,
				BOLD_UNDERLINE,
				colName,
				RESET,
			)
			found = true
		}
	}

	return found
}
