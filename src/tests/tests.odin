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

//need the following tests:
//collection,cluster, record purging
//appending a new command to the history cluster

test_counter := 0



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
	test_record_renaming(&t)
	//User tests
	test_user_creation(&t)
	test_command_history(&t)
}


test_collection_creation :: proc(t: ^testing.T) {
	test_counter += 1
	start_time := time.now()
	
	utils.log_runtime_event("Test Started", "Running test_collection_creation")
	
	data.OST_CREATE_COLLECTION(const.TEST_COLLECTION, 0)
	defer data.OST_ERASE_COLLECTION(const.TEST_COLLECTION)

	result := data.OST_CHECK_IF_COLLECTION_EXISTS(const.TEST_COLLECTION, 0)
	testing.expect(t, result, "collection should exist")

	if result {
		fmt.printf("\t%s%sPASSED%s\n", utils.BOLD, utils.GREEN, utils.RESET)
		utils.log_runtime_event("Test Passed", "test_collection_creation completed successfully")
	} else {
		fmt.printf("\t%s%sFAILED%s\n", utils.BOLD, utils.RED, utils.RESET)
		utils.log_runtime_event("Test Failed", "test_collection_creation failed")
	}

	print_test_result("test_collection_creation", result, start_time)
}

test_collection_deletion :: proc(t: ^testing.T) {
	test_counter += 1
	fmt.printf("Test %d: %stest_collection_deletion%s...", test_counter, utils.BOLD, utils.RESET)

	utils.log_runtime_event("Test Started", "Running test_collection_deletion")
	
	data.OST_CREATE_COLLECTION(const.TEST_COLLECTION, 0)
	data.OST_ERASE_COLLECTION(const.TEST_COLLECTION)

	result := !data.OST_CHECK_IF_COLLECTION_EXISTS(const.TEST_COLLECTION, 0)
	testing.expect(t, result, "collection should not exist")

	if result {
		fmt.printf("\t%s%sPASSED%s\n", utils.BOLD, utils.GREEN, utils.RESET)
		utils.log_runtime_event("Test Passed", "test_collection_deletion completed successfully")
	} else {
		fmt.printf("\t%s%sFAILED%s\n", utils.BOLD, utils.RED, utils.RESET)
		utils.log_runtime_event("Test Failed", "test_collection_deletion failed")
	}
}

test_collection_renaming :: proc(t: ^testing.T) {
	test_counter += 1
	fmt.printf("Test %d: %stest_collection_renaming%s...", test_counter, utils.BOLD, utils.RESET)

	utils.log_runtime_event("Test Started", "Running test_collection_renaming")

	data.OST_CREATE_COLLECTION(const.TEST_COLLECTION, 0)
	defer data.OST_ERASE_COLLECTION(const.TEST_COLLECTION)
	defer data.OST_ERASE_COLLECTION(const.TEST_NEW_COLLECTION)

	data.OST_RENAME_COLLECTION(const.TEST_COLLECTION, const.TEST_NEW_COLLECTION)

	result1 := !data.OST_CHECK_IF_COLLECTION_EXISTS(const.TEST_COLLECTION, 0)
	result2 := data.OST_CHECK_IF_COLLECTION_EXISTS(const.TEST_NEW_COLLECTION, 0)
	testing.expect(t, result1, "old collection should not exist")
	testing.expect(t, result2, "new collection should exist")

	if result1 && result2 {
		fmt.printf("\t%s%sPASSED%s\n", utils.BOLD, utils.GREEN, utils.RESET)
		utils.log_runtime_event("Test Passed", "test_collection_renaming completed successfully")
	} else {
		fmt.printf("\t%s%sFAILED%s\n", utils.BOLD, utils.RED, utils.RESET)
		utils.log_runtime_event("Test Failed", "test_collection_renaming failed")
	}
}

