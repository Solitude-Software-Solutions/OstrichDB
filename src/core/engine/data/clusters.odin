package data
import "../../../utils"
import "../../const"
import "../../types"
import "./metadata"
import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:strconv"
import "core:strings"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//


main :: proc() {
	OST_CREATE_CACHE_FILE()
	OST_CREAT_BACKUP_DIR()
	os.make_directory(const.OST_COLLECTION_PATH)
	metadata.OST_CREATE_FFVF()
	test := metadata.OST_GET_FILE_FORMAT_VERSION()
}

//creates a cache used to store all generated cluster ids
OST_CREATE_CACHE_FILE :: proc() {
	cacheFile, createSuccess := os.open("../bin/cluster_id_cache", os.O_CREATE, 0o666)
	if createSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_CREATE_FILE,
			utils.get_err_msg(.CANNOT_CREATE_FILE),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Error creating cluster id cache file", "OST_CREATE_CACHE_FILE")
	}
	os.close(cacheFile)
}


/*
Generates the unique cluster id for a new cluster
then returns it to the caller, relies on OST_ADD_ID_TO_CACHE_FILE() to store the retuned id in a file
*/
OST_GENERATE_CLUSTER_ID :: proc() -> i64 {
	//ensure the generated id length is 16 digits
	ID := rand.int63_max(1e16 + 1)
	idExistsAlready := OST_CHECK_CACHE_FOR_ID(ID)

	if idExistsAlready == true {
		//dont need to throw error for ID existing already
		utils.log_err("ID already exists in cache file", "OST_GENERATE_CLUSTER_ID")
		OST_GENERATE_CLUSTER_ID()
	}
	OST_ADD_ID_TO_CACHE_FILE(ID)
	return ID
}


/*
checks the cluster id cache file to see if the id already exists
*/
OST_CHECK_CACHE_FOR_ID :: proc(id: i64) -> bool {
	buf: [32]byte
	result: bool
	openCacheFile, openSuccess := os.open("../bin/cluster_id_cache", os.O_RDONLY, 0o666)
	if openSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_OPEN_FILE,
			utils.get_err_msg(.CANNOT_OPEN_FILE),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Error opening cluster id cache file", "OST_CHECK_CACHE_FOR_ID")
	}
	//step#1 convert the passed in i64 id number to a string
	idStr := strconv.append_int(buf[:], id, 10)


	//step#2 read the cache file and compare the id to the cache file
	readCacheFile, readSuccess := os.read_entire_file(openCacheFile)
	if readSuccess == false {
		error2 := utils.new_err(
			.CANNOT_READ_FILE,
			utils.get_err_msg(.CANNOT_READ_FILE),
			#procedure,
		)
		utils.throw_err(error2)
		utils.log_err("Error reading cluster id cache file", "OST_CHECK_CACHE_FOR_ID")
	}

	// step#3 convert all file contents to a string because...OdinLang go brrrr??
	contentToStr := transmute(string)readCacheFile

	//step#4 check if the string version of the id is contained in the cache file
	if strings.contains(contentToStr, idStr) {
		fmt.printfln("ID already exists in cache file")
		result = true
	} else {
		result = false
	}
	os.close(openCacheFile)
	return result
}


/*upon cluster generation this proc will take the cluster id and store it in a file so that it can not be duplicated in the future
*/
OST_ADD_ID_TO_CACHE_FILE :: proc(id: i64) -> int {
	buf: [32]byte
	cacheFile, openSuccess := os.open("../bin/cluster_id_cache", os.O_APPEND | os.O_WRONLY, 0o666)
	if openSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_OPEN_FILE,
			utils.get_err_msg(.CANNOT_OPEN_FILE),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Error opening cluster id cache file", "OST_ADD_ID_TO_CACHE_FILE")
	}

	idStr := strconv.append_int(buf[:], id, 10) //base 10 conversion

	//converting stirng to byte array then writing to file
	transStr := transmute([]u8)idStr
	writter, writeSuccess := os.write(cacheFile, transStr)
	if writeSuccess != 0 {
		error2 := utils.new_err(
			.CANNOT_WRITE_TO_FILE,
			utils.get_err_msg(.CANNOT_WRITE_TO_FILE),
			#procedure,
		)
		utils.throw_err(error2)
		utils.log_err("Error writing to cluster id cache file", "OST_ADD_ID_TO_CACHE_FILE")
	}
	OST_NEWLINE_CHAR()
	os.close(cacheFile)
	return 0
}


