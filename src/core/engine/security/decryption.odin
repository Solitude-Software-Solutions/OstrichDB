package security

import "../../../utils"
import "../../const"
import "../../types"
// import "core:crypto/_aes"
import "core:crypto/aead"
import "core:crypto/aes"
import "core:encoding/hex"
import "core:fmt"
import "core:math/rand"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            All the logic for decrypting collection files can be found within
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


//
// OST_DECRYPT_COLLECTION :: proc(
// 	fName: string,
// 	fType: types.CollectionType,
// 	user: types.User,
// 	tag: []byte,
// ) -> int {
// 	masterKey: []byte
// 	file: string
// 	switch (fType) {
// 	case .STANDARD_PUBLIC:
// 		//Public Standard Collection
// 		file = utils.concat_collection_name(fName)
// 	case .SECURE_PRIVATE:
// 		//Private Secure Collection
// 		file = fmt.tprintf(
// 			"secure_%s%s",
// 			&types.current_user.username.Value,
// 			const.OST_FILE_EXTENSION,
// 		)
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
// 		return -1
// 	}

// 	#partial switch (fType) {
// 	case .STANDARD_PUBLIC:
// 		//Standard(public) collections
// 		masterKey = user.m_k.valAsBytes
// 	case:
// 		// Private collections only OstrichDB has access to
// 		masterKey = types.system_user.m_k.valAsBytes
// 	}

// 	encryptedData, readSuccess := utils.read_file(file, #procedure)
// 	if !readSuccess {
// 		fmt.printfln("Failed to read file: %s in procedure: %s", file, #procedure)
// 		return -2
// 	}
// 	defer delete(encryptedData)

// 	//https://pkg.odin-lang.org/core/crypto/aes/#Context_GCM
// 	gcmContext := new(aes.Context_GCM)
// 	aes.init_gcm(gcmContext, masterKey)

// 	// Say encryptedData is 319 bytes long
// 	// iv: is the first 16 bytes
// 	// ciphertext: is the amount of bytes after the iv in this case 303 bytes
// 	// aad: Additional Authenticated Data
// 	// Tag Info: https://www.cryptosys.net/pki/manpki/pki_aesgcmauthencryption.html#:~:text=The%20tag%20is%20sometimes%20called,Encryption%22%20%5BRFC%205116%5D.

// 	iv := encryptedData[:aes.BLOCK_SIZE]
// 	ciphertext := encryptedData[aes.BLOCK_SIZE:]
// 	aad: []byte

// 	dataToDecrypt := make([]byte, len(ciphertext))

// 	fmt.println("Showing decryption results of file: ", file)
// 	fmt.println("master key @ decrption: ", masterKey)
// 	fmt.println("iv: @ decryption", iv) //debugging
// 	fmt.println("aad: @ decryption", aad) //debugging
// 	fmt.println("tag @ decryption: ", tag) //debugging
// 	fmt.println("ciphertext @ decryption: ", ciphertext) //debugging

// 	//https://pkg.odin-lang.org/core/crypto/aes/#open_gcm
// 	success := aes.open_gcm(gcmContext, dataToDecrypt, iv, aad, ciphertext, tag)

// 	if !success {
// 		fmt.printfln("Failed to decrypt file: %s in procedure: %s", file, #procedure)
// 		return -3
// 	}

// 	writeSuccess := utils.write_to_file(file, dataToDecrypt, #procedure)
// 	if !writeSuccess {
// 		fmt.printfln("Failed to write to file in procedure: %s", #procedure)
// 		return -4
// 	}

// 	// https://pkg.odin-lang.org/core/crypto/aes/#reset_gcm
// 	aes.reset_gcm(gcmContext)

// 	//freeing up the tag buffer so it can be reused
// 	delete(types.temp_DE.tag)

// 	return 0
// }


test_decrypt :: proc(key, ciphertext: []u8) -> []u8 {
	// assert(len(key) == aes.KEY_SIZE_256) //key MUST be 32 bytes

	n := len(ciphertext) - aes.GCM_IV_SIZE - aes.GCM_TAG_SIZE //n is the size of the ciphertext minus 16 bytes for the iv then minus another 16 bytes for the tag
	if n <= 0 do return nil //if n is less than or equal to 0 then return nil

	aad: []u8 = nil
	decryptedDataDestination := make([]u8, n) //allocate the size of the decrypted data that comes from the allocation context
	iv := ciphertext[:aes.GCM_IV_SIZE] //iv is the first 16 bytes
	encryptedData := ciphertext[aes.GCM_IV_SIZE:][:n] //the actual encryptedData is the bytes after the iv
	tag := ciphertext[aes.GCM_IV_SIZE + n:] // tag is the 16 bytes at the end of the ciphertext

	gcmContext: aes.Context_GCM
	aes.init_gcm(&gcmContext, key) //initialize the gcm context with the key

	if aes.open_gcm(&gcmContext, decryptedDataDestination, iv, aad, encryptedData, tag) {
		fmt.println("Decryption successful")
		return decryptedDataDestination
	} else {
		delete(decryptedDataDestination)
		fmt.println("Failed to decrypt data")
		return nil
	}
	fmt.println("============================================================")
	// fmt.println("Showing decryption results of file: ", file)
	fmt.println("master key @ decrption: ", key)
	fmt.println("iv: @ decryption", iv) //debugging
	fmt.println("aad: @ decryption", aad) //debugging
	fmt.println("tag @ decryption: ", tag) //debugging

	aes.reset_gcm(&gcmContext)

	return nil
}
