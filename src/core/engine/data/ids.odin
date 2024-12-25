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

//removes the passed in id from either cluster in the ids.ost file.
//if isUserId is true then the id is removed from the USER_ID_CLUSTER
//if isUserId is false then the id is removed from the CLUSTER_ID_CLUSTER
//in the event that an admin user is deleting another user the id needs to be
//removed from both clusters so the call is made twice with isUserId set to true and false
OST_REMOVE_ID_FROM_CLUSTER :: proc(id: string, isUserId: bool) -> bool {
	file, cn, rv: string

	if isUserId {
		file = const.OST_ID_PATH
		cn = const.USER_ID_CLUSTER
		rv = id
	} else {
		file = const.OST_ID_PATH
		cn = const.CLUSTER_ID_CLUSTER
		rv = id
	}

	data, readSuccess := utils.read_file(file, #procedure)
	defer delete(data)
	if !readSuccess {
		fmt.println("Failed to read file")
		return false
	}

	content := string(data)
	lines := strings.split(content, "\n")
	newLines := make([dynamic]string)
	defer delete(newLines)

	inTargetCluster := false
	recordFound := false
	isLastRecord := false
	recordCount := 0

	// First pass - count records in target cluster
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

	// Second pass - rebuild content
	inTargetCluster = false
	for line in lines {
		trimmedLine := strings.trim_space(line)

		if strings.contains(trimmedLine, fmt.tprintf("cluster_name :identifier: %s", cn)) {
			inTargetCluster = true
			append(&newLines, line)
			continue
		}

		if inTargetCluster { 	//reason its not working is because we are SUPPOSED to be looking for the record value
			if strings.has_suffix(trimmedLine, fmt.tprintf(": %s", rv)) {
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

		if !inTargetCluster || !strings.has_prefix(trimmedLine, fmt.tprintf(": %s", rv)) {
			append(&newLines, line)
		}
	}

	if !recordFound {
		fmt.println("Record not found")
		return false
	}

	// Write updated content
	newContent := strings.join(newLines[:], "\n")
	writeSuccess := utils.write_to_file(file, transmute([]byte)newContent, #procedure)
	return writeSuccess
}

//I'm not gonna lie...IDK why I was writting this. Commenting for now but might be useful later - Marshall Burns Dec 2024
// OST_SCAN_FOR_ID_RECORD_VALUE :: proc(cn, rt, rv: string) -> (string, bool) {
// 	value: string
// 	success: bool
// 	idCollection := const.OST_ID_PATH

// 	data, readSuccess := utils.read_file(idCollection, #procedure)
// 	if !readSuccess {
// 		return "", false
// 	}

// 	defer delete(data)

// 	content := string(data)
// 	clusters := strings.split(content, "},")

// 	for cluster in clusters {
// 		if !strings.contains(cluster, "cluster_name :identifier:") {
// 			continue // Skip non-cluster content
// 		}

// 		// Extract cluster name
// 		name_start := strings.index(cluster, "cluster_name :identifier:")
// 		if name_start == -1 do continue
// 		name_start += len("cluster_name :identifier:")
// 		name_end := strings.index(cluster[name_start:], "\n")
// 		if name_end == -1 do continue
// 		currentClusterName := strings.trim_space(cluster[name_start:][:name_end])
// 		// Look for record in this cluster
// 		lines := strings.split(cluster, "\n")
// 		for line in lines {
// 			line := strings.trim_space(line)
// 			value = strings.trim_space(strings.split(line, ":")[2])
// 			if strings.has_suffix(line, fmt.tprintf(": %s", rv)) {
// 				return strings.clone(value), true
// 			}
// 		}
// 	}

// 	return "", false
// }
