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
	fmt.printfln("Please enter your %susername%s:", BOLD, RESET)
	n := get_input(false)

	userName := n
	if len(userName) == 0 {
		fmt.printfln("Username cannot be empty. Please try again.")
		log_err("User did not provide a username during authentication", #procedure)
		log_runtime_event("Blank username", "User did not provide a username duing authentication")
		return false
	}
	usernameCapitalized := strings.to_upper(userName)
	secCollectionFound, userSecCollection := data.OST_FIND_SEC_COLLECTION(usernameCapitalized)
	if secCollectionFound == false {
		fmt.println(
			"There is no account within OstrichDB associated with the entered username. Please try again.",
		)
		log_runtime_event(
			"Invalid username provided",
			"Invalid username entered during authentication",
		)
		log_err("User entered a username that does not exist in the database", #procedure)
		return false
	}

	secCollection := utils.concat_secure_collection_name(userName)

	//decrypt the user secure collection
	decSuccess, _ := OST_DECRYPT_COLLECTION(
		usernameCapitalized,
		.SECURE_PRIVATE,
		types.system_user.m_k.valAsBytes,
	)

	userRole := data.OST_READ_RECORD_VALUE(
		secCollection,
		usernameCapitalized,
		"identifier",
		"role",
	)
	if userRole == "admin" {
		user.role.Value = "admin"
	} else if userRole == "user" {
		user.role.Value = "user"
	} else if userRole == "guest" {
		user.role.Value = "guest"
	}

	//Voodoo??
	userMKStr := data.OST_READ_RECORD_VALUE(
		secCollection,
		usernameCapitalized,
		"identifier",
		"m_k",
	)
	user.m_k.valAsBytes = OST_DECODE_M_K(transmute([]byte)userMKStr)
	user.username.Value = strings.clone(usernameCapitalized)

	//PRE-MESHING START=======================================================================================================
	//get the salt from the cluster that contains the entered username
	salt := data.OST_READ_RECORD_VALUE(secCollection, usernameCapitalized, "identifier", "salt")

	//get the value of the hash that is currently stored in the cluster that contains the entered username
	providedHash := data.OST_READ_RECORD_VALUE(
		secCollection,
		usernameCapitalized,
		"identifier",
		"hash",
	)
	pHashAsBytes := transmute([]u8)providedHash


	preMesh := OST_MESH_SALT_AND_HASH(salt, pHashAsBytes)
	//PRE-MESHING END=========================================================================================================
	algoMethod := data.OST_READ_RECORD_VALUE(
		secCollection,
		usernameCapitalized,
		"identifier",
		"store_method",
	)
	//POST-MESHING START=======================================================================================================

	//get the password input from the user
	fmt.printfln("Please enter your %spassword%s:", BOLD, RESET)
	libc.system("stty -echo")
	n = get_input(true)

	enteredPassword := n
	libc.system("stty echo")

	if len(enteredPassword) == 0 {
		fmt.printfln("Password cannot be empty. Please try again.")
		log_err("User did not provide a password during authentication", #procedure)
		log_runtime_event(
			"Blank password provided",
			"User did not provide a password during authentication",
		)
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
		fmt.printfln("\n\n%sSucessfully signed in!%s", GREEN, RESET)
		fmt.printfln("Welcome, %s%s%s!\n", BOLD_UNDERLINE, usernameCapitalized, RESET)
		USER_SIGNIN_STATUS = true
		current_user.username.Value = strings.clone(usernameCapitalized) //set the current user to the user that just signed in for HISTORY command reasons
		current_user.role.Value = strings.clone(userRole)

		userLoggedInValue := data.OST_READ_RECORD_VALUE(
			OST_CONFIG_PATH,
			CONFIG_CLUSTER,
			Token[.BOOLEAN],
			CONFIG_THREE,
		)

		//Master Key shit
		mkValueRead := data.OST_READ_RECORD_VALUE(
			secCollection,
			usernameCapitalized,
			"identifier",
			"m_k",
		)

		// mkValueAsBytes := security.OST_M_K_STIRNG_TO_BYTE(mkValueRead)
		current_user.m_k.valAsStr = user.m_k.valAsStr
		current_user.m_k.valAsBytes = user.m_k.valAsBytes


		if userLoggedInValue == "false" {
			// config.OST_TOGGLE_CONFIG(const.CONFIG_THREE)
			config.OST_UPDATE_CONFIG_VALUE(const.CONFIG_THREE, "true")
		}
		break
	case false:
		fmt.printfln("%sAuth Failed. Password was incorrect please try again.%s", RED, RESET)
		types.USER_SIGNIN_STATUS = false
		log_runtime_event(
			"Authentication failed",
			"User entered incorrect password during authentication",
		)
		log_err("User failed to authenticate with the provided credentials", #procedure)
		OST_RUN_SIGNIN()

	}
	OST_ENCRYPT_COLLECTION(
		usernameCapitalized,
		.SECURE_PRIVATE,
		types.system_user.m_k.valAsBytes,
		false,
	)
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

	utils.log_err("Pre & post password mesh's did not match during authentication", #procedure)
	return false
}

//Handles logic for signing out a user and exiting the program
//param - 0 for logging out and staying in the program, 1 for logging out and exiting the program
OST_USER_LOGOUT :: proc(param: int) {
	security.OST_DECRYPT_COLLECTION("", .CONFIG_PRIVATE, types.system_user.m_k.valAsBytes)
	loggedOut := config.OST_UPDATE_CONFIG_VALUE(const.CONFIG_THREE, "false")

	switch loggedOut {
	case true:
		switch (param)
		{
		case 0:
		    //Logging out but keeps program running
			OST_ENCRYPT_COLLECTION("", .CONFIG_PRIVATE, types.system_user.m_k.valAsBytes, false)
			types.USER_SIGNIN_STATUS = false
			fmt.printfln("You have been logged out.")
		case 1:
		    //Exiting
			OST_ENCRYPT_COLLECTION("", .CONFIG_PRIVATE, types.system_user.m_k.valAsBytes, false)
			fmt.printfln("You have been logged out.")
			fmt.println("Now Exiting OstrichDB See you soon!\n")
			os.exit(0)
		}
		break
	case false:
		OST_ENCRYPT_COLLECTION("", .CONFIG_PRIVATE, types.system_user.m_k.valAsBytes, false)
		types.USER_SIGNIN_STATUS = true
		fmt.printfln("You have NOT been logged out.")
		break
	}
}


//shorter version of sign in but exclusively for checking passwords for certain db actions
OST_VALIDATE_USER_PASSWORD :: proc(input: string) -> bool {
	succesfulValidation := false
	secCollection := utils.concat_secure_collection_name(types.user.username.Value)

	//PRE-MESHING START
	salt := data.OST_READ_RECORD_VALUE(
		secCollection,
		types.user.username.Value,
		"identifier",
		"salt",
	)
	//get the value of the hash that is currently stored in the cluster that contains the entered username
	providedHash := data.OST_READ_RECORD_VALUE(
		secCollection,
		types.user.username.Value,
		"identifier",
		"hash",
	)
	pHashAsBytes := transmute([]u8)providedHash
	premesh := OST_MESH_SALT_AND_HASH(salt, pHashAsBytes)
	//PRE-MESHING END


	algoMethod := data.OST_READ_RECORD_VALUE(
		secCollection,
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
