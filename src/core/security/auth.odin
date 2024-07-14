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

//meshes the salt and hashed password , returns the mesh
// s- salt , hp- hashed password
OST_MESH_SALT_AND_HASH :: proc(s: string, hp: string) -> string {
	mesh: string
	mesh = strings.concatenate([]string{s, hp})
	fmt.printfln("mesh: %s\n", mesh)
	return mesh
}

//checks if the users information does exist in the user credentials file
//cn- cluster name, un- username, s-salt , hp- hashed password
OST_CROSS_CHECK_USER_CREDS :: proc(cn: string, un: string, s: string, hp: string) -> bool {


	return true
}

//todo need to call this, make sure the username exists in the secure.ost file then move on to the password
OST_AUTH_GET_USERNAME:: proc() string
{
	buf:= [256]byte
	fmt.printfln("Please enter your username:")
	u:= misc.get_input()

	return u
}

//todo after searching for the provided username in the _secure_.ost file, and confirming that the username exists, will need to pre-mesh the salt and hashed password within that provided username's cluster BEFORE getting the user to enter their password. Doing this will provide a base to compare the entered password. 

//todo after the "pre-meshing" of the salt and hashed password, the user will be prompted to enter their password. The entered password will then be hashed using the provided hashing algo method contained within the cluster of the provided username. once hashed the "post-meshing" of the salt and hashed password will be compared to the "pre-meshing", if both match then the user will be signed in. 

OST_AUTH_GET_PASSWORD:: proc() string
{
	buf:= [256]byte
	fmt.printfln("Please enter your password:")
	p:= misc.get_input()
	return p
}