test_collection_backup :: proc(t: ^testing.T) {
	test_counter += 1
	fmt.printf("Test %d: %stest_collection_backup%s...", test_counter, utils.BOLD, utils.RESET)

	data.OST_CREATE_COLLECTION(const.TEST_COLLECTION, 0)
	defer data.OST_ERASE_COLLECTION(const.TEST_COLLECTION)
	result := data.OST_CREATE_BACKUP_COLLECTION(const.TEST_BACKUP_COLLECTION, const.TEST_COLLECTION)
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

	utils.log_runtime_event("Test Started", "Running test_cluster_creation")

	data.OST_CREATE_COLLECTION(const.TEST_COLLECTION, 0)
	result := data.OST_CREATE_CLUSTER_FROM_CL(const.TEST_COLLECTION, const.TEST_CLUSTER, const.TEST_ID)
	defer data.OST_ERASE_COLLECTION(const.TEST_COLLECTION) //clean up

	if result == 0 {
		testing.expect(t, true, "cluster should be created successfully")
		fmt.printf("\t%s%sPASSED%s\n", utils.BOLD, utils.GREEN, utils.RESET)
		utils.log_runtime_event("Test Passed", "test_cluster_creation completed successfully")
	} else {
		testing.expect(t, false, "cluster should be created successfully")
		fmt.printf("\t%s%sFAILED%s\n", utils.BOLD, utils.RED, utils.RESET)
		utils.log_runtime_event("Test Failed", "test_cluster_creation failed")
	}
}


test_cluster_deletion :: proc(t: ^testing.T) {
	test_counter += 1
	fmt.printf("Test %d: %stest_cluster_deletion%s...", test_counter, utils.BOLD, utils.RESET)

	data.OST_CREATE_COLLECTION(const.TEST_COLLECTION, 0)
	data.OST_CREATE_CLUSTER_FROM_CL(const.TEST_COLLECTION, const.TEST_CLUSTER, const.TEST_ID)
	result := data.OST_ERASE_CLUSTER(const.TEST_COLLECTION, const.TEST_CLUSTER)
	defer data.OST_ERASE_COLLECTION(const.TEST_COLLECTION)

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

	data.OST_CREATE_COLLECTION(const.TEST_COLLECTION, 0)
	data.OST_CREATE_CLUSTER_FROM_CL(const.TEST_COLLECTION, const.TEST_CLUSTER, const.TEST_ID)
	result := data.OST_RENAME_CLUSTER(const.TEST_COLLECTION, const.TEST_CLUSTER, const.TEST_NEW_CLUSTER)
	defer data.OST_ERASE_COLLECTION(const.TEST_COLLECTION)

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

	data.OST_CREATE_COLLECTION(const.TEST_COLLECTION, 0)
	data.OST_CREATE_CLUSTER_FROM_CL(const.TEST_COLLECTION, const.TEST_CLUSTER, const.TEST_ID)
	defer data.OST_ERASE_COLLECTION(const.TEST_COLLECTION)


	col := fmt.tprintf(
		"%s%s%s",
		const.OST_COLLECTION_PATH,
		const.TEST_COLLECTION,
		const.OST_FILE_EXTENSION,
	)

	result := data.OST_APPEND_RECORD_TO_CLUSTER(col, const.TEST_CLUSTER, const.TEST_RECORD, "", "STRING")

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

	result := data.OST_ERASE_RECORD(const.TEST_COLLECTION, const.TEST_CLUSTER, const.TEST_RECORD)

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

	utils.log_runtime_event("Test Started", "Running test_record_renaming")

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

	result := data.OST_RENAME_RECORD(const.TEST_RECORD, const.TEST_NEW_RECORD, true, const.TEST_COLLECTION, const.TEST_CLUSTER)

	if result == 0 {
		testing.expect(t, true, "record should be renamed successfully")
		fmt.printf("\t%s%sPASSED%s\n", utils.BOLD, utils.GREEN, utils.RESET)
		utils.log_runtime_event("Test Passed", "test_record_renaming completed successfully")
	} else {
		testing.expect(t, false, "record should be renamed successfully")
		fmt.printf("\t%s%sFAILED%s\n", utils.BOLD, utils.RED, utils.RESET)
		utils.log_runtime_event("Test Failed", "test_record_renaming failed")
	}

}

