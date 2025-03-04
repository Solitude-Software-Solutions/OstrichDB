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
	gcmContext := new(aes.Context_GCM)
	// fmt.printfln("Key: %s", types.current_user.m_k.valAsBytes)
	aes.init_gcm(gcmContext, types.current_user.m_k.valAsBytes)

	// Extract the IV from the first BLOCK_SIZE bytes of the encrypted data
	iv := encryptedData[:aes.BLOCK_SIZE]
	// The actual ciphertext starts after the IV
	ciphertext := encryptedData[aes.BLOCK_SIZE:]
	fmt.println("ciphertext: ", ciphertext)
	aad: []byte
	tag := make([]byte, aes.GCM_TAG_SIZE)
	fmt.println("tag: ", tag)
	decryptedData := make([]byte, len(ciphertext))

	//https://pkg.odin-lang.org/core/crypto/aes/#open_gcm
	// fmt.println("DecryptedData befor gcm_open:", decryptedData)
	success := aes.open_gcm(gcmContext, decryptedData, iv, aad, ciphertext, tag)
	// fmt.println("DecryptedData after gcm_open:", decryptedData)

	if !success {
		fmt.printfln("Failed to decrypt file: %s in procedure: %s", file, #procedure)
		return false
	}

	writeSuccess := utils.write_to_file(file, decryptedData, #procedure)
	if !writeSuccess {
		fmt.printfln("Failed to write to file in procedure: %s", #procedure)
		return false
	}

	// https://pkg.odin-lang.org/core/crypto/aes/#reset_gcm
	aes.reset_gcm(gcmContext)

	return true
}
