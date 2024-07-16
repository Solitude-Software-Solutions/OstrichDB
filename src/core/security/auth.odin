package security

import "../../errors"
import "../../logging"
import "../../misc"
import "../config"
import "../data"
import "../data/metadata"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

USER_SIGNIN_STATUS: bool
SEC_FILE_PATH :: "../bin/secure/_secure_.ost"
SEC_CLUSTER_NAME :: "user_credentials"


OST_RUN_SIGNIN :: proc() {
	//get the username input from the user
	buf: [1024]byte
	n, inputSuccess := os.read(os.stdin, buf[:])

	if inputSuccess != 0 {
	   error1 := errors.new_err(.CANNOT_READ_INPUT,
			errors.get_err_msg(.CANNOT_READ_INPUT),#procedure,)
			errors.throw_err(error1)
	}


	userName := strings.trim_right(string(buf[:n]), "\r\n")
	userNameFound := data.OST_READ_RECORD_VALUE(SEC_FILE_PATH, SEC_CLUSTER_NAME, userName)
	if (userNameFound != userName) {
	    error2:= errors.new_err(.ENTERED_USERNAME_NOT_FOUND, errors.get_err_msg(.ENTERED_USERNAME_NOT_FOUND), #procedure)
		errors.throw_err(error2)
		OST_RUN_SIGNIN()
	}

	//PRE-MESHING START=======================================================================================================
	//get the salt from the cluster that contains the entered username
	salt := data.OST_READ_RECORD_VALUE(SEC_FILE_PATH, SEC_CLUSTER_NAME, "salt")
	//get the value of the hash that is currently stored in the cluster that contains the entered username
	providedHash := data.OST_READ_RECORD_VALUE(SEC_FILE_PATH, SEC_CLUSTER_NAME, "hash")
	pHashAsBytes := transmute([]u8)providedHash


	preMesh := OST_MESH_SALT_AND_HASH(salt, pHashAsBytes)
	//PRE-MESHING END=========================================================================================================

	//todo cant remember if im looking for "algo_method" something else
	algoMethod := data.OST_READ_RECORD_VALUE(SEC_FILE_PATH, SEC_CLUSTER_NAME, "store_method")
	//POST-MESHING START=======================================================================================================

	//get the password input from the user
	n, inputSuccess= os.read(os.stdin, buf[:])
	if inputSuccess != 0 {
	      error3 := errors.new_err(.CANNOT_READ_INPUT,
                errors.get_err_msg(.CANNOT_READ_INPUT),#procedure,)
                errors.throw_err(error3)
		return
	}
	enteredPassword := strings.trim_right(string(buf[:n]), "\r\n")

	//conver the return algo method string to an int
	algoAsInt := strconv.atoi(algoMethod)

	//using the hasing algo from the cluster that contains the entered username, hash the entered password
	newHash := OST_HASH_PASSWORD(enteredPassword, algoAsInt, true)
	encodedHash := OST_ENCODE_HASHED_PASSWORD(newHash)
	postMesh := OST_MESH_SALT_AND_HASH(salt, encodedHash)
	//POST-MESHING END=========================================================================================================


	authPassed := OST_CROSS_CHECK_MESH(preMesh, postMesh)

	switch authPassed {
	case true:
		fmt.printfln("Auth Passed! User has been signed in!")
		USER_SIGNIN_STATUS = true
	case false:
		fmt.printfln("Auth Failed. Password was incorrect please try again.")
		USER_SIGNIN_STATUS = false
		os.exit(0)
	}

}

//meshes the salt and hashed password , returns the mesh
// s- salt , hp- hashed password
OST_MESH_SALT_AND_HASH :: proc(s: string, hp: []u8) -> string {
	mesh: string
	hpStr := transmute(string)hp
	mesh = strings.concatenate([]string{s, hpStr})
	return mesh
}

//checks if the users information does exist in the user credentials file
//cn- cluster name, un- username, s-salt , hp- hashed password
OST_CROSS_CHECK_MESH :: proc(preMesh: string, postMesh: string) -> bool {
	if preMesh == postMesh {
		return true
	}

	return false
}

//todo need to call this, make sure the username exists in the secure.ost file then move on to the password
OST_AUTH_GET_USERNAME :: proc() -> string {
	fmt.printfln("Please enter your username:")
	return misc.get_input()
}

//todo after searching for the provided username in the _secure_.ost file, and confirming that the username exists, will need to pre-mesh the salt and hashed password within that provided username's cluster BEFORE getting the user to enter their password. Doing this will provide a base to compare the entered password.

//todo after the "pre-meshing" of the salt and hashed password, the user will be prompted to enter their password. The entered password will then be hashed using the provided hashing algo method contained within the cluster of the provided username. once hashed the "post-meshing" of the salt and hashed password will be compared to the "pre-meshing", if both match then the user will be signed in.

OST_AUTH_GET_PASSWORD :: proc() -> string {
	fmt.printfln("Please enter your password:")
	return misc.get_input()
}
