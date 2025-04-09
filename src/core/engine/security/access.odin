package security

import "../../../utils"
import "../../const"
import "../../types"
import "../data"
import "../data/metadata"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:sys/posix"

/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            Contains logic how users access databases within
            OsthichDB. Not yet fully implemented.
*********************************************************/


//Ensure that the user is an admin before allowing an operation
CHECK_ADMIN_STATUS :: proc(user: ^types.User) -> bool {
	secCollection := utils.concat_secure_collection_name(user.username.Value)
	userCluster := strings.to_upper(user.username.Value)
	isAdmin := false

	userRoleVal := data.GET_RECORD_VALUE(secCollection, userCluster, "identifier", "role")

	if userRoleVal == "admin" {
		isAdmin = true
	}

	return isAdmin
}


// Set the OS permissions for a given collection file
SET_FILE_PERMISSIONS_ON_OS_LEVEL :: proc(fn, permission: string) -> (success:bool) {
	using os

	mode:posix.mode_t= posix.S_IRWXU // default to file owner read/write/execute

/*
	//I love the language and its maintainers but holy shit the docs for this is stuff are non-existant

	Looking at the docs for the posix package it seems that there are only 3 "pre-made" modes
    So I am making my own here.

    - Marshall
*/
	R_ONLY_MODE:posix.mode_t: posix.mode_t{.IRUSR} //Owner read only
	RW_MODE:posix.mode_t:posix.mode_t{.IRUSR, .IWUSR} //Owner read-write
	I_MODE:posix.mode_t:posix.mode_t{} //No Permissions

	switch permission {
	case "Read-Write":
		mode = R_ONLY_MODE
	case "Read-Only":
		mode = R_ONLY_MODE
	case "Inaccessible":
		mode = I_MODE
	}
	concat := utils.concat_standard_collection_name(fn)
	path := strings.clone_to_cstring(concat) //chmod requires a cstring
	delete(path)

	changeSuccess := posix.chmod(path, mode)

	if changeSuccess == posix.result.OK{
	   success = true
	}else{
	   success = false
	}

	return success
}

//Sets the permissions for a given operation within OstrichDB
SET_OPERATION_PERMISSIONS :: proc(opName: string) -> ^types.CommandOperation {
	using const
	using types

	operation := new(types.CommandOperation)
	opArr: [dynamic]string

	//todo: TREE should be allowed but if a collection is set to inaccessable then that collection should not be shown

	//these commands will work on a collection that is set to read only or read write
	readWriteOrReadOnlyCommands := []string {
		Token[.WHERE],
		Token[.COUNT],
		Token[.FETCH],
		Token[.SIZE_OF],
		Token[.TYPE_OF],
		Token[.VALIDATE],
	}

	//These commands will work on a collection that is set to read write
	readWriteCommands := []string {
		Token[.ISOLATE],
		Token[.BACKUP],
		Token[.ERASE],
		Token[.RENAME],
		Token[.SET],
		Token[.PURGE],
		Token[.CHANGE_TYPE],
		Token[.LOCK],
		Token[.NEW],
	}


	//check if operation can be used on a collection that is set to 'Read-Only' or 'Read-Write'
	for n in readWriteOrReadOnlyCommands {
		if opName == n {
			operation.name = n
			operation.permission = [dynamic]types.Operation_Permssion_Requirement{}
			append(&operation.permission, types.Operation_Permssion_Requirement.READ_ONLY)
			append(&operation.permission, types.Operation_Permssion_Requirement.READ_WRITE)

			append(&opArr, "Read-Write") //Believe it or not the order in which these are appended is important. Dumb design I know. - Marshall
			append(&opArr, "Read-Only")
			operation.permissionStr = opArr
			return operation
		}
	}


	//check if operation can be used on a collection that is set to 'Read-Write'
	for n in readWriteCommands {
		if opName == n {
			operation.name = n
			operation.permission = [dynamic]types.Operation_Permssion_Requirement{}
			append(&operation.permission, types.Operation_Permssion_Requirement.READ_WRITE)
			append(&opArr, "Read-Write")
			operation.permissionStr = opArr
			return operation
		}
	}


	//check if the UNLOCK operation can be used on a collection that is set to 'Inaccessible' or 'Read-Only'
	if opName == Token[.UNLOCK] {
		operation.name = opName
		operation.permission = [dynamic]types.Operation_Permssion_Requirement{}
		append(&operation.permission, types.Operation_Permssion_Requirement.READ_ONLY)
		append(&operation.permission, types.Operation_Permssion_Requirement.INACCESSABLE)
		append(&opArr, "Read-Only")
		append(&opArr, "Inaccessible")
		operation.permissionStr = opArr
		return operation
	}

	return operation
}


