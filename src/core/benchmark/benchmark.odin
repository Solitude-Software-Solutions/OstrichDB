package benchmark
import "../../utils"
import "../const"
import "../engine/data"
import "../engine/data/metadata"
import "../types"
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
Copyright (c) 2024-2025 Marshall A Burns and Solitude Software Solutions LLC
Copyright (c) 2025-Present Archetype Dynamics, Inc.

File Description:
            Contains the logic for the BENCHMARK command, allowing
            users to test the performance of the dbms.
*********************************************************/


//Note to developers: In the main() procedure, the number of iterations passed for each benchmarking operation can be adjusted unless a comment states otherwise. - Marshall
RUN_BENCHMARK :: proc(iterations: []int, default: bool) {
	using utils

	collectionIterations, clusterIterations, recordIterations: int
	basicSuiteFailCounter, mediumSuiteFailCounter, advancedSuiteFailCounter: int
	basicOperationCount, meduimOperationCount, advancedOperationCount: int
	basicOperationTime, mediumOperationTime, advancedOperationTime: time.Duration


	fmt.println("---------------------------------------------------")
	fmt.println("Running OstrichDB Benchmark Suites. Please wait...")
	//Create the benchmark directory
	os.make_directory(const.BENCHMARK_PATH, 0o777)


	//default is set if a user passes a number of iterations per data object when using the BENCHMARK command
	if default == true {
		fmt.println("Using default iteration values:\nCollections: 2\nClusters: 5\nRecords: 15")
		//Change our values at any time :)nch
		collectionIterations = 2
		clusterIterations = 5
		recordIterations = 15
	} else {
		fmt.printfln(
			"Using custom iteration values:\nCollections: %d\nClusters: %d\nRecords: %d",
			iterations[0],
			iterations[1],
			iterations[2],
		)
		collectionIterations = iterations[0]
		clusterIterations = iterations[1]
		recordIterations = iterations[2]
	}
	fmt.println("---------------------------------------------------\n")
	//Note to developers: Each benchmark operation i.e create,fetch, and erase must match the same number of iterations on the same data structure.
	//For example, if you create 10 collections, you must fetch 10 collections and erase 10 collections. The same applies to clusters and records.
	// - Marshall


	basicResults := B_BASIC_SUITE(collectionIterations, clusterIterations, recordIterations)
	mediumResults := B_MEDIUM_SUITE(collectionIterations, clusterIterations, recordIterations)
	advancedResults := B_ADVANCED_SUITE(collectionIterations, clusterIterations, recordIterations)


	//Get the count of failed operations for each suite
	for result in basicResults {
		if result.success == false {
			basicSuiteFailCounter += 1
		}
	}
	for result in mediumResults {
		if result.success == false {
			mediumSuiteFailCounter += 1
		}
	}
	for result in advancedResults {
		if result.success == false {
			advancedSuiteFailCounter += 1
		}
	}

	//get grand totals for basic suite
	for i := 0; i < len(basicResults); i += 1 {
		basicOperationCount += basicResults[i].total_ops
		basicOperationTime += basicResults[i].op_time
	}
	//get grand totals for medium suite
	for i := 0; i < len(mediumResults); i += 1 {
		meduimOperationCount += mediumResults[i].total_ops
		mediumOperationTime += mediumResults[i].op_time
	}
	//get grand totals for advanced suite
	for i := 0; i < len(advancedResults); i += 1 {
		advancedOperationCount += advancedResults[i].total_ops
		advancedOperationTime += advancedResults[i].op_time
	}

	//Get the the operations per second for each suite
	basicTotalOpsPerSecond := f64(basicOperationCount) / time.duration_seconds(basicOperationTime)
	mediumTotalOpsPerSecond :=
		f64(meduimOperationCount) / time.duration_seconds(mediumOperationTime)
	advancedTotalOpsPerSecond :=
		f64(advancedOperationCount) / time.duration_seconds(advancedOperationTime)


	//Print results
	fmt.println("Basic Benchmark Suite Results:")
	show_all_benchmark_results("Basic", basicResults)
	fmt.println("---------------------------------------------------\n")

	fmt.println("Medium Benchmark Suite Results:")
	show_all_benchmark_results("Medium", mediumResults)
	fmt.println("---------------------------------------------------\n")

	fmt.println("Advanced Benchmark Suite Results:")
	show_all_benchmark_results("Advanced", advancedResults)

	show_grand_totals(
		advancedOperationTime + basicOperationTime + mediumOperationTime,
		advancedTotalOpsPerSecond + basicTotalOpsPerSecond + mediumTotalOpsPerSecond,
		advancedOperationCount + meduimOperationCount + basicOperationCount,
		advancedSuiteFailCounter + mediumSuiteFailCounter + basicSuiteFailCounter,
	)
	//Can't forget to free the memory :)
	delete(basicResults)
	delete(mediumResults)
	delete(advancedResults)


	os.remove(const.BENCHMARK_PATH)
}

