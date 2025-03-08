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

//user - user is passed so the the proc can access 1, the username, and 2, the users master key
// OST_ENCRYPT_COLLECTION :: proc(
// 	fName: string,
// 	fType: types.CollectionType,
// 	user: types.User,
// ) -> (
// 	int,
// 	[]byte,
// ) {
// 	//depending on collection file type, concat correct path
// 	masterKey := user.m_k.valAsBytes
// 	file: string
// 	switch (fType) {
// 	case .STANDARD_PUBLIC:
// 		//Public Standard Collection
// 		file = utils.concat_collection_name(fName)
// 	case .SECURE_PRIVATE:
// 		//Private Secure Collection
// 		if user.username.Value == "OstrichDB" {
// 			//If the user is the system user, break..This proc will not need to do anything with the file if the user is the system user
// 			break
// 		} else {
// 			file = fmt.tprintf(
// 				"%ssecure_%s%s",
// 				const.OST_SECURE_COLLECTION_PATH,
// 				user.username.Value,
// 				const.OST_FILE_EXTENSION,
// 			)
// 		}
// 	case .CONFIG_PRIVATE:
// 		//Private Config Collection
// 		file = const.OST_CONFIG_PATH
// 	case .HISTORY_PRIVATE:
// 		//Private History Collection
// 		file = const.OST_HISTORY_PATH
// 	case .ID_PRIVATE:
// 		//Private ID Collection
// 		file = const.OST_ID_PATH
// 	//case 5: Todo: Add case for benchmark collections and quarantine collections
// 	case:
// 		fmt.printfln("Invalid File Type Passed in procedure: %s", #procedure)
// 		return -1, []byte{}
// 	}

// 	//Evalauete what master key to use based on collection type
// 	#partial switch (fType) {
// 	case .STANDARD_PUBLIC:
// 		//Standard(public) collections
// 		// fmt.println("len of key: ", len(user.m_k.valAsBytes)) //debugging
// 		// fmt.println("key: ", user.m_k.valAsBytes) //debugging
// 		break
// 	case .SECURE_PRIVATE ..< .ID_PRIVATE:
// 		// Private collections only OstrichDB has access to
// 		// fmt.println("len of key: ", len(types.system_user.m_k.valAsBytes)) //debugging
// 		// fmt.println("key: ", types.system_user.m_k.valAsBytes) //debugging
// 		masterKey = types.system_user.m_k.valAsBytes
// 	case:
// 		fmt.printfln("Invalid File Type Passed in procedure: %s", #procedure)
// 		return -1, []byte{}
// 	}
// 	////////////////////////////////////////////////////////

// 	data, readSuccess := utils.read_file(file, #procedure)
// 	if !readSuccess {
// 		return -2, []byte{}
// 	}
// 	defer delete(data)

// 	gcmContext := new(aes.Context_GCM)
// 	aes.init_gcm(gcmContext, masterKey)

// 	iv := OST_GENERATE_IV()
// 	aad: []byte

// 	// The ciphertext needs to be exactly the size of the plaintext(file data)
// 	ciphertext := make([]byte, len(data))
// 	tag := make([]byte, aes.GCM_TAG_SIZE)
// 	fmt.println("============================================================")
// 	fmt.println("Showing encryption results of file: ", file)
// 	fmt.println("master key @ encryption: ", masterKey)
// 	fmt.println("iv: @ encryption", iv) //debugging
// 	fmt.println("aad: @ encryption", aad) //debugging

// 	// https://pkg.odin-lang.org/core/crypto/aes/#seal_gcm
// 	aes.seal_gcm(gcmContext, ciphertext, tag, iv, aad, data)
// 	// Store tag for dec

// 	t := tag
// 	fmt.println("tag @ encryption: ", t) //debugging
// 	fmt.println("ciphertext @ encryption: ", ciphertext) //debugging
// 	fmt.println("============================================================")
// 	// Create final buffer that includes IV + ciphertext
// 	finalData := make([]byte, len(iv) + len(ciphertext))
// 	copy(finalData[:len(iv)], iv)
// 	copy(finalData[len(iv):], ciphertext)

// 	writeSuccess := utils.write_to_file(file, finalData, #procedure)
// 	if !writeSuccess {
// 		return -3, []byte{}
// 	}

