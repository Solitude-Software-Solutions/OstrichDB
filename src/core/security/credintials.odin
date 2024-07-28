package security

import "../../utils"
import "../config"
import "../data"
import "../data/metadata"
import "../types"
import "core:crypto/hash"
import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"

//=========================================================//
//Author: Marshall Burns aka @SchoolyB
//Desc: This file handles the creation and storage of user
//      credentials
//=========================================================//


SIGN_IN_ATTEMPTS: int
FAILED_SIGN_IN_TIMER := time.MIN_DURATION //this will be used to track the time between failed sign in attempts. this timeer will start after the 5th failed attempt in a row


OST_GEN_SECURE_DIR_FILE :: proc() -> int {
	//make directory locked
	createDirSuccess := os.make_directory("../bin/secure") //this will change when building entire project from cmd line

	if createDirSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_CREATE_DIRECTORY,
			utils.get_err_msg(.CANNOT_CREATE_DIRECTORY),
			#procedure,
		)
		utils.throw_err(error1)
	}

	//use os.open to create a file in the secure directory
	file, createSuccess := os.open("../bin/secure/_secure_.ost", 0o666)
	defer os.close(file)
	if createSuccess != 0 {
		error2 := utils.new_err(
			.CANNOT_CREATE_FILE,
			utils.get_err_msg(.CANNOT_CREATE_FILE),
			#procedure,
		)
		utils.throw_err(error2)
		return 1
	}

	return 0
}

//todo move all of this to main proc above
//This will handle initial setup of the admin account on first run of the program
OST_INIT_USER_SETUP :: proc() -> int {buf: [256]byte
	OST_GEN_SECURE_DIR_FILE()
	data.OST_CREATE_COLLECTION("_secure_", 1)
	OST_GEN_USER_ID()
	types.user.role = types.User_Role.ADMIN
	fmt.printfln("Welcome to the Ostrich Database Engine")
	fmt.printfln("Before getting started please setup your admin account")
	fmt.printfln("Please enter a username for the admin account")

	inituserName := OST_GET_USERNAME()
	fmt.printfln("Please enter a password for the admin account")
	initpassword := OST_GET_PASSWORD()
	saltAsString := string(types.user.salt)
	hashAsString := string(types.user.hashedPassword)
	algoMethodAsString := strconv.itoa(buf[:], types.user.store_method)
	OST_STORE_USER_CREDS("user_credentials", types.user.user_id, "role", "admin")
	OST_STORE_USER_CREDS(
		"user_credentials",
		types.user.user_id,
		"user_name",
		types.user.username.Value,
	)


	OST_STORE_USER_CREDS("user_credentials", types.user.user_id, "salt", saltAsString)
	hashAsStr := transmute(string)types.user.hashedPassword
	OST_STORE_USER_CREDS("user_credentials", types.user.user_id, "hash", hashAsStr)
	OST_STORE_USER_CREDS(
		"user_credentials",
		types.user.user_id,
		"store_method",
		algoMethodAsString,
	)
	configToggled := config.OST_TOGGLE_CONFIG("OST_ENGINE_INIT")

	switch (configToggled) 
	{
	case true:
		USER_SIGNIN_STATUS = true
	case false:
		fmt.printfln("Error toggling config")
		os.exit(1)
	}


	return 0
}

OST_GEN_USER_ID :: proc() -> i64 {
	userID := rand.int63_max(1e16 + 1)
	if OST_CHECK_IF_USER_ID_EXISTS(userID) == true {
		utils.log_err("ID already exists in user file", "OST_GEN_USER_ID")
		OST_GEN_USER_ID()
	}
	types.user.user_id = userID
	return userID

}

