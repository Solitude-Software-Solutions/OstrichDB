package data
import "core:os"
import "core:strconv"
import "core:strings"
import "core:math/rand"
import "../../types"
import "../../../utils"
import "../../const"
import "../data/metadata"

//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//


// todo: thinking about naming the records for the cluster_id cluster in a similar fashion to the history records
// something like: cluster_id_{number}:CLUSTER_ID:{id}

OST_CHECK_IF_USER_ID_EXISTS :: proc(id: i64) -> bool {
	buf: [32]byte
	result: bool
	openCacheFile, openSuccess := os.open("./cluster_id_cache", os.O_RDONLY, 0o666)

	if openSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_OPEN_FILE,
			utils.get_err_msg(.CANNOT_OPEN_FILE),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Error opening cluster id cache file", #procedure)
	}
	//step#1 convert the passed in i64 id number to a string
	idStr := strconv.append_int(buf[:], id, 10)


	//step#2 read the cache file and compare the id to the cache file
	readCacheFile, readSuccess := os.read_entire_file(openCacheFile)
	if readSuccess == false {
		errors2 := utils.new_err(
			.CANNOT_READ_FILE,
			utils.get_err_msg(.CANNOT_READ_FILE),
			#procedure,
		)
		utils.throw_err(errors2)
		utils.log_err("Error reading cluster id cache file", #procedure)
	}

	// step#3 convert all file contents to a string because...OdinLang go brrrr??
	contentToStr := transmute(string)readCacheFile

	//step#4 check if the string version of the id is contained in the cache file
	if strings.contains(contentToStr, idStr) {
		result = true
	} else {
		result = false
	}
	os.close(openCacheFile)
	return result
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
		utils.log_err("Generated ID already exists in cache file", #procedure)
		OST_GENERATE_CLUSTER_ID()
	}
	OST_ADD_ID_TO_CACHE_FILE(ID)
	return ID
}



OST_CREATE_ID_COLLECTION::proc() -> int{
    OST_CREATE_COLLECTION("ids", 4)
    id := OST_GENERATE_ID()

    //create a cluster for cluster ids
    OST_CREATE_CLUSTER_BLOCK("ids.ost", id, const.CLUSTER_ID_CLUSTER)

    //create a cluster for user ids
    OST_CREATE_CLUSTER_BLOCK("ids.ost", id, const.USER_ID_CLUSTER)





}

//todo: delete
//creates a cache used to store all generated cluster ids
OST_CREATE_CACHE_FILE :: proc() {
	cacheFile, createSuccess := os.open("./cluster_id_cache", os.O_CREATE, 0o666)
	if createSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_CREATE_FILE,
			utils.get_err_msg(.CANNOT_CREATE_FILE),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Error creating cluster id cache file", #procedure)
	}
	os.close(cacheFile)
}





//generates a random ID, ensures its not currently in use by a user or a cluster
OST_GENERATE_ID ::proc() -> i64 {
    //ensure the generated id length is 16 digits
    ID := rand.int63_max(1e16 + 1)
    idExistsAlready := OST_CHECK_CACHE_FOR_ID(ID)

    if idExistsAlready == true {
        //dont need to throw error for ID existing already
        utils.log_err("Generated ID already exists in cache file", #procedure)
        OST_GENERATE_ID()
    }
    OST_ADD_ID_TO_CACHE_FILE(ID)
    return ID
}