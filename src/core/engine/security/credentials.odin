package security

import "../../../utils"
import "../../config"
import "../../const"
import "../../types"
import "../data"
import "../data/metadata"
import "core:c/libc"
import "core:crypto/hash"
import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//

SIGN_IN_ATTEMPTS: int
FAILED_SIGN_IN_TIMER := time.MIN_DURATION //this will be used to track the time between failed sign in attempts. this timeer will start after the 5th failed attempt in a row


OST_GEN_SECURE_DIR :: proc() -> int {

	//perform a check to see if the secure directory already exists to prevent errors and overwriting
	_, err := os.stat("./secure")
	if err == nil {
		return 0
	}
	createDirSuccess := os.make_directory("./secure")
	if createDirSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_CREATE_DIRECTORY,
			utils.get_err_msg(.CANNOT_CREATE_DIRECTORY),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Error occured while attempting to generate new secure file", #procedure)
	}
	return 0
}

//This will handle initial setup of the admin account on first run of the program
OST_INIT_ADMIN_SETUP :: proc() -> int {
	buf: [256]byte
	OST_GEN_SECURE_DIR()
	OST_GEN_USER_ID()
	fmt.printfln("Welcome to the OstrichDB Database Management System")
	fmt.printfln("Before getting started please setup your admin account")
	fmt.printfln("Please enter a username for the admin account")

	inituserName := OST_GET_USERNAME(true)
	fmt.printfln("Please enter a password for the admin account")
	fmt.printf(
		"Passwords MUST: \n 1. Be least 8 characters \n 2. Contain at least one uppercase letter \n 3. Contain at least one number \n 4. Contain at least one special character \n",
	)
	libc.system("stty -echo")
	initpassword := OST_GET_PASSWORD(true)
	saltAsString := string(types.user.salt)
	hashAsString := string(types.user.hashedPassword)
	algoMethodAsString := strconv.itoa(buf[:], types.user.store_method)
	types.user.user_id = data.OST_GENERATE_ID(true) //for secure clustser, the cluster id is the user id
	data.OST_CREATE_COLLECTION("history", 2)

	types.user.username.Value = inituserName


	//store the id to both clusters in the id collection
	data.OST_APPEND_ID_TO_COLLECTION(fmt.tprintf("%d", types.user.user_id), 0)
	data.OST_APPEND_ID_TO_COLLECTION(fmt.tprintf("%d", types.user.user_id), 1)


	data.OST_CREATE_CLUSTER_BLOCK(
		const.OST_HISTORY_PATH,
		types.user.user_id,
		types.user.username.Value,
	)
	inituserName = fmt.tprintf("secure_%s", inituserName)
	data.OST_CREATE_COLLECTION(inituserName, 1)
	mk := OST_GEN_MASTER_KEY()
	mkAsString := transmute(string)mk

	OST_STORE_USER_CREDS(
		inituserName,
		types.user.username.Value,
		types.user.user_id,
		"user_name",
		types.user.username.Value,
	)
	OST_STORE_USER_CREDS(
		inituserName,
		types.user.username.Value,
		types.user.user_id,
		"role",
		"admin",
	)
	OST_STORE_USER_CREDS(
		inituserName,
		types.user.username.Value,
		types.user.user_id,
		"salt",
		saltAsString,
	)

	hashAsStr := transmute(string)types.user.hashedPassword

	OST_STORE_USER_CREDS(
		inituserName,
		types.user.username.Value,
		types.user.user_id,
		"hash",
		hashAsStr,
	)
	OST_STORE_USER_CREDS(
		inituserName,
		types.user.username.Value,
		types.user.user_id,
		"store_method",
		algoMethodAsString,
	)

	OST_STORE_USER_CREDS(
		inituserName,
		types.user.username.Value,
		types.user.user_id,
		"m_k",
		mkAsString,
	)
	engineInit := config.OST_UPDATE_CONFIG_VALUE(const.CONFIG_ONE, "true")

	switch (engineInit)
	{
	case true:
		types.USER_SIGNIN_STATUS = true
	case false:
		fmt.printfln("Error toggling config")
		os.exit(1)
	}

	//update metadata fields
	metadata.OST_METADATA_ON_CREATE(const.OST_HISTORY_PATH)
	metadata.OST_METADATA_ON_CREATE(
		fmt.tprintf(
			"%s%s%s",
			const.OST_SECURE_COLLECTION_PATH,
			inituserName,
			const.OST_FILE_EXTENSION,
		),
	)
	fmt.println("Please re-launch OstrichDB...")
	return 0
}