OST_CHECK_IF_USER_ID_EXISTS :: proc(id: i64) -> bool {
	buf: [32]byte
	result: bool
	openCacheFile, openSuccess := os.open("../bin/secure/_secure_.ost", os.O_RDONLY, 0o666)

	if openSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_OPEN_FILE,
			utils.get_err_msg(.CANNOT_OPEN_FILE),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Error opening cluster id cache file", "OST_CHECK_CACHE_FOR_ID")
	}
	//step#1 convert the passed in i64 id number to a string
	idStr := strconv.append_int(buf[:], id, 10)


	//step#2 read the cache file and compare the id to the cache file
	readCacheFile, readSuccess := os.read_entire_file(openCacheFile)
	if readSuccess == false {
		errors2 := utils.new_err(
			.CANNOT_READ_FILE,
			utils.get_err_msg(.CANNOT_READ_FILE),
			#procedure,
		)
		utils.throw_err(errors2)
		utils.log_err("Error reading cluster id cache file", "OST_CHECK_CACHE_FOR_ID")
	}

	// step#3 convert all file contents to a string because...OdinLang go brrrr??
	contentToStr := transmute(string)readCacheFile

	//step#4 check if the string version of the id is contained in the cache file
	if strings.contains(contentToStr, idStr) {
		fmt.printfln("ID already exists in cache file")
		result = true
	} else {
		result = false
	}
	os.close(openCacheFile)
	return result
}


OST_GET_USERNAME :: proc() -> string {
	utils.show_current_step("Set Up Username", "1", "3")
	buf: [256]byte
	n, inputSuccess := os.read(os.stdin, buf[:])

	if inputSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_READ_INPUT,
			utils.get_err_msg(.CANNOT_READ_INPUT),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Error reading input", "OST_GET_USERNAME")
	}
	if n > 0 {
		enteredStr := string(buf[:n])
		//trim the string of any whitespace or newline characters

		//Shoutout to the OdinLang Discord for helping me with this...
		enteredStr = strings.trim_right_proc(enteredStr, proc(r: rune) -> bool {
			return r == '\r' || r == '\n'
		})
		if (len(enteredStr) > 32) {
			fmt.printfln(
				"Username is too long. Please enter a username that is 32 characters or less",
			)
			OST_GET_USERNAME()
		} else if (len(enteredStr) < 2) {
			fmt.printfln(
				"Username is too short. Please enter a username that is 2 characters or more",
			)
			OST_GET_USERNAME()
		} else {
			types.user.username.Value = strings.clone(enteredStr)
			types.user.username.Length = len(enteredStr)
		}

	}
	return types.user.username.Value
}


OST_GET_PASSWORD :: proc() -> string {
	utils.show_current_step("Set Up Password", "2", "3")
	buf: [256]byte
	n, inputSuccess := os.read(os.stdin, buf[:])
	enteredStr: string
	if inputSuccess != 0 {

		error1 := utils.new_err(
			.CANNOT_READ_INPUT,
			utils.get_err_msg(.CANNOT_READ_INPUT),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Error reading input", "OST_GET_PASSWORD")
	}
	if n > 0 {
		enteredStr = string(buf[:n])
		//trim the string of any whitespace or newline characters

		//Shoutout to the OdinLang Discord for helping me with this...
		enteredStr = strings.trim_right_proc(enteredStr, proc(r: rune) -> bool {
			return r == '\r' || r == '\n'
		})
		types.user.password.Value = enteredStr
	}

	strongPassword := OST_CHECK_PASSWORD_STRENGTH(enteredStr)

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
OST_CONFIRM_PASSWORD :: proc(p: string) -> string {
	utils.show_current_step("Confirm Password", "3", "3")
	buf: [256]byte

	fmt.printfln("Re-enter the password:")
	n, inputSuccess := os.read(os.stdin, buf[:])
	confirmation: string

	if inputSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_READ_INPUT,
			utils.get_err_msg(.CANNOT_READ_INPUT),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Error reading input", "OST_CONFIRM_PASSWORD")
	}
	if n > 0 {
		confirmation = string(buf[:n])
		//trim the string of any whitespace or newline characters

		//Shoutout to the OdinLang Discord for helping me with this...
		confirmation = strings.trim_right_proc(confirmation, proc(r: rune) -> bool {
			return r == '\r' || r == '\n'
		})
	}
	if p != confirmation {
		fmt.printfln("Passwords do not match. Please try again")
		OST_GET_PASSWORD()
	} else {

		types.user.password.Length = len(p)
		types.user.password.Value = strings.clone(types.user.password.Value)
		types.user.hashedPassword = OST_HASH_PASSWORD(p, 0, false)

		encodedPassword := OST_ENCODE_HASHED_PASSWORD(types.user.hashedPassword)
		types.user.hashedPassword = encodedPassword
	}
	return types.user.password.Value
}

// cn- cluster name, id- cluster id, dn- data name, d- data
// //made data type any so that the encoded hash of type []u8 can be transmuted and passed as an arg
OST_STORE_USER_CREDS :: proc(cn: string, id: i64, dn: string, d: string) -> int {
	secureFilePath := "../bin/secure/_secure_.ost"
	credClusterName := "user_credentials"

	ID := data.OST_GENERATE_CLUSTER_ID()
	file, openSuccess := os.open(secureFilePath, os.O_APPEND | os.O_WRONLY, 0o666)
	defer os.close(file)
	if openSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_OPEN_FILE,
			utils.get_err_msg(.CANNOT_OPEN_FILE),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Error opening user credentials file", "OST_STORE_USER_CREDS")
	}
	defer os.close(file)

	if data.OST_CHECK_IF_CLUSTER_EXISTS(secureFilePath, credClusterName) == true {
		data.OST_APPEND_RECORD_TO_CLUSTER(secureFilePath, credClusterName, ID, dn, d)
		return 1
	} else {
		data.OST_CREATE_CLUSTER_BLOCK(secureFilePath, ID, credClusterName)
		data.OST_APPEND_RECORD_TO_CLUSTER(secureFilePath, credClusterName, ID, dn, d)
	}

	return 0
}

