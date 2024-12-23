package data
import "../../../utils"
import "../../const"
import "../../types"
import "../data/metadata"
import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:strconv"
import "core:strings"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//

userIdNum := 0
clusterIdNum := 0

//generates a random ID, ensures its not currently in use by a user or a cluster
OST_GENERATE_ID :: proc() -> i64 {
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

OST_BUMP_USER_ID_RECORD_NUMBER :: proc() -> string {
	userIdNum += 1
	return fmt.tprintln("%s%d", "user_id", userIdNum)
}

// todo: thinking about naming the records for the cluster_id cluster in a similar fashion to the history records
// something like: cluster_id_{number}:CLUSTER_ID:{id}
// takes in an id and checks if it exists in the cluster_id cluster
OST_CHECK_IF_USER_ID_EXISTS :: proc(id: i64) -> bool {

	OST_READ_RECORD_VALUE(const.OST_ID_PATH, const.USER_ID_CLUSTER, id)
	// idStr, success := strconv.parse_i64(id)
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


OST_CREATE_ID_COLLECTION :: proc() {
	OST_CREATE_COLLECTION("ids", 4)
	id := OST_GENERATE_ID()

	//create a cluster for cluster ids
	OST_CREATE_CLUSTER_BLOCK("ids.ost", id, const.CLUSTER_ID_CLUSTER)

	//create a cluster for user ids
	OST_CREATE_CLUSTER_BLOCK("ids.ost", id, const.USER_ID_CLUSTER)

	metadata.OST_UPDATE_METADATA_VALUE(const.OST_ID_PATH, 2)
	metadata.OST_UPDATE_METADATA_VALUE(const.OST_ID_PATH, 3)
}
