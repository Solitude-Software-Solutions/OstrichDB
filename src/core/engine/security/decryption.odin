package security

import "../../../utils"
import "../../const"
import "../../types"
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

//FType - 0 = Standard(public) collection,  1 = Secure(private) collection,2 config(core), 3 = history(core), 4 = ids(core)
OST_DECRYPT_COLLECTION :: proc(fName: string, fType: int, user: ..^types.User) -> bool {
	masterKey: []byte
	file: string
	switch (fType) {
	case 0:
		//Standard Collection or test collection
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
		return false
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

	encryptedData, readSuccess := utils.read_file(file, #procedure)
	if !readSuccess {
		fmt.printfln("Failed to read file: %s in procedure: %s", file, #procedure)
		return false
	}
	defer delete(encryptedData)

	//https://pkg.odin-lang.org/core/crypto/aes/#Context_GCM
	gcmContext := types.temp_DE.contxt
	aes.init_gcm(&gcmContext, masterKey)

	// Say encryptedData is 319 bytes long
	// iv: is the first 16 bytes
	// ciphertext: is the amount of bytes after the iv in this case 303 bytes
	// aad: Additional Authenticated Data
	// Tag Info: https://www.cryptosys.net/pki/manpki/pki_aesgcmauthencryption.html#:~:text=The%20tag%20is%20sometimes%20called,Encryption%22%20%5BRFC%205116%5D.

	iv := encryptedData[:aes.BLOCK_SIZE]
	ciphertext := encryptedData[aes.BLOCK_SIZE:]
	aad: []byte
	tag := types.temp_DE.tag
	dataToDecrypt := make([]byte, len(ciphertext))

	//https://pkg.odin-lang.org/core/crypto/aes/#open_gcm
	success := aes.open_gcm(&gcmContext, dataToDecrypt, iv, aad, ciphertext, tag)

	if !success {
		fmt.printfln("Failed to decrypt file: %s in procedure: %s", file, #procedure)
		return false
	}

	writeSuccess := utils.write_to_file(file, dataToDecrypt, #procedure)
	if !writeSuccess {
		fmt.printfln("Failed to write to file in procedure: %s", #procedure)
		return false
	}

	// https://pkg.odin-lang.org/core/crypto/aes/#reset_gcm
	aes.reset_gcm(&gcmContext)
	delete(tag)

	return true
}