OST_GEN_USER_ID :: proc() -> i64 {
	userID := rand.int63_max(1e16 + 1)
	if data.OST_CHECK_IF_USER_ID_EXISTS(userID) == true {
		utils.log_err("Generated ID already exists in user file", #procedure)
		OST_GEN_USER_ID()
	}
	types.user.user_id = userID
	return userID

}


//the isInitializing param will be false when if creating an account post engine initialization,
OST_GET_USERNAME :: proc(isInitializing: bool) -> string {
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
		utils.log_err("Error reading input", #procedure)
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
			if isInitializing == true {
				OST_GET_USERNAME(true)
			} else if isInitializing == false {
				OST_GET_USERNAME(false)
			}
		} else if (len(enteredStr) < 2) {
			fmt.printfln(
				"Username is too short. Please enter a username that is 2 characters or more",
			)
			if isInitializing == true {
				OST_GET_USERNAME(true)
			} else if isInitializing == false {
				OST_GET_USERNAME(false)
			}
		} else {
			if isInitializing == true {
				types.user.username.Value = strings.clone(enteredStr)
				types.user.username.Length = len(enteredStr)
			} else if isInitializing == false {
				types.new_user.username.Value = strings.clone(enteredStr)
				types.new_user.username.Length = len(enteredStr)
			}
		}

	}
	if isInitializing == false {
		return strings.clone(strings.to_upper(types.new_user.username.Value))
	}

	return strings.clone(strings.to_upper(types.user.username.Value))
}


OST_GET_PASSWORD :: proc(isInitializing: bool) -> string {
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
		utils.log_err("Error reading input", #procedure)
	}
	if n > 0 {
		enteredStr = string(buf[:n])
		//trim the string of any whitespace or newline characters

		//Shoutout to the OdinLang Discord for helping me with this...
		enteredStr = strings.trim_right_proc(enteredStr, proc(r: rune) -> bool {
			return r == '\r' || r == '\n'
		})
		if (isInitializing == true) {
			types.user.password.Value = enteredStr
		} else if (isInitializing == false) {
			types.new_user.password.Value = enteredStr
		}
	}

	strongPassword := OST_CHECK_PASSWORD_STRENGTH(enteredStr)

	switch strongPassword
	{
	case true:
		OST_CONFIRM_PASSWORD(enteredStr, isInitializing)
		break
	case false:
		fmt.printfln("Please try again")
		OST_GET_PASSWORD(isInitializing)
		break
	}

	return strings.clone(enteredStr)
}

//taKes in the plain text password and confirms it with the user
OST_CONFIRM_PASSWORD :: proc(p: string, isInitializing: bool) -> string {
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
		utils.log_err("Error reading input", #procedure)
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
		OST_GET_PASSWORD(isInitializing)
	} else {

		if isInitializing == true {
			types.user.password.Length = len(p)
			types.user.password.Value = strings.clone(p)
			types.user.hashedPassword = OST_HASH_PASSWORD(p, 0, false, true)

			encodedPassword := OST_ENCODE_HASHED_PASSWORD(types.user.hashedPassword)
			types.user.hashedPassword = encodedPassword
		} else if isInitializing == false {
			types.new_user.password.Length = len(p)
			types.new_user.password.Value = strings.clone(p)
			types.new_user.hashedPassword = OST_HASH_PASSWORD(p, 0, false, false)

			encodedPassword := OST_ENCODE_HASHED_PASSWORD(types.new_user.hashedPassword)
			types.new_user.hashedPassword = encodedPassword
			return types.new_user.password.Value
		}
	}
	libc.system("stty echo")
	return strings.clone(types.user.password.Value)
}

