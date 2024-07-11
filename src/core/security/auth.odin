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

login_status: bool

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
