package benchmark
import "../../utils"
import "../const"
import "../engine/data"
import "../engine/data/metadata"
import "../types"
import "core:c/libc"
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


//MY GUIDELINES FOR THE BENCHMARKING OSTRICHDB PACKAGAGE
// All benchmarking types,procs,utils,etc will be located in this single file.
// The file will be split into sections.
// Procs will NOT take any user input, thus all data will be generated randomly.
// Cluster IDs will be randomly generated but NOT stored in the ./ids.ost file.
// Created collection files will NOT be in the ./collections dir but in the ./benchmark dir
// After the benchmark.main() proc runs the ./benchmark directory will be deleted.
//
// Benchmarking will evaluate the performance of the following operations:
// 1. Create 3 collections
// 2. 1 collection will have 10 clusters, another 100 cluster and the last 1000 clusters
// 3. The amount of records that each cluster of each file contains will be randomly generated between 10 and 1000
// 4. The datatype and value for each record will be randomized as well.
// 5. After all data is set, the next benchmark will be to fetch entire collections, then individual clusters, then individual records.
// 6. The final benchmark will be to delete all data from the collections.


main :: proc() {
	//Create the benchmark directory
	os.make_directory(const.OST_BENCHMARK_PATH, 0o777)

	//Create the collections

	res := B_COLLECTION_OP()
	fmt.println("Finsihed Executing Benchmark: ", res.op_name)
	fmt.println("Total Operations: ", res.total_ops)
	fmt.println("Total Time: ", res.op_time)
	fmt.println("Operations Per Second: ", res.ops_per_second)


	//Create the clusters
	//Create the records
	//Fetch the collections
	//Fetch the clusters
	//Fetch the records
	//Delete the records
	//Delete the clusters
	//Delete the collections
}


B_COLLECTION_OP :: proc() -> types.Benchmark_Result {
	startTime := time.now()
	totalOperations := 1000

	for i := 0; i < totalOperations; i += 1 {
		benchmarkColName := fmt.tprintf("benchmark_collection_%d", i)
		B_CREATE_COLLECTION(benchmarkColName)
	}

	duration := time.since(startTime)
	ops_per_second := f64(totalOperations) / time.duration_seconds(duration)

	return types.Benchmark_Result {
		op_name = "Create Collection",
		total_ops = totalOperations,
		op_time = duration,
		ops_per_second = ops_per_second,
	}
}


//PROCEDURES


B_CREATE_COLLECTION :: proc(fn: string) -> int {
	file := concat_benchmark_collection(fn)

	createFile, createSuccess := os.open(file, os.O_CREATE, 0o666)
	defer os.close(createFile)
	mDataAppended := metadata.OST_APPEND_METADATA_HEADER(file)
	if !mDataAppended {
		utils.log_err("Error appending metadata to collection file", #procedure)
		return -1
	}
	if createSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_CREATE_FILE,
			utils.get_err_msg(.CANNOT_CREATE_FILE),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Error creating new collection file", #procedure)
		return -1
	} else {
		metadata.OST_UPDATE_METADATA_ON_CREATE(file)
	}
	return 0
}


// B_CREATE_CLUSTER :: proc(fn, cn: string) -> bool {
// 	using utils

// 	LAST_HALF: []string = {"\n\tcluster_id :identifier: %i\n\t\n},\n"} //defines the base structure of a cluster block in a .ost file
// 	FIRST_HALF: []string = {"\n{\n\tcluster_name :identifier: %n"}
// 	buf: [32]byte
// 	path := concat_benchmark_collection(fn)

// 	colFile, openSuccess := os.open(path, os.O_APPEND | os.O_WRONLY, 0o666)
// 	defer os.close(colFile)
// 	if openSuccess != 0 {
// 		error1 := new_err(.CANNOT_OPEN_FILE, get_err_msg(.CANNOT_OPEN_FILE), #procedure)
// 		throw_err(error1)
// 		log_err("Error opening collection file", #procedure)
// 		return false
// 	}


// 	for i := 0; i < len(FIRST_HALF); i += 1 {
// 		if (strings.contains(FIRST_HALF[i], "%n")) {
// 			newClusterName, replaceSuccess := strings.replace(FIRST_HALF[i], "%n", clusterName, -1)
// 			writeClusterName, writeSuccess := os.write(colFile, transmute([]u8)newClusterName)
// 		}
// 	}
// 	for i := 0; i < len(LAST_HALF); i += 1 {
// 		if strings.contains(LAST_HALF[i], "%i") {
// 			newClusterID, replaceSuccess := strings.replace(
// 				LAST_HALF[i],
// 				"%i",
// 				strconv.append_int(buf[:], id, 10),
// 				-1,
// 			)
// 			if replaceSuccess == false {
// 				error2 := new_err(
// 					.CANNOT_UPDATE_CLUSTER,
// 					get_err_msg(.CANNOT_UPDATE_CLUSTER),
// 					#procedure,
// 				)
// 				throw_err(error2)
// 				log_err("Error placing id into cluster template", #procedure)
// 				return false
// 			}
// 			writeClusterID, writeSuccess := os.write(colFile, transmute([]u8)newClusterID)
// 			if writeSuccess != 0 {
// 				error2 := new_err(
// 					.CANNOT_WRITE_TO_FILE,
// 					get_err_msg(.CANNOT_WRITE_TO_FILE),
// 					#procedure,
// 				)
// 				log_err("Error writing cluster block to file", #procedure)
// 				return false
// 			}
// 		}
// 	}
// 	return true
// }


//COMMON BENCHMARKING UTILS
concat_benchmark_collection :: proc(name: string) -> string {
	using const
	return strings.clone(fmt.tprintf("%s%s%s", OST_BENCHMARK_PATH, name, OST_FILE_EXTENSION))

}
