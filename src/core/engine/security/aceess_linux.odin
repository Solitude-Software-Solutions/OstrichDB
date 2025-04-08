#+build !darwin
// This is a build constraint: it tells the compiler to ignore this file when building for darwin
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
import "core:sys/linux"


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


//ngl I hacked this shit together by looking at Odin's souce code for each os' sys package. - Marshall
SET_OS_PERMISSIONS :: proc(fn, permission: string) -> bool {
	using os
	mode: uint = 0o600 // default to file owner read/write
	switch permission {
	case "Read-Only":
		mode = 0o400 // owner read only
	case "Read-Write":
		mode = 0o600 // owner read/write
	case "Inaccessible":
		mode = 0o000 // No permissions
	}
	path := utils.concat_standard_collection_name(fn)
	if ODIN_OS == .Linux {
		// linuxPath := strings.clone_to_cstring(path)
		//Todo: Finish this shit for linux and windows
		// } else if ODIN_OS == .Darwin {
		// 	darwinPath := string(path)
		// 	if mode == 0o600 {
		// 		// For owner read/write
		// 		perm := darwin.Permission{.PERMISSION_OWNER_READ, .PERMISSION_OWNER_WRITE}
		// 		success := darwin.sys_chmod(darwinPath, perm)
		// 		if !success {
		// 			return false
		// 		}
		// 	} else if mode == 0o400 {
		// 		// For owner read only
		// 		perm := darwin.Permission{.PERMISSION_OWNER_READ}
		// 		success := darwin.sys_chmod(darwinPath, perm)
		// 		if !success {
		// 			return false
		// 		}
		// 	} else if mode == 0o000 {
		// 		// No permissions
		// 		perm := darwin.Permission{} // Empty set
		// 		success := darwin.sys_chmod(darwinPath, perm)
		// 		if !success {
		// 			return false
		// 		}
		// 	}
	}
	return true // Changed from "err == 0" since err isn't defined
}
//Sets the permissions for a given operation
SET_OPERATION_PERMISSIONS :: proc(opName: string) -> ^types.CommandOperation {
	using const

	operation := new(types.CommandOperation)
	opArr: [dynamic]string

	//todo: TREE should be allowed but if a collection is set to inaccessable then that collection should not be shown

	//these commands will work on a collection that is set to read only or read write
	readWriteOrReadOnlyCommands := []string{WHERE, COUNT, FETCH, SIZE_OF, TYPE_OF, VALIDATE}

	//These commands will work on a collection that is set to read write
	readWriteCommands := []string {
		ISOLATE,
		BACKUP,
		ERASE,
		RENAME,
		SET,
		PURGE,
		CHANGE_TYPE,
		LOCK,
		NEW,
	}


	//check if operation can be used on a collection that is set to 'Read-Only' or 'Read-Write'
	for n in readWriteOrReadOnlyCommands {
		if opName == n {
			operation.name = n
			operation.permission = [dynamic]types.Operation_Permssion_Requirement{}
			append(&operation.permission, types.Operation_Permssion_Requirement.READ_ONLY)
			append(&operation.permission, types.Operation_Permssion_Requirement.READ_WRITE)

			append(&opArr, "Read-Only")
			append(&opArr, "Read-Write")
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
	if opName == UNLOCK {
		operation.name = UNLOCK
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
PERFORM_PERMISSIONS_CHECK_ON_COLLECTION :: proc(command, colName: string) -> int {
	//Get the operation permission for the command
	commandOperation := SET_OPERATION_PERMISSIONS(command)
	//Get the string representation array of the permission
	commandPermissions := commandOperation.permissionStr
	defer free(commandOperation)


	permissionValue, success := metadata.GET_METADATA_MEMBER_VALUE(colName, "# Permission", 1)
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
	lockStatus, success := metadata.GET_METADATA_MEMBER_VALUE(colName, "# Permission", 1)
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