//Checks if an the passed in operation can be performed via the command line
// permissionValue - the value from the metadata header field labeled: "Permission"
// ^types.CommandOperation - the name of the operation and the permissions said operation requires
CHECK_ID_OPERATION_IS_ALLOWED :: proc(
	permissionValue: string,
	operation: ^types.CommandOperation,
) -> bool {
	operationIsAllowed := false
	for i := 0; i < len(operation.permissionStr); i += 1 {
		if permissionValue == operation.permissionStr[i] {
			operationIsAllowed = true
			break
		}
	}
	//DO NOT FREE or DELETE commandOperation here. Shit will break - Marshall
	return operationIsAllowed
}


//Handles all the logic from above and returns a 1 if the user does not have permission to perform the passed in operation
//Performs Decryption of the secure collection, performs the check the re-encrypts the users secure collection
PERFORM_PERMISSIONS_CHECK_ON_COLLECTION :: proc(
	command, colName: string,
	colType: types.CollectionType,
) -> int {

	//Get the operation permission for the command
	commandOperation := SET_OPERATION_PERMISSIONS(command)
	//Get the string representation array of the permission
	commandPermissions := commandOperation.permissionStr
	defer free(commandOperation)


	permissionValue, success := metadata.GET_METADATA_MEMBER_VALUE(
		colName,
		"# Permission",
		colType,
	)
	for perm in commandPermissions {
		opIsAllowed := CHECK_ID_OPERATION_IS_ALLOWED(permissionValue, commandOperation)
		if !opIsAllowed {
			fmt.printfln(
				"%s%sYou do not have permission to perform this operation on this collection.%s",
				utils.BOLD,
				utils.YELLOW,
				utils.RESET,
			)
			return 1
		}
	}

	return 0
}

//Used to check if a collection is already locked before attempting to lock it again
GET_COLLECTION_LOCK_STATUS :: proc(colName: string) -> bool {
	isAlreadyLocked := false
	lockStatus, success := metadata.GET_METADATA_MEMBER_VALUE(
		colName,
		"# Permission",
		.STANDARD_PUBLIC,
	)
	if lockStatus == "Read-Only" || lockStatus == "Inaccessible" {
		isAlreadyLocked = true
	}

	return isAlreadyLocked
}


//Get user password before unlocking.
CONFTIM_COLLECTION_UNLOCK_PASSWORD :: proc() -> bool {
	passIsCorrect := false
	fmt.println("Please enter your password to continue:")
	input := utils.get_input(true)
	password := string(input)
	validatedPassword := VALIDATE_USER_PASSWORD(password)
	switch (validatedPassword) {
	case true:
		passIsCorrect = true
	case false:
		fmt.println("Invalid password. Operation cancelled.")
		break
	}

	return passIsCorrect
}


//Performs the permission check on the collection before allowing the operation to be performed. Used on command line
EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK :: proc(
	colName, commandStr: string,
	colType: types.CollectionType,
) -> int {

	//Decrypt the "working" collection to see what specific permission is set for operations to be performed
	#partial switch (colType) {
	case .CONFIG_PRIVATE:
		DECRYPT_COLLECTION("", .CONFIG_PRIVATE, types.system_user.m_k.valAsBytes)
		break
	case:
		DECRYPT_COLLECTION(colName, .STANDARD_PUBLIC, types.current_user.m_k.valAsBytes)
		break
	}

	//Decrypt the logged in users secure collection to ensure their role allows for the requested operation to be performed
	DECRYPT_COLLECTION(
		types.current_user.username.Value,
		.SECURE_PRIVATE,
		types.system_user.m_k.valAsBytes,
	)

	//Cross check the permissions set for the operation to be performed and the users role
	permissionCheckResult := PERFORM_PERMISSIONS_CHECK_ON_COLLECTION(commandStr, colName, colType)
	switch (permissionCheckResult)
	{
	case 0:
		//If the permission check passes, re-encrypt the "secure" collection and continue with the operation
		ENCRYPT_COLLECTION(
			types.current_user.username.Value,
			.SECURE_PRIVATE,
			types.system_user.m_k.valAsBytes,
			false,
		)
		break
	case:
		// If the permission check fails, re-encrypt the "working" and "secure" collections
		#partial switch (colType) {
		case .CONFIG_PRIVATE:
			ENCRYPT_COLLECTION("", .CONFIG_PRIVATE, types.system_user.m_k.valAsBytes, false)
			break
		case .ISOLATE_PUBLIC:
			ENCRYPT_COLLECTION(colName, .ISOLATE_PUBLIC, types.current_user.m_k.valAsBytes, false)
			break

		case:
			ENCRYPT_COLLECTION(colName, .STANDARD_PUBLIC, types.current_user.m_k.valAsBytes, false)
			break
		}
		ENCRYPT_COLLECTION(
			types.current_user.username.Value,
			.SECURE_PRIVATE,
			types.system_user.m_k.valAsBytes,
			false,
		)
		return -1
	}

	return 0
}