//Creates, fetches, and erases
B_BASIC_SUITE :: proc(colIter, clutIter, recIter: int) -> [dynamic]types.Benchmark_Result {
	basicResults := make([dynamic]types.Benchmark_Result, 0)
	//Create
	benchmark1, colNames := B_CREATE_COLLECTION_OP(colIter)
	benchmark2, cluNames := B_CREATE_CLUSTER_OP(clutIter, colNames)
	benchmark3, recNames := B_CREATE_RECORD_OP(colNames, cluNames, recIter)

	//Fetch
	benchmark4 := B_FETCH_COLLECTION_OP(colIter)
	benchmark5 := B_FETCH_CLUSTER_OP(colNames, clutIter)
	benchmark6 := B_FETCH_RECORD_OP(colNames, cluNames, recIter)

	//Erase
	benchmark7 := B_ERASE_RECORD_OP(colNames, cluNames, recIter)
	benchmark8 := B_ERASE_CLUSTER_OP(colNames, clutIter)
	benchmark9 := B_ERASE_COLLECTION_OP(colIter)

	append(&basicResults, benchmark1, benchmark2, benchmark3, benchmark4, benchmark5, benchmark6, benchmark7, benchmark8, benchmark9)

	return basicResults
}

//Creates,fetches, changes record types and erases
B_MEDIUM_SUITE :: proc(colIter, clutIter, recIter: int) -> [dynamic]types.Benchmark_Result {
	mediumResults := make([dynamic]types.Benchmark_Result, 0)

	//Create
	benchmark1, colNames := B_CREATE_COLLECTION_OP(colIter)
	benchmark2, cluNames := B_CREATE_CLUSTER_OP(clutIter, colNames)
	benchmark3, recNames := B_CREATE_RECORD_OP(colNames, cluNames, recIter)

	//Fetch
	benchmark4 := B_FETCH_COLLECTION_OP(colIter)
	benchmark5 := B_FETCH_CLUSTER_OP(colNames, clutIter)
	benchmark6 := B_FETCH_RECORD_OP(colNames, cluNames, recIter)

	//Change Record Type
	benchmark7 := B_CHANGE_RECORD_TYPE_OP(colNames, cluNames, recIter)

	//Erase
	benchmark8 := B_ERASE_RECORD_OP(colNames, cluNames, recIter)
	benchmark9 := B_ERASE_CLUSTER_OP(colNames, clutIter)
	benchmark10 := B_ERASE_COLLECTION_OP(colIter)

	append(&mediumResults, benchmark1,benchmark2,benchmark3, benchmark4, benchmark5, benchmark6, benchmark7, benchmark8, benchmark9, benchmark10)

	return mediumResults
}
//Creates,fetches, changes record types, purges, creates again then and erases
B_ADVANCED_SUITE :: proc(colIter, clutIter, recIter: int) -> [dynamic]types.Benchmark_Result {
	advancedResults := make([dynamic]types.Benchmark_Result, 0)

	//Create
	benchmark1, colNames := B_CREATE_COLLECTION_OP(colIter)
	benchmark2, cluNames := B_CREATE_CLUSTER_OP(clutIter, colNames)
	benchmark3, recNames := B_CREATE_RECORD_OP(colNames, cluNames, recIter)

	//Fetch
	benchmark4 := B_FETCH_COLLECTION_OP(colIter)
	benchmark5 := B_FETCH_CLUSTER_OP(colNames, clutIter)
	benchmark6 := B_FETCH_RECORD_OP(colNames, cluNames, recIter)

	//Change Record Type
	benchmark7 := B_CHANGE_RECORD_TYPE_OP(colNames, cluNames, recIter)

	//Purge
	benchmark8 := B_PURGE_COLLECTION_OP(colIter)

	//Delete
	benchmark9 := B_ERASE_COLLECTION_OP(colIter)

	//Create again
	benchmark10, colNamesAgain := B_CREATE_COLLECTION_OP(colIter)
	benchmark11, cluNamesAgain := B_CREATE_CLUSTER_OP(clutIter, colNamesAgain)
	benchmark12, recNamesAgain := B_CREATE_RECORD_OP(colNamesAgain, cluNamesAgain, recIter)

	//Erase
	benchmark13 := B_ERASE_RECORD_OP(colNamesAgain, cluNamesAgain, recIter)
	benchmark14 := B_ERASE_CLUSTER_OP(colNamesAgain, clutIter)
	benchmark15 := B_ERASE_COLLECTION_OP(colIter)

	append(&advancedResults, benchmark1, benchmark2, benchmark3, benchmark4, benchmark5, benchmark6, benchmark7, benchmark8, benchmark9, benchmark10, benchmark11, benchmark12, benchmark13, benchmark14, benchmark15)

	return advancedResults

}
//============================================CORE BENCMARKING PROCEDURES============================================//
//============================================CORE BENCMARKING PROCEDURES============================================//
//============================================CORE BENCMARKING PROCEDURES============================================//

