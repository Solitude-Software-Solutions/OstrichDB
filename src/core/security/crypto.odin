package security

import "core:crypto"
import "core:crypto/hash"
import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:encoding/hex"

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


OST_HASH_PASSWORD :: proc(p: string, action: int) -> []u8 {
	//generate the salt
	salt: []u8 = OST_GENERATE_SALT()


	ost_user.salt = salt //store the salt into the user struct

	pWithoutSalt := p //store the password without the salt
	hashPWithoutSalt: []u8 //store the hashed password without the salt
	hashPWithSalt: []u8 //store the hashed password with the salt

	//concatenate the salt and password before hashing
	pWithSalt := strings.concatenate([]string{string(salt), p})

	//generate a random number to determine which hashing algorithm to use
	x := rand.choice([]int{1, 2, 3, 4, 5, 6, 7, 8, 9, 0})
	switch (x)
	{
	case 1, 5:
		for i := 0; i < 1; i += 1 {
			hashPWithSalt = hash.hash_string(hash.Algorithm.SHA3_224, pWithSalt)
			hashPWithoutSalt = hash.hash_string(hash.Algorithm.SHA3_224, pWithoutSalt)
		}
		ost_user.hashedPassword = hashPWithoutSalt
		ost_user.store_method = 1
		break
	case 2, 6:
		for i := 0; i < 1; i += 1 {
			hashPWithSalt = hash.hash_string(hash.Algorithm.SHA3_256, pWithSalt)
			hashPWithoutSalt = hash.hash_string(hash.Algorithm.SHA3_224, pWithoutSalt)
		}
		ost_user.hashedPassword = hashPWithoutSalt
		ost_user.store_method = 2
		break
	case 3, 7:
		for i := 0; i < 1; i += 1 {
			hashPWithSalt = hash.hash_string(hash.Algorithm.SHA3_384, pWithSalt)
			hashPWithoutSalt = hash.hash_string(hash.Algorithm.SHA3_224, pWithoutSalt)
		}
		ost_user.hashedPassword = hashPWithoutSalt
		ost_user.store_method = 3
		break
	case 4, 9:
		for i := 0; i < 1; i += 1 {
			hashPWithSalt = hash.hash_string(hash.Algorithm.SHA3_512, pWithSalt)
			hashPWithoutSalt = hash.hash_string(hash.Algorithm.SHA3_224, pWithoutSalt)
		}
		ost_user.hashedPassword = hashPWithoutSalt
		ost_user.store_method = 4
		break
	case 0, 8:
		for i := 0; i < 1; i += 1 {
			hashPWithSalt = hash.hash_string(hash.Algorithm.SHA512_256, pWithSalt)
			hashPWithoutSalt = hash.hash_string(hash.Algorithm.SHA3_224, pWithoutSalt)
		}
		ost_user.hashedPassword = hashPWithoutSalt
		ost_user.store_method = 5
		break
	}
	//the action is dependent on which hash is needed
	switch (action)
	{
	case 1:
		return hashPWithoutSalt
	case 2:
		return hashPWithSalt
	}
	return []u8{}
}


// hp - hashed password
OST_ENCODE_HASHED_PASSWORD :: proc(hp: []u8) -> []u8 {
encodedHash:= hex.encode(hp)
return  encodedHash
}
