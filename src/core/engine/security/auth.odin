package security

import "../../../utils"
import "../../const"
import "../../types"
import "../config"
import "../data"
import "../data/metadata"
import "../security"
import "core:bytes"
import "core:c/libc"
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
            Contains logic for handling user authentication.
*********************************************************/

//This beffy S.O.B handles user authentication
OST_RUN_SIGNIN :: proc() -> bool {
	using const
	using types
	using utils

	//get the username input from the user
	buf: [1024]byte
	fmt.printfln("Please enter your %susername%s:", BOLD, RESET)
	n, inputSuccess := os.read(os.stdin, buf[:])

	if inputSuccess != 0 {
		error1 := new_err(
			.CANNOT_READ_INPUT,
			get_err_msg(.CANNOT_READ_INPUT),
			#file,
			#procedure,
			#line,
		)
		throw_err(error1)
		log_err("Could not read user input during sign in", #procedure)
		return false
	}

	userName := strings.trim_right(string(buf[:n]), "\r\n")
	if len(userName) == 0 {
		fmt.printfln("Username cannot be empty. Please try again.")
		return false
	}
	usernameCapitalized := strings.to_upper(userName)

	found, userSecCollection := data.OST_FIND_SEC_COLLECTION(usernameCapitalized)
	if !found {
		fmt.printfln(
			"There is no account within OstrichDB associated with the entered username. Please try again.",
		)
		log_err("User entered a username that does not exist in the database", #procedure)
		return false
	}
	secColPath := fmt.tprintf(
		"%ssecure_%s%s",
		OST_SECURE_COLLECTION_PATH,
		userName,
		OST_FILE_EXTENSION,
	)

	//decrypt the user secure collection
	OST_DECRYPT_COLLECTION(usernameCapitalized, .SECURE_PRIVATE, types.system_user.m_k.valAsBytes)

	userNameFound := data.OST_READ_RECORD_VALUE(
		secColPath,
		usernameCapitalized,
		"identifier",
		"user_name",
	)
	userRole := data.OST_READ_RECORD_VALUE(secColPath, usernameCapitalized, "identifier", "role")
	if userRole == "admin" {
		user.role.Value = "admin"
	} else if userRole == "user" {
		user.role.Value = "user"
	} else if userRole == "guest" {
		user.role.Value = "guest"
	}

	if (userNameFound != usernameCapitalized) {
		error2 := new_err(
			.ENTERED_USERNAME_NOT_FOUND,
			get_err_msg(.ENTERED_USERNAME_NOT_FOUND),
			#file,
			#procedure,
			#line,
		)
		throw_err(error2)
		fmt.printfln(
			"There is no account within OstrichDB associated with the entered username. Please try again.",
		)
		log_err("User entered a username that does not exist in the database", #procedure)
		return false
	}

	user.username.Value = strings.clone(usernameCapitalized)

	//PRE-MESHING START=======================================================================================================
	//get the salt from the cluster that contains the entered username
	salt := data.OST_READ_RECORD_VALUE(secColPath, usernameCapitalized, "identifier", "salt")

	//get the value of the hash that is currently stored in the cluster that contains the entered username
	providedHash := data.OST_READ_RECORD_VALUE(
		secColPath,
		usernameCapitalized,
		"identifier",
		"hash",
	)
	pHashAsBytes := transmute([]u8)providedHash


	preMesh := OST_MESH_SALT_AND_HASH(salt, pHashAsBytes)
	//PRE-MESHING END=========================================================================================================
	algoMethod := data.OST_READ_RECORD_VALUE(
		secColPath,
		usernameCapitalized,
		"identifier",
		"store_method",
	)
	//POST-MESHING START=======================================================================================================

	//get the password input from the user
	fmt.printfln("Please enter your %spassword%s:", BOLD, RESET)
	libc.system("stty -echo")
	n, inputSuccess = os.read(os.stdin, buf[:])
	if inputSuccess != 0 {
		error3 := new_err(
			.CANNOT_READ_INPUT,
			get_err_msg(.CANNOT_READ_INPUT),
			#file,
			#procedure,
			#line,
		)
		throw_err(error3)
		log_err("Could not read user input during sign in", #procedure)
		libc.system("stty echo")
		return false
	}
	enteredPassword := strings.trim_right(string(buf[:n]), "\r\n")
	libc.system("stty echo")

	if len(enteredPassword) == 0 {
		fmt.printfln("Password cannot be empty. Please try again.")
		return false
	}

	//conver the return algo method string to an int
	algoAsInt := strconv.atoi(algoMethod)

	//using the hasing algo from the cluster that contains the entered username, hash the entered password
	newHash := OST_HASH_PASSWORD(enteredPassword, algoAsInt, true, false)
	encodedHash := OST_ENCODE_HASHED_PASSWORD(newHash)
	postMesh := OST_MESH_SALT_AND_HASH(salt, encodedHash)
	//POST-MESHING END=========================================================================================================
	authPassed := OST_CROSS_CHECK_MESH(preMesh, postMesh)
	switch authPassed {
	case true:
		OST_START_SESSION_TIMER()
		fmt.printfln("\n\n%sSucessfully signed in!%s", GREEN, RESET)
		fmt.printfln("Welcome, %s%s%s!\n", BOLD_UNDERLINE, userNameFound, RESET)
		USER_SIGNIN_STATUS = true
		current_user.username.Value = strings.clone(userNameFound) //set the current user to the user that just signed in for HISTORY command reasons
		current_user.role.Value = strings.clone(userRole)
		userLoggedInValue := data.OST_READ_RECORD_VALUE(
			OST_CONFIG_PATH,
			CONFIG_CLUSTER,
			BOOLEAN,
			CONFIG_THREE,
		)

		//Master Key shit
		mkValueRead := data.OST_READ_RECORD_VALUE(
			secColPath,
			usernameCapitalized,
			"identifier",
			"m_k",
		)

		mkValueAsBytes := security.OST_M_K_STIRNG_TO_BYTE(mkValueRead)
		current_user.m_k.valAsStr = strings.clone(mkValueRead)
		current_user.m_k.valAsBytes = mkValueAsBytes


		if userLoggedInValue == "false" {
			// config.OST_TOGGLE_CONFIG(const.CONFIG_THREE)
			config.OST_UPDATE_CONFIG_VALUE(const.CONFIG_THREE, "true")
		}
		break
	case false:
		fmt.printfln("%sAuth Failed. Password was incorrect please try again.%s", RED, RESET)
		types.USER_SIGNIN_STATUS = false
		OST_RUN_SIGNIN()

	}
	OST_ENCRYPT_COLLECTION(usernameCapitalized, .SECURE_PRIVATE, types.system_user.m_k.valAsBytes)
	return USER_SIGNIN_STATUS

}

//meshes the salt and hashed password , returns the mesh
// s- salt , hp- hashed password
OST_MESH_SALT_AND_HASH :: proc(s: string, hp: []u8) -> string {
	mesh: string
	hpStr := transmute(string)hp
	mesh = strings.concatenate([]string{s, hpStr})
	return strings.clone(mesh)
}

//checks if the users information does exist in the user credentials file
//cn- cluster name, un- username, s-salt , hp- hashed password
OST_CROSS_CHECK_MESH :: proc(preMesh: string, postMesh: string) -> bool {
	if preMesh == postMesh {
		return true
	}

	return false
}

//Handles logic for signing out a user
//param - 0 for logging out and staying in the program, 1 for logging out and exiting the program
OST_USER_LOGOUT :: proc(param: int) {
	loggedOut := config.OST_UPDATE_CONFIG_VALUE(const.CONFIG_THREE, "false")

	switch loggedOut {
	case true:
		switch (param) 
		{
		case 0:
			types.USER_SIGNIN_STATUS = false
			fmt.printfln("You have been logged out.")
			OST_STOP_SESSION_TIMER()
			libc.system("./main.bin")

		case 1:
			//only used when logging out AND THEN exiting.
			types.USER_SIGNIN_STATUS = false
			fmt.printfln("You have been logged out.")
			fmt.println("Now Exiting OstrichDB See you soon!\n")
			os.exit(0)
		}
		break
	case false:
		types.USER_SIGNIN_STATUS = true
		fmt.printfln("You have NOT been logged out.")
		break
	}
}


//shorter version of sign in but exclusively for checking passwords for certain db actions
OST_VALIDATE_USER_PASSWORD :: proc(input: string) -> bool {
	succesfulValidation := false

	secColPath := fmt.tprintf(
		"%ssecure_%s%s",
		const.OST_SECURE_COLLECTION_PATH,
		types.user.username.Value,
		const.OST_FILE_EXTENSION,
	)

	//PRE-MESHING START
	salt := data.OST_READ_RECORD_VALUE(secColPath, types.user.username.Value, "identifier", "salt")
	//get the value of the hash that is currently stored in the cluster that contains the entered username
	providedHash := data.OST_READ_RECORD_VALUE(
		secColPath,
		types.user.username.Value,
		"identifier",
		"hash",
	)
	pHashAsBytes := transmute([]u8)providedHash
	premesh := OST_MESH_SALT_AND_HASH(salt, pHashAsBytes)
	//PRE-MESHING END


	algoMethod := data.OST_READ_RECORD_VALUE(
		secColPath,
		types.user.username.Value,
		"identifier",
		"store_method",
	)

	//POST-MESHING START
	//convert the return algo method string to an int
	algoAsInt := strconv.atoi(algoMethod)

	//using the hasing algo from the cluster that contains the entered username, hash the entered password
	newHash := OST_HASH_PASSWORD(string(input), algoAsInt, true, false)
	encodedHash := OST_ENCODE_HASHED_PASSWORD(newHash)
	postmesh := OST_MESH_SALT_AND_HASH(salt, encodedHash)
	//POST-MESHING END

	authPassed := OST_CROSS_CHECK_MESH(premesh, postmesh)
	switch authPassed {
	case true:
		succesfulValidation = true

	case false:
		succesfulValidation = false
		break
	}
	return succesfulValidation

}