/*
Creates and appends a new cluster to the specified .ost file
*/
OST_CREATE_CLUSTER_BLOCK :: proc(fileName: string, clusterID: i64, clusterName: string) -> int {
	clusterExists := OST_CHECK_IF_CLUSTER_EXISTS(fileName, clusterName)
	if clusterExists == true {
		// utils.throw_utilty_error(1, "Cluster already exists in file", "OST_CREATE_CLUSTER_BLOCK")
		utils.log_err("Cluster already exists in file", "OST_CREATE_CLUSTER_BLOCK")
		return 1
	}
	FIRST_HALF: []string = {"{\n\tcluster_name :identifier: %n"}
	LAST_HALF: []string = {"\n\tcluster_id :identifier: %i\n\t\n},\n"} //defines the base structure of a cluster block in a .ost file
	buf: [32]byte
	//step#1: open the file
	clusterFile, openSuccess := os.open(fileName, os.O_APPEND | os.O_WRONLY, 0o666)
	if openSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_OPEN_FILE,
			utils.get_err_msg(.CANNOT_OPEN_FILE),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Error opening collection file", "OST_CREATE_CLUSTER_BLOCK")
	}


	for i := 0; i < len(FIRST_HALF); i += 1 {
		if (strings.contains(FIRST_HALF[i], "%n")) {
			//step#5: replace the %n with the cluster name
			newClusterName, alright := strings.replace(FIRST_HALF[i], "%n", clusterName, -1)
			writeClusterName, ight := os.write(clusterFile, transmute([]u8)newClusterName)
		}
	}
	//step#2: iterate over the FIRST_HALF array and replace the %s with the passed in clusterID
	for i := 0; i < len(LAST_HALF); i += 1 {
		//step#3: check if the string contains the %s placeholder if it does replace it with the clusterID
		if strings.contains(LAST_HALF[i], "%i") {
			//step#4: replace the %s with the clusterID that is now being converted to a string
			newClusterID, replaceSuccess := strings.replace(
				LAST_HALF[i],
				"%i",
				strconv.append_int(buf[:], clusterID, 10),
				-1,
			)
			if replaceSuccess == false {
				error2 := utils.new_err(
					.CANNOT_UPDATE_CLUSTER,
					utils.get_err_msg(.CANNOT_UPDATE_CLUSTER),
					#procedure,
				)
				utils.throw_err(error2)
				utils.log_err("Error placing id into cluster template", "OST_CREATE_CLUSTER_BLOCK")
			}
			writeClusterID, writeSuccess := os.write(clusterFile, transmute([]u8)newClusterID)
			if writeSuccess != 0 {
				error2 := utils.new_err(
					.CANNOT_WRITE_TO_FILE,
					utils.get_err_msg(.CANNOT_WRITE_TO_FILE),
					#procedure,
				)

				utils.log_err("Error writing cluster block to file", "OST_CREATE_CLUSTER_BLOCK")
			}
		}
	}
	fmt.printfln(
		"Succesfully created account: %s%s%s",
		utils.BOLD,
		types.user.username.Value,
		utils.RESET,
	)
	fmt.println("Please re-launch OstrichDB...")
	//step#FINAL: close the file
	os.close(clusterFile)
	return 0
}


/*
Used to add a newline character to the end of each id entry in the cluster cache file.
See usage in OST_ADD_ID_TO_CACHE_FILE()
*/
OST_NEWLINE_CHAR :: proc() {
	cacheFile, openSuccess := os.open("../bin/cluster_id_cache", os.O_APPEND | os.O_WRONLY, 0o666)
	if openSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_OPEN_FILE,
			utils.get_err_msg(.CANNOT_OPEN_FILE),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Error opening cluster id cache file", "OST_NEWLINE_CHAR")
	}
	newLineChar: string = "\n"
	transStr := transmute([]u8)newLineChar
	writter, writeSuccess := os.write(cacheFile, transStr)
	if writeSuccess != 0 {
		error2 := utils.new_err(
			.CANNOT_WRITE_TO_FILE,
			utils.get_err_msg(.CANNOT_WRITE_TO_FILE),
			#procedure,
		)
		utils.throw_err(error2)
		utils.log_err(
			"Error writing newline character to cluster id cache file",
			"OST_NEWLINE_CHAR",
		)
	}
	os.close(cacheFile)
}


// =====================================DATA INTERACTION=====================================//

