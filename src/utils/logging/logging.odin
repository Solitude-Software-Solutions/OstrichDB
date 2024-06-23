package logging

import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"
import "core:strconv"

LOG_DIR_PATH:string: "../../../bin/logs/" //todo: might not need
RUNTIME_LOG:string: "runtime.log"
ERROR_LOG:string: "errors.log"


main:: proc() 
{
  log_runtime_event("Test","Testing logging")
  // create_logs_dir()
  // create_log_files()
}

create_logs_dir:: proc() -> int 
{
  logsDir:= os.make_directory(LOG_DIR_PATH)
  return 0
}

create_log_files:: proc() -> int 
{
  fullRuntimePath := strings.concatenate([]string{LOG_DIR_PATH, RUNTIME_LOG} )
  runtimeFile,err:= os.open(fullRuntimePath, os.O_CREATE, 0o666)
  defer os.close(runtimeFile)

  fullErrorPath:= strings.concatenate([]string{LOG_DIR_PATH, ERROR_LOG})
  errorFile,er:= os.open(fullErrorPath, os.O_CREATE, 0o666)

  os.close(errorFile) 
  return 0 
}

//###############################|RUNTIME LOGGING|############################################


//eventDesc will be passed from the generate_event_description proc
// eventDateTime will come from the time package and be assined to a string variable with string formatting
log_runtime_event :: proc(eventName:string, eventDesc: string)
{
  buf:[256]byte
  y,m,d:= time.date(time.now())
  
  // Conversions because everything in Odin needs to be converted... :)
  mAsInt:=transmute(int)m //month comes base as a type "Month" so need to convert
  
  Y:= transmute(i64)y
  M:= transmute(i64)m
  D:= transmute(i64)d
  
  Year:= strconv.append_int(buf[:], Y, 10)
  Month:= strconv.append_int(buf[:], M, 10)
  Day:= strconv.append_int(buf[:], D, 10)


  switch(mAsInt)
  {
    case 1:
      Month= "January"
      break
    case 2:
      Month= "February"
      break
    case 3:
      Month= "March"
      break
    case 4:
      Month= "April"
      break
    case 5:
      Month= "May"
      break
    case 6:
      Month= "June"
      break
    case 7:
      Month= "July"
      break
    case 8:
      Month= "August"
      break
    case 9:
      Month= "September"
      break
    case 10:
      Month= "October"
      break
    case 11:
      Month= "November"
      break
    case 12:
      Month= "December"
      break
  }

  
  Date:= strings.concatenate([]string{Month, " ", Day, ", ", Year, "\n"})
  paramsAsMessage:= strings.concatenate([]string{"Event: ",eventName,"\n","Desc: ", eventDesc, "\n"})
  fullLogMessage:= strings.concatenate([]string{paramsAsMessage,"Logged @:", Date})
  
  fullPath:= strings.concatenate([]string{LOG_DIR_PATH, RUNTIME_LOG})
  runtimeFile,e:=os.open(fullPath, os.O_APPEND | os.O_RDWR, 0o666)
  LogMessage:= transmute([]u8)fullLogMessage
  _,ee:=os.write(runtimeFile, LogMessage)
  //TODO for some od reason the log message is not being written to the file
  //every thing seems to have been converted correctly and passed correctly. The file does exist, the path is correct, the file is being opened correctly
  os.close(runtimeFile)

  
} 


// generate_event_description