package data
import "../../../utils"
import "../../const"
import "../../types"
import "../data/metadata"
import "core:c/libc"
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


//generates a random ID, ensures its not currently in use by a user or a cluster
//the uponCreation param is used to evalute at whether or not the cluster or user that the ID will be assigned to has been created yet
//TODO: A possible solution to the issue of skipping the check is:
//when a cluster is being first created it doesnt need and id.
//the cluster then creates created without that ID then the ID is generated and appended
OST_GENERATE_ID :: proc(uponCreation: bool) -> i64 {
	idAlreadyExists := false
	//ensure the generated id length is 16 digits
	ID := rand.int63_max(1e16 + 1)


	if uponCreation == true {
		return ID
	} else {
		if OST_CHECK_IF_USER_ID_EXISTS(ID) == true && OST_CHECK_IF_CLUSTER_ID_EXISTS(ID) == true {
			utils.log_err("Generated ID already exists in cache file", #procedure)
			idAlreadyExists = true
		}

		if idAlreadyExists == true {
			OST_GENERATE_ID(false)
		}

		return ID
	}
}

// takes in an id and checks if it exists in the USER_IDS cluster
OST_CHECK_IF_USER_ID_EXISTS :: proc(id: i64) -> bool {
	idStr := fmt.tprintf("%d", id)
	idFound := OST_CHECK_IF_RECORD_EXISTS(const.OST_ID_PATH, const.USER_ID_CLUSTER, idStr)
	return idFound
}
//same as above but for the cluster_id cluster
OST_CHECK_IF_CLUSTER_ID_EXISTS :: proc(id: i64) -> bool {
	idStr := fmt.tprintf("%d", id)
	idFound := OST_CHECK_IF_RECORD_EXISTS(const.OST_ID_PATH, const.CLUSTER_ID_CLUSTER, idStr)
	return idFound
}


OST_CREATE_ID_COLLECTION_AND_CLUSTERS :: proc() {
	OST_CREATE_COLLECTION("ids", 4)
	cluOneid := OST_GENERATE_ID(true)

	// doing this prevents the creation of cluster_id records each time the program starts up. Only allows it once
	if OST_CHECK_IF_CLUSTER_EXISTS(const.OST_ID_PATH, const.CLUSTER_ID_CLUSTER) == true &&
	   OST_CHECK_IF_CLUSTER_EXISTS(const.OST_ID_PATH, const.USER_ID_CLUSTER) == true {
		return
	}
	//create a cluster for cluster ids
	OST_CREATE_CLUSTER_BLOCK("ids.ost", cluOneid, const.CLUSTER_ID_CLUSTER)
	OST_APPEND_ID_TO_COLLECTION(fmt.tprintf("%d", cluOneid), 0)

	//TODO: SEE THE COMMENT IN OST_GENERATE_ID!!!! - Marshall Burns Dec 2024
	cluTwoid := OST_GENERATE_ID(true)
	//create a cluster for user ids
	OST_CREATE_CLUSTER_BLOCK("ids.ost", cluTwoid, const.USER_ID_CLUSTER)
	OST_APPEND_ID_TO_COLLECTION(fmt.tprintf("%d", cluTwoid), 0)

	metadata.OST_UPDATE_METADATA_VALUE(const.OST_ID_PATH, 2)
	metadata.OST_UPDATE_METADATA_VALUE(const.OST_ID_PATH, 3)
}

//appends eiter a user id or a cluster id to their respective clusters in the id collection
//0 = cluster id, 1 = user id
OST_APPEND_ID_TO_COLLECTION :: proc(idStr: string, idType: int) {
	idBuf: [1024]byte
	switch (idType) 
	{
	case 0:
		types.id.clusterIdCount = OST_COUNT_RECORDS_IN_CLUSTER(
			"ids",
			const.CLUSTER_ID_CLUSTER,
			false,
		)

		idCountStr := strconv.itoa(idBuf[:], types.id.clusterIdCount)
		recordName := fmt.tprintf("%s%s", "clusterID_", idCountStr)

		appendSuccess := OST_APPEND_RECORD_TO_CLUSTER(
			const.OST_ID_PATH,
			const.CLUSTER_ID_CLUSTER,
			recordName,
			idStr,
			"CLUSTER_ID",
		)
		break
	case 1:
		types.id.userIdCount = OST_COUNT_RECORDS_IN_CLUSTER("ids", const.USER_ID_CLUSTER, false)

		idCountStr := strconv.itoa(idBuf[:], types.id.userIdCount)
		recordName := fmt.tprintf("%s%s", "userID_", idCountStr)

		appendSuccess := OST_APPEND_RECORD_TO_CLUSTER(
			const.OST_ID_PATH,
			const.USER_ID_CLUSTER,
			recordName,
			idStr,
			"USER_ID",
		)
		break
	}

}
