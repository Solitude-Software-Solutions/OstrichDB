package tests

import "../core/engine/data"
import "../core/types"
import "../utils"
import "core:fmt"
import "core:testing"

test_counter := 0

OST_INIT_TESTS :: proc() {
	types.TESTING = true
	t := testing.T{} //create a test context
	test_counter = 0 // Reset counter at start

	test_collection_creation(&t)
	test_collection_deletion(&t)
	test_collection_renaming(&t)
	test_collection_backup(&t)
}


test_collection_creation :: proc(t: ^testing.T) {
	test_counter += 1
	fmt.printf("Test %d: %stest_collection_creation%s...", test_counter, utils.BOLD, utils.RESET)

	collectionName := "test_collection"
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

	collectionName := "test_collection"
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

	collectionName := "test_collection"
	newCollectionName := "test_collection_new"
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

	backUpCollectionName := "test_collection_backup"
	collectionName := "test_collection"
	data.OST_CREATE_COLLECTION(collectionName, 0)
	defer data.OST_ERASE_COLLECTION(collectionName)
	result := data.OST_CREATE_BACKUP_COLLECTION(backUpCollectionName, collectionName)
	testing.expect(t, result, "backup should be created successfully")

	if result {
		fmt.printf("\t%s%sPASSED%s\n", utils.BOLD, utils.GREEN, utils.RESET)
	} else {
		fmt.printf("\t%s%sFAILED%s\n", utils.BOLD, utils.RED, utils.RESET)
	}
}
