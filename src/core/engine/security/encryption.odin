package security

import "../../../utils"
import "../../const"
import "../../types"
import "core:crypto/"
import "core:crypto/aead"
import "core:crypto/aes"
import "core:encoding/hex"
import "core:fmt"
import "core:os"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            All the logic for encrypting collection files can be found within
*********************************************************/


/*
Note: Here is a general outline of the "EDE" process within OstrichDB:

Encryption rocess :
1. Generate IV (16 bytes)
2. Create ciphertext buffer (same size as input data)
3. Create tag buffer (16 bytes for GCM)
4. Encrypt the data into ciphertext buffer
5. Combine IV + ciphertext for storage

In plaintest the encrypted data would look like:
[IV (16 bytes)][Ciphertext (N bytes)]
Where N is the size of the plaintext data
----------------------------------------

Decryption process :
1. Read IV from encrypted data
2. Read ciphertext from encrypted data
3. Use IV, ciphertext, and tag to decrypt data
*/

//FType - 0 = Standard(public) collection,  1 = Secure(private) collection,2 config(core), 3 = history(core), 4 = ids(core)
//user - user is passed so the the proc can access 1, the username, and 2, the users master key
OST_ENCRYPT_COLLECTION :: proc(fName: string, fType: int, user: ..^types.User) -> int {
	//depending on collection file type, concat correct path
	masterKey: []byte
	file: string
	switch (fType) {
	case 0:
		//Standard Collection
		file = utils.concat_collection_name(fName)
	case 1:
		//Secure Collection
		file = fmt.tprintf(
			"secure_%s%s",
			&types.current_user.username.Value,
			const.OST_FILE_EXTENSION,
		)
	case 2:
		//Config Collection
		file = const.OST_CONFIG_PATH
	case 3:
		//History Collection
		file = const.OST_HISTORY_PATH
	case 4:
		//ID Collection
		file = const.OST_ID_PATH
	//case 5: Todo: Add case for benchmark collections and quarantine collections
	case:
		fmt.printfln("Invalid File Type Passed in procedure: %s", #procedure)
		return -1
	}

	//Evalauete what master key to use based on collection type
	switch (fType) {
	case 0:
		//Standard(public) collections
		masterKey = types.current_user.m_k.valAsBytes
	case 1 ..< 4:
		// Private collections only OstrichDB has access to
		masterKey = const.SYS_MASTER_KEY
	}


	data, readSuccess := utils.read_file(file, #procedure)
	if !readSuccess {
		return -2
	}
	defer delete(data)

	gcmContext := types.temp_DE.contxt
	aes.init_gcm(&gcmContext, masterKey)

	iv := OST_GENERATE_IV()
	aad: []byte

	// The ciphertext needs to be exactly the size of the plaintext(file data)
	ciphertext := make([]byte, len(data))
	tag := make([]byte, aes.GCM_TAG_SIZE)

	// https://pkg.odin-lang.org/core/crypto/aes/#seal_gcm
	aes.seal_gcm(&gcmContext, ciphertext, tag, iv, aad, data)
	// Store tag for dec
	types.temp_DE.tag = tag

	// Create final buffer that includes IV + ciphertext
	finalData := make([]byte, len(iv) + len(ciphertext))
	copy(finalData[:len(iv)], iv)
	copy(finalData[len(iv):], ciphertext)

	writeSuccess := utils.write_to_file(file, finalData, #procedure)
	if !writeSuccess {
		return -3
	}

	aes.reset_gcm(&gcmContext)
	return 0
}


//IV is the initialization vector for the encryption
OST_GENERATE_IV :: proc() -> []byte {
	iv := make([]byte, aes.BLOCK_SIZE)
	crypto.rand_bytes(iv)
	return iv
}


OST_CHECK_IF_COLLECTION_IS_ENCRYPTED :: proc(fName: string, fType: int) -> int {
	masterKey: []byte
	file: string

	switch (fType) {
	case 0:
		//Standard Collection
		file = utils.concat_collection_name(fName)
	case 1:
		//Secure Collection
		file = fmt.tprintf(
			"secure_%s%s",
			&types.current_user.username.Value,
			const.OST_FILE_EXTENSION,
		)
	case 2:
		//Config Collection
		file = const.OST_CONFIG_PATH
	case 3:
		//History Collection
		file = const.OST_HISTORY_PATH
	case 4:
		//ID Collection
		file = const.OST_ID_PATH
	case:
		fmt.printfln("Invalid File Type Passed in procedure: %s", #procedure)
		return -1
	}

	// Read the file content
	data, readSuccess := utils.read_file(file, #procedure)
	if !readSuccess {
		return -2
	}
	defer delete(data)

	// Check if file is large enough to contain IV (16 bytes) and some encrypted content
	// //if the file is less than 16 bytes, it is not encrypted
	if len(data) < aes.BLOCK_SIZE {
		return 1
	}

	// Check if the file starts with a valid IV (16 bytes)
	// and has additional content (encrypted data)
	if len(data) > aes.BLOCK_SIZE {
		return 0
	}

	return -3
}


OST_RUN_ENC_CHECKS :: proc() {


	//Todo: This needs to be moved bacause the secure_ collection doesnt get created until after initial user setup
	//I know this is shit and I apologize but I really just want to get this shit done
	// if OST_CHECK_IF_COLLECTION_IS_ENCRYPTED("", 1) == 1 {
	// 	if OST_ENCRYPT_COLLECTION("", 1) != 0 {
	// 		fmt.printfln(const.encWarningMsg)
	// 		os.exit(1)
	// 	} else {
	// 		fmt.printfln("Standard collection status: %sEncrypted%s", utils.GREEN, utils.RESET)
	// 	}
	// } else if OST_CHECK_IF_COLLECTION_IS_ENCRYPTED("", 1) == 0 {
	// 	fmt.printfln("Secure collection status: %sEncrypted%s", utils.GREEN, utils.RESET)
	// }


	//Todo: This needs to be moved bacause the histoy collection doesnt get created until after the initial user set up
	// if OST_CHECK_IF_COLLECTION_IS_ENCRYPTED("", 3) == 1 {
	// 	if OST_ENCRYPT_COLLECTION("", 3) != 0 {
	// 		fmt.printfln(const.encWarningMsg)
	// 		os.exit(1)
	// 	} else {
	// 		fmt.printfln("History collection status: %sEncrypted%s", utils.GREEN, utils.RESET)
	// 	}
	// } else if OST_CHECK_IF_COLLECTION_IS_ENCRYPTED("", 3) == 0 {
	// 	fmt.printfln("History collection status: %sEncrypted%s", utils.GREEN, utils.RESET)
	// }

	if OST_CHECK_IF_COLLECTION_IS_ENCRYPTED("", 4) == 1 {
		if OST_ENCRYPT_COLLECTION("", 4) != 0 {
			fmt.printfln(const.encWarningMsg)
			os.exit(1)
		} else {
			fmt.printfln("ID collection status: %sEncrypted%s", utils.GREEN, utils.RESET)
		}
	} else if OST_CHECK_IF_COLLECTION_IS_ENCRYPTED("", 4) == 0 {
		fmt.printfln("ID collection status: %sEncrypted%s", utils.GREEN, utils.RESET)

	}
}
