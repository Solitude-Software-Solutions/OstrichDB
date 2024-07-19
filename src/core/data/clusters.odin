package data
import "../../errors"
import "../../logging"
import "../../misc"
import "../const"
import "./metadata"
import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:strconv"
import "core:strings"
//=========================================================//
//Author: Marshall Burns aka @SchoolyB
//Desc: This file handles the creation and manipulation of
//			cluster files and their data within the db engine
//=========================================================//


cluster: Cluster
Cluster :: struct {
	_id:    int, //unique identifier for the record cannot be duplicated
	record: struct {}, //allows for multiple records to be stored in a cluster
}

main :: proc() {
	OST_CREATE_CACHE_FILE()
	os.make_directory(const.OST_COLLECTION_PATH)

}

//creates a file in the bin directory used to store the all used cluster ids
OST_CREATE_CACHE_FILE :: proc() {
	cacheFile, createSuccess := os.open("../bin/cluster_id_cache", os.O_CREATE, 0o666)
	if createSuccess != 0 {
		error1 := errors.new_err(
			.CANNOT_CREATE_FILE,
			errors.get_err_msg(.CANNOT_CREATE_FILE),
			#procedure,
		)
		errors.throw_err(error1)
		logging.log_utils_error("Error creating cluster id cache file", "OST_CREATE_CACHE_FILE")
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
		logging.log_utils_error("ID already exists in cache file", "OST_GENERATE_CLUSTER_ID")
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
		error1 := errors.new_err(
			.CANNOT_OPEN_FILE,
			errors.get_err_msg(.CANNOT_OPEN_FILE),
			#procedure,
		)
		errors.throw_err(error1)
		logging.log_utils_error("Error opening cluster id cache file", "OST_CHECK_CACHE_FOR_ID")
	}
	//step#1 convert the passed in i64 id number to a string
	idStr := strconv.append_int(buf[:], id, 10)


	//step#2 read the cache file and compare the id to the cache file
	readCacheFile, readSuccess := os.read_entire_file(openCacheFile)
	if readSuccess == false {
		error2 := errors.new_err(
			.CANNOT_READ_FILE,
			errors.get_err_msg(.CANNOT_READ_FILE),
			#procedure,
		)
		errors.throw_err(error2)
		logging.log_utils_error("Error reading cluster id cache file", "OST_CHECK_CACHE_FOR_ID")
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
		error1 := errors.new_err(
			.CANNOT_OPEN_FILE,
			errors.get_err_msg(.CANNOT_OPEN_FILE),
			#procedure,
		)
		errors.throw_err(error1)
		logging.log_utils_error("Error opening cluster id cache file", "OST_ADD_ID_TO_CACHE_FILE")
	}

	idStr := strconv.append_int(buf[:], id, 10) //the 10 is the base of the number
	//there are several bases, 10 is decimal, 2 is binary, 16 is hex, 16 is octal, 32 is base32, 64 is base64, computer science is fun

	//converting stirng to byte array then writing to file
	transStr := transmute([]u8)idStr
	writter, writeSuccess := os.write(cacheFile, transStr)
	if writeSuccess != 0 {
		error2 := errors.new_err(
			.CANNOT_WRITE_TO_FILE,
			errors.get_err_msg(.CANNOT_WRITE_TO_FILE),
			#procedure,
		)
		errors.throw_err(error2)
		logging.log_utils_error(
			"Error writing to cluster id cache file",
			"OST_ADD_ID_TO_CACHE_FILE",
		)
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
		// errors.throw_utilty_error(1, "Cluster already exists in file", "OST_CREATE_CLUSTER_BLOCK")
		logging.log_utils_error("Cluster already exists in file", "OST_CREATE_CLUSTER_BLOCK")
		return 1
	}
	FIRST_HALF: []string = {"{\n\tcluster_name : %n"}
	LAST_HALF: []string = {"\n\tcluster_id : %i\n\t\n},\n"} //defines the base structure of a cluster block in a .ost file
	buf: [32]byte
	//step#1: open the file
	clusterFile, openSuccess := os.open(fileName, os.O_APPEND | os.O_WRONLY, 0o666)
	if openSuccess != 0 {
		error1 := errors.new_err(
			.CANNOT_OPEN_FILE,
			errors.get_err_msg(.CANNOT_OPEN_FILE),
			#procedure,
		)
		errors.throw_err(error1)
		logging.log_utils_error("Error opening collection file", "OST_CREATE_CLUSTER_BLOCK")
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
				error2 := errors.new_err(
					.CANNOT_UPDATE_CLUSTER,
					errors.get_err_msg(.CANNOT_UPDATE_CLUSTER),
					#procedure,
				)
				errors.throw_err(error2)
				logging.log_utils_error(
					"Error placing id into cluster template",
					"OST_CREATE_CLUSTER_BLOCK",
				)
			}
			writeClusterID, writeSuccess := os.write(clusterFile, transmute([]u8)newClusterID)
			if writeSuccess != 0 {
				error2 := errors.new_err(
					.CANNOT_WRITE_TO_FILE,
					errors.get_err_msg(.CANNOT_WRITE_TO_FILE),
					#procedure,
				)

				logging.log_utils_error(
					"Error writing cluster block to file",
					"OST_CREATE_CLUSTER_BLOCK",
				)
			}
		}
	}
	fmt.printfln(
		"Creating cluster with name: %s and id: %i inside collection:%s",
		clusterName,
		clusterID,
		fileName,
	)
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
		error1 := errors.new_err(
			.CANNOT_OPEN_FILE,
			errors.get_err_msg(.CANNOT_OPEN_FILE),
			#procedure,
		)
		errors.throw_err(error1)
		logging.log_utils_error("Error opening cluster id cache file", "OST_NEWLINE_CHAR")
	}
	newLineChar: string = "\n"
	transStr := transmute([]u8)newLineChar
	writter, writeSuccess := os.write(cacheFile, transStr)
	if writeSuccess != 0 {
		error2 := errors.new_err(
			.CANNOT_WRITE_TO_FILE,
			errors.get_err_msg(.CANNOT_WRITE_TO_FILE),
			#procedure,
		)
		errors.throw_err(error2)
		logging.log_utils_error(
			"Error writing newline character to cluster id cache file",
			"OST_NEWLINE_CHAR",
		)
	}
	os.close(cacheFile)
}


