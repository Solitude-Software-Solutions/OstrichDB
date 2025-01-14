package tests
import "../core/config"
import "../core/const"
import "../core/engine/data"
import "../core/engine/security"
import "../core/types"
import "../utils"
import "core:fmt"
import "core:strings"
import "core:testing"
import "core:time"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//

//todo:
//after tests run logged in user's username has been changed. need to not do that lol. breaks everything after tests
//after tests, the test history cluster is not being deleted
//need the following tests:
//collection,cluster, record purging
//appending a new command to the history cluster

test_counter := 0


main :: proc() {
	types.TESTING = true
	res := data.OST_READ_RECORD_VALUE(
		const.OST_CONFIG_PATH,
		const.CONFIG_CLUSTER,
		const.CONFIG,
		const.configSix,
	) //error supression
	if res == "true" {
		types.errSupression.enabled = true
	} else if res == "false" {
		config.OST_UPDATE_CONFIG_VALUE(const.configSix, "false")
		types.errSupression.enabled = false
	} else {
		utils.log_err("Error reading error suppression config", #procedure)
	}
	OST_INIT_TESTS()
	types.TESTING = false
}


OST_INIT_TESTS :: proc() {
	t := testing.T{} //create a test context
	test_counter = 0 // Reset counter at start

	//Collection tests
	// test_collection_creation(&t)
	// test_collection_deletion(&t)
	// test_collection_renaming(&t)
	// test_collection_backup(&t)
	// test_collection_isolation(&t)
	// //Cluster tests
	// test_cluster_creation(&t)
	// test_cluster_deletion(&t)
	// test_cluster_renamimg(&t)
	// //Record tests
	// test_record_creation(&t)
	// test_record_deletion(&t)
	test_record_renaming(&t)
	//User tests
	// test_user_creation(&t)
	// test_command_history(&t)

}


test_collection_creation :: proc(t: ^testing.T) {
	test_counter += 1
	start_time := time.now()
	utils.log_runtime_event("Test Started", "Running test_collection_creation")

	data.OST_CREATE_COLLECTION(const.TEST_COLLECTION, 0)
	defer data.OST_ERASE_COLLECTION(const.TEST_COLLECTION)

	result := data.OST_CHECK_IF_COLLECTION_EXISTS(const.TEST_COLLECTION, 0)


	if result {
		utils.log_runtime_event("Test Passed", "test_collection_creation completed successfully")
	} else {
		utils.log_runtime_event("Test Failed", "test_collection_creation failed")
	}

	print_test_result("test_collection_creation", result, start_time)
}

test_collection_deletion :: proc(t: ^testing.T) {
	test_counter += 1
	start_time := time.now()


	utils.log_runtime_event("Test Started", "Running test_collection_deletion")

	data.OST_CREATE_COLLECTION(const.TEST_COLLECTION, 0)
	data.OST_ERASE_COLLECTION(const.TEST_COLLECTION)

	result := !data.OST_CHECK_IF_COLLECTION_EXISTS(const.TEST_COLLECTION, 0)
	testing.expect(t, result, "collection should not exist")

	if result {
		utils.log_runtime_event("Test Passed", "test_collection_deletion completed successfully")
	} else {

		utils.log_runtime_event("Test Failed", "test_collection_deletion failed")
	}
	print_test_result("test_dcollection_deletion", result, start_time)
}

test_collection_renaming :: proc(t: ^testing.T) {
	test_counter += 1
	start_time := time.now()


	utils.log_runtime_event("Test Started", "Running test_collection_renaming")

	data.OST_CREATE_COLLECTION(const.TEST_COLLECTION, 0)
	data.OST_APPEND_ID_TO_COLLECTION(fmt.tprintf("%d", const.TEST_ID), 0)

	// defer data.OST_ERASE_COLLECTION(const.TEST_COLLECTION)
	// defer data.OST_ERASE_COLLECTION(const.TEST_NEW_COLLECTION)

	// data.OST_RENAME_COLLECTION(const.TEST_COLLECTION, const.TEST_NEW_COLLECTION)

	// result1 := !data.OST_CHECK_IF_COLLECTION_EXISTS(const.TEST_COLLECTION, 0)
	// result2 := data.OST_CHECK_IF_COLLECTION_EXISTS(const.TEST_NEW_COLLECTION, 0)
	// testing.expect(t, result1, "old collection should not exist")
	// testing.expect(t, result2, "new collection should exist")
	// result: bool
	// if result1 && result2 {
	// 	result = true
	// 	utils.log_runtime_event("Test Passed", "test_collection_renaming completed successfully")
	// } else {
	// 	result = false
	// 	utils.log_runtime_event("Test Failed", "test_collection_renaming failed")
	// }
	// print_test_result("test_collection_renaming", result, start_time)
}

test_collection_backup :: proc(t: ^testing.T) {
	test_counter += 1
	start_time := time.now()


	data.OST_CREATE_COLLECTION(const.TEST_COLLECTION, 0)
	defer data.OST_ERASE_COLLECTION(const.TEST_COLLECTION)
	result := data.OST_CREATE_BACKUP_COLLECTION(
		const.TEST_BACKUP_COLLECTION,
		const.TEST_COLLECTION,
	)
	testing.expect(t, result, "backup should be created successfully")

	if result {
		utils.log_runtime_event("Test Passed", "test_collection_backup completed successfully")
	} else {
		utils.log_runtime_event("Test Failed", "test_collection_backup failed")
	}
	print_test_result("test_collection_backup", result, start_time)
}

test_cluster_creation :: proc(t: ^testing.T) {
	test_counter += 1
	start_time := time.now()


	utils.log_runtime_event("Test Started", "Running test_cluster_creation")

	data.OST_CREATE_COLLECTION(const.TEST_COLLECTION, 0)
	result := data.OST_CREATE_CLUSTER_FROM_CL(
		const.TEST_COLLECTION,
		const.TEST_CLUSTER,
		const.TEST_ID,
	)
	id := data.OST_GET_CLUSTER_ID(const.TEST_COLLECTION, const.TEST_CLUSTER)
	defer data.OST_ERASE_COLLECTION(const.TEST_COLLECTION) //clean up
	res: bool
	if result == 0 {
		res = true
		utils.log_runtime_event("Test Passed", "test_cluster_creation completed successfully")
	} else {
		res = false
		utils.log_runtime_event("Test Failed", "test_cluster_creation failed")
	}
	print_test_result("test_cluster_creation", res, start_time)
}


test_cluster_deletion :: proc(t: ^testing.T) {
	test_counter += 1
	start_time := time.now()


	data.OST_CREATE_COLLECTION(const.TEST_COLLECTION, 0)
	data.OST_CREATE_CLUSTER_FROM_CL(const.TEST_COLLECTION, const.TEST_CLUSTER, const.TEST_ID)
	result := data.OST_ERASE_CLUSTER(const.TEST_COLLECTION, const.TEST_CLUSTER)

	id := data.OST_GET_CLUSTER_ID(const.TEST_COLLECTION, const.TEST_CLUSTER)
	// defer utils.remove_id_from_cache(id)
	defer data.OST_ERASE_COLLECTION(const.TEST_COLLECTION)

	if result {
		utils.log_runtime_event("Test Passed", "test_cluster_deletion completed successfully")

	} else {
		utils.log_runtime_event("Test Failed", "test_cluster_deletion failed")
	}
	print_test_result("test_cluster_deletion", result, start_time)
}


test_cluster_renamimg :: proc(t: ^testing.T) {
	test_counter += 1
	start_time := time.now()


	data.OST_CREATE_COLLECTION(const.TEST_COLLECTION, 0)
	data.OST_CREATE_CLUSTER_FROM_CL(const.TEST_COLLECTION, const.TEST_CLUSTER, const.TEST_ID)
	result := data.OST_RENAME_CLUSTER(
		const.TEST_COLLECTION,
		const.TEST_CLUSTER,
		const.TEST_NEW_CLUSTER,
	)

	id := data.OST_GET_CLUSTER_ID(const.TEST_COLLECTION, const.TEST_CLUSTER)
	// defer utils.remove_id_from_cache(id)
	defer data.OST_ERASE_COLLECTION(const.TEST_COLLECTION)

	if result {
		utils.log_runtime_event("Test Passed", "test_cluster_renamimg completed successfully")

	} else {
		utils.log_runtime_event("Test Failed", "test_cluster_renamimg failed")
	}
	print_test_result("test_cluster_renaming", result, start_time)
}


test_record_creation :: proc(t: ^testing.T) {

	test_counter += 1
	start_time := time.now()


	data.OST_CREATE_COLLECTION(const.TEST_COLLECTION, 0)
	data.OST_CREATE_CLUSTER_FROM_CL(const.TEST_COLLECTION, const.TEST_CLUSTER, const.TEST_ID)

	id := data.OST_GET_CLUSTER_ID(const.TEST_COLLECTION, const.TEST_CLUSTER)
	// defer utils.remove_id_from_cache(id)
	defer data.OST_ERASE_COLLECTION(const.TEST_COLLECTION)


	col := fmt.tprintf(
		"%s%s%s",
		const.OST_COLLECTION_PATH,
		const.TEST_COLLECTION,
		const.OST_FILE_EXTENSION,
	)

	result := data.OST_APPEND_RECORD_TO_CLUSTER(
		col,
		const.TEST_CLUSTER,
		const.TEST_RECORD,
		"",
		"STRING",
	)
	res: bool
	if result == 0 {
		res = true
		utils.log_runtime_event("Test Passed", "test_record_creation completed successfully")

	} else {
		res = false
		utils.log_runtime_event("Test Failed", "test_record_creation failed")
	}

	print_test_result("test_record_creation", res, start_time)
}

test_record_deletion :: proc(t: ^testing.T) {
	test_counter += 1
	start_time := time.now()


	data.OST_CREATE_COLLECTION(const.TEST_COLLECTION, 0)
	data.OST_CREATE_CLUSTER_FROM_CL(const.TEST_COLLECTION, const.TEST_CLUSTER, const.TEST_ID)

	col := fmt.tprintf(
		"%s%s%s",
		const.OST_COLLECTION_PATH,
		const.TEST_COLLECTION,
		const.OST_FILE_EXTENSION,
	)
	data.OST_APPEND_RECORD_TO_CLUSTER(
		col,
		const.TEST_CLUSTER,
		const.TEST_RECORD,
		"This is a test string",
		"STRING",
	)
	defer data.OST_ERASE_COLLECTION(const.TEST_COLLECTION)

	id := data.OST_GET_CLUSTER_ID(const.TEST_COLLECTION, const.TEST_CLUSTER)
	// defer utils.remove_id_from_cache(id)

	result := data.OST_ERASE_RECORD(const.TEST_COLLECTION, const.TEST_CLUSTER, const.TEST_RECORD)

	if result {
		utils.log_runtime_event("Test Passed", "test_record_deletion completed successfully")

	} else {
		utils.log_runtime_event("Test Failed", "test_record_deletion failed")

	}
	print_test_result("test_record_deletion", result, start_time)
}

test_record_renaming :: proc(t: ^testing.T) {
	test_counter += 1
	start_time := time.now()


	utils.log_runtime_event("Test Started", "Running test_record_renaming")

	data.OST_CREATE_COLLECTION(const.TEST_COLLECTION, 0)
	data.OST_CREATE_CLUSTER_FROM_CL(const.TEST_COLLECTION, const.TEST_CLUSTER, const.TEST_ID)

	col := fmt.tprintf(
		"%s%s%s",
		const.OST_COLLECTION_PATH,
		const.TEST_COLLECTION,
		const.OST_FILE_EXTENSION,
	)

	foo := data.OST_APPEND_RECORD_TO_CLUSTER(
		col,
		const.TEST_CLUSTER,
		const.TEST_RECORD,
		"This is a test string",
		"STRING",
	)
	defer data.OST_ERASE_COLLECTION(const.TEST_COLLECTION)

	result := data.OST_RENAME_RECORD(
		const.TEST_COLLECTION,
		const.TEST_CLUSTER,
		const.TEST_RECORD,
		const.TEST_NEW_RECORD,
	)
	res: bool
	if result == 0 {
		res = true
		utils.log_runtime_event("Test Passed", "test_record_renaming completed successfully")
	} else {
		res = false
		utils.log_runtime_event("Test Failed", "test_record_renaming failed")
	}
	print_test_result("test_record_renaming", res, start_time)
}

test_user_creation :: proc(t: ^testing.T) {
	test_counter += 1
	start_time := time.now()


	utils.log_runtime_event("Test Started", "Running test_user_creation")

	// Set up admin role for test since only admins can create users
	//todo: remove this shit man wtf - Marshall
	types.user.role.Value = "admin"


	result := security.OST_CREATE_NEW_USER(
		const.TEST_USERNAME,
		const.TEST_PASSWORD,
		const.TEST_ROLE,
	)


	// defer security.OST_DELETE_USER(const.TEST_USERNAME)

	// Check if secure collection was created for the user
	// testing.expect(t, result, "secure collection should exist for new user")
	// res: bool
	// if result == 0{
	// 	res = true
	// 	utils.log_runtime_event("Test Passed", "test_user_creation completed successfully")
	// } else {
	// 	res = false
	// 	utils.log_runtime_event("Test Failed", "test_user_creation failed")
	// }
	// print_test_result("test_user_creation", res, start_time)
}

test_command_history :: proc(t: ^testing.T) {
	test_counter += 1
	start_time := time.now()


	utils.log_runtime_event("Test Started", "Running test_command_history")


	security.OST_CREATE_NEW_USER(const.TEST_USERNAME, const.TEST_PASSWORD, const.TEST_ROLE)
	defer security.OST_DELETE_USER(const.TEST_USERNAME)
	// defer data.OST_ERASE_HISTORY_CLUSTER(const.TEST_USERNAME)


	test_command := "NEW COLLECTION test_collection"

	// Get current history count
	// todo: this should not be getting pased history. this proc only looks for normal collection
	initial_count := data.OST_COUNT_RECORDS_IN_HISTORY_CLUSTER(const.TEST_USERNAME)

	// Append command to history
	data.OST_APPEND_RECORD_TO_CLUSTER(
		"./history.ost",
		const.TEST_USERNAME,
		fmt.tprintf("HISTORY_%d", initial_count + 1),
		strings.to_upper(test_command),
		"COMMAND",
	)

	// Verify command was added
	new_count := data.OST_COUNT_RECORDS_IN_CLUSTER("history", const.TEST_USERNAME, false)
	testing.expect(t, new_count == initial_count + 1, "history count should increase by 1")

	// Verify command content
	record_value := data.OST_READ_RECORD_VALUE(
		"./history.ost",
		const.TEST_USERNAME,
		"COMMAND",
		fmt.tprintf("HISTORY_%d", new_count),
	)

	result := strings.contains(record_value, strings.to_upper(test_command))
	testing.expect(t, result, "history should contain the test command")

	if result {
		utils.log_runtime_event("Test Passed", "test_command_history completed successfully")
	} else {
		utils.log_runtime_event("Test Failed", "test_command_history failed")
	}
	print_test_result("test_command_history", result, start_time)
	//todo: need to delete the test users history cluster from the collection. when done testing.
}

//todo: nmeed to find a way to run this test. it requires the security poackage but cant import it because the tests package is import into security...
// test_auth_process :: proc(t: ^testing.T) {
//     test_counter += 1
// 	    start_time := time.now()
//

//     utils.log_runtime_event("Test Started", "Running test_auth_process")

//     test_password := const.TEST_PASSWORD

//     // Hash the password
//     hashed_password := security.OST_HASH_PASSWORD(test_password, 0, false, true)

//     // Get the salt that was generated
//     salt := string(types.user.salt)

//     // Encode the hashed password
//     encoded_hash := security.OST_ENCODE_HASHED_PASSWORD(hashed_password)

//     // Create pre-mesh
//     pre_mesh := security.OST_MESH_SALT_AND_HASH(salt, encoded_hash)

//     // Simulate login attempt with same password
//     new_hash := security.OST_HASH_PASSWORD(test_password, 0, true, false)
//     new_encoded := security.OST_ENCODE_HASHED_PASSWORD(new_hash)
//     post_mesh := security.OST_MESH_SALT_AND_HASH(salt, new_encoded)

//     // Verify meshes match
//     result := security.OST_CROSS_CHECK_MESH(pre_mesh, post_mesh)
//     testing.expect(t, result, "authentication process should succeed with correct password")

//     if result {
//         utils.log_runtime_event("Test Passed", "test_auth_process completed successfully")
//     } else {
//         utils.log_runtime_event("Test Failed", "test_auth_process failed")
//     }
//     print_test_result("test_collection_creation", result, start_time)
// }

test_collection_isolation :: proc(t: ^testing.T) {
	test_counter += 1
	start_time := time.now()

	utils.log_runtime_event("Test Started", "Running test_collection_isolation")


	data.OST_CREATE_COLLECTION(const.TEST_COLLECTION, 0)
	//no need to erase since isolation will do that
	result := data.OST_PERFORM_ISOLATION(const.TEST_COLLECTION)

	res: bool
	if result == 0 {
		res = true
		utils.log_runtime_event("Test Passed", "test_collection_isolation completed successfully")
	} else {
		res = false
		utils.log_runtime_event("Test Failed", "test_collection_isolation failed")
	}

	print_test_result("test_collection_isolation", res, start_time)

}


print_test_result :: proc(name: string, passed: bool, start_time: time.Time) {
	duration := time.since(start_time)
	status: string
	if passed {
		status = fmt.tprintf("%s%sPASSED%s", utils.BOLD, utils.GREEN, utils.RESET)
	} else {
		status = fmt.tprintf("%s%sFAILED%s", utils.BOLD, utils.RED, utils.RESET)
	}

	fmt.printf(
		"Test: %s%s%s - Status: %s - Duration: %.2fms\n",
		utils.BOLD,
		name,
		utils.RESET,
		status,
		time.duration_milliseconds(duration),
	)
}