//exclusivley used for checking if the name of a cluster exists...NOT the ID
//fn- filename, cn- clustername
OST_CHECK_IF_CLUSTER_EXISTS :: proc(fn: string, cn: string) -> bool {
	data, read_success := os.read_entire_file(fn)
	if !read_success {
		error1 := utils.new_err(
			.CANNOT_READ_FILE,
			utils.get_err_msg(.CANNOT_READ_FILE),
			#procedure,
		)
		utils.throw_err(error1)
		fmt.println("Error reading cluster file")
		return false
	}
	defer delete(data)

	content := string(data)

	cluster_strings := strings.split(content, "},")
	defer delete(cluster_strings)

	for cluster_str in cluster_strings {
		cluster_str := strings.trim_space(cluster_str)
		if cluster_str == "" do continue
		// Finds the start index of "cluster_name :" in the string
		name_start := strings.index(cluster_str, "cluster_name :identifier:")
		// If "cluster_name :" is not found, skip this cluster
		if name_start == -1 do continue
		// Move the start index to after "cluster_name :"
		name_start += len("cluster_name :identifier:")
		// Find the end of the cluster name
		name_end := strings.index(cluster_str[name_start:], "\n")
		// If newline is not found, skip this cluster
		if name_end == -1 do continue
		// Extract the cluster name and remove leading/trailing whitespace
		cluster_name := strings.trim_space(cluster_str[name_start:][:name_end])
		// Compare the extracted cluster name with the provided cluster name
		if strings.compare(cluster_name, cn) == 0 {
			return true
		}
	}
	return false
}

OST_RENAME_CLUSTER :: proc(collection_name: string, old: string, new: string) -> bool {
	collection_path := fmt.tprintf(
		"%s%s%s",
		const.OST_COLLECTION_PATH,
		collection_name,
		const.OST_FILE_EXTENSION,
	)

	// check if the desired new cluster name already exists
	if OST_CHECK_IF_CLUSTER_EXISTS(collection_path, new) {
		fmt.printfln(
			"Cluster with name:%s%s%s already exists in collection: %s",
			utils.BOLD,
			new,
			utils.RESET,
			collection_name,
		)
		fmt.println("Please try again with a different name")
		return false
	}

	data, readSuccess := os.read_entire_file(collection_path)
	if !readSuccess {
		utils.throw_err(
			utils.new_err(.CANNOT_READ_FILE, utils.get_err_msg(.CANNOT_READ_FILE), #procedure),
		)
		return false
	}
	defer delete(data)

	content := string(data)
	clusters := strings.split(content, "}")
	newContent := make([dynamic]u8)
	defer delete(newContent)

	clusterFound := false
	for cluster in clusters {
		if strings.contains(cluster, fmt.tprintf("cluster_name : %s", old)) {
			// if a cluster with the old name is found, replace the name with the new name
			clusterFound = true
			newCluster, e := strings.replace(
				cluster,
				fmt.tprintf("cluster_name : %s", old),
				fmt.tprintf("cluster_name : %s", new),
				1,
			)
			//append the new data to the new content variable
			append(&newContent, ..transmute([]u8)newCluster)
			// append the closing brace
			append(&newContent, '}')
		} else if len(strings.trim_space(cluster)) > 0 {
			// For other clusters, just add them back unchanged and add the closing brace
			append(&newContent, ..transmute([]u8)cluster)
			append(&newContent, '}')
		}
	}

	if !clusterFound {
		utils.throw_err(
			utils.new_err(
				.CANNOT_FIND_CLUSTER,
				fmt.tprintf("Cluster '%s' not found in collection '%s'", old, collection_name),
				#procedure,
			),
		)
		return false
	}

	// write new content to file
	writeSuccess := os.write_entire_file(collection_path, newContent[:])
	if !writeSuccess {
		utils.throw_err(
			utils.new_err(
				.CANNOT_WRITE_TO_FILE,
				utils.get_err_msg(.CANNOT_WRITE_TO_FILE),
				#procedure,
			),
		)
		return false
	}

	return true
}


//only used to create a cluster from the COMMAND LINE
OST_CREATE_CLUSTER_FROM_CL :: proc(collectionName: string, clusterName: string, id: i64) -> int {

	collection_path := fmt.tprintf(
		"%s%s%s",
		const.OST_COLLECTION_PATH,
		collectionName,
		const.OST_FILE_EXTENSION,
	)

	clusterExist := OST_CHECK_IF_CLUSTER_EXISTS(collection_path, clusterName)
	if clusterExist {
		return -1
	}

	FIRST_HALF: []string = {"\n{\n\tcluster_name :identifier: %n"}
	LAST_HALF: []string = {"\n\tcluster_id :identifier: %i\n\t\n},\n"} //defines the base structure of a cluster block in a .ost file
	buf: [32]byte
	//step#1: open the file
	clusterFile, openSuccess := os.open(collection_path, os.O_APPEND | os.O_WRONLY, 0o666)
	defer os.close(clusterFile)
	if openSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_OPEN_FILE,
			utils.get_err_msg(.CANNOT_OPEN_FILE),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Error opening collection file", "OST_CREATE_CLUSTER_BLOCK")
		return 1
	}


	for i := 0; i < len(FIRST_HALF); i += 1 {
		if (strings.contains(FIRST_HALF[i], "%n")) {
			//step#5: replace the %n with the cluster name
			newClusterName, alright := strings.replace(FIRST_HALF[i], "%n", clusterName, -1)
			writeClusterName, ight := os.write(clusterFile, transmute([]u8)newClusterName)
		}
	}
	//step#2: iterate over the FIRST_HALF array and replace the %s with the passed in clusterID
	for i := 0; i < len(LAST_HALF); i += 1 {
		//step#3: check if the string contains the %s placeholder if it does replace it with the clusterID
		if strings.contains(LAST_HALF[i], "%i") {
			//step#4: replace the %s with the clusterID that is now being converted to a string
			newClusterID, replaceSuccess := strings.replace(
				LAST_HALF[i],
				"%i",
				strconv.append_int(buf[:], id, 10),
				-1,
			)
			if replaceSuccess == false {
				error2 := utils.new_err(
					.CANNOT_UPDATE_CLUSTER,
					utils.get_err_msg(.CANNOT_UPDATE_CLUSTER),
					#procedure,
				)
				utils.throw_err(error2)
				utils.log_err("Error placing id into cluster template", "OST_CREATE_CLUSTER_BLOCK")
				return 2
			}
			writeClusterID, writeSuccess := os.write(clusterFile, transmute([]u8)newClusterID)
			if writeSuccess != 0 {
				error2 := utils.new_err(
					.CANNOT_WRITE_TO_FILE,
					utils.get_err_msg(.CANNOT_WRITE_TO_FILE),
					#procedure,
				)
				utils.log_err("Error writing cluster block to file", "OST_CREATE_CLUSTER_BLOCK")
				return 3
			}
		}
	}
	return 0
}