// 	aes.reset_gcm(gcmContext)
// 	return 0, t
// }


// //IV is the initialization vector for the encryption
// //16 bytes
// OST_GENERATE_IV :: proc() -> []byte {
// 	iv := make([]byte, aes.BLOCK_SIZE)
// 	crypto.rand_bytes(iv)
// 	return iv
// }


// OST_CHECK_IF_COLLECTION_IS_ENCRYPTED :: proc(fName: string, fType: types.CollectionType) -> int {
// 	file: string

// 	switch (fType) {
// 	case .STANDARD_PUBLIC:
// 		file = utils.concat_collection_name(fName)
// 	case .SECURE_PRIVATE:
// 		file = fmt.tprintf(
// 			"secure_%s%s",
// 			&types.current_user.username.Value,
// 			const.OST_FILE_EXTENSION,
// 		)
// 	case .CONFIG_PRIVATE:
// 		file = const.OST_CONFIG_PATH
// 	case .HISTORY_PRIVATE:
// 		file = const.OST_HISTORY_PATH
// 	case .ID_PRIVATE:
// 		file = const.OST_ID_PATH
// 	case:
// 		fmt.printfln("Invalid File Type Passed in procedure: %s", #procedure)
// 		return -1
// 	}

// 	// Read the file content
// 	data, readSuccess := utils.read_file(file, #procedure)
// 	if !readSuccess {
// 		return -2
// 	}
// 	defer delete(data)

// 	// Check minimum required size for encrypted data (IV + at least some content)
// 	if len(data) < aes.BLOCK_SIZE + aes.GCM_TAG_SIZE {
// 		return 1 // Not encrypted
// 	}

// 	// Extract IV from the beginning of the file
// 	iv := data[:aes.BLOCK_SIZE]

// 	// Check if IV looks random (a characteristic of encrypted data)
// 	// We'll check if it contains all zeros or all same value
// 	all_same := true
// 	for i := 1; i < len(iv); i += 1 {
// 		if iv[i] != iv[0] {
// 			all_same = false
// 			break
// 		}
// 	}

// 	if all_same {
// 		return 1 // Likely not encrypted
// 	}

// 	// Additional pattern check: encrypted data should look random
// 	// Check if the rest of the data has some variation
// 	remaining_data := data[aes.BLOCK_SIZE:]
// 	variation_count := 0
// 	last_byte := remaining_data[0]

// 	for i := 1; i < min(len(remaining_data), 32); i += 1 {
// 		if remaining_data[i] != last_byte {
// 			variation_count += 1
// 		}
// 		last_byte = remaining_data[i]
// 	}

// 	// If we see enough variation in the data, it's likely encrypted
// 	if variation_count > 10 {
// 		return 0 // Encrypted
// 	}

// 	return 1 // Not encrypted
// }


