package utils
import "../core/types"
import "core:fmt"
import "core:os"
import "core:strings"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
*********************************************************/

ErrorType :: enum {
	NO_ERROR,
	//General File Errors
	CANNOT_CREATE_FILE,
	CANNOT_OPEN_FILE,
	CANNOT_READ_FILE,
	CANNOT_UPDATE_FILE, //rarely used. see 1 usage in metadata.odin
	CANNOT_WRITE_TO_FILE,
	CANNOT_CLOSE_FILE,
	CANNOT_DELETE_FILE,
	FILE_ALREADY_EXISTS,
	//Directory Errors
	CANNOT_OPEN_DIRECTORY,
	CANNOT_READ_DIRECTORY,
	CANNOT_CREATE_DIRECTORY,
	//Cluster Errors
	INVALID_CLUSTER_STRUCTURE,
	CANNOT_CREATE_CLUSTER,
	CANNOT_FIND_CLUSTER,
	CANNOT_DELETE_CLUSTER,
	CANNOT_READ_CLUSTER,
	CANNOT_UPDATE_CLUSTER,
	CANNOT_APPEND_CLUSTER, //to a file
	//Record Errors
	INVALID_RECORD_DATA,
	CANNOT_CREATE_RECORD,
	CANNOT_FIND_RECORD,
	CANNOT_DELETE_RECORD,
	CANNOT_READ_RECORD,
	CANNOT_UPDATE_RECORD,
	CANNOT_APPEND_RECORD, //to a cluster within a file
	//Input Error
	CANNOT_READ_INPUT,
	//Signup Errors
	USERNAME_ALREADY_EXISTS,
	INVALID_USERNAME,
	PASSWORD_TOO_SHORT,
	PASSWORD_TOO_LONG,
	WEAK_PASSWORD,
	PASSWORDS_DO_NOT_MATCH,
	//Auth Errors
	INCORRECT_USERNAME_ENTERED,
	INCORRECT_PASSWORD_ENTERED,
	ENTERED_USERNAME_NOT_FOUND,
	//command ERRORS
	INCOMPLETE_COMMAND,
	INVALID_COMMAND,
	COMMAND_TOO_LONG, //??? idk
	CANNOT_PURGE_HISTORY,
	//Data Integrity Errors
	FILE_SIZE_TOO_LARGE,
	FILE_FORMAT_NOT_VALID,
	FILE_FORMAT_VERSION_NOT_SUPPORTED,
	CLUSTER_IDS_NOT_VALID,
	INVALID_CHECKSUM,
	INVALID_DATA_TYPE_FOUND,
	INVALID_VALUE_FOR_EXPECTED_TYPE,


	//Miscellaneous
	INVALID_INPUT,
}

Error :: struct {
	type:      ErrorType,
	message:   string, //The message that the error displays/logs
	procedure: string, //the procedure that the error occurred in
}

