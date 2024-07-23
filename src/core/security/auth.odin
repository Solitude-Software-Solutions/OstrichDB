package security

import "../../errors"
import "../../logging"
import "../../misc"
import "../config"
import "../const"
import "../data"
import "../data/metadata"
import "core:c/libc"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

USER_SIGNIN_STATUS: bool

OST_RUN_SIGNIN :: proc() -> bool {
	//get the username input from the user
	buf: [1024]byte
	fmt.printfln("Please enter your username:")
	n, inputSuccess := os.read(os.stdin, buf[:])

	if inputSuccess != 0 {
		error1 := errors.new_err(
			.CANNOT_READ_INPUT,
			errors.get_err_msg(.CANNOT_READ_INPUT),
			#procedure,
		)
		errors.throw_err(error1)
	}


	userName := strings.trim_right(string(buf[:n]), "\r\n")
	userNameFound := data.OST_READ_RECORD_VALUE(
		const.SEC_FILE_PATH,
		const.SEC_CLUSTER_NAME,
		userName,
	)
	if (userNameFound != userName) {
		error2 := errors.new_err(
			.ENTERED_USERNAME_NOT_FOUND,
			errors.get_err_msg(.ENTERED_USERNAME_NOT_FOUND),
			#procedure,
		)
		errors.throw_err(error2)
		OST_RUN_SIGNIN()
	}

	//PRE-MESHING START=======================================================================================================
	//get the salt from the cluster that contains the entered username
	salt := data.OST_READ_RECORD_VALUE(const.SEC_FILE_PATH, const.SEC_CLUSTER_NAME, "salt")
	//get the value of the hash that is currently stored in the cluster that contains the entered username
	providedHash := data.OST_READ_RECORD_VALUE(const.SEC_FILE_PATH, const.SEC_CLUSTER_NAME, "hash")
	pHashAsBytes := transmute([]u8)providedHash


	preMesh := OST_MESH_SALT_AND_HASH(salt, pHashAsBytes)
	//PRE-MESHING END=========================================================================================================

	//todo cant remember if im looking for "algo_method" something else
	algoMethod := data.OST_READ_RECORD_VALUE(
		const.SEC_FILE_PATH,
		const.SEC_CLUSTER_NAME,
		"store_method",
	)
	//POST-MESHING START=======================================================================================================

	//get the password input from the user
	fmt.printfln("Please enter your password:")
	libc.system("stty -echo")
	n, inputSuccess = os.read(os.stdin, buf[:])
	if inputSuccess != 0 {
		error3 := errors.new_err(
			.CANNOT_READ_INPUT,
			errors.get_err_msg(.CANNOT_READ_INPUT),
			#procedure,
		)
		errors.throw_err(error3)
		return false
	}
	enteredPassword := strings.trim_right(string(buf[:n]), "\r\n")
	libc.system("stty echo")
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
		config.OST_TOGGLE_CONFIG("OST_USER_LOGGED_IN")
	case false:
		fmt.printfln("Auth Failed. Password was incorrect please try again.")
		USER_SIGNIN_STATUS = false
		os.exit(0)
	}
	return USER_SIGNIN_STATUS

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

OST_USER_LOGOUT :: proc(param: int) -> bool {
	loggedOut := config.OST_TOGGLE_CONFIG("OST_USER_LOGGED_IN")

	switch loggedOut {
	case true:
		switch (param) 
		{
		case 0:
			USER_SIGNIN_STATUS = false
			fmt.printfln("You have been logged out.")
			OST_RUN_SIGNIN()
			break
		case 1:
			//only used when logging out AND THEN exiting.
			USER_SIGNIN_STATUS = false
			fmt.printfln("You have been logged out.")
			fmt.println("Now Exiting OstrichDB See you soon!\n")
			os.exit(0)
		}
		break
	case false:
		USER_SIGNIN_STATUS = true
		fmt.printfln("You have NOT been logged out.")
		break
	}
	return USER_SIGNIN_STATUS
}
