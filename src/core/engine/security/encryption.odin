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
import "core:strings"
import "../data/metadata"
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

ENCRYPT_COLLECTION :: proc(
	colName: string,
	colType: types.CollectionType,
	key: []u8
) -> (
	success: int,
	encData: []u8,
) {
    using types
	file: string

	#partial switch (colType) {
	case .STANDARD_PUBLIC:
		//Public Standard Collection
		file = utils.concat_standard_collection_name(colName)
		break
	case .USER_CONFIG_PRIVATE:
	    file = utils.concat_user_config_collection_name(colName)
	case .USER_CREDENTIALS_PRIVATE:
		//Private Secure Collection
		file = utils.concat_user_credential_path(colName)
		break
	case .SYSTEM_CONFIG_PRIVATE:
		//Private Config Collection
		file = const.SYSTEM_CONFIG_PATH
		break
	case .USER_HISTORY_PRIVATE:
		//Private History Collection
		file = utils.concat_user_history_path(colName)
		break
	case .SYSTEM_ID_PRIVATE:
		//Private ID Collection
		file = const.ID_PATH
		break
	case .ISOLATED_PUBLIC:
		file = fmt.tprintf("%s%s", const.QUARANTINE_PATH, colName)
		break
	//case 5: Todo: Add case for benchmark collections
	case:
		fmt.printfln("Invalid File Type Passed in procedure: %s", #procedure)
		return -1, nil
	}

	//Update the encryption state metadaheader member to 1 before reading bytes
	metadata.ASSIGN_EXPLICIT_METADATA_VALUE(file, MetadataField.ENCRYPTION_STATE, "1")

	data, readSuccess := utils.read_file(file, #procedure)
	if !readSuccess {
		fmt.printfln("Failed to read file: %s for encryption", file)
		return -2, nil
	}
	defer delete(data)

	n := len(data) //n is the size of the data

	aad: []u8 = nil
	dst := make([]u8, n + aes.GCM_IV_SIZE + aes.GCM_TAG_SIZE) //create a buffer that is the size of the data plus 16 bytes for the iv and 16 bytes for the tag
	iv := dst[:aes.GCM_IV_SIZE] //set the iv to the first 16 bytes of the buffer
	encryptedData := dst[aes.GCM_IV_SIZE:][:n] //set the actual encrypted data to the bytes after the iv
	tag := dst[aes.GCM_IV_SIZE + n:] //set the tag to the 16 bytes at the end of the buffer

	crypto.rand_bytes(iv) //generate a random iv

	gcmContext: aes.Context_GCM //create a gcm context
	aes.init_gcm(&gcmContext, key) //initialize the gcm context with the key

	aes.seal_gcm(&gcmContext, encryptedData, tag, iv, aad, data) //encrypt the data

	writeSuccess := utils.write_to_file(file, dst, #procedure) //write the encrypted data to the file

	if !writeSuccess {
		fmt.printfln("Failed to write ENCRYPTED data to file: %s", file)
		//If we fail to write the encrypted data to the file, reset the encrypted state metadata back to 0
		metadata.ASSIGN_EXPLICIT_METADATA_VALUE(file, MetadataField.ENCRYPTION_STATE)
		return -4, nil
	}

	return 0, dst
}