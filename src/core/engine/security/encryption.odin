package security

import "../../../utils"
import "../../const"
import "../../types"
import "core:crypto/"
import "core:crypto/aead"
import "core:crypto/aes"
import "core:encoding/hex"
import "core:fmt"

/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            All the logic for encrypting collection files can be found within
*********************************************************/


//FType - 0 = Standard(public) collection,  1 = Secure(private) collection,2 config(core), 3 = history(core), 4 = ids(core)
//user - user is passed so the the proc can access 1, the username, and 2, the users master key
OST_ENCRYPT_COLLECTION :: proc(fName: string, fType: int, user: ..^types.User) -> bool {
	//depending on collection file type, concat correct path
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
	data, readSuccess := utils.read_file(file, #procedure)
	if !readSuccess {
		fmt.printfln("Failed to read file: %s in procedure: %s", file, #procedure)
		return false
	}
	defer delete(data)

	//https://pkg.odin-lang.org/core/crypto/aes/#Context_GCM
	gcmContext := types.temp_ECE.contxt

	//https://pkg.odin-lang.org/core/crypto/aes/#init_gcm
	aes.init_gcm(&gcmContext, types.current_user.m_k.valAsBytes)

	iv := OST_GENERATE_IV()
	aad: []byte
	ciphertext := make([]byte, len(data) + aes.BLOCK_SIZE)
	tag := make([]byte, aes.GCM_TAG_SIZE)
	dataToEncrypt := make([]byte, len(data) + aes.BLOCK_SIZE)

	// https://pkg.odin-lang.org/core/crypto/aes/#seal_gcm
	aes.seal_gcm(&gcmContext, dataToEncrypt, tag, iv, aad, data)

	//I think its super fucking unsafe but dec needs to use it so fuck it for now - Marshall
	types.temp_ECE.tag = tag

	//Write encrypted data to file
	writeSuccess := utils.write_to_file(file, dataToEncrypt, #procedure)
	if !writeSuccess {
		fmt.printfln("Failed to write to file in procedure: %s", #procedure)
		return false
	}
	//Reset the gcm context so it can be used again
	// https://pkg.odin-lang.org/core/crypto/aes/#reset_gcm
	aes.reset_gcm(&gcmContext)


	return true

}


//IV is the initialization vector for the encryption
OST_GENERATE_IV :: proc() -> []byte {
	iv := make([]byte, aes.BLOCK_SIZE)
	crypto.rand_bytes(iv)
	return iv
}
