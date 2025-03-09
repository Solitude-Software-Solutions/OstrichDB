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
OST_ENCRYPT_COLLECTION :: proc(colName: string, colType: types.CollectionType, key: []u8) -> []u8 {
	file: string
	// assert(len(key) == aes.KEY_SIZE_256) //key MUST be 32 bytes

	switch (colType) {
	case .STANDARD_PUBLIC:
		//Public Standard Collection
		file = utils.concat_collection_name(colName)
	case .SECURE_PRIVATE:
		//Private Secure Collection
		file = fmt.tprintf(
			"%ssecure_%s%s",
			const.OST_SECURE_COLLECTION_PATH,
			colName,
			const.OST_FILE_EXTENSION,
		)
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

	data, readSuccess := utils.read_file(file, #procedure)
	if !readSuccess {
		fmt.printfln("Failed to read file: %s", file)
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
	// fmt.println("encryptedData: ", encryptedData) //debugging
	// fmt.println("============================================================")
	// fmt.println("Showing encryption results of file: ", file) //debugging
	// fmt.println("master key @ encryption: ", key) //debugging
	// fmt.println("iv: @ encryption", iv) //debugging
	// fmt.println("aad: @ encryption", aad) //debugging
	// fmt.println("tag @ encryption: ", tag) //debugging

	writeSuccess := utils.write_to_file(file, dst, #procedure) //write the encrypted data to the file

	if !writeSuccess {
		fmt.printfln("Failed to write to file: %s", file)
		return []u8{}
	}

	return dst //return the encrypted data
}