//All "B_<name>_OP" procedures perform the actual benchmarking operational logic
B_CREATE_COLLECTION_OP :: proc(iterations: int) -> (types.Benchmark_Result, [dynamic]string) {
	startTime := time.now()
	names: [dynamic]string

	// Get current collection count
	if dir_handle, err := os.open(const.BENCHMARK_PATH); err == 0 {
		defer os.close(dir_handle)
		if files, read_err := os.read_dir(dir_handle, 0); read_err == 0 {
			defer delete(files)
			startIndex := len(files)

			// Create new collections starting from existing count
			for i := 0; i < iterations; i += 1 {
				benchmarkColName := fmt.tprintf("benchmark_collection_%d", startIndex + i)
				if B_CREATE_COLLECTION(benchmarkColName) == 0 {
					append(&names, benchmarkColName)
				} else {
					return types.Benchmark_Result {
							op_name = "Create Collection",
							total_ops = i,
							op_time = time.since(startTime),
							ops_per_second = 0,
							success = false,
						},
						names
				}
			}
		}
	}


	duration := time.since(startTime)
	ops_per_second := f64(iterations) / time.duration_seconds(duration)

	return types.Benchmark_Result {
			op_name = "Create Collection",
			total_ops = iterations,
			op_time = duration,
			ops_per_second = ops_per_second,
			success = true,
		},
		names
}

B_CREATE_CLUSTER_OP :: proc(
	iterations: int,
	colNames: [dynamic]string,
) -> (
	types.Benchmark_Result,
	[dynamic]string,
) {
	names: [dynamic]string
	startTime := time.now()


	//collection names
	for colName in colNames {
		for i := 0; i < iterations; i += 1 {
			benchmarkCluName := fmt.tprintf("benchmark_cluster_%d", i)
			if B_CREATE_CLUSTER(colName, benchmarkCluName) == 0 {
				append(&names, benchmarkCluName)
			} else {
				return types.Benchmark_Result {
						op_name = "Create Cluster",
						total_ops = i,
						op_time = time.since(startTime),
						ops_per_second = 0,
						success = false,
					},
					names
			}
		}
	}


	duration := time.since(startTime)
	ops_per_second := f64(iterations) / time.duration_seconds(duration)

	return types.Benchmark_Result {
			op_name = "Create Cluster",
			total_ops = iterations,
			op_time = duration,
			ops_per_second = ops_per_second,
			success = true,
		},
		names
}


B_CREATE_RECORD_OP :: proc(
	colNames, cluNames: [dynamic]string,
	iterations: int,
) -> (
	types.Benchmark_Result,
	[dynamic]string,
) {
	names: [dynamic]string
	startTime := time.now()
	recordCounter := 0

	for colName in colNames {
		for cluName in cluNames {
			for k := 0; k < iterations; k += 1 {
				benchmarkRecName := fmt.tprintf("benchmark_record_%d", recordCounter)
				rType := B_GENERATE_RECORD_TYPE()
				rValue := B_GENERATE_RECORD_VALUES(rType)
				if B_CREATE_RECORD(colName, cluName, benchmarkRecName, rType, rValue) == 0 {
					append(&names, benchmarkRecName)
					recordCounter += 1
				} else {
					return types.Benchmark_Result {
							op_name = "Create Records",
							total_ops = recordCounter,
							op_time = time.since(startTime),
							ops_per_second = 0,
							success = false,
						},
						names
				}
			}
		}
	}

	duration := time.since(startTime)
	total_ops := len(colNames) * len(cluNames) * iterations
	ops_per_second := f64(total_ops) / time.duration_seconds(duration)

	return types.Benchmark_Result {
			op_name = "Create Records",
			total_ops = total_ops,
			op_time = duration,
			ops_per_second = ops_per_second,
			success = true,
		},
		names
}

B_FETCH_COLLECTION_OP :: proc(iterations: int) -> types.Benchmark_Result {
	startTime := time.now()
	for i := 0; i < iterations; i += 1 {
		if B_FETCH_COLLECTION(fmt.tprintf("benchmark_collection_%d", i)) == 0 {
			continue
		} else {
			return types.Benchmark_Result {
				op_name = "Fetch Collection",
				total_ops = i,
				op_time = time.since(startTime),
				ops_per_second = 0,
				success = false,
			}
		}
	}
	duration := time.since(startTime)
	ops_per_second := f64(iterations) / time.duration_seconds(duration)

	return types.Benchmark_Result {
		op_name = "Fetch Collection",
		total_ops = iterations,
		op_time = duration,
		ops_per_second = ops_per_second,
		success = true,
	}
}