// checks if the passed in password is strong enough returns true or false.
//todo need to rework this proc. Its not working as intended
OST_CHECK_PASSWORD_STRENGTH :: proc(p: string) -> bool {
	specialChars: []string = {"!", "@", "#", "$", "%", "^", "&", "*"}
	charsLow: []string = {
		"a",
		"b",
		"c",
		"d",
		"e",
		"f",
		"g",
		"h",
		"i",
		"j",
		"k",
		"l",
		"m",
		"n",
		"o",
		"p",
		"q",
		"r",
		"s",
		"t",
		"u",
		"v",
		"w",
		"x",
		"y",
		"z",
	}
	charsUp: []string = {
		"A",
		"B",
		"C",
		"D",
		"E",
		"F",
		"G",
		"H",
		"I",
		"J",
		"K",
		"L",
		"M",
		"N",
		"O",
		"P",
		"Q",
		"R",
		"S",
		"T",
		"U",
		"V",
		"W",
		"X",
		"Y",
		"Z",
	}
	nums: []string = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"}
	strong: bool

	check1 := 0
	check2 := 0
	check3 := 0

	//check for the length of the password
	if len(p) > 32 {
		fmt.printfln("Password is too long. Please enter a password that is 32 characters or less")
		OST_GET_PASSWORD()
	} else if len(p) < 8 {
		fmt.printfln("Password is too short. Please enter a password that is 8 characters or more")
		OST_GET_PASSWORD()
	}

	//check for the presence of numbers
	for i := 0; i < len(nums); i += 1 {
		if strings.contains(p, nums[i]) {
			check1 += 1
		}
	}

	// check for the presence of special characters
	for i := 0; i < len(specialChars); i += 1 {
		if strings.contains(p, specialChars[i]) {
			check2 += 1
		}
	}
	//check for the presence of uppercase letters
	for i := 0; i < len(charsUp); i += 1 {
		if strings.contains(p, charsUp[i]) {
			check3 += 1
		}
	}
	//add the results of the checks together
	checkResults: int
	checkResults = check1 + check2 + check3

	switch checkResults 
	{
	//because i iterate through the arrays, the program adds 1 to the checkResults variable for each type of character found in the password so if the user enters 2 numbers, then 3 special characters the check2 variable will be 2 and the check1 variable will be 3. so basically, as long as the checkResults variable is greater or equal to 3, the password is strong enough. Kinda hacky but maybe someone can come up with a better way to do this one day. Cannot be more than 36 because the password is only 32 characters long
	case 3 ..< 32:
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
//4. implement a proc wipes the user credentials file after a certain number of failed login attempts....will probably max out at 5
