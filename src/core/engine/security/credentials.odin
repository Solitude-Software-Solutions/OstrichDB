package security

import "../../../utils"
import "../../const"
import "../../types"
import "../config"
import "../data"
import "../data/metadata"
import "core:c/libc"
import "core:crypto/hash"
import "core:encoding/hex"
import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-2025 Marshall A Burns and Solitude Software Solutions LLC
Copyright (c) 2025-Present Archetype Dynamics, Inc.

File Description:
            Contains logic for handling user management,
            including creating, deleting, and updating
            user accounts.
*********************************************************/


//Handle initial setup of the admin account on first run of the program
HANDLE_FIRST_TIME_ACCOUNT_SETUP :: proc() -> int {
	using types
	using data
	using const

	buf: [256]byte
	GENERATE_USER_ID()
	fmt.printfln("Welcome to the OstrichDB Database Management System")
	fmt.printfln("Before getting started please setup your admin account")
	fmt.printfln("Please enter a username for the admin account")

	userName := CREATE_NEW_USERNAME()
	fmt.printfln("Please enter a password for the admin account")
	fmt.printf(
		"Passwords MUST: \n 1. Be least 8 characters \n 2. Contain at least one uppercase letter \n 3. Contain at least one number \n 4. Contain at least one special character \n",
	)
	libc.system("stty -echo")
	CREATE_NEW_USER_PASSWORD()
	salt := string(user.salt.valAsBytes)
	hash := string(user.hashedPassword.valAsBytes)
	storeMethod := fmt.tprintf("%d", user.store_method)
	userID := data.GENERATE_ID(true) //for secure clustser, the cluster id is the user id
	user.username.Value = userName
	types.current_user.username.Value = userName

	// //store the id to both clusters in the id collection
	APPEND_ID_TO_ID_COLLECTION(fmt.tprintf("%d", user.user_id), 0)
	APPEND_ID_TO_ID_COLLECTION(fmt.tprintf("%d", user.user_id), 1)

	CREATE_NEW_USERS_PROFILE(userName, userID, salt, hash, storeMethod)

	TRY_TO_DECRYPT("", .SYSTEM_CONFIG_PRIVATE, system_user.m_k.valAsBytes)
	//update the engine init value in th system configs
	engineInit := config.UPDATE_CONFIG_VALUE(.SYSTEM_CONFIG_PRIVATE, ENGINE_INIT, "true")
	metadata.INIT_METADATA_IN_NEW_COLLECTION(SYSTEM_CONFIG_PATH)
	ENCRYPT_COLLECTION("", .SYSTEM_CONFIG_PRIVATE, system_user.m_k.valAsBytes)

	switch (engineInit)
	{
	case true:
		USER_SIGNIN_STATUS = true
	case false:
		fmt.printfln("Error toggling config")
		os.exit(1)
	}

	metadata.INIT_METADATA_IN_NEW_COLLECTION(utils.concat_user_history_path(userName))
	metadata.INIT_METADATA_IN_NEW_COLLECTION(ID_PATH)
	metadata.INIT_METADATA_IN_NEW_COLLECTION(utils.concat_user_credential_path(userName))

	//Create a cluster within the the users history collection
	historyClusterID := data.GENERATE_ID(true)
	res := CREATE_CLUSTER_BLOCK(
		utils.concat_user_history_path(userName),
		historyClusterID,
		utils.concat_user_history_cluster_name(userName),
	)

	//Encrypt the the system id, user credentials,configs & history collections
	ENCRYPT_COLLECTION(userName, .USER_CREDENTIALS_PRIVATE, system_user.m_k.valAsBytes)
	ENCRYPT_COLLECTION(userName, .USER_CONFIG_PRIVATE, system_user.m_k.valAsBytes)
	ENCRYPT_COLLECTION(userName, .USER_HISTORY_PRIVATE, system_user.m_k.valAsBytes)
	ENCRYPT_COLLECTION("", .SYSTEM_ID_PRIVATE, system_user.m_k.valAsBytes)


	fmt.println("Please re-launch OstrichDB...")
	return 0
}


