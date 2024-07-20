package security

import "../types"
import "core:crypto"
import "core:crypto/hash"
import "core:encoding/hex"
import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:strconv"
import "core:strings"

//=========================================================//
//Author: Marshall Burns aka @SchoolyB
//Desc: This file handles the encryption of user credentials
//=========================================================//


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
	//  rand.shuffle(saltSlice, nil)
	rand.shuffle(saltSlice) //todo according to compiler this is the correct way to call the function

	return saltSlice
}

// p - password, hMethod - store/hashing method, isAuth - is the user authenticating or creating an account
OST_HASH_PASSWORD :: proc(p: string, sMethod: int, isAuth: bool) -> []u8 {
	//generate the salt
	salt: []u8 = OST_GENERATE_SALT()
	types.user.salt = salt //store the salt into the user struct
	hashedPassword: []u8


	//if this password is being hashed during authentication then we already have the hashing method provided
	//see auth.odin
	if (isAuth) {
		x := sMethod
		hashedPassword = OST_CHOOSE_ALGORITHM(x, p)
	} else {
		x := rand.choice([]int{1, 2, 3, 4, 5})
		hashedPassword = OST_CHOOSE_ALGORITHM(x, p)
	}
	return hashedPassword
}

// choice - hashing method, p - password
OST_CHOOSE_ALGORITHM :: proc(choice: int, p: string) -> []u8 {
	x := choice
	hashedPassword: []u8
	switch (x) 
	{
	case 1:
		for i := 0; i < 1; i += 1 {
			hashedPassword = hash.hash_string(hash.Algorithm.SHA3_224, p)
		}
		types.user.hashedPassword = hashedPassword
		types.user.store_method = 1
		break
	case 2:
		for i := 0; i < 1; i += 1 {
			hashedPassword = hash.hash_string(hash.Algorithm.SHA3_256, p)
		}
		types.user.hashedPassword = hashedPassword
		types.user.store_method = 2
		break
	case 3:
		for i := 0; i < 1; i += 1 {
			hashedPassword = hash.hash_string(hash.Algorithm.SHA3_384, p)
		}
		types.user.hashedPassword = hashedPassword
		types.user.store_method = 3
		break
	case 4:
		for i := 0; i < 1; i += 1 {
			hashedPassword = hash.hash_string(hash.Algorithm.SHA3_512, p)
		}
		types.user.hashedPassword = hashedPassword
		types.user.store_method = 4
		break
	case 5:
		for i := 0; i < 1; i += 1 {
			hashedPassword = hash.hash_string(hash.Algorithm.SHA512_256, p)
		}
		types.user.hashedPassword = hashedPassword
		types.user.store_method = 5
	}
	return hashedPassword
}

// hp - hashed password
OST_ENCODE_HASHED_PASSWORD :: proc(hp: []u8) -> []u8 {
	encodedHash := hex.encode(hp)
	str := transmute(string)encodedHash
	return encodedHash
}
