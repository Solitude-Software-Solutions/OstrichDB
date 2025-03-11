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

//checkingEncryptStatus is false if we are just encrypting and true if we are just checking if the collection is already encrypted
OST_ENCRYPT_COLLECTION :: proc(
	colName: string,
	colType: types.CollectionType,
	key: []u8,
	checkingEncryptStatus: bool,
) -> (
	success: int,
	encData: []u8,
) {
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
		return -1, nil
	}

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

	if checkingEncryptStatus == true {
		return 2, nil

	}

	writeSuccess := utils.write_to_file(file, dst, #procedure) //write the encrypted data to the file

	if !writeSuccess {
		fmt.printfln("Failed to write to file: %s", file)
		return -3, nil
	}

	return 0, dst
}

//TODO: Incomplete procedure - Marshall
// //Used go through each collection wether private or public. Check if its ecrypted and if not encrypt it.
// OST_RUN_ENCRYPTION_CHECK :: proc(
// ) -> (
// 	totalCollections: int,
// 	alreadyEncrypted: int,
// 	notEncryted: int,
// ) {
// 	totalCollections = 0
// 	alreadyEncrypted = 0
// 	notEncryted = 0

// 	//Core private collections
// 	privateDir, _ := os.open(const.OST_PRIVATE_PATH)
// 	files, _ := os.read_dir(privateDir, -1)
// 	for file in files {

// 		//Config collection
// 		if file.name == "config.ost" {
// 			totalCollections += 1
// 			configCheckSuccess, _ := OST_ENCRYPT_COLLECTION(
// 				"",
// 				.CONFIG_PRIVATE,
// 				types.system_user.m_k.valAsBytes,
// 				true,
// 			)
// 			if configCheckSuccess == 2 {
// 				alreadyEncrypted += 1
// 			} else if configCheckSuccess == 1 {
// 				notEncryted += 1
// 			}
// 			//NEXT COLLECTION
// 		} else if file.name == "history.ost" { 	//History collection
// 			totalCollections += 1
// 			historyCheckSuccess, _ := OST_ENCRYPT_COLLECTION(
// 				"",
// 				.HISTORY_PRIVATE,
// 				types.system_user.m_k.valAsBytes,
// 				true,
// 			)
// 			if historyCheckSuccess == 2 {
// 				alreadyEncrypted += 1
// 			} else if historyCheckSuccess == 1 {
// 				notEncryted += 1
// 			}
// 			//NEXT COLLECTION
// 		} else if file.name == "ids.ost" { 	//ID collection
// 			totalCollections += 1
// 			idsCheckSuccess, _ := OST_ENCRYPT_COLLECTION(
// 				"",
// 				.ID_PRIVATE,
// 				types.system_user.m_k.valAsBytes,
// 				true,
// 			)
// 			if idsCheckSuccess == 2 {
// 				alreadyEncrypted += 1
// 			} else if idsCheckSuccess == 1 {
// 				notEncryted += 1
// 			}
// 		}
// 	}


// 	//Secure collections
// 	secDir, _ := os.open(const.OST_SECURE_COLLECTION_PATH)
// 	secFiles, _ := os.read_dir(secDir, -1)
// 	for file in secFiles {
// 		totalCollections += 1
// 		secFileWithoutExt := strings.trim_right(file.name, const.OST_FILE_EXTENSION)
// 		secFileWithoutPrefix := strings.trim_left(secFileWithoutExt, "secure_")
// 		fmt.printfln("Checking if %s is encrypted\n", secFileWithoutPrefix)
// 		seccColCheckSuccess, _ := OST_ENCRYPT_COLLECTION(
// 			secFileWithoutPrefix,
// 			.SECURE_PRIVATE,
// 			types.system_user.m_k.valAsBytes,
// 			true,
// 		)
// 		if seccColCheckSuccess == 2 {
// 			alreadyEncrypted += 1
// 		} else if seccColCheckSuccess == 1 {
// 			notEncryted += 1
// 		}
// 	}


// 	//Standard Public collections
// 	standardPublicDir, _ := os.open(const.OST_PUBLIC_STANDARD_COLLECTION_PATH)
// 	standardFiles, _ := os.read_dir(standardPublicDir, -1)

// 	for file in standardFiles {
// 		totalCollections += 1
// 		standardFileWithoutExt := strings.trim_right(file.name, const.OST_FILE_EXTENSION)
// 		fmt.printfln("Checking if %s is encrypted", standardFileWithoutExt)
// 		standardCheckSuccess, _ := OST_ENCRYPT_COLLECTION(
// 			standardFileWithoutExt,
// 			.STANDARD_PUBLIC,
// 			types.system_user.m_k.valAsBytes,
// 			true,
// 		)
// 		if standardCheckSuccess == 2 {
// 			alreadyEncrypted += 1
// 		} else if standardCheckSuccess == 1 {
// 			notEncryted += 1
// 		}
// 	}

// 	return totalCollections, alreadyEncrypted, notEncryted
// }
