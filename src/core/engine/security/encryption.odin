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
            All the logic for encryption collection files can be found within
*********************************************************/


//FType - 0 = Standard(public) collection,  1 = Secure(private) collection,2 config(core), 3 = history(core), 4 = ids(core)
//user - user is passed so the the proc can access 1, the username, and 2, the users master key
OST_ENCRYPT_FILE :: proc(fName: string, fType: int, user: ..^types.User) -> bool {
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

	fmt.println(types.user.m_k)
	gcmContext := new(aes.Context_GCM)
	aes.init_gcm(gcmContext, types.current_user.m_k.valAsBytes)

	iv := OST_GENERATE_IV()
	aad: []byte
	ciphertext := make([]byte, len(data) + aes.BLOCK_SIZE)
	tag := make([]byte, aes.GCM_TAG_SIZE)

	encryptedData := make([]byte, len(data) + aes.BLOCK_SIZE)
	success := aes.open_gcm(gcmContext, encryptedData, iv, aad, ciphertext, tag)

	aes.seal_gcm(gcmContext, encryptedData, tag, iv, aad, encryptedData)

	//Write encrypted data to file
	writeSuccess := utils.write_to_file(file, encryptedData, #procedure)
	if !writeSuccess {
		fmt.printfln("Failed to write to file in procedure: %s", #procedure)
		return false
	}

	return true

}


//IV is the initialization vector for the encryption
OST_GENERATE_IV :: proc() -> []byte {
	iv := make([]byte, aes.BLOCK_SIZE)

	for i := 0; i < aes.BLOCK_SIZE; i += 1 {
		iv[i] = byte(rand.int127())
	}

	return iv
}
