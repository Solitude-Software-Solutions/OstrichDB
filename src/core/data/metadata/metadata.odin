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
import "core:c/libc"
//=========================================================//
//Author: Marshall Burns aka @SchoolyB
//Desc: This file handles the metadata for .ost files within
//      the Ostrich database engine.
//=========================================================//


@(private="file")
METADATA_TEMPLATE:[]string= {
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
OST_APPEND_METADATA_TEMPLATE:: proc(fn:string) -> bool
{

  file,e:=os.open(fn,os.O_APPEND | os.O_WRONLY, 0o666)
  defer os.close(file)

  if e != 0{
    errors.throw_utilty_error(1,"Error opening file" ,"OST_APPEND_METADATA_TEMPLATE")
  }

  blockAsBytes:= transmute([]u8)strings.concatenate(METADATA_TEMPLATE)
 
  writter,ok:=os.write(file, blockAsBytes)
  return true
} 



// //does not work yet
// //only updates data that changes, not the entire metadata block
// OST_UPDATE_METADATA:: proc(fn:string,fltm:string,fs:i64) -> int
// {
//   buf:[256]byte
//   file,e:=os.open(fn,os.O_APPEND | os.O_WRONLY, 0o666)
//   defer os.close(file)
//   if e != 0{
//     errors.throw_utilty_error(1,"Error opening file" ,"OST_UPDATE_METADATA")
//   }

  
//   rawData,ok:= os.read_entire_file(fn)
//   dataToStr:= cast(string)rawData
  
//   if strings.contains(dataToStr, "#Last Time Modified: %fltm")
//   {
//     fmt.println("Found the last time modified")
//     newFLTM,alright:= strings.replace_all(dataToStr, "%fltm",fltm)
//     writeFLTM,ight:= os.write(file, transmute([]u8)newFLTM)
//   }
  
  
//   // f:=strings.concatenate(METADATA_TEMPLATE)
// 	// for i:=0; i<len(METADATA_TEMPLATE); i+=1
// 	// {
// 	// 	if(strings.contains(f, "#Last Time Modified: %fltm"))
//   //   {
//   //     //step#1: replace the %fltm with the new last time modified
//   //     newFLTM,alright:= strings.replace_all(METADATA_TEMPLATE[i], "%fltm",fltm)
//   //     writeFLTM,ight:= os.write(file, transmute([]u8)newFLTM)
// 	//   }
//   // }
// return 1
// }



//fn = file name, , mdn = metadata name, mdv = metadata value
// OST_UPDATE_METADATA ::proc(fn:string, mdn:string, mdv:string)
OST_UPDATE_METADATA ::proc(fn:string)
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
    // new_content,ok = strings.replace(new_content, "#Time of Creation: %ftoc", fmt.tprintf("#Time of Creation: %s", current_time), -1) //todo will only need to add this on file creation, so need to move it 
    new_content,ok = strings.replace(new_content, "#Last Time Modified: %fltm", fmt.tprintf("#Last Time Modified: %v", current_time), -1)
    new_content,ok = strings.replace(new_content, "#File Size: %fs Bytes", fmt.tprintf("#File Size: %d Bytes", file_size), -1)
    
    // Note: Updating the checksum would require implementing a checksum algorithm
    // new_content = strings.replace(new_content, "#Checksum: %cs", fmt.tprintf("#Checksum: %s", calculate_checksum(new_content)))
    
    err := os.write_entire_file(fn, transmute([]byte)new_content)
}

