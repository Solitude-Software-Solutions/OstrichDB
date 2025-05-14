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
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            Contains logic for generating and managing IDs for users and clusters.
            All users and clusters have a unique ID that is generated when they are created.
*********************************************************/


//generates a random ID, ensures its not currently in use by a user or a cluster
//the uponCreation param is used to evalute at whether or not the cluster or user that the ID will be assigned to has been created yet
GENERATE_ID :: proc(uponCreation: bool) -> i64 {
    if uponCreation == true {
        return rand.int63_max(1e16 + 1)
    }

    for { //Tries to create a random ID until it is not already in use
        ID := rand.int63_max(1e16 + 1)
        if !CHECK_IF_USER_ID_EXISTS(ID) || !CHECK_IF_CLUSTER_ID_EXISTS(ID) {
            return ID
        }
        utils.log_err("Generated ID already exists in cache file, retrying", #procedure)
    }
}

// takes in an id and checks if it exists in the USER_IDS cluster
CHECK_IF_USER_ID_EXISTS :: proc(id: i64) -> bool {
	idStr := fmt.tprintf("%d", id)
	//this is incorrect, record names are not the same as the id values
	_, idFound := SCAN_ID_COLLECTION_FOR_ID_VALUE(const.USER_ID_CLUSTER, "USER_ID", idStr)
	return idFound
}
//same as above but for the cluster_id cluster
CHECK_IF_CLUSTER_ID_EXISTS :: proc(id: i64) -> bool {
	idStr := fmt.tprintf("%d", id)
	//this is incorrect, record names are not the same as the id values
	_, idFound := SCAN_ID_COLLECTION_FOR_ID_VALUE(const.CLUSTER_ID_CLUSTER, "CLUSTER_ID", idStr)
	return idFound
}

//Used to create the private collection that holds 2 clusters:
//1. cluster_id_cluster
//2. user_id_cluster
//These are important for keeping track of used ids in the system
CREATE_AND_FILL_PRIVATE_ID_COLLECTION :: proc() {
	using const

	CREATE_COLLECTION("", .SYSTEM_ID_PRIVATE)
	cluOneid := GENERATE_ID(true)

	// doing this prevents the creation of cluster_id records each time the program starts up. Only allows it once
	if CHECK_IF_CLUSTER_EXISTS(ID_PATH, CLUSTER_ID_CLUSTER) == true &&
	   CHECK_IF_CLUSTER_EXISTS(ID_PATH, USER_ID_CLUSTER) == true {
		return
	}
	//create a cluster for cluster ids
	CREATE_CLUSTER_BLOCK(const.ID_PATH, cluOneid, CLUSTER_ID_CLUSTER)
	APPEND_ID_TO_ID_COLLECTION(fmt.tprintf("%d", cluOneid), 0)

	cluTwoid := GENERATE_ID(true)
	//create a cluster for user ids
	CREATE_CLUSTER_BLOCK(const.ID_PATH, cluTwoid, USER_ID_CLUSTER)
	APPEND_ID_TO_ID_COLLECTION(fmt.tprintf("%d", cluTwoid), 0)

	metadata.INIT_METADATA_IN_NEW_COLLECTION(ID_PATH)
}

//appends either a user id or a cluster id to their respective clusters in the private id collection
//0 = cluster id, 1 = user id
APPEND_ID_TO_ID_COLLECTION :: proc(idStr: string, idType: int) {
	using types
	using const

	idBuf: [1024]byte
	switch (idType)
	{
	case 0:
		id.clusterIdCount = GET_RECORD_COUNT_WITHIN_CLUSTER("ids", CLUSTER_ID_CLUSTER, false)

		idCountStr := strconv.itoa(idBuf[:], id.clusterIdCount)
		recordName := fmt.tprintf("%s%s", "clusterID_", idCountStr)

		recordCreationSuccess := CREATE_RECORD(
			ID_PATH,
			CLUSTER_ID_CLUSTER,
			recordName,
			idStr,
			"CLUSTER_ID",
		)
		break
	case 1:
		id.userIdCount = GET_RECORD_COUNT_WITHIN_CLUSTER("ids", USER_ID_CLUSTER, false)

		idCountStr := strconv.itoa(idBuf[:], id.userIdCount)
		recordName := fmt.tprintf("%s%s", "userID_", idCountStr)

		recordCreationSuccess := CREATE_RECORD(
			ID_PATH,
			USER_ID_CLUSTER,
			recordName,
			idStr,
			"USER_ID",
		)
		break
	}
}

//removes the passed in id from either cluster in the ids.ostrichdb file.
//if isUserId is true then the id is removed from the USER_ID_CLUSTER
//if isUserId is false then the id is removed from the CLUSTER_ID_CLUSTER
//in the event that an admin user is deleting another user the id needs to be
//removed from both clusters so the call is made twice with isUserId set to true and false
REMOVE_ID_FROM_ID_COLLECTION :: proc(id: string, isUserId: bool) -> bool {
	file, cn, rv: string

	if isUserId {
		file = const.ID_PATH
		cn = const.USER_ID_CLUSTER
		rv = id
	} else {
		file = const.ID_PATH
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

//Scans the private id collection for a record with the passed in record value
// cn = cluster name, rt = record type, rv = record value
SCAN_ID_COLLECTION_FOR_ID_VALUE :: proc(cn, rt, rv: string) -> (string, bool) {
	value: string
	success: bool


	data, readSuccess := utils.read_file(const.ID_PATH, #procedure)
	if !readSuccess {
		return "", false
	}

	defer delete(data)

	content := string(data)
	clusters := strings.split(content, "},")

	for cluster in clusters {
		if !strings.contains(cluster, "cluster_name :identifier:") {
			continue // Skip non-cluster content
		}

		// Extract cluster name
		name_start := strings.index(cluster, "cluster_name :identifier:")
		if name_start == -1 do continue
		name_start += len("cluster_name :identifier:")
		name_end := strings.index(cluster[name_start:], "\n")
		if name_end == -1 do continue
		currentClusterName := strings.trim_space(cluster[name_start:][:name_end])
		// Look for record in this cluster
		lines := strings.split(cluster, "\n")
		for line in lines {
			line := strings.trim_space(line)
			// fmt.println("line: ", line)
			value = strings.trim_space(strings.split(line, ":")[0])
			if strings.has_suffix(line, fmt.tprintf(": %s", rv)) {
				return strings.clone(value), true
			}
		}
	}

	return "", false
}
