package data
import "../../const"
import "../../types"
import "core:fmt"
import "core:strings"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC


File Description:
            Contains logic for handling batch requests, allowing
            users to perform multiple operations in a single request
            when using a client to interact with the OstrichDB server.
            Currently unstable and not fully implemented.
*********************************************************/

//Used to create, delete, and fetch several collections
//only used for NEW, ERASE, AND FETCH tokens. NOT RENAME!!!
HANDLE_COLLECTION_BATCH_REQ :: proc(
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
			if !OST_CREATE_COLLECTION(strings.to_upper(name), .STANDARD_PUBLIC) {
				return 1, ""
			}
		}
		return 0, ""
	case .ERASE:
		for name in collectionNames {
			if !OST_ERASE_COLLECTION(strings.to_upper(name), false) {
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
BATCH_RENAME_COLLECTIONS :: proc(oldNames: []string, newNames: []string) -> int {
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


HANDLE_CLUSTER_BATCH_REQ :: proc(
	collectionNames, clusterNames: []string,
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
		append(&colNames, strings.to_upper(colName))
	}

	//next the cluster names
	for cluName in clusterNames {
		append(&cluNames, strings.to_upper(cluName))
	}

	switch (operation) {
	case .NEW:
		for i in colNames {
			for j in cluNames {
				id := OST_GENERATE_ID(true) //todo: this might be fucked. Passing true skips a check to see if the id is already in use...
				if CREATE_CLUSTER(strings.to_upper(i), j, id) != 0 {
					return 1, ""
				}
			}
		}
	case .ERASE:
		for i in colNames {
			for j in cluNames {
				if !ERASE_CLUSTER(i, j, true) {
					return 1, ""
				} else {
					return 0, "NO WAY THAT WORKED."
				}
			}
		}
	case .FETCH:
		for i in colNames {
			for j in cluNames {
				return 0, FETCH_CLUSTER(i, j)
			}
		}
	}

	return 0, fmt.tprintfln("SUCCESS!")
}

//batch request for handling records
HANDLE_RECORD_BATCH_REQ :: proc(
	collectionNames, clusterNames, recordNames, recordTypes, recordValues: []string,
	operation: types.BatchOperations,
) -> (
	int,
	string,
) {
	colNames := make([dynamic]string)
	cluNames := make([dynamic]string)
	recNames := make([dynamic]string)
	recordTypes := make([dynamic]string)
	recValues := make([dynamic]string)

	defer delete(colNames)
	defer delete(cluNames)
	defer delete(recNames)
	defer delete(recordTypes)
	defer delete(recValues)


	for colName in collectionNames {
		append(&colNames, strings.to_upper(colName))
	}

	for cluName in clusterNames {
		append(&cluNames, strings.to_upper(cluName))
	}

	for recName in recordNames {
		append(&recNames, strings.to_upper(recName))
	}

	for recType in recordTypes {
		append(&recordTypes, strings.to_upper(recType))
	}

	for recValue in recordValues {
		append(&recValues, strings.to_upper(recValue))
	}

	switch (operation) {
	case .NEW:
		for i in colNames {
			for j in cluNames {
				for k in recNames {
					for l in recordTypes {
						for m in recValues {
							if OST_APPEND_RECORD_TO_CLUSTER(i, j, k, m, l) != 0 {
								return 1, "Error encountered while creating new records"
							} else {
								return 0, "New records created succesfully"
							}
						}
					}
				}
			}
		}
	case .ERASE:
		for i in colNames {
			for j in cluNames {
				for k in recNames {
					if !OST_ERASE_RECORD(i, j, k, true) {
						return 1, "Error encountered while erasing records"

					} else {
						return 0, "Records erased successfully"
					}
				}
			}
		}
	case .FETCH:
		for i in colNames {
			for j in cluNames {
				for k in recNames {
					recordData, fetchSucess := OST_FETCH_RECORD(i, j, k)
					if !fetchSucess {
						return 1, "Error fetching records"
					} else {
						return 0, fmt.tprintfln(
							"%s :%s: %s",
							recordData.name,
							recordData.type,
							recordData.value,
						)
					}
				}
			}
		}
	}


	return 1, "SOMETHING WENT WRONG"
}