test_encrypt :: proc(colName: string, colType: types.CollectionType, user: types.User) -> []u8 {

	file: string
	key := user.m_k.valAsBytes
	// assert(len(key) == aes.KEY_SIZE_256) //key MUST be 32 bytes

	switch (colType) {
	case .STANDARD_PUBLIC:
		//Public Standard Collection
		file = utils.concat_collection_name(colName)
	case .SECURE_PRIVATE:
		//Private Secure Collection
		if user.username.Value == "OstrichDB" {
			//If the user is the system user, break..This proc will not need to do anything with the file if the user is the system user
			break
		} else {
			file = fmt.tprintf(
				"%ssecure_%s%s",
				const.OST_SECURE_COLLECTION_PATH,
				user.username.Value,
				const.OST_FILE_EXTENSION,
			)
		}
	case .CONFIG_PRIVATE:
		//Private Config Collection
		file = const.OST_CONFIG_PATH
	case .HISTORY_PRIVATE:
		//Private History Collection
		file = const.OST_HISTORY_PATH
	case .ID_PRIVATE:
		//Private ID Collection
		file = const.OST_ID_PATH
	//case 5: Todo: Add case for benchmark collections and quarantine collections
	case:
		fmt.printfln("Invalid File Type Passed in procedure: %s", #procedure)
		return []u8{}
	}

	//Evalauete what master key to use based on collection type
	#partial switch (colType) {
	case .STANDARD_PUBLIC:
		//Standard(public) collections
		break
	case .SECURE_PRIVATE ..< .ID_PRIVATE:
		// Private collections only OstrichDB has access to
		key = types.system_user.m_k.valAsBytes
	case:
		fmt.printfln("Invalid File Type Passed in procedure: %s", #procedure)
		return []u8{}
	}


	data, readSuccess := utils.read_file(file, #procedure)
	if !readSuccess {
		return []u8{}
	}
	defer delete(data)

	n := len(data) //n is the size of the data


	aad: []u8 = nil
	dst := make([]u8, n + aes.GCM_IV_SIZE + aes.GCM_TAG_SIZE) //create a buffer that is the size of the data plus 16 bytes for the iv and 16 bytes for the tag
	iv := dst[:aes.GCM_IV_SIZE] //set the iv to the first 16 bytes of the buffer
	encryptedData := dst[aes.GCM_IV_SIZE:][:n] //set the actual encrypted data to the bytes after the iv
	tag := dst[aes.GCM_IV_SIZE + n:] //set the tag to the 16 bytes at the end of the buffer


	// fmt.println("dst: ", dst) //debugging

	crypto.rand_bytes(iv) //generate a random iv

	gcmContext: aes.Context_GCM //create a gcm context
	aes.init_gcm(&gcmContext, key) //initialize the gcm context with the key


	aes.seal_gcm(&gcmContext, encryptedData, tag, iv, aad, data) //encrypt the data
	fmt.println("encryptedData: ", encryptedData) //debugging
	fmt.println("============================================================")
	fmt.println("Showing encryption results of file: ", file)
	fmt.println("master key @ encryption: ", key)
	fmt.println("iv: @ encryption", iv) //debugging
	fmt.println("aad: @ encryption", aad) //debugging
	fmt.println("tag @ encryption: ", tag) //debugging

	writeSuccess := utils.write_to_file(file, dst, #procedure) //write the encrypted data to the file

	if !writeSuccess {
		return []u8{}
	}

	return dst //return the encrypted data


}

// OST_RUN_ENC_CHECKS :: proc() {
// 	//I know this is shit and I apologize but I really just want to get this shit done
// 	if OST_CHECK_IF_COLLECTION_IS_ENCRYPTED("", .SECURE_PRIVATE) == 1 {
// 		if OST_ENCRYPT_COLLECTION("", .SECURE_PRIVATE, &types.user) != 0 {
// 			fmt.printfln(const.encWarningMsg)
// 			os.exit(1)
// 		} else {
// 			fmt.printfln("Standard collection status: %sEncrypted%s", utils.GREEN, utils.RESET)
// 		}
// 	} else if OST_CHECK_IF_COLLECTION_IS_ENCRYPTED("", .SECURE_PRIVATE) == 0 {
// 		fmt.printfln("Secure collection status: %sEncrypted%s", utils.GREEN, utils.RESET)
// 	}

// 	// if OST_CHECK_IF_COLLECTION_IS_ENCRYPTED("", 3) == 1 {
// 	// 	if OST_ENCRYPT_COLLECTION("", 3, &types.system_user) != 0 {
// 	// 		fmt.printfln(const.encWarningMsg)
// 	// 		os.exit(1)
// 	// 	} else {
// 	// 		fmt.printfln("History collection status: %sEncrypted%s", utils.GREEN, utils.RESET)
// 	// 	}
// 	// } else if OST_CHECK_IF_COLLECTION_IS_ENCRYPTED("", 3) == 0 {
// 	// 	fmt.printfln("History collection status: %sEncrypted%s", utils.GREEN, utils.RESET)
// 	// }

// 	if OST_CHECK_IF_COLLECTION_IS_ENCRYPTED("", .ID_PRIVATE) == 1 {
// 		if OST_ENCRYPT_COLLECTION("", .ID_PRIVATE, &types.system_user) != 0 {
// 			fmt.printfln(const.encWarningMsg)
// 			os.exit(1)
// 		} else {
// 			fmt.printfln("ID collection status: %sEncrypted%s", utils.GREEN, utils.RESET)
// 		}
// 	} else if OST_CHECK_IF_COLLECTION_IS_ENCRYPTED("", .ID_PRIVATE) == 0 {
// 		fmt.printfln("ID collection status: %sEncrypted%s", utils.GREEN, utils.RESET)

// 	}
// }
