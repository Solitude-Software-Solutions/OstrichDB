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

OST_DECRYPT_COLLECTION :: proc(fName: string, fType: int, user: ..^types.User) -> bool {
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
	encryptedData, readSuccess := utils.read_file(file, #procedure)
	if !readSuccess {
		fmt.printfln("Failed to read file: %s in procedure: %s", file, #procedure)
		return false
	}
	defer delete(encryptedData)

	//https://pkg.odin-lang.org/core/crypto/aes/#Context_GCM
	gcmContext := types.temp_ECE.contxt
	aes.init_gcm(&gcmContext, types.current_user.m_k.valAsBytes)

	// Developer Note:
	// say encryptedData is 319 bytes long
	// iv: is the first 16 bytes
	// ciphertext: is the amount of bytes after the iv in this case 303 bytes
	// aad: Additional Authenticated Data
	// Tag Info: https://www.cryptosys.net/pki/manpki/pki_aesgcmauthencryption.html#:~:text=The%20tag%20is%20sometimes%20called,Encryption%22%20%5BRFC%205116%5D.

	iv := encryptedData[:aes.BLOCK_SIZE]
	ciphertext := encryptedData[aes.BLOCK_SIZE:]
	aad: []byte
	tag := types.temp_ECE.tag
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

	return true
}
