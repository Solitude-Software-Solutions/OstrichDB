package security

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:crypto/hash"
import "core:math/rand"
import "../../utils/errors"
import "../../utils/logging"
import "../../utils/misc"
import "../data"

//=========================================================//
//Author: Marshall Burns aka @SchoolyB
//Desc: This file handles the creation and storage of user
//      credentials
//=========================================================//


ost_user:OST_USER

OST_User_Role :: enum {
  ADMIN,
  USER,
  GUEST,
}

OST_User_Credential::struct
{
  Value: string, //username
  Length: int, //length of the username
}

OST_USER :: struct {
  user_id: i64, //randomly generated user id
  role: OST_User_Role,
  username: OST_User_Credential,
  password: OST_User_Credential, //will never be stored as plain text

  //below this line is for encryption purposes
  salt: []u8,
  hashedPassword: []u8, //this is the hashed password without the salt 
  algo_method:int //todo might not use. if I do, a single int will represent the hashing algorithm used...also could make this an enum
}


// main ::proc() //for testing purposes
// {
//   OST_INIT_USER_SETUP(true) 
// }


//This will handle initial setup of the admin account on first run of the program
OST_INIT_USER_SETUP ::proc() -> int
{

    OST_GEN_USER_ID()
    ost_user.role=OST_User_Role.ADMIN
    fmt.printfln("Welcome to the Ostrich Database Engine")
    fmt.printfln("Before getting started please setup your admin account")
    fmt.printfln("Please enter a username for the admin account")

    inituserName:=OST_GET_USERNAME()
    fmt.printfln("Please enter a password for the admin account")
    initpassword:=OST_GET_PASSWORD()
    fmt.printfln("User ID: %d", ost_user.user_id)
    fmt.printfln("Username: %s", ost_user.username.Value) //!remove this line after testing
    fmt.printfln("Password: %s", ost_user.password.Value) //!remove this line after testing

    fmt.printfln("Hashed Password: %s", ost_user.hashedPassword) //!remove this line after testing
    fmt.printfln("Salt: %s", ost_user.salt)
    fmt.printfln("Algo Method: %d", ost_user.algo_method) //!remove this line after testing
    OST_STORE_USER_CREDS()
  
    

  return 0
}

OST_GEN_USER_ID ::proc() -> i64
{
	userID:=rand.int63_max(1e16 + 1)
  if OST_CHECK_IF_USER_ID_EXISTS(userID) == true
  {
    logging.log_utils_error("ID already exists in user file", "OST_GEN_USER_ID")
    OST_GEN_USER_ID()
  }
  ost_user.user_id=userID
  return userID

}

OST_CHECK_IF_USER_ID_EXISTS ::proc(id:i64) -> bool
{
	buf: [32]byte
	result: bool
  openCacheFile,err:=os.open("../bin/secure/_secure_.ost", os.O_RDONLY, 0o666)
	if err != 0
	{
		errors.throw_utilty_error(1, "Error opening cluster id cache file", "OST_CHECK_CACHE_FOR_ID")
		logging.log_utils_error("Error opening cluster id cache file", "OST_CHECK_CACHE_FOR_ID")
	}
	//step#1 convert the passed in i64 id number to a string
	idStr := strconv.append_int(buf[:], id, 10) 

	
	//step#2 read the cache file and compare the id to the cache file
	readCacheFile,ok:=os.read_entire_file(openCacheFile)
	if ok == false
	{
		errors.throw_utilty_error(1, "Error reading cluster id cache file", "OST_CHECK_CACHE_FOR_ID")
		logging.log_utils_error("Error reading cluster id cache file", "OST_CHECK_CACHE_FOR_ID")
	}

	// step#3 convert all file contents to a string because...OdinLang go brrrr??
	contentToStr:= transmute(string)readCacheFile

	//step#4 check if the string version of the id is contained in the cache file
		if strings.contains(contentToStr, idStr)
		{
			fmt.printfln("ID already exists in cache file")
			result = true
		}
		else
		{
			result = false
		}
	os.close(openCacheFile)
		return result
}


OST_GET_USERNAME :: proc() -> string
{   
    misc.show_current_step("Set Up Username", "1", "3")
    buf:[256]byte
    n,err:=os.read(os.stdin, buf[:])

    if err != 0 {

		errors.throw_utilty_error(1, "Error reading input", "OST_GET_USERNAME")
		logging.log_utils_error("Error reading input", "OST_GET_USERNAME")
	  }
  	if n > 0 {
        enteredStr := string(buf[:n]) 
				//trim the string of any whitespace or newline characters 

				//Shoutout to the OdinLang Discord for helping me with this...
        enteredStr = strings.trim_right_proc(enteredStr, proc(r: rune) -> bool {
            return r == '\r' || r == '\n'
        })
        if(len(enteredStr) > 32)
        {
            fmt.printfln("Username is too long. Please enter a username that is 32 characters or less")
            OST_GET_USERNAME()          
        }
        else if(len(enteredStr) < 2)
        {
            fmt.printfln("Username is too short. Please enter a username that is 2 characters or more")
            OST_GET_USERNAME()
        }
        else
        {
          ost_user.username.Value = strings.clone(enteredStr)
          ost_user.username.Length = len(enteredStr)
        }

    }
    return ost_user.username.Value
}


