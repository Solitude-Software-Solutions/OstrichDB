package data
import "../../const"
import "../../types"
import "core:fmt"
import "core:strings"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//

//Used to create, delete, and fetch several collections
//only used for NEW, ERASE, AND FETCH tokens. NOT RENAME!!!
OST_HANDLE_COLLECTION_BATCH_REQ :: proc(
	names: []string,
	operation: types.BatchOperations,
) -> (
	int,
	string,
) {
	collectionNames := make([dynamic]string)
	defer delete(collectionNames)

	for name in names {
		append(&collectionNames, name)
	}

	switch (operation) {
	case .NEW:
		for name in collectionNames {
			fmt.printfln("Creating collection: %s", name)
			if !OST_CREATE_COLLECTION(strings.to_upper(name), 0) {
				return 1, ""
			}
		}
		return 0, ""
	case .ERASE:
		for name in collectionNames {
			if !OST_ERASE_COLLECTION(strings.to_upper(name)) {
				return 1, ""
			}
			return 0, ""
		}
	case .FETCH:
		result: string
		for name in collectionNames {
			result = OST_FETCH_COLLECTION(strings.to_upper(name))
			if result == "" {
				return 1, ""
			} else {
				return 0, result
			}
		}
	}

	return 0, fmt.tprintfln("SUCCESS!")
}


//handles renaming several collection files
OST_RENAME_COLLECTIONS_BATCH :: proc(oldNames: []string, newNames: []string) -> int {
	if len(oldNames) != len(newNames) {
		return 1
	}

	for i in 0 ..< len(oldNames) {
		if !OST_RENAME_COLLECTION(oldNames[i], newNames[i]) {
			return 1
		}
	}
	return 0
}


OST_HANDLE_CLUSTER_BATCH_REQ :: proc(
	collectionNames: []string,
	clusterNames: []string,
	operation: types.BatchOperations,
) -> (
	int,
	string,
) {
	colNames := make([dynamic]string)
	cluNames := make([dynamic]string)
	defer delete(collectionNames)
	defer delete(clusterNames)

	//first append the collection names to the dynamic array
	for colName in collectionNames {
		append(&colNames, colName)
	}

	//next the cluster names
	for cluName in clusterNames {
		append(&cluNames, cluName)
	}

	switch (operation) {
	case .NEW:
		for i in colNames {
			for j in cluNames {
				id := OST_GENERATE_CLUSTER_ID()
				if OST_CREATE_CLUSTER_FROM_CL(strings.to_upper(i), j, id) != 0 {
					return 1, ""
				} else {
					return 0, "HOLY SHIT THAT WORKED??"
				}
			}
		}
	case .ERASE:
		for i in colNames {
			for j in cluNames {
				if !OST_ERASE_CLUSTER(i, j) {
					return 1, ""
				} else {
					return 0, "NO WAY THAT WORKED."
				}
			}
		}
	case .FETCH:
		for i in colNames {
			for j in cluNames {
				return 0, OST_FETCH_CLUSTER(i, j)
			}
		}

	}

	return 0, fmt.tprintfln("SUCCESS!")
}