OST_ERASE_CLUSTER :: proc(fn: string, cn: string) -> bool {
	buf: [64]byte
	fmt.printfln(
		"Are you sure that you want to delete Cluster: %s%s%s from Collection: %s%s%s?\nThis action can not be undone.",
		utils.BOLD,
		cn,
		utils.RESET,
		utils.BOLD,
		fn,
		utils.RESET,
	)
	fmt.printfln("Type 'yes' to confirm or 'no' to cancel.")
	n, inputSuccess := os.read(os.stdin, buf[:])
	if inputSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_READ_INPUT,
			utils.get_err_msg(.CANNOT_READ_INPUT),
			#procedure,
		)
		utils.throw_err(error1)
	}

	confirmation := strings.trim_right(string(buf[:n]), "\r\n")
	cap := strings.to_upper(confirmation)
	switch cap 
	{
	case const.YES:
		collection_path := fmt.tprintf(
			"%s%s%s",
			const.OST_COLLECTION_PATH,
			fn,
			const.OST_FILE_EXTENSION,
		)

		data, readSuccess := os.read_entire_file(collection_path)
		if !readSuccess {
			utils.throw_err(
				utils.new_err(.CANNOT_READ_FILE, utils.get_err_msg(.CANNOT_READ_FILE), #procedure),
			)
			return false
		}
		defer delete(data)

		content := string(data)
		clusterClosingBrace := strings.split(content, "}")
		newContent := make([dynamic]u8)
		defer delete(newContent)
		clusterFound := false


		for i := 0; i < len(clusterClosingBrace); i += 1 {
			cluster := clusterClosingBrace[i] // everything in the file up to the first instance of "},"
			if strings.contains(cluster, fmt.tprintf("cluster_name : %s", cn)) {
				clusterFound = true
			} else if len(strings.trim_space(cluster)) > 0 {
				append(&newContent, ..transmute([]u8)cluster) // Add closing brace
				if i < len(clusterClosingBrace) - 1 {
					append(&newContent, "}")
				}
			}
		}

		if !clusterFound {
			utils.throw_err(
				utils.new_err(
					.CANNOT_FIND_CLUSTER,
					fmt.tprintf("Cluster '%s' not found in collection '%s'", cn, fn),
					#procedure,
				),
			)
			return false
		}
		writeSuccess := os.write_entire_file(collection_path, newContent[:])
		if !writeSuccess {
			utils.throw_err(
				utils.new_err(
					.CANNOT_WRITE_TO_FILE,
					utils.get_err_msg(.CANNOT_WRITE_TO_FILE),
					#procedure,
				),
			)
			return false
		}
		utils.log_runtime_event(
			"Database Cluster",
			"User confirmed deletion of cluster and it was successfully deleted.",
		)
		break

	case const.NO:
		utils.log_runtime_event("User canceled deletion", "User canceled deletion of database")
		return false
	case:
		utils.log_runtime_event(
			"User entered invalid input",
			"User entered invalid input when trying to delete cluster",
		)
		error2 := utils.new_err(.INVALID_INPUT, utils.get_err_msg(.INVALID_INPUT), #procedure)
		utils.throw_custom_err(error2, "Invalid input. Please type 'yes' or 'no'.")
		return false
	}
	return true
}


OST_FETCH_CLUSTER :: proc(fn: string, cn: string) -> string {
	cluster_content: string
	collection_path := fmt.tprintf(
		"%s%s%s",
		const.OST_COLLECTION_PATH,
		fn,
		const.OST_FILE_EXTENSION,
	)

	clusterExists := OST_CHECK_IF_CLUSTER_EXISTS(collection_path, cn)
	switch clusterExists 
	{
	case false:
		fmt.printfln("Cluster '%s' does not exist in collection '%s'", cn, fn)
		break
	}
	data, readSuccess := os.read_entire_file(collection_path)
	if !readSuccess {
		utils.throw_err(
			utils.new_err(.CANNOT_READ_FILE, utils.get_err_msg(.CANNOT_READ_FILE), #procedure),
		)
		return ""
	}
	defer delete(data)

	content := string(data)
	clusters := strings.split(content, "}")

	for cluster in clusters {
		if strings.contains(cluster, fmt.tprintf("cluster_name :identifier: %s", cn)) {
			// Find the start of the cluster (opening brace)
			start_index := strings.index(cluster, "{")
			if start_index != -1 {
				// Extract the content between braces
				cluster_content = cluster[start_index + 1:]
				// Trim any leading or trailing whitespace
				cluster_content = strings.trim_space(cluster_content)
				return cluster_content
			}
		}
	}

	utils.throw_err(
		utils.new_err(
			.CANNOT_FIND_CLUSTER,
			fmt.tprintf("Cluster '%s' not found in collection '%s'", cn, fn),
			#procedure,
		),
	)
	return ""
}


OST_LIST_CLUSTERS_IN_FILE :: proc(fn: string) -> int {
	buf := make([]byte, 64)
	defer delete(buf)
	filePath := fmt.tprintf("%s%s%s", const.OST_COLLECTION_PATH, fn, const.OST_FILE_EXTENSION)

	data, readSuccess := os.read_entire_file(filePath)
	if !readSuccess {
		utils.throw_err(
			utils.new_err(.CANNOT_READ_FILE, utils.get_err_msg(.CANNOT_READ_FILE), #procedure),
		)
		return 0
	}

	content := string(data)
	defer delete(content)
	clusters := strings.split(content, "}")
	for cluster in clusters {
		cluster := strings.trim_space(cluster)
		if cluster == "" do continue
		// Finds the start index of "cluster_name :" in the string
		name_start := strings.index(cluster, "cluster_name :identifier:")
		// If "cluster_name :" is not found, skip this cluster
		if name_start == -1 do continue
		// Move the start index to after "cluster_name :"
		name_start += len("cluster_name :identifier:")
		// Find the end of the cluster name
		name_end := strings.index(cluster[name_start:], "\n")
		// If newline is not found, skip this cluster
		if name_end == -1 do continue
		// Extract the cluster name and remove leading/trailing whitespace
		cluster_name := strings.trim_space(cluster[name_start:][:name_end])
		// Compare the extracted cluster name with the provided cluster name

		clusterName := fmt.tprintf("|\n|_________%s\n", cluster_name)


		fmt.println(clusterName)
	}
	return 0
}