// =====================================DATA INTERACTION=====================================//
//This section holds procs that deal with user/data interation within the Ostrich Engine


//handles logic whehn the user chooses to interact with a specific cluster in a .ost file
OST_CHOOSE_CLUSTER_NAME :: proc(fn: string) {
	buf: [256]byte
	n, inputSuccess := os.read(os.stdin, buf[:])
	if inputSuccess != 0 {
		error1 := errors.new_err(
			.CANNOT_READ_INPUT,
			errors.get_err_msg(.CANNOT_READ_INPUT),
			#procedure,
		)
		errors.throw_err(error1)
	}
	if n > 0 {
		fmt.printfln("Which cluster would you like to interact with?")
		input := string(buf[:n])
		//trim the string of any whitespace or newline characters

		//Shoutout to the OdinLang Discord for helping me with this...
		input = strings.trim_right_proc(input, proc(r: rune) -> bool {
			return r == '\r' || r == '\n'
		})

		cluserExists := OST_CHECK_IF_CLUSTER_EXISTS(fn, input)
		switch (cluserExists) 
		{
		case true:
			//todo what would the user like to do with this cluster?
			break
		case false:
			fmt.printfln(
				"Cluster with name:%s%s%s does not exist in database: %s",
				misc.BOLD,
				input,
				misc.RESET,
				fn,
			)
			fmt.printfln("Please try again")
			OST_CHOOSE_CLUSTER_NAME(fn)
			//todo add a commands the lists all available cluster in the current db file.
			break
		}
	}
}

