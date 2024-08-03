package data

import "../../../utils"
import "../../const"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

// example of a cluster with records in it

/*
{
	cluster_id: 12345 //this is technically a record
	player name: "Marshall" //this is a record
	player age: 25 //this is a record
	player height: "6'2" //this is a record
}
*/

//can be used to check if several records exist within a cluster
OST_CHECK_IF_RECORDS_EXIST :: proc(fn: string, cn: string, records: ..string) -> bool {
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

	// Check if all passed in records exist within the cluster
	all_records_exist := true
	for record in records {
		record_exists := false
		for i := cluster_start; i <= closing_brace; i += 1 {
			if strings.contains(lines[i], record) {
				record_exists = true
				break
			}
		}
		if !record_exists {
			all_records_exist = false
			break
		}
	}

	return all_records_exist
}

//can be used to check if a single record exists within a cluster
OST_CHECK_IF_RECORD_EXISTS :: proc(fn: string, cn: string, record: string) -> bool {
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
		if strings.contains(lines[i], record) {
			return true
		}
	}

	return false
}

//so Im trying to get the type of the data that is passed in. but I cannot use type_of on anything that is of type "any"

// todo
//need to create a proc that takes in the users input on which cluster they want to store the record in
//create a proc that checks if the cluster that the user wants to store the record in actually exists
// need to create a proc that passes all info of a record to a different proc that will then store the record into a cluster


//.appends the passed in record to the passed in cluster
//fn-filename, cn-clustername,id-cluster id, rn-record name, rd-record data
OST_APPEND_RECORD_TO_CLUSTER :: proc(fn: string, cn: string, id: i64, rn: string, rd: string) {
	data, readSuccess := os.read_entire_file(fn)
	if !readSuccess {
		error1 := utils.new_err(
			.CANNOT_READ_FILE,
			utils.get_err_msg(.CANNOT_READ_FILE),
			#procedure,
		)
		utils.throw_err(error1)
		return
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
	record_exists := OST_CHECK_IF_RECORD_EXISTS(fn, cn, rn)
	if record_exists == true {
		return
	}
	//if the cluster is not found or the structure is invalid, return
	if cluster_start == -1 || closing_brace == -1 {
		error2 := utils.new_err(
			.CANNOT_FIND_CLUSTER,
			utils.get_err_msg(.CANNOT_FIND_CLUSTER),
			#procedure,
		)
		utils.throw_err(error2)
		return
	}

	// Create the new line
	new_line := fmt.tprintf("\t%s : %s", rn, rd)

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
	}
}

// get the value from the right side of a key value
OST_READ_RECORD_VALUE :: proc(fn: string, cn: string, rn: string) -> string {
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

	// Check if the record exists within the cluster
	for i in cluster_start ..= closing_brace {
		if strings.contains(lines[i], rn) {
			record := strings.split(lines[i], ":")
			if len(record) > 1 {
				return strings.trim_space(record[1])
			}
			return ""
		}
	}

	return ""
}


//used to get the type from the command line EX: NEW RECORD isAlive WITHIN CLUSTER presidents OF_TYPE bool. this would return "bool"
OST_GET_RECORD_TYPE :: proc(rType: string) -> string {
	switch (rType) 
	{
	case const.STRING:
		return "string"
	case const.INT:
		return "int"
	case const.FLOAT:
		return "float"
	case const.BOOL:
		return "bool"
	}
	return ""
}


//used to set the type of a record within the .ost file
//rType is the type of record that is being set
//rd is the data that is being set
OST_SET_RECORD_TYPE :: proc(rType: string, rd: string) -> (string, any) {
	type := rType
	qouteChar := "'"
	alpha := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	numbers := "0123456789"
	specialChars := "!@#$%^&*()_+{}|:<>?~" //todo find a way to add double quotes to this
	periodChar := "."
	b_true := "true"
	b_false := "false"

	switch (rType) 
	{
	case "string":
		recordAsStr := fmt.tprintf("%s%s%s", qouteChar, rd, qouteChar)
		type = "string"
		return rType, recordAsStr

	case "int":
		// ints can only be whole numbers or a negative number.Prob dont need last two checks lol
		if strings.contains(rd, qouteChar) ||
		   strings.contains(rd, specialChars) ||
		   strings.contains(rd, periodChar) ||
		   strings.contains(rd, alpha) ||
		   strings.contains(rd, b_true) ||
		   strings.contains(rd, b_false) {
			error1 := utils.new_err(
				.INVALID_RECORD_DATA,
				utils.get_err_msg(.INVALID_RECORD_DATA),
				#procedure,
			)
			utils.throw_err(error1)
			return "", error1
		} else {
			type = "int"
			return rType, rd
		}
		break
	case "float":
		// floats can only be numbers or a negative number and must contain a period char. prob dont need last two checks lol
		if strings.contains(rd, qouteChar) ||
		   strings.contains(rd, specialChars) ||
		   strings.contains(rd, alpha) ||
		   !strings.contains(rd, periodChar) ||
		   strings.contains(rd, b_true) ||
		   strings.contains(rd, b_false) {
			error2 := utils.new_err(
				.INVALID_RECORD_DATA,
				utils.get_err_msg(.INVALID_RECORD_DATA),
				#procedure,
			)
			utils.throw_err(error2)
			return "", error2
		} else {
			type = "float"
			return rType, rd
		}
		break
	case "bool":
		// bools can only be true or false
		if !strings.contains(rd, b_true) || !strings.contains(rd, b_false) {
			error3 := utils.new_err(
				.INVALID_RECORD_DATA,
				utils.get_err_msg(.INVALID_RECORD_DATA),
				#procedure,
			)
			utils.throw_err(error3)
			return "", error3
		} else {
			type = "bool"
			return rType, rd
		}
	}
	return "", rd
}