test_user_creation :: proc(t: ^testing.T) {
    test_counter += 1
    fmt.printf("Test %d: %stest_user_creation%s...", test_counter, utils.BOLD, utils.RESET)

    utils.log_runtime_event("Test Started", "Running test_user_creation")

	// Set up admin role for test since only admins can create users
    types.user.role.Value = "admin"
    types.user.username.Value = "test_user_head"
    
    // Create test user
    types.new_user.role.Value = const.TEST_ROLE
    types.new_user.username.Value = const.TEST_USERNAME
    
    result := security.OST_CREATE_NEW_USER(const.TEST_USERNAME, const.TEST_PASSWORD, const.TEST_ROLE)
	defer security.OST_DELETE_USER(types.new_user.username.Value)
    
    // Check if secure collection was created for the user
    exists, _ := data.OST_FIND_SEC_COLLECTION(const.TEST_USERNAME)
    testing.expect(t, exists, "secure collection should exist for new user")
    
    if result == 0 && exists {
        fmt.printf("\t%s%sPASSED%s\n", utils.BOLD, utils.GREEN, utils.RESET)
        utils.log_runtime_event("Test Passed", "test_user_creation completed successfully")
    } else {
        fmt.printf("\t%s%sFAILED%s\n", utils.BOLD, utils.RED, utils.RESET)
        utils.log_runtime_event("Test Failed", "test_user_creation failed")
    }
}

test_command_history :: proc(t: ^testing.T) {
    test_counter += 1
    fmt.printf("Test %d: %stest_command_history%s...", test_counter, utils.BOLD, utils.RESET)
    
    utils.log_runtime_event("Test Started", "Running test_command_history")
    
    // Set up test user first
    types.user.role.Value = "admin"
    types.user.username.Value = "test_user_head"
    
    // Create test user
    types.new_user.role.Value = const.TEST_ROLE
    types.new_user.username.Value = const.TEST_USERNAME
    security.OST_CREATE_NEW_USER(const.TEST_USERNAME, const.TEST_PASSWORD, const.TEST_ROLE)
    defer security.OST_DELETE_USER(types.new_user.username.Value)
    

    types.current_user.username.Value = const.TEST_USERNAME
    

    test_command := "NEW COLLECTION test_collection"
    
    // Get current history count
    initial_count := data.OST_COUNT_RECORDS_IN_CLUSTER("history", const.TEST_USERNAME, false)
    
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
        fmt.printf("\t%s%sPASSED%s\n", utils.BOLD, utils.GREEN, utils.RESET)
        utils.log_runtime_event("Test Passed", "test_command_history completed successfully")
    } else {
        fmt.printf("\t%s%sFAILED%s\n", utils.BOLD, utils.RED, utils.RESET)
        utils.log_runtime_event("Test Failed", "test_command_history failed")
    }

	//todo: need to delete the test users history cluster from the collection. when done testing.
}

//todo: nmeed to find a way to run this test. it requires the security poackage but cant import it because the tests package is import into security...
// test_auth_process :: proc(t: ^testing.T) {
//     test_counter += 1
//     fmt.printf("Test %d: %stest_auth_process%s...", test_counter, utils.BOLD, utils.RESET)
    
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
//         fmt.printf("\t%s%sPASSED%s\n", utils.BOLD, utils.GREEN, utils.RESET)
//         utils.log_runtime_event("Test Passed", "test_auth_process completed successfully")
//     } else {
//         fmt.printf("\t%s%sFAILED%s\n", utils.BOLD, utils.RED, utils.RESET)
//         utils.log_runtime_event("Test Failed", "test_auth_process failed")
//     }
// }

print_test_result :: proc(name: string, passed: bool, start_time: time.Time) {
    duration := time.since(start_time)
    status: string
    if passed {
        status = fmt.tprintf("%s%sPASSED%s", utils.BOLD, utils.GREEN, utils.RESET)
    } else {
        status = fmt.tprintf("%s%sFAILED%s", utils.BOLD, utils.RED, utils.RESET)
    }
    
    fmt.printf("Test: %s%s%s - Status: %s - Duration: %.2fms\n", 
        utils.BOLD, 
        name, 
        utils.RESET,
        status,
        time.duration_milliseconds(duration))
}