//store the entered and generated user credentials in the secure cluster
// cn- cluster name, id- cluster id, dn- data name, d- data
OST_STORE_USER_CREDS :: proc(fn: string, cn: string, id: i64, dn: string, d: string) -> int {
	secureFilePath := fmt.tprintf(
		"%s%s%s",
		const.OST_SECURE_COLLECTION_PATH,
		fn,
		const.OST_FILE_EXTENSION,
	)

	file, openSuccess := os.open(secureFilePath, os.O_APPEND | os.O_WRONLY, 0o666)
	defer os.close(file)
	if openSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_OPEN_FILE,
			utils.get_err_msg(.CANNOT_OPEN_FILE),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Error opening user credentials file", #procedure)
	}
	defer os.close(file)


	data.OST_CREATE_CLUSTER_BLOCK(secureFilePath, id, cn)

	data.OST_APPEND_CREDENTIAL_RECORD(secureFilePath, cn, dn, d, "identifier", id)

	metadata.OST_UPDATE_METADATA_VALUE(secureFilePath, 2)
	metadata.OST_UPDATE_METADATA_VALUE(secureFilePath, 3)
	return 0
}

// checks if the passed in password is strong enough returns true or false.
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

	longEnough: bool
	hasNumber: bool
	hasSpecial: bool
	hasUpper: bool
	strong: bool


	// //check for the length of the password
	switch (len(p))
	{
	case 0:
		fmt.printfln("Password cannot be empty. Please enter a password")
		return false
	case 1 ..< 8:
		fmt.printfln("Password is too short. Please enter a password that is 8 characters or more")
		return false
	case 32 ..< 1000:
		fmt.printfln("Password is too long. Please enter a password that is 32 characters or less")
		return false
	case:
		longEnough = true
	}

	//check for the presence of numbers
	for i := 0; i < len(nums); i += 1 {
		if strings.contains(p, nums[i]) {
			hasNumber = true
		}
	}

	// check for the presence of special characters
	for i := 0; i < len(specialChars); i += 1 {
		if strings.contains(p, specialChars[i]) {
			hasSpecial = true
			break
		}
	}
	//check for the presence of uppercase letters
	for i := 0; i < len(charsUp); i += 1 {
		if strings.contains(p, charsUp[i]) {
			hasUpper = true
			break
		}
	}

	switch (true)
	{
	case longEnough && hasNumber && hasSpecial && hasUpper:
		strong = true
	case !hasNumber:
		fmt.printfln("Password must contain at least one number")
		strong = false
	case !hasSpecial:
		fmt.printfln("Password must contain at least one special character")
		strong = false
	case !hasUpper:
		fmt.printfln("Password must contain at least one uppercase letter")
		strong = false
	}

	return strong
}

