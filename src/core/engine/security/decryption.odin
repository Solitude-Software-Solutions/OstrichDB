package security

import "../../../utils"
import "../../const"
import "../../types"
import "core:crypto/aead"
import "core:crypto/aes"
import "core:encoding/hex"
import "core:fmt"
import "core:math/rand"
import "core:os"
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

DECRYPT_COLLECTION :: proc(
	colName: string,
	colType: types.CollectionType,
	key: []u8,
) -> (
	success: int,
	decData: []u8,
) {
	file: string

	#partial switch (colType) {
	case .STANDARD_PUBLIC:
		file = utils.concat_standard_collection_name(colName)
		break
	case .USER_CONFIG_PRIVATE:
	    file = utils.concat_user_config_collection_name(colName)
		break
	case .USER_CREDENTIALS_PRIVATE:
		file = utils.concat_user_credential_path(colName)
		break
	case .SYSTEM_CONFIG_PRIVATE:
		file = const.SYSTEM_CONFIG_PATH
		break
	case .USER_HISTORY_PRIVATE:
		file = utils.concat_user_history_path(types.current_user.username.Value)
		break
	case .SYSTEM_ID_PRIVATE:
		file = const.ID_PATH
		break
	}

	ciphertext, readSuccess := utils.read_file(file, #procedure)
	if !readSuccess {
		fmt.println("Failed to read file")
		return -1, nil
	}

	n := len(ciphertext) - aes.GCM_IV_SIZE - aes.GCM_TAG_SIZE //n is the size of the ciphertext minus 16 bytes for the iv then minus another 16 bytes for the tag
	if n <= 0 do return -2, nil //if n is less than or equal to 0 then return nil

	aad: []u8 = nil
	decryptedData := make([]u8, n) //allocate the size of the decrypted data that comes from the allocation context
	iv := ciphertext[:aes.GCM_IV_SIZE] //iv is the first 16 bytes
	encryptedData := ciphertext[aes.GCM_IV_SIZE:][:n] //the actual encryptedData is the bytes after the iv
	tag := ciphertext[aes.GCM_IV_SIZE + n:] // tag is the 16 bytes at the end of the ciphertext

	gcmContext: aes.Context_GCM
	aes.init_gcm(&gcmContext, key) //initialize the gcm context with the key

	if !aes.open_gcm(&gcmContext, decryptedData, iv, aad, encryptedData, tag) {
		delete(decryptedData)
		fmt.println("Failed to decrypt data in file: ", file)
		return -3, nil
	}

	aes.reset_gcm(&gcmContext)

	//For all NON-secure collections :
	//1. delete the decrypted file
	//2. Create a new file with the same name
	//3. Write the decrypted data to that new file
	 #partial switch(colType){
	case .USER_CREDENTIALS_PRIVATE:
	    // buf:= make([]byte ,size_of(decryptedData)) //create a buffer in mem that will hold the decrypted data
		return 0, decryptedData
	case:
	    os.remove(file)
		writeSuccess := utils.write_to_file(file, decryptedData, #procedure)
        if !writeSuccess {
            fmt.println("Failed to write DECRYPTED data to file: ", file)
           	return -4, nil
        }
        break
	}
	return 0, decryptedData
}

