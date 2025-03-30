package security

import "../../types"
import "core:crypto"
import "core:crypto/hash"
import "core:encoding/hex"
import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:strconv"
import "core:strings"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            Contains logic for hashing passwords and generating salts.
            Also contains logic for generating a master key for each user.
            Not to be confused with the encryption logic in the encryption.odin file.
*********************************************************/


OST_GENERATE_SALT :: proc() -> []u8 {
	salt: string
	randC: string //random char
	randN: int //random number
	concatStr: string

	possibleChars: []string = {
		"a",
		"b",
		"c",
		"d",
		"e",
		"f",
		"g",
		"h",
		"i",
		"j",
		"k",
		"l",
		"m",
		"n",
		"o",
		"p",
		"q",
		"r",
		"s",
		"t",
		"u",
		"v",
		"w",
		"x",
		"y",
	}

	nums := []int{1, 2, 3, 4, 5, 6, 7, 8, 9, 0}

	//generate a random string of 15 lower case characters
	for c := 0; c < 10; c += 1 {
		randC = rand.choice(possibleChars)
		concatStr = strings.concatenate([]string{salt, randC})
		salt = concatStr
	}


	//generate a random number and convert it to a string
	nBuff: [8]byte
	for n := 0; n < 5; n += 1 {
		randN = rand.choice(nums)
		convetedN := strconv.itoa(nBuff[:], randN)
		charsAndNums := strings.concatenate([]string{salt, convetedN})
		salt = charsAndNums
	}

	//convert the string to a byte array then shuffle the array
	saltSlice: []byte
	saltSlice = transmute([]byte)salt
	rand.shuffle(saltSlice)

	return saltSlice
}

//Hashes p using the hashing method provided
// p - password, hMethod - store/hashing method, isAuth - is the user authenticating or creating an account, isInitializing - is this being done pre or post engine initialization
OST_HASH_PASSWORD :: proc(p: string, sMethod: int, isAuth: bool, isInitializing: bool) -> []u8 {
	//generate the salt
	salt: []u8 = OST_GENERATE_SALT()
	if (isInitializing == true) {
		types.user.salt.valAsBytes = salt //store the salt into the user struct
	} else if (isInitializing == false) {
		types.new_user.salt.valAsBytes = salt //store the salt into the user struct
	}
	hashedPassword: []u8


	//if this password is being hashed during authentication then we already have the hashing method provided
	//see auth.odin
	if (isAuth) {
		x := sMethod
		if isInitializing == true {
			hashedPassword = OST_CHOOSE_ALGORITHM(x, p, true)
		} else if isInitializing == false {
			hashedPassword = OST_CHOOSE_ALGORITHM(x, p, false)
		}
	} else {
		x := rand.choice([]int{1, 2, 3, 4, 5})
		if isInitializing == true {
			hashedPassword = OST_CHOOSE_ALGORITHM(x, p, true)
		} else if isInitializing == false {
			hashedPassword = OST_CHOOSE_ALGORITHM(x, p, false)
		}
	}
	return hashedPassword
}

//Chooses which hashing algorithm to use on p based on the choice provided
// choice - hashing method, p - password, isInitializing - is this being done pre or post engine initialization
OST_CHOOSE_ALGORITHM :: proc(choice: int, p: string, isInitializing: bool) -> []u8 {
	using types

	x := choice
	hashedPassword: []u8
	switch (x) 
	{
	case 1:
		for i := 0; i < 1; i += 1 {
			hashedPassword = hash.hash_string(hash.Algorithm.SHA3_224, p)
		}
		if (isInitializing == true) {
			user.hashedPassword.valAsBytes = hashedPassword
			user.store_method = 1
		} else if (isInitializing == false) {
			new_user.hashedPassword.valAsBytes = hashedPassword
			new_user.store_method = 1
		}
		break
	case 2:
		for i := 0; i < 1; i += 1 {
			hashedPassword = hash.hash_string(hash.Algorithm.SHA3_256, p)
		}
		if (isInitializing == true) {
			user.hashedPassword.valAsBytes = hashedPassword
			user.store_method = 2
		} else if (isInitializing == false) {
			new_user.hashedPassword.valAsBytes = hashedPassword
			new_user.store_method = 2
		}
		break
	case 3:
		for i := 0; i < 1; i += 1 {
			hashedPassword = hash.hash_string(hash.Algorithm.SHA3_384, p)
		}
		if (isInitializing == true) {
			user.hashedPassword.valAsBytes = hashedPassword
			user.store_method = 3
		} else if (isInitializing == false) {
			new_user.hashedPassword.valAsBytes = hashedPassword
			new_user.store_method = 3
		}
		break
	case 4:
		for i := 0; i < 1; i += 1 {
			hashedPassword = hash.hash_string(hash.Algorithm.SHA3_512, p)
		}
		if (isInitializing == true) {
			user.hashedPassword.valAsBytes = hashedPassword
			user.store_method = 4
		} else if (isInitializing == false) {
			new_user.hashedPassword.valAsBytes = hashedPassword
			new_user.store_method = 4
		}
		break
	case 5:
		for i := 0; i < 1; i += 1 {
			hashedPassword = hash.hash_string(hash.Algorithm.SHA512_256, p)
		}
		if (isInitializing == true) {
			user.hashedPassword.valAsBytes = hashedPassword
			user.store_method = 5
		} else if (isInitializing == false) {
			new_user.hashedPassword.valAsBytes = hashedPassword
			new_user.store_method = 5
		}
	}
	return hashedPassword
}

// //encode the hashed password then convert it to a string and return it
// hp - hashed password
OST_ENCODE_HASHED_PASSWORD :: proc(hp: []u8) -> []u8 {
	encodedHash := hex.encode(hp)
	str := transmute(string)encodedHash
	return encodedHash
}


//used to generate a 256 bit master key for each user, encodes it to hexidecimal, then returns it as a 64 byte array
OST_GEN_MASTER_KEY :: proc() -> []byte {
	key := make([]byte, 32)
	// Fill the buffer with random bytes
	for i := 0; i < 32; i += 1 {
		key[i] = byte(rand.int31_max(256))
	}


	encodedKey := hex.encode(key) //encode the key to us hexidecimal characters
	return encodedKey
}

OST_DECODE_M_K :: proc(m_k: []byte) -> []byte {
	decodedKey, _ := hex.decode(m_k)
	return decodedKey
}

