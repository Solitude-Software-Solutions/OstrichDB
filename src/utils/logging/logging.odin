package logging

import "../errors"
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
  // log_utils_error("Test","Testing logging")
  // errors.throw_utilty_error(1, "Test", "Testing logging")
  // log_runtime_event("Test","Testing logging")
  // create_logs_dir()
  // create_log_files()
}

create_logs_dir:: proc() -> int 
{
  err:= os.make_directory(LOG_DIR_PATH)
  if err != 0
  {
    errors.throw_utilty_error(1, "Error creating logs directory", "create_logs_dir")
    log_utils_error("Error creating logs directory", "create_logs_dir")
    return -1
  }
  return 0
}

create_log_files:: proc() -> int 
{
  fullRuntimePath := strings.concatenate([]string{LOG_DIR_PATH, RUNTIME_LOG} )
  runtimeFile,err:= os.open(fullRuntimePath, os.O_CREATE, 0o666)
  if err != 0
  {
    errors.throw_utilty_error(1, "Error creating runtime log file", "create_log_files")
    log_utils_error("Error creating runtime log file", "create_log_files")
    return -1
  }
  
  defer os.close(runtimeFile)

  fullErrorPath:= strings.concatenate([]string{LOG_DIR_PATH, ERROR_LOG})
  errorFile,er:= os.open(fullErrorPath, os.O_CREATE, 0o666)
  if er != 0
  {
    errors.throw_utilty_error(1, "Error creating error log file", "create_log_files")
    log_utils_error("Error creating error log file", "create_log_files")
    return -1
  }

  os.close(errorFile) 
  return 0 
}

//###############################|RUNTIME LOGGING|############################################
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

  //TODO need figure out why year is coming out incorrectly

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
  LogMessage:= transmute([]u8)fullLogMessage

  runtimeFile,e:=os.open(fullPath, os.O_APPEND | os.O_RDWR, 0o666)
  if e != 0
  {
    errors.throw_utilty_error(1, "Error opening runtime log file", "log_runtime_event")
    log_utils_error("Error opening runtime log file", "log_runtime_event")
    return
  }

  
  _,ee:=os.write(runtimeFile, LogMessage)
  if ee != 0
  {
    errors.throw_utilty_error(1, "Error writing to runtime log file", "log_runtime_event")
    log_utils_error("Error writing to runtime log file", "log_runtime_event")
    return  
  }

  //every thing seems to have been converted correctly and passed correctly. The file does exist, the path is correct, the file is being opened correctly
  os.close(runtimeFile)

} 


//###############################|ERROR LOGGING|############################################
//TODO probably need to refactor this to be more, no need to repeat the same code....
log_utils_error:: proc(message:string,location:string) ->int
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

  //TODO need figure out why year is coming out incorrectly

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
  paramsAsMessage:= strings.concatenate([]string{"UTILS Error: ",message,"\n","Location: ", location, "\n"})
  fullLogMessage:= strings.concatenate([]string{paramsAsMessage,"Logged @:", Date})
  fullPath:= strings.concatenate([]string{LOG_DIR_PATH, ERROR_LOG})
  LogMessage:= transmute([]u8)fullLogMessage

  errorFile,e:=os.open(fullPath, os.O_APPEND | os.O_RDWR, 0o666)
  if e != 0
  {
    errors.throw_utilty_error(1, "Error opening error log file", "log_utils_error")
    log_utils_error("Error opening error log file", "log_utils_error")
    return -1
  }

  
  _,ee:=os.write(errorFile, LogMessage)
  if ee != 0
  {
    errors.throw_utilty_error(1, "Error writing to error log file", "log_utils_error")
    log_utils_error("Error writing to error log file", "log_utils_error")
  }
  return 0
}
