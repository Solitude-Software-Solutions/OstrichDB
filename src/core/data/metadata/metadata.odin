package metadata

import "../../../utils/errors"
import "../../../utils/logging"
import "../../../utils/misc"
import "core:os"
import "core:fmt"
import "core:strings"
import "core:math/rand"
import "core:strconv"
import "core:time"
import "core:crypto/hash"
//=========================================================//
//Author: Marshall Burns aka @SchoolyB
//Desc: This file handles the metadata for .ost files within
//      the Ostrich database engine.
//=========================================================//


@(private="file")
METADATA_HEADER:[]string= {
  "[Ostrich File Header Start]\n\n","#File Format Version: %ffv\n","#Time of Creation: %ftoc\n","#Last Time Modified: %fltm\n","#File Size: %fs Bytes\n","#Checksum: %cs\n\n[Ostrich File Header End]\n\n\n\n"
}

// sets the files time of creation(FTOC) or last time modified(FLTM)
OST_SET_TIME :: proc() -> string {
  buf:[256]byte
  
  y,m,d:= time.date(time.now())

  Y:= transmute(i64)y
  M:= transmute(i64)m
  D:= transmute(i64)d

  Year:= strconv.append_int(buf[:], Y, 10)
  Month:= strconv.append_int(buf[:], M, 10)
  Day:= strconv.append_int(buf[:], D, 10)

  timeCreated:=strings.concatenate([]string{Day, "/", Month, "/", Year})
  return timeCreated
}


//sets the files format version(FFV)
OST_SET_FFV :: proc() -> string {
  fileVersion:="0.0.0_dev"
  return fileVersion
}

//sets the files size(FS)
//this will be called when a file is read or modified through the engine to ensure the file size is accurate
OST_GET_FS :: proc(file: string) -> os.File_Info{
  //get the file size
  fileSize,_:=os.stat(file)
  return fileSize
}



// Generate a random 32 char checksum for .ost files.
OST_GENERATE_CHECKSUM :: proc() -> string {
  checksum:string

  possibleNums:[]string={"1","2","3","4","5","6","7","8","9","0"}
  possibleChars:[]string={"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"}

  for c:=0; c<16; c+=1
    {
      randC:=rand.choice(possibleChars)
      checksum=strings.concatenate([]string{checksum, randC})
    }

  for n:=0; n<16; n+=1
    {
      randN:=rand.choice(possibleNums)
      checksum=strings.concatenate([]string{checksum, randN})
    }

    fmt.println("Checksum generated: ", checksum)
  
  return checksum
}



//sets the scheme info for the .ost file
// fn = file name, rn = record name, d = data
//example of use in metadata:
/*

{
  "records": [cluster_name, cluster_id, player_name, player_age, player_location],
  "types": [string, int, string, int, string],
}

OST_GET_SCHEMA_INFO ::proc (fn:string,rn:string, d:string)
{
  

}
*/



//!Only used when to append the meta template upon .ost file creation NOT modification
//this appends the metadata header to the file as well as sets the time of creation
OST_APPEND_METADATA_HEADER:: proc(fn:string) -> bool
{

  file,e:=os.open(fn,os.O_APPEND | os.O_WRONLY, 0o666)
  defer os.close(file)

  if e != 0{
    errors.throw_utilty_error(1,"Error opening file" ,"OST_APPEND_METADATA_HEADER")
  }

  blockAsBytes:= transmute([]u8)strings.concatenate(METADATA_HEADER)
  
  writter,ok:=os.write(file, blockAsBytes)
  return true
} 


//fn = file name, param = distiguish between which metadata value to set 1 = time of creation, 2 = last time modified, 3 = file size, 4 = file format version, 5 = checksum 
OST_UPDATE_METADATA_VALUE ::proc(fn:string,param:int)
{
    data, success := os.read_entire_file(fn)
    if !success {
        fmt.println("Failed to read file")
        return
    }
    
    content := string(data)
    
    // Update the header values
    current_time := OST_SET_TIME()
    file_info := OST_GET_FS(fn)
    file_size := file_info.size
    
    new_content := strings.clone(content)
    ok:bool

    switch(param)
    {
      case 1: //set time of creation
        new_content,ok = strings.replace(new_content, "#Time of Creation: %ftoc", fmt.tprintf("#Time of Creation: %s", current_time), -1)
        err := os.write_entire_file(fn, transmute([]byte)new_content)
        break
      case 2: //set last time modified
        new_content,ok = strings.replace(new_content, "#Last Time Modified: %fltm", fmt.tprintf("#Last Time Modified: %s", current_time), -1)
        err := os.write_entire_file(fn, transmute([]byte)new_content)
        break
      case 3: //set file size
        new_content,ok = strings.replace(new_content, "#File Size: %fs Bytes", fmt.tprintf("#File Size: %d Bytes", file_size), -1)
        err := os.write_entire_file(fn, transmute([]byte)new_content)
        break
      case 4: //set file format version
        new_content,ok = strings.replace(new_content, "#File Format Version: %ffv", fmt.tprintf("#File Format Version: %s", OST_SET_FFV()), -1)
        err := os.write_entire_file(fn, transmute([]byte)new_content)
        break
      case 5: //set checksum
        new_content,ok = strings.replace(new_content, "#Checksum: %cs", fmt.tprintf("#Checksum: %s", OST_GENERATE_CHECKSUM()), -1)
        err := os.write_entire_file(fn, transmute([]byte)new_content)
        break
    }
}

OST_METADATA_ON_CREATE :: proc(fn:string)
{
  fmt.println("Creating metadata for file: ", fn)
  OST_APPEND_METADATA_HEADER(fn)
  OST_UPDATE_METADATA_VALUE(fn, 1)
  OST_UPDATE_METADATA_VALUE(fn, 3)
  OST_UPDATE_METADATA_VALUE(fn, 4)
  OST_UPDATE_METADATA_VALUE(fn, 5)
}