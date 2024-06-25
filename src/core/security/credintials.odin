package security

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "../../utils/errors"
import "../../utils/logging"

USER_CREDINTIALS_FILE :string= "../../../../bin/users.bin" 


ost_user_cred: OST_User_Credential
ost_user: OST_USER

OST_User_Role :: enum {
  ADMIN,
  USER,
  GUEST,
}

OST_User_Credential::struct
{
  Value: string, //username
  Length: int, //length of the username
  isUserId: bool, //if the value is an id
  userIdType: string //if the id is an admin, user, or guest id. depends on the value of isId
}

OST_USER :: struct {
  user_id: OST_User_Credential, //generated user id
  username: OST_User_Credential,
  password: OST_User_Credential,
  role: OST_User_Role,
}



//This will handle initial setup of the admin account on first run of the program
OST_INIT_USER_SETUP ::proc(engineInit: bool) -> int
{

  if engineInit == true
  {
    fmt.printfln("Welcome to the Ostrich Database Engine")
    fmt.printfln("Before getting started please setup your admin account")
    fmt.printfln("Please enter a username for the admin account")

    inituserName:=OST_GET_USERNAME()
    fmt.printfln("Please enter a password for the admin account")

  }
  return 0
}


OST_GET_USERNAME :: proc() -> string
{   
    buf:[256]byte
    n,err:=os.read(os.stdin, buf[:])

    if err != 0 {
		errors.throw_utilty_error(1, "Error reading input", "main")
		logging.log_utils_error("Error reading input", "main")
	  }
  	if n > 0 {
        enteredStr := string(buf[:n]) 
				//trim the string of any whitespace or newline characters 

				//Shoutout to the OdinLang Discord for helping me with this...
        enteredStr = strings.trim_right_proc(enteredStr, proc(r: rune) -> bool {
            return r == '\r' || r == '\n'
        })
        ost_user.username.Value = enteredStr
        //todo need to return the string value in an encryption function to encrypt the value before storing it
    }
    return ost_user.username.Value
}


OST_GET_PASSWORD :: proc() -> string
{
    buf:[256]byte
    n,err:=os.read(os.stdin, buf[:])

    if err != 0 {
    errors.throw_utilty_error(1, "Error reading input", "main")
    logging.log_utils_error("Error reading input", "main")
    }
    if n > 0 {
        enteredStr := string(buf[:n]) 
        //trim the string of any whitespace or newline characters 

        //Shoutout to the OdinLang Discord for helping me with this...
        enteredStr = strings.trim_right_proc(enteredStr, proc(r: rune) -> bool {
            return r == '\r' || r == '\n'
        })
        ost_user.password.Value = enteredStr
        //todo need to return the string value in an encryption function to encrypt the value before storing it
    }
    return ost_user.password.Value
  }

OST_CONFIRM_PASSWORD:: proc() -> string
{
  
}

OST_STORE_USER_CREDS::proc(user:OST_USER) -> int 
{

}


//todos
//1. implement a proc that on inital startup of th eprogram to request the user to create an admin account
//2. create procs that create a .bin file to store all the user credentials
//3. create a proc that will add a new user to the .bin file
//4. implement a proc that will check the user credentials against the stored user credentials
//5. implement a proc that will check the user credentials file for the existence of a user
//6. implement a proc wipes the user credentials file after a certain number of failed login attempts....will probably max out at 5
//7. send user creds to encryption module to encrypt the creds before storing them in the .bin file
//8. implement a proc that will decrypt the user creds before checking them against the stored creds