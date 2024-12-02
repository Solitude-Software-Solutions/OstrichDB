package tests

import "../core/config"
import "../core/const"
import "../core/engine/data"
import "../core/types"
import "../utils"
import "core:fmt"
import "core:testing"


//need the following tests:
//new user creation
//collection,cluster, record purging
//appending a new command to the history cluster
//all operations on cluster and records

test_counter := 0
id: i64 = 000000000000
collectionName := "test_collection"
clusterName := "test_cluster"
recordName := "test_record"
newCollectionName := "test_collection_new"
newClusterName := "test_cluster_new"
newRecordName := "test_record_new"
backupCollectionName := "test_collection_backup"


main :: proc() {
	types.TESTING = true
	res := config.OST_READ_CONFIG_VALUE(const.configSix) //error supression
	if res == "true" {
		types.errSupression.enabled = true
	} else if res == "false" {
		config.OST_TOGGLE_CONFIG(const.configSix)
		types.errSupression.enabled = false
	} else {
		utils.log_err("Error reading error suppression config", #procedure)
	}
	OST_INIT_TESTS()
}


OST_INIT_TESTS :: proc() {
	t := testing.T{} //create a test context
	test_counter = 0 // Reset counter at start

	//Collection tests
	test_collection_creation(&t)
	test_collection_deletion(&t)
	test_collection_renaming(&t)
	test_collection_backup(&t)
	//Cluster tests
	test_cluster_creation(&t)
	test_cluster_deletion(&t)
	test_cluster_renamimg(&t)
	//Record tests
	test_record_creation(&t)
	test_record_deletion(&t)
	// test_record_renaming(&t)
}


test_collection_creation :: proc(t: ^testing.T) {
	test_counter += 1
	fmt.printf("Test %d: %stest_collection_creation%s...", test_counter, utils.BOLD, utils.RESET)

	data.OST_CREATE_COLLECTION(collectionName, 0)
	defer data.OST_ERASE_COLLECTION(collectionName)

	result := data.OST_CHECK_IF_COLLECTION_EXISTS(collectionName, 0)
	testing.expect(t, result, "collection should exist")

	if result {
		fmt.printf("\t%s%sPASSED%s\n", utils.BOLD, utils.GREEN, utils.RESET)
	} else {
		fmt.printf("\t%s%sFAILED%s\n", utils.BOLD, utils.RED, utils.RESET)
	}
}

test_collection_deletion :: proc(t: ^testing.T) {
	test_counter += 1
	fmt.printf("Test %d: %stest_collection_deletion%s...", test_counter, utils.BOLD, utils.RESET)

	data.OST_CREATE_COLLECTION(collectionName, 0)
	data.OST_ERASE_COLLECTION(collectionName)

	result := !data.OST_CHECK_IF_COLLECTION_EXISTS(collectionName, 0)
	testing.expect(t, result, "collection should not exist")

	if result {
		fmt.printf("\t%s%sPASSED%s\n", utils.BOLD, utils.GREEN, utils.RESET)
	} else {
		fmt.printf("\t%s%sFAILED%s\n", utils.BOLD, utils.RED, utils.RESET)
	}
}

test_collection_renaming :: proc(t: ^testing.T) {
	test_counter += 1
	fmt.printf("Test %d: %stest_collection_renaming%s...", test_counter, utils.BOLD, utils.RESET)

	data.OST_CREATE_COLLECTION(collectionName, 0)
	defer data.OST_ERASE_COLLECTION(collectionName)
	defer data.OST_ERASE_COLLECTION(newCollectionName)

	data.OST_RENAME_COLLECTION(collectionName, newCollectionName)

	result1 := !data.OST_CHECK_IF_COLLECTION_EXISTS(collectionName, 0)
	result2 := data.OST_CHECK_IF_COLLECTION_EXISTS(newCollectionName, 0)
	testing.expect(t, result1, "old collection should not exist")
	testing.expect(t, result2, "new collection should exist")

	if result1 && result2 {
		fmt.printf("\t%s%sPASSED%s\n", utils.BOLD, utils.GREEN, utils.RESET)
	} else {
		fmt.printf("\t%s%sFAILED%s\n", utils.BOLD, utils.RED, utils.RESET)
	}

}

test_collection_backup :: proc(t: ^testing.T) {
	test_counter += 1
	fmt.printf("Test %d: %stest_collection_backup%s...", test_counter, utils.BOLD, utils.RESET)

	data.OST_CREATE_COLLECTION(collectionName, 0)
	defer data.OST_ERASE_COLLECTION(collectionName)
	result := data.OST_CREATE_BACKUP_COLLECTION(backupCollectionName, collectionName)
	testing.expect(t, result, "backup should be created successfully")

	if result {
		fmt.printf("\t%s%sPASSED%s\n", utils.BOLD, utils.GREEN, utils.RESET)
	} else {
		fmt.printf("\t%s%sFAILED%s\n", utils.BOLD, utils.RED, utils.RESET)
	}
}

test_cluster_creation :: proc(t: ^testing.T) {
	test_counter += 1
	fmt.printf("Test %d: %stest_cluster_creation%s...", test_counter, utils.BOLD, utils.RESET)

	data.OST_CREATE_COLLECTION(collectionName, 0)
	result := data.OST_CREATE_CLUSTER_FROM_CL(collectionName, clusterName, id)
	defer data.OST_ERASE_COLLECTION(collectionName) //clean up

	if result == 0 {
		testing.expect(t, true, "cluster should be created successfully")
		fmt.printf("\t%s%sPASSED%s\n", utils.BOLD, utils.GREEN, utils.RESET)
	} else {
		testing.expect(t, false, "cluster should be created successfully")
		fmt.printf("\t%s%sFAILED%s\n", utils.BOLD, utils.RED, utils.RESET)
	}
}


test_cluster_deletion :: proc(t: ^testing.T) {
	test_counter += 1
	fmt.printf("Test %d: %stest_cluster_deletion%s...", test_counter, utils.BOLD, utils.RESET)

	data.OST_CREATE_COLLECTION(collectionName, 0)
	data.OST_CREATE_CLUSTER_FROM_CL(collectionName, clusterName, id)
	result := data.OST_ERASE_CLUSTER(collectionName, clusterName)
	defer data.OST_ERASE_COLLECTION(collectionName)

	if result {
		testing.expect(t, true, "cluster should be deleted successfully")
		fmt.printf("\t%s%sPASSED%s\n", utils.BOLD, utils.GREEN, utils.RESET)
	} else {
		testing.expect(t, false, "cluster should be deleted successfully")
		fmt.printf("\t%s%sFAILED%s\n", utils.BOLD, utils.RED, utils.RESET)
	}
}


test_cluster_renamimg :: proc(t: ^testing.T) {
	test_counter += 1
	fmt.printf("Test %d: %stest_cluster_renamimg%s...", test_counter, utils.BOLD, utils.RESET)

	data.OST_CREATE_COLLECTION(collectionName, 0)
	data.OST_CREATE_CLUSTER_FROM_CL(collectionName, clusterName, id)
	result := data.OST_RENAME_CLUSTER(collectionName, clusterName, newClusterName)
	defer data.OST_ERASE_COLLECTION(collectionName)

	if result {
		testing.expect(t, true, "cluster should be renamed successfully")
		fmt.printf("\t%s%sPASSED%s\n", utils.BOLD, utils.GREEN, utils.RESET)
	} else {
		testing.expect(t, false, "cluster should be renamed successfully")
		fmt.printf("\t%s%sFAILED%s\n", utils.BOLD, utils.RED, utils.RESET)
	}
}


test_record_creation :: proc(t: ^testing.T) {

	test_counter += 1
	fmt.printf("Test %d: %stest_record_creation%s...", test_counter, utils.BOLD, utils.RESET)

	data.OST_CREATE_COLLECTION(collectionName, 0)
	data.OST_CREATE_CLUSTER_FROM_CL(collectionName, clusterName, id)
	defer data.OST_ERASE_COLLECTION(collectionName)


	col := fmt.tprintf(
		"%s%s%s",
		const.OST_COLLECTION_PATH,
		collectionName,
		const.OST_FILE_EXTENSION,
	)

	result := data.OST_APPEND_RECORD_TO_CLUSTER(col, clusterName, recordName, "", "STRING")

	if result == 0 {
		testing.expect(t, true, "record should be created successfully")
		fmt.printf("\t%s%sPASSED%s\n", utils.BOLD, utils.GREEN, utils.RESET)
	} else {
		testing.expect(t, false, "record should be created successfully")
		fmt.printf("\t%s%sFAILED%s\n", utils.BOLD, utils.RED, utils.RESET)
	}


}

test_record_deletion :: proc(t: ^testing.T) {
	test_counter += 1
	fmt.printf("Test %d: %stest_record_deletion%s...", test_counter, utils.BOLD, utils.RESET)

	data.OST_CREATE_COLLECTION(collectionName, 0)
	data.OST_CREATE_CLUSTER_FROM_CL(collectionName, clusterName, id)

	col := fmt.tprintf(
		"%s%s%s",
		const.OST_COLLECTION_PATH,
		collectionName,
		const.OST_FILE_EXTENSION,
	)
	data.OST_APPEND_RECORD_TO_CLUSTER(
		col,
		clusterName,
		recordName,
		"This is a test string",
		"STRING",
	)
	defer data.OST_ERASE_COLLECTION(collectionName)

	result := data.OST_ERASE_RECORD(collectionName, clusterName, recordName)

	if result {
		testing.expect(t, true, "record should be deleted successfully")
		fmt.printf("\t%s%sPASSED%s\n", utils.BOLD, utils.GREEN, utils.RESET)
	} else {
		testing.expect(t, false, "record should be deleted successfully")
		fmt.printf("\t%s%sFAILED%s\n", utils.BOLD, utils.RED, utils.RESET)
	}
}

test_record_renaming :: proc(t: ^testing.T) {
	test_counter += 1
	fmt.printf("Test %d: %stest_record_renaming%s...", test_counter, utils.BOLD, utils.RESET)

	data.OST_CREATE_COLLECTION(collectionName, 0)
	data.OST_CREATE_CLUSTER_FROM_CL(collectionName, clusterName, id)

	col := fmt.tprintf(
		"%s%s%s",
		const.OST_COLLECTION_PATH,
		collectionName,
		const.OST_FILE_EXTENSION,
	)

	data.OST_APPEND_RECORD_TO_CLUSTER(
		col,
		clusterName,
		recordName,
		"This is a test string",
		"STRING",
	)
	defer data.OST_ERASE_COLLECTION(collectionName)

	result := data.OST_RENAME_RECORD(recordName, newRecordName, true, collectionName, clusterName)

	if result == 0 {
		testing.expect(t, true, "record should be renamed successfully")
		fmt.printf("\t%s%sPASSED%s\n", utils.BOLD, utils.GREEN, utils.RESET)
	} else {
		testing.expect(t, false, "record should be renamed successfully")
		fmt.printf("\t%s%sFAILED%s\n", utils.BOLD, utils.RED, utils.RESET)
	}

}


test_secure_collection_creation :: proc() {}