ERROR_MESSAGE := [ErrorType]string {
	.NO_ERROR                          = "No Error",
	.CANNOT_CREATE_FILE                = "Cannot Create File",
	.CANNOT_OPEN_FILE                  = "Cannot Open File",
	.CANNOT_READ_FILE                  = "Cannot Read File",
	.CANNOT_UPDATE_FILE                = "Cannot Update File",
	.CANNOT_WRITE_TO_FILE              = "Cannot Write To File",
	.CANNOT_CLOSE_FILE                 = "Cannot Close File",
	.CANNOT_DELETE_FILE                = "Cannot Delete File",
	.FILE_ALREADY_EXISTS               = "File Already Exists",
	.CANNOT_OPEN_DIRECTORY             = "Cannot Open Directory",
	.CANNOT_READ_DIRECTORY             = "Cannot Read Files In Directory",
	.CANNOT_CREATE_DIRECTORY           = "Cannot Create Directory",
	.INVALID_CLUSTER_STRUCTURE         = "Invalid Cluster Structure Detected",
	.CANNOT_CREATE_CLUSTER             = "Cannot Create Cluster",
	.CANNOT_FIND_CLUSTER               = "Cannot Find Cluster",
	.CANNOT_DELETE_CLUSTER             = "Cannot Delete Cluster",
	.CANNOT_READ_CLUSTER               = "Cannot Read Cluster",
	.CANNOT_UPDATE_CLUSTER             = "Cannot Update Cluster",
	.CANNOT_APPEND_CLUSTER             = "Cannot Append Cluster",
	.INVALID_RECORD_DATA               = "Invalid Record Data",
	.CANNOT_CREATE_RECORD              = "Cannot Create Record",
	.CANNOT_FIND_RECORD                = "Cannot Find Record",
	.CANNOT_DELETE_RECORD              = "Cannot Delete Record",
	.CANNOT_READ_RECORD                = "Cannot Read Record",
	.CANNOT_UPDATE_RECORD              = "Cannot Update Record",
	.CANNOT_APPEND_RECORD              = "Cannot Append Record",
	.CANNOT_READ_INPUT                 = "Cannot Read Input",
	.USERNAME_ALREADY_EXISTS           = "Entered Username Already Exists",
	.INVALID_USERNAME                  = "Invalid Username",
	.PASSWORD_TOO_SHORT                = "Entered Password Too Short",
	.PASSWORD_TOO_LONG                 = "Entered Password Too Long",
	.WEAK_PASSWORD                     = "Weak Password Detected",
	.PASSWORDS_DO_NOT_MATCH            = "Entered Passwords Do Not Match",
	.INCORRECT_USERNAME_ENTERED        = "Incorrect Username Entered",
	.INCORRECT_PASSWORD_ENTERED        = "Incorrect Password Entered",
	.ENTERED_USERNAME_NOT_FOUND        = "Entered Username Was Not Found",
	.INCOMPLETE_COMMAND                = "Incomplete Command",
	.INVALID_COMMAND                   = "Invalid Command",
	.COMMAND_TOO_LONG                  = "Command Too Long",
	.INVALID_INPUT                     = "Invalid Input",
	.FILE_SIZE_TOO_LARGE               = "Collection File Size Is Too Large",
	.FILE_FORMAT_NOT_VALID             = "Collection File Formatting Is Not Valid",
	.FILE_FORMAT_VERSION_NOT_SUPPORTED = "Collection File Format Version Is Not Supported",
	.CLUSTER_IDS_NOT_VALID             = "Cluster IDs Found In Collection Do Not Match Valid Cluster IDs",
	.INVALID_CHECKSUM                  = "Checksum mismatch. File may be corrupt",
	.INVALID_DATA_TYPE_FOUND           = "Invalid Data Type(s) Found In Collection",
	.INVALID_VALUE_FOR_EXPECTED_TYPE   = "An invalid value was given for the expected type",
	.CANNOT_PURGE_HISTORY              = "Cannot Purge Users History Cluster",
}

new_err :: proc(type: ErrorType, message: string, procedure: string) -> Error {
	return Error{type = type, message = message, procedure = procedure}
}

get_err_msg :: proc(type: ErrorType) -> string {
	return strings.clone(ERROR_MESSAGE[type])
}

throw_err :: proc(err: Error) -> int {
	if types.errSupression.enabled { 	//if error supression is off return
		return 0
	} else {
		fmt.printfln("%s%s[ERROR ERROR ERROR ERROR]%s", RED, BOLD, RESET)
		fmt.printfln(
			"ERROR%s occured in procedure: [%s%s%s]\nInternal Error Type: %s[%v]%s\nError Message: [%s%s%s]",
			RESET,
			BOLD,
			err.procedure,
			RESET,
			BOLD,
			err.type,
			RESET,
			BOLD,
			err.message,
			RESET,
		)
		return 1
	}
}

//allows for more customization of error messages.
//the custom err message that is passed is the same as the err message in the print statement
throw_custom_err :: proc(err: Error, custom_message: string) -> int {
	if types.errSupression.enabled {
		return 0
	} else {
		fmt.printfln("%s%s[ERROR ERROR ERROR ERROR]%s", RED, BOLD, RESET)
		fmt.printfln(
			"ERROR%s occured in procedure: [%s%s%s]\nInternal Error Type: %s[%v]%s\nError Message: [%s%s%s]",
			RESET,
			BOLD,
			err.procedure,
			RESET,
			BOLD,
			err.type,
			RESET,
			BOLD,
			custom_message,
			RESET,
		)
		return 1
	}
}

/*
Example Error Usage:

    error2:= new_err(.ENTERED_USERNAME_NOT_FOUND, get_err_msg(.ENTERED_USERNAME_NOT_FOUND), #procedure)
    throw_err(error2)
*/