// creates a new user account post engine initialization
//also determines if the currently logged in user has permission to create a new user account
//allows for test mode to be used to create a new user without the need for interactive input
OST_CREATE_NEW_USER :: proc(
	username: string = "",
	password: string = "",
	role: string = "",
) -> int {
	buf: [1024]byte


	if types.TESTING {
		// In testing mode, use provided test values
		if role == "" || username == "" || password == "" {
			fmt.println("Error: Required test parameters are missing")
			return 1
		}

		// Set role based on test input
		switch strings.to_upper(role) {
		case "ADMIN":
			types.new_user.role.Value = "admin"
		case "USER":
			types.new_user.role.Value = "user"
		case "GUEST":
			types.new_user.role.Value = "guest"
		case:
			return 1
		}

		types.new_user.username.Value = username
		types.new_user.password.Value = password

	} else {
		if types.user.role.Value == "admin" {
			fmt.println("Please enter role you would like to assign the new account")
			fmt.printf("1. Admin\n2. User\n3. Guest\n")
			n, inputSuccess := os.read(os.stdin, buf[:])
			if inputSuccess != 0 {
				fmt.printfln("Error reading input")
				return 1
			}

			inputToCap := strings.to_upper(strings.trim_right(string(buf[:n]), "\r\n"))
			if inputToCap == "1" || inputToCap == "ADMIN" {
				types.new_user.role.Value = "admin"
			} else if inputToCap == "2" || inputToCap == "USER" {
				types.new_user.role.Value = "user"
			} else if inputToCap == "3" || inputToCap == "GUEST" {
				types.new_user.role.Value = "guest"
			} else {
				fmt.printfln("Invalid role entered")
				return 1
			}
		} else if (types.user.role.Value == "user") {
			types.new_user.role.Value = "guest"
		} else {
			fmt.println("You do not have the required permissions to create a new account")
			fmt.printfln(
				"To create a new account you must be logged in as an admin or user account",
			)
			return 1
		}

		newUserName := OST_GET_USERNAME(false)
		types.new_user.username.Value = newUserName
	}

	// Common validation logic for both test and interactive modes
	isBannedUsername := OST_CHECK_FOR_BANNED_USERNAME(types.new_user.username.Value)
	if isBannedUsername {
		fmt.printfln("Username is banned. Please enter a different username")
		fmt.println("Cannot create user with name: ", types.new_user.username.Value)
		return 1
	}

	newColName := fmt.tprintf("secure_%s", types.new_user.username.Value)
	exists, _ := data.OST_FIND_SEC_COLLECTION(newColName)

	if exists {
		fmt.printfln(
			"There is already a user with the name: %s%s%s\nPlease try again.",
			utils.BOLD_UNDERLINE,
			types.new_user.username.Value,
			utils.RESET,
		)
		return 1
	}

	result := data.OST_CREATE_COLLECTION(newColName, 1)
	if !types.TESTING {
		fmt.printf(
			"Passwords MUST: \n 1. Be least 8 characters \n 2. Contain at least one uppercase letter \n 3. Contain at least one number \n 4. Contain at least one special character \n",
		)
		libc.system("stty -echo")
		initpassword := OST_GET_PASSWORD(false)
		libc.system("stty echo")
		types.new_user.password.Value = initpassword
	}

	saltAsString := string(types.new_user.salt)
	hashAsString := string(types.new_user.hashedPassword)
	algoMethodAsString := strconv.itoa(buf[:], types.new_user.store_method)

	types.new_user.user_id = data.OST_GENERATE_ID(true)

	//store the id to both clusters in the id collection
	data.OST_APPEND_ID_TO_COLLECTION(fmt.tprintf("%d", types.new_user.user_id), 0)
	data.OST_APPEND_ID_TO_COLLECTION(fmt.tprintf("%d", types.new_user.user_id), 1)

	// Store user credentials
	OST_STORE_USER_CREDS(
		newColName,
		types.new_user.username.Value,
		types.new_user.user_id,
		"user_name",
		types.new_user.username.Value,
	)
	OST_STORE_USER_CREDS(
		newColName,
		types.new_user.username.Value,
		types.new_user.user_id,
		"role",
		types.new_user.role.Value,
	)
	OST_STORE_USER_CREDS(
		newColName,
		types.new_user.username.Value,
		types.new_user.user_id,
		"salt",
		saltAsString,
	)
	OST_STORE_USER_CREDS(
		newColName,
		types.new_user.username.Value,
		types.new_user.user_id,
		"hash",
		hashAsString,
	)
	OST_STORE_USER_CREDS(
		newColName,
		types.new_user.username.Value,
		types.new_user.user_id,
		"store_method",
		algoMethodAsString,
	)

	// Create history cluster.
	data.OST_CREATE_CLUSTER_BLOCK(
		const.OST_HISTORY_PATH,
		types.user.user_id,
		types.new_user.username.Value,
	)

	return 0
}


OST_CHECK_FOR_BANNED_USERNAME :: proc(un: string) -> bool {
	for i := 0; i < len(const.BannedUserNames); i += 1 {
		if strings.contains(un, const.BannedUserNames[i]) {
			return true
		}
	}
	return false
}

