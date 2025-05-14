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
	userNameInput := get_input(false)
	defer delete(userNameInput)

	userNameInput = strings.to_upper(userNameInput)
	if len(userNameInput) == 0 {
		fmt.printfln("Username cannot be empty. Please try again.")
		log_err("User did not provide a username during authentication", #procedure)
		log_runtime_event("Blank username", "User did not provide a username duing authentication")
		return false
	}


	//Check that a profile with the entered username exists
	profileFound:= FIND_USERS_PROFILE(userNameInput)
	if !profileFound{
	    fmt.println(
		"There is no account within OstrichDB associated with the entered username. Please try again.",)
		log_runtime_event(
		"Invalid username provided",
		"Invalid username entered during authentication",)
		log_err("User entered a username that does not exist in the database", #procedure)
	    return false
	}

	// Check that there is a user.credentials.ostrichdb file within it
	coreFileFound:= FIND_USERS_CORE_FILE(userNameInput,0)
	if !coreFileFound{
	    fmt.printfln(
		"A profile with the name %s was found but was missing a core file neccassary to authorize.",userNameInput)
		log_runtime_event(
		"Missing user.credential.ostrichdb core file",
		"Valid username but was missing user.credential.ostrichdb core file")
		log_err("User entered a valid username but OstrichDB could not find that users user.credential.ostrichdb file ", #procedure)
	    return false
	}

	usersCredentialFile := utils.concat_user_credential_path(userNameInput)

	// Decrypt and read that file to ensure there is a cluster with the entered userName
	TRY_TO_DECRYPT(userNameInput, .USER_CREDENTIALS_PRIVATE, system_user.m_k.valAsBytes)
    usersClusterExists := data.CHECK_IF_CLUSTER_EXISTS(usersCredentialFile, userNameInput )
    if !usersClusterExists{
        fmt.printfln(
		"An important cluster within a core file was not found. OstrichDB could not authroize you...",)
		log_runtime_event(
		"Cluster not found in user.credential.ostrichdb core file",
		"",)
		log_err("Cluster not found in user.credential.ostrichdb core file", #procedure)
	    return false
    }

	userRole := data.GET_RECORD_VALUE(usersCredentialFile, userNameInput, "identifier", "role")
	if userRole == "admin" {
		user.role.Value = "admin"
	} else if userRole == "user" {
		user.role.Value = "user"
	} else if userRole == "guest" {
		user.role.Value = "guest"
	}


	//Master Key shit
	userMKStr := data.GET_RECORD_VALUE(usersCredentialFile, userNameInput, "identifier", "m_k")
	user.m_k.valAsBytes = DECODE_MASTER_KEY(transmute([]byte)userMKStr)
	user.username.Value = strings.clone(userNameInput)
	current_user.m_k.valAsStr = user.m_k.valAsStr
	current_user.m_k.valAsBytes = user.m_k.valAsBytes



	//PRE-MESHING START=======================================================================================================
	//get the salt from the cluster that contains the entered username
	salt := data.GET_RECORD_VALUE(usersCredentialFile, userNameInput, "identifier", "salt")

	//get the value of the hash that is currently stored in the cluster that contains the entered username
	providedHash := data.GET_RECORD_VALUE(usersCredentialFile, userNameInput, "identifier", "hash")
	pHashAsBytes := transmute([]u8)providedHash


	preMesh := MESH_SALT_AND_HASH(salt, pHashAsBytes)
	//PRE-MESHING END=========================================================================================================
	algoMethod := data.GET_RECORD_VALUE(
		usersCredentialFile,
		userNameInput,
		"identifier",
		"store_method",
	)
	//POST-MESHING START=======================================================================================================
	//After storing values into the sessions memory, re-encrypt the user.credentials.ostrichdb file
	ENCRYPT_COLLECTION(userNameInput, .USER_CREDENTIALS_PRIVATE, system_user.m_k.valAsBytes,false)
		//get the password input from the user
	fmt.printfln("Please enter your %spassword%s:", BOLD, RESET)
	libc.system("stty -echo")
	passwordInput := get_input(true)
	defer delete(passwordInput)

	//Hide input
	libc.system("stty echo")

	if len(passwordInput) == 0 {
		fmt.printfln("Password cannot be empty. Please try again.")
		log_err("User did not provide a password during authentication", #procedure)
		log_runtime_event(
			"Blank password provided",
			"User did not provide a password during authentication",
		)
		return false
	}

	//convert the return algo method string to an int
	algoAsInt := strconv.atoi(algoMethod)

	//using the hasing algo from the cluster that contains the entered username, hash the entered password
	newHash := HASH_PASSWORD(passwordInput , algoAsInt, true, false)
	encodedHash := ENCODE_HASHED_PASSWORD(newHash)
	postMesh := MESH_SALT_AND_HASH(salt, encodedHash)
	//POST-MESHING END=========================================================================================================
	authPassed := CROSS_CHECK_MESH(preMesh, postMesh)
	switch authPassed {
	case true:
		fmt.printfln("\n\n%sSucessfully signed in!%s", GREEN, RESET)
		fmt.printfln("Welcome, %s%s%s!\n", BOLD_UNDERLINE, userNameInput, RESET)
		USER_SIGNIN_STATUS = true
		current_user.username.Value = strings.clone(userNameInput) //set the current user to the user that just signed in for HISTORY command reasons
		current_user.role.Value = strings.clone(userRole)

		//Look through the system config and set USER_LOGGED_IN val to true
		TRY_TO_DECRYPT("", .SYSTEM_CONFIG_PRIVATE, system_user.m_k.valAsBytes)
		userLoggedInValue := data.GET_RECORD_VALUE(
            SYSTEM_CONFIG_PATH,
            SYSTEM_CONFIG_CLUSTER,
			Token[.BOOLEAN],
			USER_LOGGED_IN,
		)

		if userLoggedInValue == "false" {
			config.UPDATE_CONFIG_VALUE(.SYSTEM_CONFIG_PRIVATE, USER_LOGGED_IN, "true")
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
	security.DECRYPT_COLLECTION("", .SYSTEM_CONFIG_PRIVATE, types.system_user.m_k.valAsBytes)
	loggedOut := config.UPDATE_CONFIG_VALUE(.SYSTEM_CONFIG_PRIVATE,const.USER_LOGGED_IN, "false")

	switch loggedOut {
	case true:
		switch (param)
		{
		case 0:
			//Logging out but keeps program running
			ENCRYPT_COLLECTION("", .SYSTEM_CONFIG_PRIVATE, types.system_user.m_k.valAsBytes, false)
			types.USER_SIGNIN_STATUS = false
			fmt.printfln("You have been logged out.")
		case 1:
			//Exiting
			ENCRYPT_COLLECTION("", .SYSTEM_CONFIG_PRIVATE, types.system_user.m_k.valAsBytes, false)
			fmt.printfln("You have been logged out.")
			fmt.println("Now Exiting OstrichDB See you soon!\n")
			os.exit(0)
		}
		break
	case false:
		ENCRYPT_COLLECTION("", .SYSTEM_CONFIG_PRIVATE, types.system_user.m_k.valAsBytes, false)
		types.USER_SIGNIN_STATUS = true
		fmt.printfln("You have NOT been logged out.")
		break
	}
}


//shorter version of sign in but exclusively for checking passwords for certain db actions
VALIDATE_USER_PASSWORD :: proc(input: string) -> bool {
	succesfulValidation := false
	secCollection := utils.concat_user_credential_path(types.user.username.Value)

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