OST_GET_PASSWORD :: proc() -> string
{
    misc.show_current_step("Set Up Password", "2", "3")
    buf:[256]byte
    n,err:=os.read(os.stdin, buf[:])
    enteredStr: string
    if err != 0 {

    errors.throw_utilty_error(1, "Error reading input", "OST_GET_PASSWORD")
    logging.log_utils_error("Error reading input", "OST_GET_PASSWORD")
    }
    if n > 0 {
        enteredStr = string(buf[:n]) 
        //trim the string of any whitespace or newline characters 

        //Shoutout to the OdinLang Discord for helping me with this...
        enteredStr = strings.trim_right_proc(enteredStr, proc(r: rune) -> bool {
            return r == '\r' || r == '\n'
        })
        ost_user.password.Value = enteredStr
        //todo implement a check to see if the password is strong enough
      } 
      
      strongPassword:= OST_CHECK_PASSWORD_STRENGTH(enteredStr)

      switch strongPassword
      {
        case true:
          OST_CONFIRM_PASSWORD(enteredStr)
          break
        case false:
          fmt.printfln("Please enter a stronger password")
          OST_GET_PASSWORD()
          break
      }
      
    return enteredStr
  }

  //taKes in the plain text password and confirms it with the user
OST_CONFIRM_PASSWORD:: proc(p:string) -> string
{
  misc.show_current_step("Confirm Password", "3", "3")
  buf:[256]byte

  fmt.printfln("Re-enter the password:")
  n,err:=os.read(os.stdin, buf[:])
  confirmation: string

  if err != 0 {
    errors.throw_utilty_error(1, "Error reading input", "OST_CONFIRM_PASSWORD")
    logging.log_utils_error("Error reading input", "OST_CONFIRM_PASSWORD")
  }
  if n > 0 {
    confirmation = string(buf[:n]) 
    //trim the string of any whitespace or newline characters 

    //Shoutout to the OdinLang Discord for helping me with this...
    confirmation = strings.trim_right_proc(confirmation, proc(r: rune) -> bool {
        return r == '\r' || r == '\n'
    })
  }
  if p != confirmation
  {
    fmt.printfln("Passwords do not match. Please try again")
    OST_GET_PASSWORD()
  }
  else
  {
     
  ost_user.password.Length = len(p)
  ost_user.password.Value=strings.clone(ost_user.password.Value)
  ost_user.hashedPassword = OST_HASH_PASSWORD(p,1)
}
  return ost_user.password.Value
}

// i- user id, u- username, r- role, s- salt, hp- hashed password
// OST_STORE_USER_CREDS::proc(i:i64,u:string,r:int,s:string,hp:string) -> int 
OST_STORE_USER_CREDS::proc() -> int 
{
  data.OST_CREATE_OST_FILE("_secure_")
  ID:=data.OST_GENERATE_CLUSTER_ID()
  file,e:= os.open("../bin/secure/_secure_.ost", os.O_APPEND | os.O_WRONLY, 0o666)
  if e != 0
  {
    errors.throw_utilty_error(1, "Error opening user credentials file", "OST_STORE_USER_CREDS")
    logging.log_utils_error("Error opening user credentials file", "OST_STORE_USER_CREDS")
  }
  defer os.close(file)
  // data.OST_CREATE_CLUSTER_BLOCK("../bin/secure/_secure_.ost", ID, "user_credentials") //todo uncomment this line after testing
  data.OST_APPEND_DATA_TO_CLUSTER("../bin/secure/_secure_.ost","user_credentials", 3581445065921312, "test", "test data")

  return 0

  // todo: currently I am working on records. I need to finish basic set up of records  before I can store the user credentials since technically the user credentials are each a record...

}

// checks if the passed in password is strong enough returns true or false.
OST_CHECK_PASSWORD_STRENGTH::proc(p:string) -> bool
{
  specialChars:[]string={"!","@","#","$","%","^","&","*"}
  charsLow:[]string={"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",}
  charsUp:[]string={"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",}
  nums:[]string={"0","1","2","3","4","5","6","7","8","9",}
  strong:bool

  check1:=0
  check2:=0
  check3:=0

  //check for the length of the password
  if len(p) > 32
  {
    fmt.printfln("Password is too long. Please enter a password that is 32 characters or less")
    OST_GET_PASSWORD()
  }
  else if len(p) < 8
  {
    fmt.printfln("Password is too short. Please enter a password that is 8 characters or more")
    OST_GET_PASSWORD()
  }
  
  //check for the presence of numbers
  for i:=0; i<len(nums); i+=1
  {
    if strings.contains(p, nums[i])
    {
      check1+=1
    }
  }
  
  // check for the presence of special characters
  for i:=0; i<len(specialChars); i+=1
  {
    if strings.contains(p, specialChars[i])
    {
      check2+=1
    }
  }
  //check for the presence of uppercase letters
  for i:=0; i<len(charsUp); i+=1
  {
    if strings.contains(p, charsUp[i])
    {
      check3+=1
    }
  }
  //add the results of the checks together
  checkResults:int
  checkResults = check1 + check2 + check3
  
  switch checkResults
  {
    //because i iterate through the arrays, the program adds 1 to the checkResults variable for each type of character found in the password so if the user enters 2 numbers, then 3 special characters the check2 variable will be 2 and the check1 variable will be 3. so basically, as long as the checkResults variable is greater or equal to 3, the password is strong enough. Kinda hacky but maybe someone can come up with a better way to do this one day. Cannot be more than 36 because the password is only 32 characters long
    case 3..<32:
      strong = true
      break
    case 2:
      fmt.printfln("Password is weak. Please include at least one uppercase letter")
      strong = false
      break
    case 1:
      fmt.printfln("Password is weak. Please include at least one number")
      strong = false
      break
    case 0:
      fmt.printfln("Password is weak. Please include at least one special character")
      strong = false
      break
  }

  return strong
}

//todos
//1. create a proc that will add a new user to the _secure_.ost file ALMOST DONE
//2. implement a proc that will check the user credentials against the stored user credentials
//3.. implement a proc that will check the user credentials file for the existence of a user
//4. implement a proc wipes the user credentials file after a certain number of failed login attempts....will probably max out at 5
