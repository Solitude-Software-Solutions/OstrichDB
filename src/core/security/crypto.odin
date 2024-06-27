package security

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"
import "core:crypto/hash"
import "core:math/rand"


salt:string  


main:: proc()
{
  OST_GENERATE_SALT()
}

OST_USER_CREDENTIALS :: struct 
{
  username: string,
  hashedPassword: string
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



  


// OST_HASH_PASSWORD :: proc (p:string) -> string
// {

  
// }