B_FETCH_CLUSTER_OP :: proc(colNames: [dynamic]string, iterations: int) -> types.Benchmark_Result {
	startTime := time.now()
	for colName in colNames {
		for i := 0; i < iterations; i += 1 {
			if B_FETCH_CLUSTER(colName, fmt.tprintf("benchmark_cluster_%d", i)) == 0 {
				continue
			} else {
				return types.Benchmark_Result {
					op_name = "Fetch Cluster",
					total_ops = len(colNames) * i,
					op_time = time.since(startTime),
					ops_per_second = 0,
				}
			}
		}
	}
	duration := time.since(startTime)
	ops_per_second := f64(len(colNames) * iterations) / time.duration_seconds(duration)

	return types.Benchmark_Result {
		op_name = "Fetch Cluster",
		total_ops = len(colNames) * iterations,
		op_time = duration,
		ops_per_second = ops_per_second,
		success = true,
	}

}


B_FETCH_RECORD_OP :: proc(
	colNames, cluNames: [dynamic]string,
	iterations: int,
) -> types.Benchmark_Result {
	startTime := time.now()
	recordCounter := 0 // Add a record counter to match creation pattern

	for colName in colNames {
		for cluName in cluNames {
			for i := 0; i < iterations; i += 1 {
				// Use recordCounter instead of i to match creation pattern
				if B_FETCH_RECORD(
					   colName,
					   cluName,
					   fmt.tprintf("benchmark_record_%d", recordCounter),
				   ) ==
				   0 {
					recordCounter += 1
					continue
				} else {
					return types.Benchmark_Result {
						op_name        = "Fetch Record",
						total_ops      = recordCounter, // Use recordCounter instead of calculation
						op_time        = time.since(startTime),
						ops_per_second = 0,
						success        = false,
					}
				}
			}
		}
	}
	duration := time.since(startTime)
	total_ops := len(colNames) * len(cluNames) * iterations
	ops_per_second := f64(total_ops) / time.duration_seconds(duration)

	return types.Benchmark_Result {
		op_name = "Fetch Record",
		total_ops = total_ops,
		op_time = duration,
		ops_per_second = ops_per_second,
		success = true,
	}
}

B_ERASE_COLLECTION_OP :: proc(iterations: int) -> types.Benchmark_Result {
	startTime := time.now()
	for i := 0; i < iterations; i += 1 {
		if B_ERASE_COLLECTION(fmt.tprintf("benchmark_collection_%d", i)) == 0 {
			continue
		} else {
			return types.Benchmark_Result {
				op_name = "Erase Collection",
				total_ops = i,
				op_time = time.since(startTime),
				ops_per_second = 0,
				success = false,
			}
		}
	}
	duration := time.since(startTime)
	ops_per_second := f64(iterations) / time.duration_seconds(duration)

	return types.Benchmark_Result {
		op_name = "Erase Collection",
		total_ops = iterations,
		op_time = duration,
		ops_per_second = ops_per_second,
		success = true,
	}
}

B_ERASE_CLUSTER_OP :: proc(fn: [dynamic]string, iterations: int) -> types.Benchmark_Result {
	startTime := time.now()
	for colName in fn {
		for i := 0; i < iterations; i += 1 {
			if B_ERASE_CLUSTER(colName, fmt.tprintf("benchmark_cluster_%d", i)) == 0 {
				continue
			} else {
				return types.Benchmark_Result {
					op_name = "Erase Cluster",
					total_ops = len(fn) * i,
					op_time = time.since(startTime),
					ops_per_second = 0,
					success = false,
				}
			}
		}
	}
	duration := time.since(startTime)
	ops_per_second := f64(len(fn) * iterations) / time.duration_seconds(duration)

	return types.Benchmark_Result {
		op_name = "Erase Cluster",
		total_ops = len(fn) * iterations,
		op_time = duration,
		ops_per_second = ops_per_second,
		success = true,
	}
}

