package errors

import "core:fmt"
import "core:os"

//=========================================================//
//Author: Marshall Burns aka @SchoolyB
//Desc: This file contains helper functions for error handling
//=========================================================//


utils_error:Utility_Error
Utility_Error:: struct
{
  Message: string, //The message that the error displays/logs
  Location: string //the procedure that the error occurred in
}

//rv is the return value of the procedure that the error occurred in
throw_utilty_error:: proc(rv:int , m:string, l:string) -> Utility_Error
{
  utils_error.Message = m
  utils_error.Location = l
  switch(rv)
  {
    case 0:
      break
      case -1,1..<5: //odin allows for ranges in case statements      
      fmt.printf("Error: %s, occured in proc: %s()\n", m, l)
      break
  }
  return utils_error
}