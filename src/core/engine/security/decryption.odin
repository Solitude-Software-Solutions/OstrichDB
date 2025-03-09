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

OST_DECRYPT_COLLECTION :: proc(
	colName: string,
	colType: types.CollectionType,
	key, ciphertext: []u8,
) -> []u8 {
	// assert(len(key) == aes.KEY_SIZE_256) //key MUST be 32 bytes

	file: string

	#partial switch (colType) {
	case .STANDARD_PUBLIC:
		file = utils.concat_collection_name(colName)
		break
	case .SECURE_PRIVATE:
		file = fmt.tprintf(
			"%ssecure_%s%s",
			const.OST_SECURE_COLLECTION_PATH,
			colName,
			const.OST_FILE_EXTENSION,
		)
		break
	case .CONFIG_PRIVATE:
		file = const.OST_CONFIG_PATH
		break
	case .HISTORY_PRIVATE:
		file = const.OST_HISTORY_PATH
		break
	case .ID_PRIVATE:
		file = const.OST_ID_PATH
		break
	}
	n := len(ciphertext) - aes.GCM_IV_SIZE - aes.GCM_TAG_SIZE //n is the size of the ciphertext minus 16 bytes for the iv then minus another 16 bytes for the tag
	if n <= 0 do return nil //if n is less than or equal to 0 then return nil

	aad: []u8 = nil
	decryptedData := make([]u8, n) //allocate the size of the decrypted data that comes from the allocation context
	iv := ciphertext[:aes.GCM_IV_SIZE] //iv is the first 16 bytes
	encryptedData := ciphertext[aes.GCM_IV_SIZE:][:n] //the actual encryptedData is the bytes after the iv
	tag := ciphertext[aes.GCM_IV_SIZE + n:] // tag is the 16 bytes at the end of the ciphertext

	gcmContext: aes.Context_GCM
	aes.init_gcm(&gcmContext, key) //initialize the gcm context with the key

	if aes.open_gcm(&gcmContext, decryptedData, iv, aad, encryptedData, tag) {
		fmt.println("Decryption successful")
	} else {
		delete(decryptedData)
		fmt.println("Failed to decrypt data")
		return nil
	}

	aes.reset_gcm(&gcmContext)

	//delete the decrypted file then create a new one with the same name and write the decrypted data to it
	os.remove(file)
	utils.write_to_file(file, decryptedData, #procedure)


	return decryptedData
}

//TODO: one possible solution to actually storing the decrypted data into the file itself is to take the decrypted data that is in memory, delete the "decrypted" file, then make a new one in the same path
// with the same name and write the decrypted data to it. This would be a good way to ensure that the decrypted data is not stored in memory for long periods of time
