package security

import "../../../utils"
import "../../const"
import "../../types"
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

	readWriteCommands := []string{ISOLATE, BACKUP, ERASE, RENAME, SET, PURGE, CHANGE_TYPE, LOCK}

	//THese commands will work on a collection that is set to read only
	readOnlyPermissionReqCommands := []string{FETCH, COUNT, VALIDATE}

	//The LOCK command can work in Read-Only and Read-Write mode
	//The UNLOCK command can only work on a collection that is set to Read-Only or Inaccessible


	for n in readWriteOrReadOnlyCommands {
		if opName == n {
			operation.name = n
			operation.permission = []types.Operation_Permssion_Requirement {
				types.Operation_Permssion_Requirement.READ_ONLY,
				types.Operation_Permssion_Requirement.READ_WRITE,
			}
			append(&opArr, "Read Only")
			append(&opArr, "Read Write")
			operation.permissionStr = opArr
			return operation
		}
	}


	for n in readWriteCommands {
		if opName == n {
			operation.name = n
			operation.permission = []types.Operation_Permssion_Requirement {
				types.Operation_Permssion_Requirement.READ_WRITE,
			}
			append(&opArr, "Read Write")
			operation.permissionStr = opArr
			return operation
		}
	}

	for n in readOnlyPermissionReqCommands {
		if opName == n {
			operation.name = n
			operation.permission = []types.Operation_Permssion_Requirement {
				types.Operation_Permssion_Requirement.READ_ONLY,
			}
			append(&opArr, "Read Only")
			operation.permissionStr = opArr
			return operation
		}
	}

	if opName == UNLOCK {
		operation.name = UNLOCK
		operation.permission = []types.Operation_Permssion_Requirement {
			types.Operation_Permssion_Requirement.READ_ONLY,
			types.Operation_Permssion_Requirement.INACCESSABLE,
		}
		append(&opArr, "Read Only")
		append(&opArr, "Inaccessible")
		operation.permissionStr = opArr
		return operation
	}

	return operation
}


//Checks if an the passed in operation can be performed via the command line
// permissionValue - the value from the metadata header field labeled: "Permission"
// ^types.CommandOperation - the name of the operation and the permissions said operation requires
OST_CROSS_CHECK_OPERATION_PERMISSIONS :: proc(
	permissionValue: string,
	operation: ^types.CommandOperation,
) -> bool {
	accessAllowed := true
	// fmt.println("Permission Value from collection file: ", permissionValue) //debugging
	for perm in operation.permissionStr {
		if permissionValue != perm {
			accessAllowed = false
			break
		}
	}
	// delete(operation.permissionStr)
	return accessAllowed
}