//exclusivley used for checking if the name of a cluster exists...NOT the ID
//fn- filename, cn- clustername
OST_CHECK_IF_CLUSTER_EXISTS :: proc(fn: string, cn: string) -> bool {
	clusterFound: bool
	data, readSuccess := os.read_entire_file(fn)
	if !readSuccess {
		error1 := errors.new_err(
			.CANNOT_READ_FILE,
			errors.get_err_msg(.CANNOT_READ_FILE),
			#procedure,
		)
		errors.throw_err(error1)
		return false
	}
	defer delete(data)

	content := string(data)
	if strings.contains(content, cn) {
		clusterFound = true
	} else {
		clusterFound = false
	}
	return clusterFound
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
			misc.BOLD,
			new,
			misc.RESET,
			collection_name,
		)
		fmt.println("Please try again with a different name")
		return false
	}

	data, readSuccess := os.read_entire_file(collection_path)
	if !readSuccess {
		errors.throw_err(
			errors.new_err(.CANNOT_READ_FILE, errors.get_err_msg(.CANNOT_READ_FILE), #procedure),
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
		errors.throw_err(
			errors.new_err(
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
		errors.throw_err(
			errors.new_err(
				.CANNOT_WRITE_TO_FILE,
				errors.get_err_msg(.CANNOT_WRITE_TO_FILE),
				#procedure,
			),
		)
		return false
	}

	return true
}


//only used to create a cluster from the COMMAND LINE
OST_CREATE_CLUSTER_FROM_CL :: proc(collectionName: string, clusterName: string, id: i64) -> bool {

	collection_path := fmt.tprintf(
		"%s%s%s",
		const.OST_COLLECTION_PATH,
		collectionName,
		const.OST_FILE_EXTENSION,
	)
	FIRST_HALF: []string = {"\n{\n\tcluster_name : %n"}
	LAST_HALF: []string = {"\n\tcluster_id : %i\n\t\n},\n"} //defines the base structure of a cluster block in a .ost file
	buf: [32]byte
	//step#1: open the file
	clusterFile, openSuccess := os.open(collection_path, os.O_APPEND | os.O_WRONLY, 0o666)
	defer os.close(clusterFile)
	if openSuccess != 0 {
		error1 := errors.new_err(
			.CANNOT_OPEN_FILE,
			errors.get_err_msg(.CANNOT_OPEN_FILE),
			#procedure,
		)
		errors.throw_err(error1)
		logging.log_utils_error("Error opening collection file", "OST_CREATE_CLUSTER_BLOCK")
		return false
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
				error2 := errors.new_err(
					.CANNOT_UPDATE_CLUSTER,
					errors.get_err_msg(.CANNOT_UPDATE_CLUSTER),
					#procedure,
				)
				errors.throw_err(error2)
				logging.log_utils_error(
					"Error placing id into cluster template",
					"OST_CREATE_CLUSTER_BLOCK",
				)
				return false
			}
			writeClusterID, writeSuccess := os.write(clusterFile, transmute([]u8)newClusterID)
			if writeSuccess != 0 {
				error2 := errors.new_err(
					.CANNOT_WRITE_TO_FILE,
					errors.get_err_msg(.CANNOT_WRITE_TO_FILE),
					#procedure,
				)
				logging.log_utils_error(
					"Error writing cluster block to file",
					"OST_CREATE_CLUSTER_BLOCK",
				)
				return false
			}
		}
	}
	return true
}


OST_ERASE_CLUSTER :: proc(fn: string, cn: string) -> bool {
	collection_path := fmt.tprintf(
		"%s%s%s",
		const.OST_COLLECTION_PATH,
		fn,
		const.OST_FILE_EXTENSION,
	)
	data, readSuccess := os.read_entire_file(collection_path)
	if !readSuccess {
		errors.throw_err(
			errors.new_err(.CANNOT_READ_FILE, errors.get_err_msg(.CANNOT_READ_FILE), #procedure),
		)
		return false
	}
	defer delete(data)

	content := string(data)
	clusters := strings.split(content, "}")
	newContent := make([dynamic]u8)
	defer delete(newContent)
	clusterFound := false

	for i := 0; i < len(clusters); i += 1 {
		cluster := clusters[i]
		if strings.contains(cluster, fmt.tprintf("cluster_name : %s", cn)) {
			clusterFound = true
		} else if len(strings.trim_space(cluster)) > 0 {
			append(&newContent, ..transmute([]u8)cluster)
			// Add closing brace only if it's not the last cluster
			if i < len(clusters) - 1 {
				append(&newContent, "}")
			}
		}
	}

	if !clusterFound {
		errors.throw_err(
			errors.new_err(
				.CANNOT_FIND_CLUSTER,
				fmt.tprintf("Cluster '%s' not found in collection '%s'", cn, fn),
				#procedure,
			),
		)
		return false
	}

	writeSuccess := os.write_entire_file(collection_path, newContent[:])
	if !writeSuccess {
		errors.throw_err(
			errors.new_err(
				.CANNOT_WRITE_TO_FILE,
				errors.get_err_msg(.CANNOT_WRITE_TO_FILE),
				#procedure,
			),
		)
		return false
	}

	return true
}
