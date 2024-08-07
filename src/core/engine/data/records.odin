package data

import "../../../utils"
import "../../const"
import "../../types"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

// example of a cluster with records in it
/*
{   cluster_name :identifier: example //special record that cannot be changed or deleted without deleting the entire cluster
	cluster_id :identifier: 91849991478591014 //special record that cannot be changed or deleted without deleting the entire cluster

	player name :string: "Marshall"
	player age :int: 25
	player height :string: "6'2"
    player avg grade :float: 3.5
    player is active :bool: true
}
*/

record: types.Record


//can be used to check if a single record exists within a cluster
OST_CHECK_IF_RECORD_EXISTS :: proc(fn: string, cn: string, rn: string) -> bool {
	using const
	data, readSuccess := os.read_entire_file(fn)
	if !readSuccess {
		error1 := utils.new_err(
			.CANNOT_READ_FILE,
			utils.get_err_msg(.CANNOT_READ_FILE),
			#procedure,
		)
		utils.throw_err(error1)
		return false
	}
	defer delete(data)

	// Check if the cluster exists
	clusterExists := OST_CHECK_IF_CLUSTER_EXISTS(fn, cn)
	if !clusterExists {
		error2 := utils.new_err(
			.CANNOT_FIND_CLUSTER,
			utils.get_err_msg(.CANNOT_FIND_CLUSTER),
			#procedure,
		)
		utils.throw_err(error2)
		fmt.println("Cluster does not exist")
		return false
	}

	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)

	cluster_start := -1
	closing_brace := -1
	// Find the cluster and its closing brace
	for i := 0; i < len(lines); i += 1 {
		if strings.contains(lines[i], cn) {
			cluster_start = i
		}
		if cluster_start != -1 && strings.contains(lines[i], "}") {
			closing_brace = i
			break
		}
	}
	// If the cluster is not found or the structure is invalid, return false
	if cluster_start == -1 || closing_brace == -1 {
		error3 := utils.new_err(
			.CANNOT_FIND_CLUSTER,
			utils.get_err_msg(.CANNOT_FIND_CLUSTER),
			#procedure,
		)
		utils.throw_err(error3)
		return false
	}

	// Check if the record exists within the cluster
	for i := cluster_start; i <= closing_brace; i += 1 {
		if strings.contains(lines[i], rn) {
			return true
		}
	}

	return false
}

//fn-filename, cn-clustername,id-cluster id, rn-record name, rd-record data
OST_APPEND_RECORD_TO_CLUSTER :: proc(
	fn: string,
	cn: string,
	rn: string,
	rd: string,
	rType: string,
	ID: ..i64,
) -> int {
	data, readSuccess := os.read_entire_file(fn)
	if !readSuccess {
		error1 := utils.new_err(
			.CANNOT_READ_FILE,
			utils.get_err_msg(.CANNOT_READ_FILE),
			#procedure,
		)
		utils.throw_err(error1)
		return -1
	}
	defer delete(data)

	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)

	cluster_start := -1
	closing_brace := -1

	// Find the cluster and its closing brace
	for i := 0; i < len(lines); i += 1 {
		if strings.contains(lines[i], cn) {
			cluster_start = i
		}
		if cluster_start != -1 && strings.contains(lines[i], "}") {
			closing_brace = i
			break
		}
	}

	//check if the record name already exists if it does return
	recordExists := OST_CHECK_IF_RECORD_EXISTS(fn, cn, rn)
	if recordExists == true {
		fmt.printfln(
			"Record: %s%s%s already exists within Collection: %s%s%s -> Cluster: %s%s%s",
			utils.BOLD,
			rn,
			utils.RESET,
			utils.BOLD,
			fn,
			utils.RESET,
			utils.BOLD,
			cn,
			utils.RESET,
		)
		return 1
	}
	//if the cluster is not found or the structure is invalid, return
	if cluster_start == -1 || closing_brace == -1 {
		error2 := utils.new_err(
			.CANNOT_FIND_CLUSTER,
			utils.get_err_msg(.CANNOT_FIND_CLUSTER),
			#procedure,
		)
		utils.throw_err(error2)
		return -1
	}

	// Create the new line
	new_line := fmt.tprintf("\t%s :%s: %s", rn, rType, rd)

	// Insert the new line and adjust the closing brace
	new_lines := make([dynamic]string, len(lines) + 1)
	copy(new_lines[:closing_brace], lines[:closing_brace])
	new_lines[closing_brace] = new_line
	new_lines[closing_brace + 1] = "}"
	if closing_brace + 1 < len(lines) {
		copy(new_lines[closing_brace + 2:], lines[closing_brace + 1:])
	}

	new_content := strings.join(new_lines[:], "\n")
	writeSuccess := os.write_entire_file(fn, transmute([]byte)new_content)
	if writeSuccess != true {
		error3 := utils.new_err(
			.CANNOT_WRITE_TO_FILE,
			utils.get_err_msg(.CANNOT_WRITE_TO_FILE),
			#procedure,
		)
		utils.throw_err(error3)
		return -1
	}


	return 0
}