OST_DELETE_USER :: proc(username: string) -> bool {
	file := fmt.tprintf(
		"%ssecure_%s%s",
		const.OST_SECURE_COLLECTION_PATH,
		username,
		const.OST_FILE_EXTENSION,
	)


	// NOTE: This check is reliant on the value stored in memory. if this becomes is a problem remove it and uncomment the line below
	if types.current_user.role.Value != "admin" {
		fmt.printfln(
			"You do not have permission to delete users. Only administrators can perform this action.",
		)
		return false
	}

	// Check if user is an admin based on the role stored in the secure collection
	// if data.OST_READ_RECORD_VALUE(file, username, "identifier", "role") == "admin" {
	// 	fmt.printfln("You cannot delete an admin account.")
	// 	return false
	// }

	// Cannot delete your own account
	if username == types.current_user.username.Value {
		fmt.printfln("You cannot delete your own account.")
		return false
	}

	// Check if user exists
	secureColName := fmt.tprintf("secure_%s", username)
	exists, _ := data.OST_FIND_SEC_COLLECTION(secureColName)
	if !exists {
		fmt.printfln(
			"User %s%s%s does not exist. Terminating operation",
			utils.BOLD_UNDERLINE,
			username,
			utils.RESET,
		)
		return false
	}

	// Get confirmation
	buf: [64]byte
	fmt.printfln(
		"Are you sure you want to delete user: %s%s%s?\nThis action cannot be undone.",
		utils.BOLD_UNDERLINE,
		username,
		utils.RESET,
	)
	fmt.printfln("Type 'yes' to confirm or 'no' to cancel.")

	n, inputSuccess := os.read(os.stdin, buf[:])
	if inputSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_READ_INPUT,
			utils.get_err_msg(.CANNOT_READ_INPUT),
			#procedure,
		)
		utils.throw_err(error1)
		return false
	}

	confirmation := strings.trim_right(string(buf[:n]), "\r\n")
	cap := strings.to_upper(confirmation)

	switch cap {
	case const.NO:
		utils.log_runtime_event("User canceled deletion", "User canceled deletion of user account")
		return false
	case const.YES:
		break
	case:
		utils.log_runtime_event(
			"User entered invalid input",
			"User entered invalid input when trying to delete user",
		)
		error2 := utils.new_err(.INVALID_INPUT, utils.get_err_msg(.INVALID_INPUT), #procedure)
		utils.throw_custom_err(error2, "Invalid input. Please type 'yes' or 'no'.")
		return false
	}

	//remove the users ID from both clusters in the ids.ost collection file.
	id := data.OST_GET_CLUSTER_ID("", username)
	idStr := fmt.tprintf("%d", id)


	//called twice to remove the id from both clusters
	removedFromUserIDCluster := data.OST_REMOVE_ID_FROM_CLUSTER(idStr, true)
	removedFromClusterIDCluster := data.OST_REMOVE_ID_FROM_CLUSTER(idStr, false)
	if !removedFromUserIDCluster && !removedFromClusterIDCluster {
		utils.log_err("Error removing user ID from clusters", #procedure)
		return false
	}


	// Delete the user's secure collection file
	deleteSuccess := os.remove(file)
	if deleteSuccess != 0 {
		error1 := utils.new_err(
			.CANNOT_DELETE_FILE,
			utils.get_err_msg(.CANNOT_DELETE_FILE),
			#procedure,
		)
		utils.throw_err(error1)
		utils.log_err("Error deleting user's secure collection file", #procedure)
		return false
	}

	// Remove the users histrory cluster
	data.OST_ERASE_HISTORY_CLUSTER(username)
	utils.log_runtime_event(
		"User deleted",
		fmt.tprintf("Administrator %s deleted user %s", types.user.username.Value, username),
	)
	return true
}


OST_ADD_USERS_TO_LIST :: proc() -> [dynamic]string {
	//remember to free mem when calling
	userArr := make([dynamic]string)
	secPath, openSuccess := os.open(const.OST_SECURE_COLLECTION_PATH)
	users, readSuccess := os.read_dir(secPath, -1)

	for user in users {
		//trim fat
		nameWithoutSuffix := strings.trim_suffix(user.name, const.OST_FILE_EXTENSION)
		nameWithoutPrefix := strings.trim_prefix(nameWithoutSuffix, "secure_")
		append(&userArr, nameWithoutPrefix)
	}
	return userArr
}
