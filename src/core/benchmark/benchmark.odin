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

main :: proc() {
	using utils

	//Create the benchmark directory
	os.make_directory(const.OST_BENCHMARK_PATH, 0o777)

	//Create the collections

	benchmark1, colNames := B_COLLECTION_OP(1) //pass num of iterations
	benchmark2, cluNames := B_CLUSTER_OP(10, colNames) //pass num of iterations and collection names
	benchmark3, recNames := B_RECORDS_OP(colNames, cluNames, 10) //pass collection names, cluster names, and num of iterations


	//get grand totals
	totalOperations := benchmark1.total_ops + benchmark2.total_ops + benchmark3.total_ops
	totalTime := benchmark1.op_time + benchmark2.op_time + benchmark3.op_time
	totalOpsPerSecond := f64(totalOperations) / time.duration_seconds(totalTime)


	show_benchmark_results(benchmark1)
	show_benchmark_results(benchmark2)
	show_benchmark_results(benchmark3)
	fmt.printfln("----------------------------------")
	fmt.println("OstrichDB Benchmark Grand Totals")
	fmt.printfln("Time: %s%d%s", GREEN, totalTime, RESET)
	fmt.printfln("Operations Per Second: %s%f%s ", GREEN, totalOpsPerSecond, RESET)
	fmt.printfln("Operations: %s%d%s ", GREEN, totalOperations, RESET)

	//Fetch the collections
	//Fetch the clusters
	//Fetch the records
	//Delete the records
	//Delete the clusters
	//Delete the collections
}


B_COLLECTION_OP :: proc(iterations: int) -> (types.Benchmark_Result, [dynamic]string) {
	startTime := time.now()
	names: [dynamic]string

	for i := 0; i < iterations; i += 1 {
		benchmarkColName := fmt.tprintf("benchmark_collection_%d", i)
		B_CREATE_COLLECTION(benchmarkColName)
		append(&names, benchmarkColName)
	}

	duration := time.since(startTime)
	ops_per_second := f64(iterations) / time.duration_seconds(duration)

	return types.Benchmark_Result {
			op_name = "Create Collection",
			total_ops = iterations,
			op_time = duration,
			ops_per_second = ops_per_second,
		},
		names
}

B_CLUSTER_OP :: proc(
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
			B_CREATE_CLUSTER(colName, benchmarkCluName)
			append(&names, benchmarkCluName)
		}
	}


	duration := time.since(startTime)
	ops_per_second := f64(iterations) / time.duration_seconds(duration)

	return types.Benchmark_Result {
			op_name = "Create Cluster",
			total_ops = iterations,
			op_time = duration,
			ops_per_second = ops_per_second,
		},
		names
}


B_RECORDS_OP :: proc(
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
				res := B_CREATE_RECORD(colName, cluName, benchmarkRecName, rType, rValue)
				append(&names, benchmarkRecName)
				recordCounter += 1
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
		},
		names
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


B_GENERATE_ID :: proc() -> i64 {
	//ensure the generated id length is 16 digits
	ID := rand.int63_max(1e16 + 1)
	return ID
}

B_CREATE_CLUSTER :: proc(fn, cn: string) -> bool {
	using utils

	id := B_GENERATE_ID()
	LAST_HALF: []string = {"\n\tcluster_id :identifier: %i\n\t\n},\n"}
	FIRST_HALF: []string = {"\n{\n\tcluster_name :identifier: %n"}
	buf: [32]byte
	path := concat_benchmark_collection(fn)

	colFile, openSuccess := os.open(path, os.O_APPEND | os.O_WRONLY, 0o666)
	defer os.close(colFile)
	if openSuccess != 0 {
		error1 := new_err(.CANNOT_OPEN_FILE, get_err_msg(.CANNOT_OPEN_FILE), #procedure)
		throw_err(error1)
		log_err("Error opening collection file", #procedure)
		return false
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
				error2 := new_err(
					.CANNOT_UPDATE_CLUSTER,
					get_err_msg(.CANNOT_UPDATE_CLUSTER),
					#procedure,
				)
				throw_err(error2)
				log_err("Error placing id into cluster template", #procedure)
				return false
			}
			writeClusterID, writeSuccess := os.write(colFile, transmute([]u8)newClusterID)
			if writeSuccess != 0 {
				error2 := new_err(
					.CANNOT_WRITE_TO_FILE,
					get_err_msg(.CANNOT_WRITE_TO_FILE),
					#procedure,
				)
				log_err("Error writing cluster block to file", #procedure)
				return false
			}
		}
	}

	//update metadata
	refresh_metadata(fn)
	return true
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
	// fmt.println("debugging-- passing fn:, ", fn) //debugging
	// fmt.println("debugging-- passing cn:, ", cn) //debugging
	// fmt.println("debugging-- passing rn:, ", rn) //debugging
	// fmt.println("debugging-- passing rValue:, ", rValue) //debugging
	// fmt.println("debugging-- passing rType:, ", rType) //debugging
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
		error2 := utils.new_err(
			.CANNOT_FIND_CLUSTER,
			utils.get_err_msg(.CANNOT_FIND_CLUSTER),
			#procedure,
		)
		utils.throw_err(error2)
		utils.log_err("Unable to find cluster/valid structure", #procedure)
		return -1
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
	// fmt.println("debugging-- new_content: ", new_content) //debugging
	writeSuccess := utils.write_to_file(file, transmute([]byte)new_content, #procedure)
	if !writeSuccess {
		return -1
	}

	//update metadata
	refresh_metadata(fn)
	return 0


}

//COMMON BENCHMARKING UTILS
concat_benchmark_collection :: proc(name: string) -> string {
	using const
	return strings.clone(fmt.tprintf("%s%s%s", OST_BENCHMARK_PATH, name, OST_FILE_EXTENSION))

}


refresh_metadata :: proc(fn: string) {
	using metadata
	file := concat_benchmark_collection(fn)
	OST_UPDATE_METADATA_VALUE(file, 2)
	OST_UPDATE_METADATA_VALUE(file, 3)
	OST_UPDATE_METADATA_VALUE(file, 5)
}


show_benchmark_results :: proc(res: types.Benchmark_Result) {
	using utils
	fmt.printfln("Benchmark: %s%s%s Complete", BOLD_UNDERLINE, res.op_name, RESET)
	fmt.printfln("Total Operations: %s%d%s", GREEN, res.total_ops, RESET)
	fmt.printfln("Total Time: %s%d%s", GREEN, res.op_time, RESET)
	fmt.printfln("Operations Per Second: %s%f%s\n", GREEN, res.ops_per_second, RESET)
}
