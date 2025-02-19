package security

import "../../../utils"
import "../../const"
import "../../types"
import "../data/metadata"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            Contains logic for handling user management,
            including creating, deleting, and updating
            user accounts.
*********************************************************/


//Ensure that the user is an admin before allowing an operation
OST_CHECK_ADMIN_STATUS :: proc(user: ^types.User) -> bool {
	isAdmin := false
	if user.role.Value == "admin" {
		isAdmin = true
	}

	return isAdmin
}


OST_SET_OPERATION_PERMISSIONS :: proc(opName: string) -> ^types.CommandOperation {
	using const

	operation := new(types.CommandOperation)
	opArr: [dynamic]string

	//todo: TREE should be allowed but if a collection is set to inaccessable then that collection should not be shown
	//todo: NEW should be allowed but if a collection is set to inaccessable then NEW should not work on clusters/records in that collection

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

	// //THese commands will work on a collection that is set to read only
	// readOnlyPermissionReqCommands := []string{FETCH, COUNT, VALIDATE}


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
OST_OPERATION_IS_ALLOWED :: proc(
	permissionValue: string,
	operation: ^types.CommandOperation,
) -> bool {
	operationIsAllowed := false
	// fmt.println("Permission Value from collection file: ", permissionValue) //debugging
	for i := 0; i < len(operation.permissionStr); i += 1 {
		// fmt.println("This operation can be performed on a collection that is set to: ", perm) //debugging
		if permissionValue == operation.permissionStr[i] {
			operationIsAllowed = true
			break
		}
	}
	//DO NOT FREE or DELETE commandOperation here. Shit will break - Marshall
	return operationIsAllowed
}


//Handles all the logic from above and returns a 1 if the user does not have permission to perform the passed in operation
OST_PERFORM_PERMISSIONS_CHECK_ON_COLLECTION :: proc(command, colName: string) -> int {
	// fmt.println("Getting passed colName: ", colName) //debugging
	//Get the operation permission for the command
	commandOperation := OST_SET_OPERATION_PERMISSIONS(command)
	// fmt.println("commandOperation: ", commandOperation) //debugging
	//Get the string representation array of the permission
	commandPermissions := commandOperation.permissionStr
	// fmt.println("commandPermissions: ", commandPermissions) //debugging
	defer free(commandOperation)


	permissionValue, success := metadata.OST_GET_METADATA_VALUE(colName, "# Permission", 1)
	// fmt.println("Retrieved metadata Permission field successfully: ", success) //debugging
	// fmt.println("Permission Value from collection file: ", permissionValue) //debugging
	for perm in commandPermissions {
		// fmt.println("This operation can be performed on a collection that is set to: ", perm) //debugging
		opIsAllowed := OST_OPERATION_IS_ALLOWED(permissionValue, commandOperation)
		// fmt.println("opIsAllowed: ", opIsAllowed) //debugging
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
