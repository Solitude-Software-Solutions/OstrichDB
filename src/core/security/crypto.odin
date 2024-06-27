package security

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"
import "core:crypto/hash"
import "core:math/rand"
import "core:crypto" 


main:: proc()
{
  // OST_GENERATE_SALT()
  // OST_HASH_PASSWORD("password")
  OST_GEN_SECURE_DIR_FILE()
}

OST_GENERATE_SALT :: proc () -> []u8
{
  salt:string
  randC:string //random char
  randN:int //random number
  concatStr:string 

  possibleChars:[]string={"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y"}
  
  nums:=[]int{1,2,3,4,5,6,7,8,9,0}
  
  //generate a random string of 15 lower case characters
  for c:=0; c<10; c+=1
    {
      randC=rand.choice(possibleChars)
      concatStr=strings.concatenate([]string{salt, randC})
      salt=concatStr
    }
    

  //generate a random number and convert it to a string
  nBuff:[8]byte
  for n:=0; n < 5; n+=1
    {
      randN=rand.choice(nums)
      convetedN:=strconv.itoa(nBuff[:], randN)
      charsAndNums:=strings.concatenate([]string{salt, convetedN})
      salt=charsAndNums 
    }

   //convert the string to a byte array then shuffle the array
   saltSlice:[]byte
   saltSlice=transmute([]byte)salt
   rand.shuffle(saltSlice, nil)
   fmt.printfln("Salt After shuffling: %s", saltSlice)
   
   return saltSlice  
}



OST_HASH_PASSWORD :: proc (p:string) -> []u8
{
  //generate the salt
  salt:[]u8= OST_GENERATE_SALT()
  
  ost_user.salt=salt //store the salt into the user struct
  
  pWithoutSalt:=p //store the password without the salt
  hashPWithoutSalt:[]u8 //store the hashed password without the salt
  hashPWithSalt:[]u8 //store the hashed password with the salt
  
  //concatenate the salt and password before hashing
  pWithSalt:=strings.concatenate([]string{string(salt),p}) 
  
  //generate a random number to determine which hashing algorithm to use
  x:=rand.choice([]int{1,2,3,4,5,6,7,8,9,0})
  switch(x)
  {
    case 1,5:
      for i:=0; i<1; i+=1
      {
        hashPWithSalt=hash.hash_string(hash.Algorithm.SHA3_224, pWithSalt)
        hashPWithoutSalt=hash.hash_string(hash.Algorithm.SHA3_224,pWithoutSalt) 
      }
      ost_user.hashedPassword=hashPWithoutSalt
      ost_user.algo_method=1
      break
    case 2,6:
      for i:=0; i<1; i+=1
      {
        hashPWithSalt=hash.hash_string(hash.Algorithm.SHA3_256, pWithSalt)
        hashPWithoutSalt=hash.hash_string(hash.Algorithm.SHA3_224,pWithoutSalt)
      }
      ost_user.hashedPassword=hashPWithoutSalt
      ost_user.algo_method= 2
      break
    case 3,7:
      for i:=0; i<1; i+=1
      {
        hashPWithSalt=hash.hash_string(hash.Algorithm.SHA3_384, pWithSalt)
        hashPWithoutSalt=hash.hash_string(hash.Algorithm.SHA3_224,pWithoutSalt)
      }
      ost_user.hashedPassword=hashPWithoutSalt
      ost_user.algo_method= 3
      break
    case 4,9:
      for i:=0; i<1; i+=1
      {
        hashPWithSalt=hash.hash_string(hash.Algorithm.SHA3_512, pWithSalt)
        hashPWithoutSalt=hash.hash_string(hash.Algorithm.SHA3_224,pWithoutSalt)
      }
      ost_user.hashedPassword=hashPWithoutSalt
      ost_user.algo_method= 4
      break
    case 0,8:
      for i:=0; i<1; i+=1
      {
        hashPWithSalt=hash.hash_string(hash.Algorithm.SHA512_256, pWithSalt)
        hashPWithoutSalt=hash.hash_string(hash.Algorithm.SHA3_224,pWithoutSalt)
      }
      ost_user.hashedPassword=hashPWithoutSalt
      ost_user.algo_method= 5
      break
  } 
  return hashPWithSalt  
}

//todo store salt and hashed password in a "user" cluster in a secure .ost file
/*
exmaple
{
  username: "john doe",
  role: "admin",
  hashedPassword: "hashedPassword",
  salt: "salt"
  hashedMethod: "SHA3_224" ??? Not sure if I should do this. see below
}
*/

//todo once this is done create proc that checks if the entered password(once hashed) matches the hashed password in the file.
//might need to store the hashing method used like in the example above(PROB SEMI-UNSAFE) into the user cluster. |OR| just run a hash on the entered password for each method and see if one passes.(THAT IS PROB SUPER UNSAFE!!!) |OR| I could assign a number to each hashing algo that is used and store that in the user cluser and use that to determine which method to use when checking the password.(PROB THE SAFEST)

OST_GEN_SECURE_DIR_FILE :: proc() -> int
{
  //make directory locked
  err:=os.make_directory("../../bin/secure") //this will change when building entire project from cmd line
  
  file,e:=os.open("../../bin/secure/_secure_.ost", os.O_CREATE, 0o600)
  if e !=0
  {
    fmt.printfln("Error creating secure file")
    return 1
  }

  return 0
}