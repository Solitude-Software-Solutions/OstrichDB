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
RUN_USER_SIGNIN :: proc() -> bool {
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
	secCollectionFound, userSecCollection := data.FIND_SECURE_COLLECTION(usernameCapitalized)
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
	decSuccess, _ := DECRYPT_COLLECTION(
		usernameCapitalized,
		.SECURE_PRIVATE,
		types.system_user.m_k.valAsBytes,
	)

	userRole := data.GET_RECORD_VALUE(secCollection, usernameCapitalized, "identifier", "role")
	if userRole == "admin" {
		user.role.Value = "admin"
	} else if userRole == "user" {
		user.role.Value = "user"
	} else if userRole == "guest" {
		user.role.Value = "guest"
	}

	//Voodoo??
	userMKStr := data.GET_RECORD_VALUE(secCollection, usernameCapitalized, "identifier", "m_k")
	user.m_k.valAsBytes = DECODE_MASTER_KEY(transmute([]byte)userMKStr)
	user.username.Value = strings.clone(usernameCapitalized)

	//PRE-MESHING START=======================================================================================================
	//get the salt from the cluster that contains the entered username
	salt := data.GET_RECORD_VALUE(secCollection, usernameCapitalized, "identifier", "salt")

	//get the value of the hash that is currently stored in the cluster that contains the entered username
	providedHash := data.GET_RECORD_VALUE(secCollection, usernameCapitalized, "identifier", "hash")
	pHashAsBytes := transmute([]u8)providedHash


	preMesh := MESH_SALT_AND_HASH(salt, pHashAsBytes)
	//PRE-MESHING END=========================================================================================================
	algoMethod := data.GET_RECORD_VALUE(
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
	newHash := HASH_PASSWORD(enteredPassword, algoAsInt, true, false)
	encodedHash := ENCODE_HASHED_PASSWORD(newHash)
	postMesh := MESH_SALT_AND_HASH(salt, encodedHash)
	//POST-MESHING END=========================================================================================================
	authPassed := CROSS_CHECK_MESH(preMesh, postMesh)
	switch authPassed {
	case true:
		fmt.printfln("\n\n%sSucessfully signed in!%s", GREEN, RESET)
		fmt.printfln("Welcome, %s%s%s!\n", BOLD_UNDERLINE, usernameCapitalized, RESET)
		USER_SIGNIN_STATUS = true
		current_user.username.Value = strings.clone(usernameCapitalized) //set the current user to the user that just signed in for HISTORY command reasons
		current_user.role.Value = strings.clone(userRole)

		userLoggedInValue := data.GET_RECORD_VALUE(
			CONFIG_PATH,
			CONFIG_CLUSTER,
			Token[.BOOLEAN],
			USER_LOGGED_IN,
		)

		//Master Key shit
		mkValueRead := data.GET_RECORD_VALUE(
			secCollection,
			usernameCapitalized,
			"identifier",
			"m_k",
		)

		// mkValueAsBytes := security.OST_M_K_STIRNG_TO_BYTE(mkValueRead)
		current_user.m_k.valAsStr = user.m_k.valAsStr
		current_user.m_k.valAsBytes = user.m_k.valAsBytes


		if userLoggedInValue == "false" {
			// config.OST_TOGGLE_CONFIG(const.USER_LOGGED_IN)
			config.UPDATE_CONFIG_VALUE(const.USER_LOGGED_IN, "true")
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
		RUN_USER_SIGNIN()

	}
	ENCRYPT_COLLECTION(
		usernameCapitalized,
		.SECURE_PRIVATE,
		types.system_user.m_k.valAsBytes,
		false,
	)
	return USER_SIGNIN_STATUS

}

//meshes the salt and hashed password , returns the mesh
// s- salt , hp- hashed password
MESH_SALT_AND_HASH :: proc(s: string, hp: []u8) -> string {
	mesh: string
	hpStr := transmute(string)hp
	mesh = strings.concatenate([]string{s, hpStr})
	return strings.clone(mesh)
}

//checks if the users information does exist in the user credentials file
//cn- cluster name, un- username, s-salt , hp- hashed password
CROSS_CHECK_MESH :: proc(preMesh: string, postMesh: string) -> bool {
	if preMesh == postMesh {
		return true
	}

	utils.log_err("Pre & post password mesh's did not match during authentication", #procedure)
	return false
}

//Handles logic for signing out a user and exiting the program
//param - 0 for logging out and staying in the program, 1 for logging out and exiting the program
RUN_USER_LOGOUT :: proc(param: int) {
	security.DECRYPT_COLLECTION("", .CONFIG_PRIVATE, types.system_user.m_k.valAsBytes)
	loggedOut := config.UPDATE_CONFIG_VALUE(const.USER_LOGGED_IN, "false")

	switch loggedOut {
	case true:
		switch (param) 
		{
		case 0:
			//Logging out but keeps program running
			ENCRYPT_COLLECTION("", .CONFIG_PRIVATE, types.system_user.m_k.valAsBytes, false)
			types.USER_SIGNIN_STATUS = false
			fmt.printfln("You have been logged out.")
		case 1:
			//Exiting
			ENCRYPT_COLLECTION("", .CONFIG_PRIVATE, types.system_user.m_k.valAsBytes, false)
			fmt.printfln("You have been logged out.")
			fmt.println("Now Exiting OstrichDB See you soon!\n")
			os.exit(0)
		}
		break
	case false:
		ENCRYPT_COLLECTION("", .CONFIG_PRIVATE, types.system_user.m_k.valAsBytes, false)
		types.USER_SIGNIN_STATUS = true
		fmt.printfln("You have NOT been logged out.")
		break
	}
}


//shorter version of sign in but exclusively for checking passwords for certain db actions
VALIDATE_USER_PASSWORD :: proc(input: string) -> bool {
	succesfulValidation := false
	secCollection := utils.concat_secure_collection_name(types.user.username.Value)

	//PRE-MESHING START
	salt := data.GET_RECORD_VALUE(secCollection, types.user.username.Value, "identifier", "salt")
	//get the value of the hash that is currently stored in the cluster that contains the entered username
	providedHash := data.GET_RECORD_VALUE(
		secCollection,
		types.user.username.Value,
		"identifier",
		"hash",
	)
	pHashAsBytes := transmute([]u8)providedHash
	premesh := MESH_SALT_AND_HASH(salt, pHashAsBytes)
	//PRE-MESHING END


	algoMethod := data.GET_RECORD_VALUE(
		secCollection,
		types.user.username.Value,
		"identifier",
		"store_method",
	)

	//POST-MESHING START
	//convert the return algo method string to an int
	algoAsInt := strconv.atoi(algoMethod)

	//using the hasing algo from the cluster that contains the entered username, hash the entered password
	newHash := HASH_PASSWORD(string(input), algoAsInt, true, false)
	encodedHash := ENCODE_HASHED_PASSWORD(newHash)
	postmesh := MESH_SALT_AND_HASH(salt, encodedHash)
	//POST-MESHING END

	authPassed := CROSS_CHECK_MESH(premesh, postmesh)
	switch authPassed {
	case true:
		succesfulValidation = true

	case false:
		succesfulValidation = false
		break
	}
	return succesfulValidation

}