//Generates and returns a unique id
GENERATE_USER_ID :: proc() -> i64 {
	userID := rand.int63_max(1e16 + 1)
	if data.CHECK_IF_USER_ID_EXISTS(userID) == true {
		utils.log_err("Generated ID already exists in user file", #procedure)
		GENERATE_USER_ID()
	}
	types.user.user_id = userID
	return userID

}

//Prompts user to select a username, ensures it not too long/short or taken, then returns the username
//the isInitializing param will be false when if creating an account post engine initialization,
CREATE_NEW_USERNAME :: proc() -> string {
	using types
	using utils

	show_current_step("Set Up Username", "1", "4")
	buf: [256]byte
	input := utils.get_input(false)

	//At the first instance of a space in the username, warn then prompt again
	for r in input {
		if r == ' ' {
			fmt.printfln(
				"%sWARNING:%s The entered username: %s%s%s contains spaces. Please enter a username that does NOT contain spaces.\n",
				utils.YELLOW,
				utils.RESET,
				utils.BOLD_UNDERLINE,
				input,
				utils.RESET,
			)
			CREATE_NEW_USERNAME()
		}
	}

	// Ensure there are no invalid special characters in the username
	for r in input {
		if r == '!' ||
		   r == '@' ||
		   r == '#' ||
		   r == '$' ||
		   r == '%' ||
		   r == '^' ||
		   r == '&' ||
		   r == '.' ||
		   r == '*' ||
		   r == '_' ||
		   r == '(' ||
		   r == ')' ||
		   r == '+' ||
		   r == '=' ||
		   r == '[' ||
		   r == ']' ||
		   r == '{' ||
		   r == '}' ||
		   r == '|' ||
		   r == ';' ||
		   r == ':' ||
		   r == '"' ||
		   r == '\'' ||
		   r == '<' ||
		   r == '>' ||
		   r == ',' ||
		   r == '/' ||
		   r == '?' {
			fmt.printfln(
				"%sWARNING:%s The entered username: %s%s%s contains special characters. Please enter a username that does NOT contain special characters.",
				utils.YELLOW,
				utils.RESET,
				utils.BOLD_UNDERLINE,
				input,
				utils.RESET,
			)
			fmt.println("The only valid special character is '-'.\n")
			CREATE_NEW_USERNAME()
		}
	}


	if len(input) > 32{
		fmt.printfln("Username is too long. Please enter a username that is 32 characters or less")
		CREATE_NEW_USERNAME()
	}else if len(input) < 2{
		fmt.printfln("Username is too short. Please enter a username that is 2 characters or more")
		CREATE_NEW_USERNAME()
	}



	if CONFIRM_NEW_USERNAME(strings.to_upper(input)) {
		user.username.Value = strings.clone(input)
		user.username.Length = len(input)
	} else {
		fmt.printfln("%sUsernames did not match. Please try again.%s", RED, RESET)
		CREATE_NEW_USERNAME()
	}

	return strings.clone(strings.to_upper(input))
}

CONFIRM_NEW_USERNAME :: proc(username: string) -> (match: bool) {
	using utils
	match = false
	show_current_step("Confirm Username", "2", "4")
	fmt.println("Please re-enter your username")

	confirmation := get_input(false)

	if username == strings.to_upper(confirmation) {
		match = true
	}
	return match
}

//Prompts the user for a password, checks if it is strong enough, then calls the confirm password proc
//the isInitializing param will be false when if creating an account post engine initialization,
CREATE_NEW_USER_PASSWORD :: proc() -> string {
	using types
	using utils

	buf: [256]byte
	show_current_step("Set Up Password", "3", "4")
	fmt.printfln("Please enter a password for %s%s%s:", BOLD_UNDERLINE, user.username.Value, RESET)
	input := utils.get_input(true)

	isStrongPassword := check_password_strength(input)

	switch isStrongPassword {
	case true:
		CONFIRM_NEW_USER_PASSWORD(input)
		break
	case false:
		fmt.printfln("Please try again")
		CREATE_NEW_USER_PASSWORD()
		break
	}

	return strings.clone(input)
}

//Takes in p as password and compares it to the confirmation password
//if the passwords do not match, the user is prompted to re-enter the password
//the isInitializing param will be false when if creating an account post engine initialization,
CONFIRM_NEW_USER_PASSWORD :: proc(p: string) -> string {
	using types
	using utils

	show_current_step("Confirm Password", "4", "4")
	buf: [256]byte

	fmt.printfln(
		"Please re-enter the password for %s%s%s:",
		BOLD_UNDERLINE,
		user.username.Value,
		RESET,
	)
	input := utils.get_input(true)
	confirmation: string

	if len(input) > 0 {
		confirmation = input
		//trim the string of any whitespace or newline characters

		//Shoutout to the OdinLang Discord for helping me with this...
		confirmation = strings.trim_right_proc(confirmation, proc(r: rune) -> bool {
				return r == '\r' || r == '\n'
			})
	}
	if p != confirmation {
		fmt.printfln("Passwords do not match. Please try again")
		CREATE_NEW_USER_PASSWORD()
	} else {
		user.password.Length = len(p)
		user.password.Value = strings.clone(p)
		user.hashedPassword.valAsBytes = HASH_PASSWORD(p, 0, false, true)
		encodedPassword := ENCODE_HASHED_PASSWORD(user.hashedPassword.valAsBytes)
		user.hashedPassword.valAsBytes = encodedPassword
	}
	libc.system("stty echo")
	return strings.clone(types.user.password.Value)
}

//Stores the entered user credentials in the users secure collection file/cluster
// The file(collection) and clustername will always be the same value when this is called
// id- cluster id, rn- record name, rd- record data
STORE_USER_CREDENTIALS :: proc(
	fileAndClusterName: string,
	id: i64,
	rn: string,
	rd: string,
) -> int {
	using metadata
	using const
	using utils

	secureFilePath := concat_user_credential_path(fileAndClusterName)

	file, openSuccess := os.open(secureFilePath, os.O_APPEND | os.O_WRONLY, 0o666)
	defer os.close(file)
	if openSuccess != 0 {
		errorLocation := get_caller_location()
		error1 := utils.new_err(
			.CANNOT_OPEN_FILE,
			utils.get_err_msg(.CANNOT_OPEN_FILE),
			errorLocation,
		)
		throw_err(error1)
		log_err("Error opening user credentials file", #procedure)
	}
	defer os.close(file)


	data.CREATE_CLUSTER_BLOCK(secureFilePath, id, fileAndClusterName)
	data.CREATE_AND_APPEND_PRIVATE_RECORD(
		secureFilePath,
		fileAndClusterName,
		rn,
		rd,
		"identifier",
		id,
	)

	UPDATE_METADATA_FIELD_AFTER_OPERATION(secureFilePath)
	return 0
}

// checks if the passed in password is strong enough returns true or false.
check_password_strength :: proc(p: string) -> bool {
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

CREATE_NEW_USERS_PROFILE :: proc(userName: string, id: i64, salt, hash, storeMethod: string) {
	using data
	using types
	using const

	//Create a directory and a credentials collection for the user
	os.make_directory(fmt.tprintf("%s/%s/", USERS_PATH, userName))
	CREATE_COLLECTION(userName, .USER_CREDENTIALS_PRIVATE)

	//Create the users own command(query) history collection
	CREATE_COLLECTION(userName, .USER_HISTORY_PRIVATE)

	//Create the users own collection backup directory
	os.make_directory(fmt.tprintf("%s/%s/backups/", USERS_PATH, userName))

	//Create the users own config collection
	CREATE_COLLECTION(userName, .USER_CONFIG_PRIVATE)
	CREATE_CLUSTER_BLOCK(
		utils.concat_user_config_collection_name(userName),
		user.user_id,
		utils.concat_user_config_cluster_name(userName),
	)
	config.APPEND_ALL_CONFIGS_TO_CONFIG_FILE(types.CollectionType.USER_CONFIG_PRIVATE, userName)

	// GENERATE_MASTER_KEY returns a 32 byte master key that is hex encoded
	mk := GENERATE_MASTER_KEY()
	mkAsString := transmute(string)mk //dont worry about this
	// user.m_k.valAsStr = mkAsString //dont worry about this

	//this value is passed to my encryption and decryption functions. must be 32 bytes
	user.m_k.valAsBytes = DECODE_MASTER_KEY(mk)

	//Store all the user credentials within the secure collection
	STORE_USER_CREDENTIALS(userName, user.user_id, "user_name", userName)
	STORE_USER_CREDENTIALS(userName, user.user_id, "role", "admin")
	STORE_USER_CREDENTIALS(userName, user.user_id, "salt", salt)
	STORE_USER_CREDENTIALS(userName, user.user_id, "hash", hash)
	STORE_USER_CREDENTIALS(userName, user.user_id, "store_method", storeMethod)
	STORE_USER_CREDENTIALS(userName, user.user_id, "m_k", mkAsString)

}

// creates a new user account post engine initialization
//also determines if the currently logged in user has permission to create a new user account
//allows for test mode to be used to create a new user without the need for interactive input
// OST_CREATE_NEW_USER :: proc(
// 	username: string = "",
// 	password: string = "",
// 	role: string = "",
// ) -> int {
// 	using types

// 	buf: [1024]byte
// 	if user.role.Value == "admin" {
// 		fmt.println("Please enter role you would like to assign the new account")
// 		fmt.printf("1. Admin\n2. User\n3. Guest\n")
// 		input := utils.get_input(false)

// 		inputToCap := strings.to_upper(input)
// 		if inputToCap == "1" || inputToCap == "ADMIN" {
// 			new_user.role.Value = "admin"
// 		} else if inputToCap == "2" || inputToCap == "USER" {
// 			new_user.role.Value = "user"
// 		} else if inputToCap == "3" || inputToCap == "GUEST" {
// 			new_user.role.Value = "guest"
// 		} else {
// 			fmt.printfln("Invalid role entered")
// 			return 1
// 		}
// 	} else if (user.role.Value == "user") {
// 		new_user.role.Value = "guest"
// 	} else {
// 		fmt.println("You do not have the required permissions to create a new account")
// 		fmt.printfln("To create a new account you must be logged in as an admin or user account")
// 		return 1
// 	}

// 	newUserName := CREATE_NEW_USERNAME(false)
// 	new_user.username.Value = newUserName


// 	// Common validation logic for both test and interactive modes
// 	isBannedUsername := check_if_username_is_banned(new_user.username.Value)
// 	if isBannedUsername {
// 		fmt.printfln("Username is banned. Please enter a different username")
// 		fmt.println("Cannot create user with name: ", new_user.username.Value)
// 		return 1
// 	}

// 	newColName := fmt.tprintf("secure_%s", new_user.username.Value)
// 	exists, _ := data.FIND_SECURE_COLLECTION(newColName)

// 	if exists {
// 		fmt.printfln(
// 			"There is already a user with the name: %s%s%s\nPlease try again.",
// 			utils.BOLD_UNDERLINE,
// 			new_user.username.Value,
// 			utils.RESET,
// 		)
// 		return 1
// 	}

// 	result := data.CREATE_COLLECTION(newColName, .USER_CREDENTIALS_PRIVATE)
// 	fmt.printf(
// 		"Passwords MUST: \n 1. Be least 8 characters \n 2. Contain at least one uppercase letter \n 3. Contain at least one number \n 4. Contain at least one special character \n",
// 	)
// 	libc.system("stty -echo")
// 	initpassword := CREATE_NEW_USER_PASSWORD(false)
// 	libc.system("stty echo")
// 	new_user.password.Value = initpassword


// 	saltAsString := string(new_user.salt.valAsStr)
// 	hashAsString := string(new_user.hashedPassword.valAsStr)
// 	algoMethodAsString := strconv.itoa(buf[:], new_user.store_method)

// 	new_user.user_id = data.GENERATE_ID(true)

// 	//store the id to both clusters in the id collection
// 	data.APPEND_ID_TO_ID_COLLECTION(fmt.tprintf("%d", new_user.user_id), 0)
// 	data.APPEND_ID_TO_ID_COLLECTION(fmt.tprintf("%d", new_user.user_id), 1)

// 	// Store user credentials
// 	STORE_USER_CREDENTIALS(
// 		newColName,
// 		new_user.username.Value,
// 		new_user.user_id,
// 		"user_name",
// 		new_user.username.Value,
// 	)
// 	STORE_USER_CREDENTIALS(
// 		newColName,
// 		new_user.username.Value,
// 		new_user.user_id,
// 		"role",
// 		new_user.role.Value,
// 	)
// 	STORE_USER_CREDENTIALS(
// 		newColName,
// 		new_user.username.Value,
// 		new_user.user_id,
// 		"salt",
// 		saltAsString,
// 	)
// 	STORE_USER_CREDENTIALS(
// 		newColName,
// 		new_user.username.Value,
// 		new_user.user_id,
// 		"hash",
// 		hashAsString,
// 	)
// 	STORE_USER_CREDENTIALS(
// 		newColName,
// 		new_user.username.Value,
// 		new_user.user_id,
// 		"store_method",
// 		algoMethodAsString,
// 	)

// 	// Create history cluster.
// 	data.CREATE_CLUSTER_BLOCK(const.HISTORY_PATH, user.user_id, new_user.username.Value)

// 	return 0
// }

//Checks that un as username is not a banned username from the banned usernames list
check_if_username_is_banned :: proc(un: string) -> bool {
	for i := 0; i < len(const.BannedUserNames); i += 1 {
		if strings.contains(un, const.BannedUserNames[i]) {
			return true
		}
	}
	return false
}

//Searches the `{root}/private/users` dir for a sub dir for with the passed in username
FIND_USERS_PROFILE :: proc(username: string) -> bool {
	using const
	found := false

	//Look for a dir with the passed in username
	userDir, _ := os.open(USERS_PATH, 0)
	userProfiles, readDirError := os.read_dir(userDir, -1)
	for profile in userProfiles {
		if profile.is_dir {
			if profile.name == username {
				found = true
				break
			}
		}
	}

	return found
}

//looks over the passed in users dir for the passed in files if found, return true. Assumes the user does exist
//Each users should have the following core files in their profile:
//- user.config.ostrichdb
//- user.credentials.ostrichdb
//- user.history.ostrichdb
FIND_USERS_CORE_FILE :: proc(username: string, fileToFind: int) -> bool {
	using const
	found := false
	fileName: string

	switch (fileToFind) {
	case 0:
		fileName = USER_CREDENTIAL_FILE_NAME
		break
	case 1:
		fileName = USER_CONFIGS_FILE_NAME
		break
	case 2:
		fileName = USER_HISTORY_FILE_NAME
		break
	}

	userProfileDir, _ := os.open(fmt.tprintf("%s/%s", USERS_PATH, username), 0)
	coreFiles, readDirError := os.read_dir(userProfileDir, -1)
	for coreFile in coreFiles {
		if coreFile.name == fileName {
			found = true
			break
		}
	}


	return found
}
