package security

import "../../utils/errors"
import "../../utils/logging"
import "../../utils/misc"
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
    n, err := os.read(os.stdin, buf[:])

    if err != 0 {
        fmt.println("Debug: Error occurred")
        return
    }
    userName := strings.trim_right(string(buf[:n]), "\r\n")


    fmt.printfln("userName: %s\n", userName)
	//check if the username exists in the secure.ost file
	//!todo working on figuring out why this is returning the wrong record value
	userNameFound := data.OST_READ_RECORD_VALUE(SEC_FILE_PATH, SEC_CLUSTER_NAME, userName)
	fmt.printfln("usernameFound: %s\n", userNameFound)

	//PRE-MESHING START=======================================================================================================
	//get the salt from the cluster that contains the entered username
	salt:= data.OST_READ_RECORD_VALUE(SEC_FILE_PATH, SEC_CLUSTER_NAME, "salt")
	fmt.printfln("salt: %s\n", salt)
    //get the value of the hash that is currently stored in the cluster that contains the entered username
    providedHash:= data.OST_READ_RECORD_VALUE(SEC_FILE_PATH, SEC_CLUSTER_NAME, "hash")
    fmt.printfln("providedHash: %s\n", providedHash)
    pHashAsBytes:= transmute([]u8)providedHash


    preMesh:= OST_MESH_SALT_AND_HASH(salt, pHashAsBytes)
    fmt.printfln("preMesh: %s\n", preMesh)
    //PRE-MESHING END=========================================================================================================

	//todo cant remember if im looking for "algo_method" something else
	algoMethod := data.OST_READ_RECORD_VALUE(SEC_FILE_PATH, SEC_CLUSTER_NAME, "store_method")
	fmt.printfln("algoMethod: %s\n", algoMethod)
	//POST-MESHING START=======================================================================================================

	//get the password input from the user
	n, err = os.read(os.stdin, buf[:])
    if err != 0 {
        return
    }
    enteredPassword := strings.trim_right(string(buf[:n]), "\r\n")
    fmt.printfln("enteredPassword %s", enteredPassword)

    //conver the return algo method string to an int
	algoAsInt := strconv.atoi(algoMethod)
	fmt.printfln("algoAsInt: %d\n", algoAsInt)

	//using the hasing algo from the cluster that contains the entered username, hash the entered password
	newHash:=OST_HASH_PASSWORD(enteredPassword, algoAsInt)

	encodedHash:= OST_ENCODE_HASHED_PASSWORD(newHash)
	bar:=encodedHash
	foo:= transmute(string)bar
	fmt.printfln("new hash: %s:", foo)

	postMesh:= OST_MESH_SALT_AND_HASH(salt,encodedHash)

	//POST-MESHING END=========================================================================================================

	fmt.printfln("postMesh: %s\n", postMesh)
	authPassed:=OST_CROSS_CHECK_MESH(preMesh, postMesh)

	switch authPassed {
        case true:
            fmt.printfln("Auth Passed! User has been signed in!")
            USER_SIGNIN_STATUS = true
            // ost_engine.UserLoggedIn = USER_SIGNIN_STATUS
        case false:
            fmt.printfln("Auth Failed. User has not been signed in!")
            USER_SIGNIN_STATUS = false
            // ost_engine.UserLoggedIn = USER_SIGNIN_STATUS
    }

}

//meshes the salt and hashed password , returns the mesh
// s- salt , hp- hashed password
OST_MESH_SALT_AND_HASH :: proc(s: string, hp: []u8) -> string {
	mesh: string
	hpStr:= transmute(string)hp
	mesh = strings.concatenate([]string{s, hpStr})
	// fmt.printfln("mesh: %s\n", mesh)
	return mesh
}

//checks if the users information does exist in the user credentials file
//cn- cluster name, un- username, s-salt , hp- hashed password
OST_CROSS_CHECK_MESH :: proc(preMesh:string, postMesh:string ) -> bool {
    if preMesh == postMesh {
        fmt.printfln("Entered password matches the stored password!")
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
