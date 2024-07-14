package misc


import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"
import "../errors"
import "../logging"
// This file contains miscellaneous entities that are used throughout the program

ostrich_version:string 
ostrich_art := 
`  _______               __                __             __
  /       \             /  |              /  |           /  |      
  /$$$$$$  |  _______  _$$ |_     ______  $$/   _______ $$ |____  
  $$ |  $$ | /       |/ $$   |   /      \ /  | /       |$$      \ 
  $$ |  $$ |/$$$$$$$/ $$$$$$/   /$$$$$$  |$$ |/$$$$$$$/ $$$$$$$  |
  $$ |  $$ |$$      \   $$ | __ $$ |  $$/ $$ |$$ |      $$ |  $$ |
  $$ \__$$ | $$$$$$  |  $$ |/  |$$ |      $$ |$$ \_____ $$ |  $$ |
  $$    $$/ /     $$/   $$  $$/ $$ |      $$ |$$       |$$ |  $$ |
   $$$$$$/  $$$$$$$/     $$$$/  $$/       $$/  $$$$$$$/ $$/   $$/ 
  ===============================================================`



//Constants for text colors and styles
RED:: "\033[31m"
BLUE:: "\033[34m"
GREEN:: "\033[32m"
YELLOW:: "\033[33m"

BOLD:: "\033[1m"
ITALIC:: "\033[3m"
UNDERLINE:: "\033[4m"
RESET:: "\033[0m"



get_ost_version :: proc() -> []u8
{
    buf:[256]byte
    version_file,err := os.open("../version")
    if err !=0
    {
      logging.log_utils_error("Could not open version file", "get_ost_version")
    }
    data,e := os.read_entire_file(version_file)
    if e ==false
    {
      logging.log_utils_error("Could not read version file", "get_ost_version")
    }
    os.close(version_file)
    return data
}

//n- name of step, c- current step, t- total steps of current process
show_current_step:: proc(n:string,c:string,t:string)
{
  fmt.printfln("Step %s/%s:\n%s%s%s\n", c, t,BOLD, n, RESET)
}


get_input :: proc() -> string
{
    buf:[256]bytes
    
    //n - number of bytes read
    n, err := os.read(os.stdin, buf[:])
	  if n > 0 {
		input := string(buf[:n])
		//trim the string of any whitespace or newline characters
		input = strings.trim_right_proc(input, proc(r: rune) -> bool {
			return r == '\r' || r == '\n'
		})
    return string(buf)
  }
}