// // get the value from the right side of a key value
OST_READ_RECORD_VALUE :: proc(fn: string, cn: string, rType: string, rn: string) -> string {
	data, readSuccess := os.read_entire_file(fn)
	if !readSuccess {
		error1 := utils.new_err(
			.CANNOT_READ_FILE,
			utils.get_err_msg(.CANNOT_READ_FILE),
			#procedure,
		)
		utils.throw_err(error1)
		return ""
	}
	defer delete(data)

	content := string(data)
	lines := strings.split(content, "\n")
	defer delete(lines)

	cluster_start := -1
	closing_brace := -1

	// Find the cluster and its closing brace
	for line, i in lines {
		if strings.contains(line, cn) {
			cluster_start = i
		}
		if cluster_start != -1 && strings.contains(line, "}") {
			closing_brace = i
			break
		}
	}

	// If the cluster is not found or the structure is invalid, return an empty string
	if cluster_start == -1 || closing_brace == -1 {
		error2 := utils.new_err(
			.CANNOT_FIND_CLUSTER,
			utils.get_err_msg(.CANNOT_FIND_CLUSTER),
			#procedure,
		)
		utils.throw_err(error2)
		return ""
	}

	type := fmt.tprintf(":%s:", rType)
	// Check if the record exists within the cluster
	for i in cluster_start ..= closing_brace {
		if strings.contains(lines[i], rn) {
			record := strings.split(lines[i], type)
			if len(record) > 1 {
				return strings.trim_space(record[1])
			}
			return ""
		}
	}

	return ""
}

//here is where the type that the user enters in their command is passed
OST_SET_RECORD_TYPE :: proc(rType: string) -> (string, int) {
	for type in const.VALID_RECORD_TYPES {
		if rType == type {
			record.type = rType
			return record.type, 0
		}
	}

	fmt.printfln("Invalid record type %s", rType)
	return record.type, 1
}


OST_SET_RECORD_NAME :: proc(rn: string) -> (string, int) {
	if len(rn) > 256 {
		fmt.println("The Entered Record Name is too long. Please try again.")
		return "", 1
	}

	record.name = rn
	return record.name, 0
}


//Present user with prompt on where to save the record
OST_CHOOSE_RECORD_LOCATION :: proc(rName: string, rType: string) -> (col: string, clu: string) {
	buf := make([]byte, 1024)
	defer delete(buf)

	fmt.printfln(
		"Select the collection that you would like to store the record: %s%s%s in.",
		utils.BOLD,
		rName,
		utils.RESET,
	)

	n, colNameSuccess := os.read(os.stdin, buf)

	if colNameSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_READ_INPUT,
			utils.get_err_msg(.CANNOT_READ_INPUT),
			#procedure,
		)
		utils.throw_err(error1)
	}


	collection := strings.trim_right(string(buf[:n]), "\r\n")
	collection = strings.to_upper(collection)
	collectionExists := OST_CHECK_IF_COLLECTION_EXISTS(collection, 0)


	switch collectionExists 
	{
	case true:
		col = collection
		break

	}

	fmt.printfln(
		"Select the cluster that you would like to store the record: %s%s%s in.",
		utils.BOLD,
		rName,
		utils.RESET,
	)

	nn, cluNameSuccess := os.read(os.stdin, buf)

	if cluNameSuccess != 0 {
		error2 := utils.new_err(
			.CANNOT_READ_INPUT,
			utils.get_err_msg(.CANNOT_READ_INPUT),
			#procedure,
		)
		utils.throw_err(error2)
	}

	cluster := strings.trim_right(string(buf[:nn]), "\r\n")
	cluster = strings.to_upper(cluster)
	collectionPath := fmt.tprintf(
		"%s%s%s",
		const.OST_COLLECTION_PATH,
		collection,
		const.OST_FILE_EXTENSION,
	)
	clusterExists := OST_CHECK_IF_CLUSTER_EXISTS(collectionPath, cluster)


	switch clusterExists 
	{
	case true:
		clu = cluster
		break
	}

	return col, clu
}