B_ERASE_RECORD_OP :: proc(fn, cn: [dynamic]string, iterations: int) -> types.Benchmark_Result {
	startTime := time.now()
	recordCounter := 0

	for colName in fn {
		for cluName in cn {
			for i := 0; i < iterations; i += 1 {
				if B_ERASE_RECORD(
					   colName,
					   cluName,
					   fmt.tprintf("benchmark_record_%d", recordCounter),
				   ) ==
				   0 {
					recordCounter += 1
					continue
				} else {
					return types.Benchmark_Result {
						op_name = "Erase Record",
						total_ops = recordCounter,
						op_time = time.since(startTime),
						ops_per_second = 0,
						success = false,
					}
				}
			}
		}
	}
	duration := time.since(startTime)
	total_ops := len(fn) * len(cn) * iterations
	ops_per_second := f64(total_ops) / time.duration_seconds(duration)

	return types.Benchmark_Result {
		op_name = "Erase Record",
		total_ops = total_ops,
		op_time = duration,
		ops_per_second = ops_per_second,
		success = true,
	}
}


B_CHANGE_RECORD_TYPE_OP :: proc(
	colNames, cluNames: [dynamic]string,
	iterations: int,
) -> types.Benchmark_Result {
	startTime := time.now()
	recordCounter := 0

	for colName in colNames {
		for cluName in cluNames {
			for i := 0; i < iterations; i += 1 {
				recordName := fmt.tprintf("benchmark_record_%d", recordCounter)
				newType := B_GENERATE_RECORD_TYPE()
				newValue := B_GENERATE_RECORD_VALUES(newType)

				if B_CHANGE_RECORD_TYPE(colName, cluName, recordName, newType, newValue) == 0 {
					recordCounter += 1
					continue
				} else {
					return types.Benchmark_Result {
						op_name = "Change Record Type",
						total_ops = recordCounter,
						op_time = time.since(startTime),
						ops_per_second = 0,
						success = false,
					}
				}
			}
		}
	}

	duration := time.since(startTime)
	total_ops := len(colNames) * len(cluNames) * iterations
	ops_per_second := f64(total_ops) / time.duration_seconds(duration)

	return types.Benchmark_Result {
		op_name = "Change Record Type",
		total_ops = total_ops,
		op_time = duration,
		ops_per_second = ops_per_second,
		success = true,
	}
}


B_PURGE_COLLECTION_OP :: proc(iterations: int) -> types.Benchmark_Result {
	startTime := time.now()
	for i := 0; i < iterations; i += 1 {
		if B_PURGE_COLLECTION(fmt.tprintf("benchmark_collection_%d", i)) == 0 {
			continue
		} else {
			return types.Benchmark_Result {
				op_name = "Purge Collection",
				total_ops = i,
				op_time = time.since(startTime),
				ops_per_second = 0,
				success = false,
			}
		}
	}
	duration := time.since(startTime)
	ops_per_second := f64(iterations) / time.duration_seconds(duration)

	return types.Benchmark_Result {
		op_name = "Purge Collection",
		total_ops = iterations,
		op_time = duration,
		ops_per_second = ops_per_second,
		success = true,
	}
}

//============================================DATA MANIPULATION PROCEDURES============================================//
//============================================DATA MANIPULATION PROCEDURES============================================//
//============================================DATA MANIPULATION PROCEDURES============================================//

//CREATION PROCEDURES START
B_CREATE_COLLECTION :: proc(fn: string) -> int {
	file := concat_benchmark_collection(fn)

	createFile, createSuccess := os.open(file, os.O_CREATE, 0o666)
	defer os.close(createFile)
	mDataAppended := metadata.APPEND_METADATA_HEADER_TO_COLLECTION(file)
	if !mDataAppended {
		return -1
	}
	if createSuccess != 0 {
		return -2
	} else {
		metadata.INIT_METADATA_IN_NEW_COLLECTION(file)
	}
	return 0
}

B_GENERATE_ID :: proc() -> i64 {
	//ensure the generated id length is 16 digits
	ID := rand.int63_max(1e16 + 1)
	return ID
}

B_CREATE_CLUSTER :: proc(fn, cn: string) -> int {
	using utils

	id := B_GENERATE_ID()
	LAST_HALF: []string = {"\n\tcluster_id :identifier: %i\n\t\n},\n"}
	FIRST_HALF: []string = {"\n{\n\tcluster_name :identifier: %n"}
	buf: [32]byte
	path := concat_benchmark_collection(fn)

	colFile, openSuccess := os.open(path, os.O_APPEND | os.O_WRONLY, 0o666)
	defer os.close(colFile)
	if openSuccess != 0 {
		return -1
	}


	for i := 0; i < len(FIRST_HALF); i += 1 {
		if (strings.contains(FIRST_HALF[i], "%n")) {
			newClusterName, replaceSuccess := strings.replace(FIRST_HALF[i], "%n", cn, -1)
			writeClusterName, writeSuccess := os.write(colFile, transmute([]u8)newClusterName)
		}
	}
	for i := 0; i < len(LAST_HALF); i += 1 {
		if strings.contains(LAST_HALF[i], "%i") {
			newClusterID, replaceSuccess := strings.replace(
				LAST_HALF[i],
				"%i",
				strconv.append_int(buf[:], id, 10),
				-1,
			)
			if replaceSuccess == false {
				return -2
			}
			writeClusterID, writeSuccess := os.write(colFile, transmute([]u8)newClusterID)
			if writeSuccess != 0 {
				return -3
			}
		}
	}

	//update metadata
	refresh_metadata(fn)
	return 0
}

