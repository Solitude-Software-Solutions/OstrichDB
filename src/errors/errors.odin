package errors

import "../misc"
import "core:fmt"
import "core:os"

//=========================================================//
//Author: Marshall Burns aka @SchoolyB
//Desc: This file contains helper functions for error handling
//=========================================================//
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
	PASSWORD_TO_SHORT,
	PASSWORD_TO_LONG,
	WEAK_PASSWORD,
	PASSWORDS_DO_NOT_MATCH,
	//Auth Errors
	INCORRECT_USERNAME_ENTERED,
	INCORRECT_PASSWORD_ENTERED,
	ENTERED_USERNAME_NOT_FOUND,
	//COMMNAD ERRORS
	INCOMPLETE_COMMAND,
	INVALID_COMMAND,
	COMMAND_TOO_LONG, //??? idk
}

Error :: struct {
	type:      ErrorType,
	message:   string, //The message that the error displays/logs
	procedure: string, //the procedure that the error occurred in
}

ERROR_MESSAGE := [ErrorType]string {
	.NO_ERROR                   = "No Error",
	.CANNOT_CREATE_FILE         = "Cannot Create File",
	.CANNOT_OPEN_FILE           = "Cannot Open File",
	.CANNOT_READ_FILE           = "Cannot Read File",
	.CANNOT_UPDATE_FILE         = "Cannot Update File",
	.CANNOT_WRITE_TO_FILE       = "Cannot Write To File",
	.CANNOT_CLOSE_FILE          = "Cannot Close File",
	.CANNOT_DELETE_FILE         = "Cannot Delete File",
	.FILE_ALREADY_EXISTS        = "File Already Exists",
	.CANNOT_OPEN_DIRECTORY      = "Cannot Open Directory",
	.CANNOT_READ_DIRECTORY      = "Cannot Read Files In Directory",
	.CANNOT_CREATE_DIRECTORY    = "Cannot Create Directory",
	.INVALID_CLUSTER_STRUCTURE  = "Invalid Cluster Structure Detected",
	.CANNOT_CREATE_CLUSTER      = "Cannot Create Cluster",
	.CANNOT_FIND_CLUSTER        = "Cannot Find Cluster",
	.CANNOT_DELETE_CLUSTER      = "Cannot Delete Cluster",
	.CANNOT_READ_CLUSTER        = "Cannot Read Cluster",
	.CANNOT_UPDATE_CLUSTER      = "Cannot Update Cluster",
	.CANNOT_APPEND_CLUSTER      = "Cannot Append Cluster",
	.INVALID_RECORD_DATA        = "Invalid Record Data",
	.CANNOT_CREATE_RECORD       = "Cannot Create Record",
	.CANNOT_FIND_RECORD         = "Cannot Find Record",
	.CANNOT_DELETE_RECORD       = "Cannot Delete Record",
	.CANNOT_READ_RECORD         = "Cannot Read Record",
	.CANNOT_UPDATE_RECORD       = "Cannot Update Record",
	.CANNOT_APPEND_RECORD       = "Cannot Append Record",
	.CANNOT_READ_INPUT          = "Cannot Read Input",
	.USERNAME_ALREADY_EXISTS    = "Entered Username Already Exists",
	.INVALID_USERNAME           = "Invalid Username",
	.PASSWORD_TO_SHORT          = "Entered Password Too Short",
	.PASSWORD_TO_LONG           = "Entered Password Too Long",
	.WEAK_PASSWORD              = "Weak Password Detected",
	.PASSWORDS_DO_NOT_MATCH     = "Entered Passwords Do Not Match",
	.INCORRECT_USERNAME_ENTERED = "Incorrect Username Entered",
	.INCORRECT_PASSWORD_ENTERED = "Incorrect Password Entered",
	.ENTERED_USERNAME_NOT_FOUND = "Entered Username Was Not Found",
	.INCOMPLETE_COMMAND         = "Incomplete Command",
	.INVALID_COMMAND            = "Invalid Command",
	.COMMAND_TOO_LONG           = "Command Too Long",
}

new_err :: proc(type: ErrorType, message: string, procedure: string) -> Error {
	return Error{type = type, message = message, procedure = procedure}
}

get_err_msg :: proc(type: ErrorType) -> string {
	return ERROR_MESSAGE[type]
}

throw_err :: proc(err: Error) -> string {
	return fmt.tprintf(
		"ERROR occured in procedure: %s%s%s\nError Type: %s(%v)%s\nError Message: %s%s%s ",
		misc.BOLD,
		err.procedure,
		misc.RESET,
		misc.BOLD,
		err.type,
		misc.RESET,
		misc.BOLD,
		err.message,
		misc.RESET,
	)
}

throw_custom_err :: proc(err: Error, custom_message: string) -> string {
	return fmt.tprintf(
		"ERROR occured in procedure: %s%s%s\nError Type: %s(%v)%s\nError Message: %s%s%s\nCustom Message: %s%s%s",
		misc.BOLD,
		err.procedure,
		misc.RESET,
		misc.BOLD,
		err.type,
		misc.RESET,
		misc.BOLD,
		err.message,
		misc.RESET,
		misc.BOLD,
		custom_message,
		misc.RESET,
	)
}

/*

Example Error Usahe:

    error2:= errors.new_err(.ENTERED_USERNAME_NOT_FOUND, errors.get_err_msg(.ENTERED_USERNAME_NOT_FOUND), #procedure)
    errors.throw_err(error2)
*/