B_GENERATE_RECORD_TYPE :: proc() -> string {
	types := []string{"STRING", "INTEGER", "FLOAT", "BOOLEAN"}
	return rand.choice(types)
}

B_GENERATE_RECORD_VALUES :: proc(rType: string) -> string {
	buf: [32]byte
	boolValues := []string{"true", "false"}
	stringValues := "lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor incididunt ut labore et dolore magna aliqua"

	intValue := rand.int63_max(1e16 + 1)
	intAsStr := fmt.tprintf("%d", intValue)

	floatValue := rand.float64()
	floatAsStr := fmt.tprintf("%f", floatValue)


	switch rType {
	case "STRING":
		return utils.append_qoutations(stringValues)
	case "INTEGER":
		return intAsStr
	case "FLOAT":
		return floatAsStr
	case "BOOLEAN":
		return rand.choice(boolValues)
	}

	return "You should not see this"
}

B_CREATE_RECORD :: proc(fn, cn, rn, rType, rValue: string) -> int {
	file := concat_benchmark_collection(fn)
	data, readSuccess := utils.read_file(file, #procedure)
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

	//if the cluster is not found or the structure is invalid, return
	if clusterStart == -1 || closingBrace == -1 {
		return -2
	}

	// Create the new line
	new_line := fmt.tprintf("\t%s :%s: %s", rn, rType, rValue)

	// Insert the new line and adjust the closing brace
	new_lines := make([dynamic]string, len(lines) + 1)
	copy(new_lines[:closingBrace], lines[:closingBrace])
	new_lines[closingBrace] = new_line
	new_lines[closingBrace + 1] = "},"
	if closingBrace + 1 < len(lines) {
		copy(new_lines[closingBrace + 2:], lines[closingBrace + 1:])
	}

	new_content := strings.join(new_lines[:], "\n")
	writeSuccess := utils.write_to_file(file, transmute([]byte)new_content, #procedure)
	if !writeSuccess {
		return -3
	}

	//update metadata
	refresh_metadata(fn)
	return 0
}
//CREATION PROCEDURES END


//FETCHING PROCEDURES START
//All FETCH procs only ensure that the file is read and the starting point is found nothing more
B_FETCH_COLLECTION :: proc(fn: string) -> int {
	fileStart := -1
	startingPoint := "BTM@@@@@@@@@@@@@@@"
	file := concat_benchmark_collection(fn)
	data, readSuccess := os.read_entire_file(file)
	if !readSuccess {
		return -1
	}
	defer delete(data)
	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)
	for i := 0; i < len(lines); i += 1 {
		if strings.contains(lines[i], startingPoint) {
			fileStart = i + 1
			break
		}
	}
	if fileStart == -1 || fileStart >= len(lines) {
		return -2
	}

	return 0
}

B_FETCH_CLUSTER :: proc(fn, cn: string) -> int {
	using const
	using utils

	clusterContent: string
	collectionPath := concat_benchmark_collection(fn)

	data, readSuccess := os.read_entire_file(collectionPath)
	if !readSuccess {
		return -1
	}

	defer delete(data)

	content := string(data)
	clusters := strings.split(content, "}")

	for cluster in clusters {
		if strings.contains(cluster, fmt.tprintf("cluster_name :identifier: %s", cn)) {
			// Find the start of the cluster (opening brace)
			startIndex := strings.index(cluster, "{")
			if startIndex != -1 {
				// Extract the content between braces
				clusterContent = cluster[startIndex + 1:]
				// Trim any leading or trailing whitespace
				clusterContent = strings.trim_space(clusterContent)
				return 0
			}
		}
	}

	return -2
}

B_FETCH_RECORD :: proc(fn, cn, rn: string) -> int {
	clusterContent: string
	recordContent: string
	collectionPath := concat_benchmark_collection(fn)

	data, readSuccess := os.read_entire_file(collectionPath)
	if !readSuccess {
		return -1
	}

	defer delete(data)

	content := string(data)
	clusters := strings.split(content, "}")

	for cluster in clusters {
		if strings.contains(cluster, fmt.tprintf("cluster_name :identifier: %s", cn)) {
			// Find the start of the cluster (opening brace)
			startIndex := strings.index(cluster, "{")
			if startIndex != -1 {
				// Extract the content between braces
				clusterContent = cluster[startIndex + 1:]
				// Trim any leading or trailing whitespace
				clusterContent = strings.trim_space(clusterContent)
				// return strings.clone(clusterContent)
			}
		}
	}

	for line in strings.split_lines(clusterContent) {
		if strings.contains(line, rn) {
			return 0
		}
	}

	return -2 //fail to fetch record

}
//FETCHING PROCEDURES END

//ERASE PROCEDURES START
B_ERASE_COLLECTION :: proc(fn: string) -> int {
	file := concat_benchmark_collection(fn)
	deleteSuccess := os.remove(file)
	if deleteSuccess != 0 {
		return -1
	}
	return 0
}

B_ERASE_CLUSTER :: proc(fn, cn: string) -> int {
	using utils

	success: int
	buf: [64]byte
	file: string
	collectionPath := concat_benchmark_collection(fn)

	data, readSuccess := read_file(collectionPath, #procedure)
	defer delete(data)

	content := string(data)

	// Find the end of the metadata header
	headerEnd := strings.index(content, const.METADATA_END)
	// Move past the metadata header
	headerEnd += len(const.METADATA_END) + 1

	//split content into metadata header and body
	metaDataHeader := content[:headerEnd]
	body := content[headerEnd:]


	clusters := strings.split(content, "},")
	newContent := make([dynamic]u8)
	defer delete(newContent)
	clusterFound := false
	append(&newContent, ..transmute([]u8)metaDataHeader)


	for cluster in clusters {
		// Find the cluster name in the current cluster
		nameStart := strings.index(cluster, "cluster_name :identifier:")
		if nameStart != -1 {
			// Move past the identifier prefix
			nameStart += len("cluster_name :identifier:")
			// Find the end of the line
			nameEnd := strings.index(cluster[nameStart:], "\n")
			if nameEnd != -1 {
				// Extract the actual cluster name and remove leading/trailing whitespace
				cluster_name := strings.trim_space(cluster[nameStart:][:nameEnd])

				// Skip this cluster if it matches the one we want to delete
				if cluster_name == cn {
					clusterFound = true
					continue
				}
			}
		}
		//perseve non-empty clusters
		if len(strings.trim_space(cluster)) > 0 {
			append(&newContent, ..transmute([]u8)cluster)
			append(&newContent, "},")
		}
	}

	if !clusterFound {
		return -1
	}

	writeSuccess := write_to_file(collectionPath, newContent[:], #procedure)
	if !writeSuccess {
		return -2
	} else {
		refresh_metadata(fn)
		return 0
	}
}

B_ERASE_RECORD :: proc(fn, cn, rn: string) -> int {
	using utils

	collectionPath := concat_benchmark_collection(fn)

	data, readSuccess := utils.read_file(collectionPath, #procedure)
	defer delete(data)
	if !readSuccess {
		return -1
	}

	content := string(data)
	lines := strings.split(content, "\n")
	newLines := make([dynamic]string)
	defer delete(newLines)

	inTargetCluster := false
	recordFound := false
	isLastRecord := false
	recordCount := 0

	for line in lines {
		trimmedLine := strings.trim_space(line)
		if strings.contains(trimmedLine, fmt.tprintf("cluster_name :identifier: %s", cn)) {
			inTargetCluster = true
			continue
		}
		if inTargetCluster {
			if trimmedLine == "}," {
				inTargetCluster = false
				continue
			}
			if len(trimmedLine) > 0 &&
			   !strings.has_prefix(trimmedLine, "cluster_name") &&
			   !strings.has_prefix(trimmedLine, "cluster_id") {
				recordCount += 1
			}
		}
	}

	inTargetCluster = false
	for line in lines {
		trimmedLine := strings.trim_space(line)

		if strings.contains(trimmedLine, fmt.tprintf("cluster_name :identifier: %s", cn)) {
			inTargetCluster = true
			append(&newLines, line)
			continue
		}

		if inTargetCluster {
			if strings.has_prefix(trimmedLine, fmt.tprintf("%s :", rn)) {
				recordFound = true
				if recordCount == 1 {
					isLastRecord = true
				}
				continue
			}

			if trimmedLine == "}," {
				if !isLastRecord {
					append(&newLines, line)
				} else {
					append(&newLines, "}")
				}
				inTargetCluster = false
				continue
			}
		}

		if !inTargetCluster || !strings.has_prefix(trimmedLine, fmt.tprintf("%s :", rn)) {
			append(&newLines, line)
		}
	}

	if !recordFound {
		return -2
	}

	newContent := strings.join(newLines[:], "\n")
	writeSuccess := utils.write_to_file(collectionPath, transmute([]byte)newContent, #procedure)
	return 0
}
//ERASE PROCEDURES END


// PURGE PROCEDURES START
B_PURGE_COLLECTION :: proc(fn: string) -> int {
	file := concat_benchmark_collection(fn)
	data, readSuccess := utils.read_file(file, #procedure)
	defer delete(data)
	if !readSuccess {
		return -1
	}

	// Find metadata section end
	content := string(data)
	headerEnd := strings.index(content, const.METADATA_END)
	if headerEnd == -1 {
		return -2
	}

	// Keep only the metadata header
	headerEnd += len(const.METADATA_END)
	metadataHeader := content[:headerEnd]

	// Write back just the metadata
	writeSuccess := utils.write_to_file(file, transmute([]byte)metadataHeader, #procedure)
	if !writeSuccess {
		return -3
	}

	refresh_metadata(fn)
	return 0
}

//Add purge cluster and record procedures here
// PURGE PROCEDURES END


B_CHANGE_RECORD_TYPE :: proc(fn, cn, rn, newType, newValue: string) -> int {
	file := concat_benchmark_collection(fn)
	data, readSuccess := utils.read_file(file, #procedure)
	defer delete(data)
	if !readSuccess {
		return -1
	}

	content := string(data)
	lines := strings.split(content, "\n")
	newLines := make([dynamic]string)
	defer delete(lines)
	defer delete(newLines)

	inTargetCluster := false
	recordFound := false

	for line in lines {
		trimmedLine := strings.trim_space(line)

		if strings.contains(trimmedLine, fmt.tprintf("cluster_name :identifier: %s", cn)) {
			inTargetCluster = true
			append(&newLines, line)
			continue
		}

		if inTargetCluster {
			if strings.has_prefix(trimmedLine, fmt.tprintf("%s :", rn)) {
				recordFound = true
				// Replace with new type and value
				append(&newLines, fmt.tprintf("\t%s :%s: %s", rn, newType, newValue))
				continue
			}

			if trimmedLine == "}," {
				inTargetCluster = false
			}
		}

		append(&newLines, line)
	}

	if !recordFound {
		return -2
	}

	newContent := strings.join(newLines[:], "\n")
	writeSuccess := utils.write_to_file(file, transmute([]byte)newContent, #procedure)
	if !writeSuccess {
		return -3
	}

	refresh_metadata(fn)
	return 0
}
//============================================COMMON UTILS============================================//
//============================================COMMON UTILS============================================//
//============================================COMMON UTILS============================================//

//Might move them to their own file in the package at some point - Marshall
concat_benchmark_collection :: proc(name: string) -> string {
	using const

	return strings.clone(fmt.tprintf("%s%s%s", BENCHMARK_PATH, name, OST_EXT))
}

refresh_metadata :: proc(fn: string) {
	using metadata

	file := concat_benchmark_collection(fn)
	UPDATE_METADATA_FIELD_AFTER_OPERATION(file)
}

show_benchmark_result :: proc(suite: string, res: types.Benchmark_Result) {
	using utils
	if res.success {
		fmt.printfln("Suite: %s%s%s", BOLD, suite, RESET)
		fmt.printfln("Benchmark: %s%s%s Complete", BOLD_UNDERLINE, res.op_name, RESET)
		fmt.printfln("Total Operations: %s%d%s", GREEN, res.total_ops, RESET)
		fmt.printfln("Total Time: %s%d%s", GREEN, res.op_time, RESET)
		fmt.printfln("Operations Per Second: %s%f%s\n", GREEN, res.ops_per_second, RESET)
	} else if !res.success {
		fmt.printfln(
			"%sBenchmark: %s%s%s %sFailed%s",
			RED,
			BOLD_UNDERLINE,
			res.op_name,
			RESET,
			RED,
			RESET,
		)
		fmt.printfln("Finished %d operations before failing", res.total_ops)
	}
}

show_all_benchmark_results :: proc(suite: string, results: [dynamic]types.Benchmark_Result) {
	for res in results {
		show_benchmark_result(suite, res)
	}
}

//t1: total time, t2: operations per second, t3: total operations, t4: failed operations
show_grand_totals :: proc(t1: time.Duration, t2: f64, t3, t4: int) {
	using utils

	fmt.printfln("----------------------------------")
	fmt.println("OstrichDB Benchmark Grand Totals")
	fmt.printfln("Time: %s%d%s", GREEN, t1, RESET)
	fmt.printfln("Operations Per Second: %s%f%s ", GREEN, t2, RESET)
	fmt.printfln("Operations: %s%d%s ", GREEN, t3, RESET)
	fmt.printfln("Failed Operations: %s%d%s ", RED, t4, RESET)
}
