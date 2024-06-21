package data
import "core:fmt"
import "core:os"
import "core:strings"
import "core:math/rand"
import "core:strconv"

MAX_FILE_NAME_LENGTH_AS_BYTES :[512]byte
OST_CLUSTER_PATH :: "../../../bin/"
OST_FILE_EXTENSION ::".ost"
cluster: Cluster
Cluster :: struct {
	_id:     int, //unique identifier for the record cannot be duplicated
	record: struct{}, //allows for multiple records to be stored in a cluster
}
//todo this proc will change once engine is built
main::proc() {
	buf:[256]byte
	fmt.printfln("What would you like to name your DB file?: ")	
	n, err := os.read(os.stdin, buf[:])
	
	//if the number of bytes entered is greater than 0 then assign the entered bytes to a string
	if n > 0 {
        enteredStr := string(buf[:n]) 
				//trim the string of any whitespace or newline characters 

				//Shoutout to the OdinLang Discord for helping me with this...
        enteredStr = strings.trim_right_proc(enteredStr, proc(r: rune) -> bool {
            return r == '\r' || r == '\n'
        })

        OST_CREATE_OST_FILE(enteredStr)
    }
}


//creates a file in the bin directory used to store the all used cluster ids
OST_CREATE_CACHE_FILE :: proc() {
	cacheFile,err := os.open("../../../bin/cluster_id_cache", os.O_CREATE, 0o666)
}



/*
Create a new empty Cluster file within the DB
Clusters are collections of records stored in a .ost file
Params: fileName - the desired file(cluster) name
*/
OST_CREATE_OST_FILE :: proc(fileName:string) -> int {
		// concat the path and the file name into a string 
  pathAndName:= strings.concatenate([]string{OST_CLUSTER_PATH, fileName })
  pathNameExtension:= strings.concatenate([]string{pathAndName, OST_FILE_EXTENSION})
	nameAsBytes:= transmute([]byte)fileName
	if len(nameAsBytes) > len(MAX_FILE_NAME_LENGTH_AS_BYTES)
	{
		fmt.printfln("Given file name is too long, Cannot exceed 512 bytes")
		return 1
	}
	//CHECK#2: check if the file already exists
	existenceCheck,exists := os.read_entire_file_from_filename(pathNameExtension)
	if exists {
		fmt.printfln("File already exists")
		return 1
	}
	//CHECK#3: check if the file name is valid
	invalidChars := "[]{}()<>;:.,?/\\|`~!@#$%^&*+-="
	for c:=0; c<len(fileName); c+=1
	{
		if strings.contains(invalidChars, fileName)
		{
			fmt.printfln("Invalid character in file name: %s", fileName)
			return 1
		}
	}

	// If all checks pass then create the file with read/write permissions
	//on Linux the permissions are octal. 0o666 is read/write
	createFile, creationErr := os.open(pathNameExtension, os.O_CREATE, 0o666 )
	if creationErr == 1 {
		return 1
	}
	os.close(createFile)

	//generate a unique cluster id and create a new cluster block in the file
	ID:=OST_GENERATE_CLUSTER_ID()
	OST_CREATE_CLUSTER_BLOCK(pathNameExtension, ID)
	
	return 0
}

/*
Generates the unique cluster id for a new cluster
then returns it to the caller, relies on OST_ADD_ID_TO_CACHE_FILE() to store the retuned id in a file
*/
OST_GENERATE_CLUSTER_ID :: proc() -> i64
{
	//ensure the generated id length is 16 digits
	ID:=rand.int63_max(1e16 + 1)
	idExistsAlready:= OST_CHECK_CACHE_FOR_ID(ID)

	if idExistsAlready == true
	{
		OST_GENERATE_CLUSTER_ID()
	}

    OST_ADD_ID_TO_CACHE_FILE(ID)
		return ID
}


/*
checks the cluster id cache file to see if the id already exists
*/
OST_CHECK_CACHE_FOR_ID:: proc(id:i64) -> bool 
{
	buf: [32]byte
	result: bool
	openCacheFile,err:=os.open("../../../bin/cluster_id_cache", os.O_RDONLY, 0o666)

	//step#1 convert the passed in i64 id number to a string
	idStr := strconv.append_int(buf[:], id, 10) 

	
	//step#2 read the cache file and compare the id to the cache file
	readCacheFile,ok:=os.read_entire_file(openCacheFile)


	// step#3 convert all file contents to a string because...OdinLang go brrrr??
	contentToStr:= transmute(string)readCacheFile

	//step#4 check if the string version of the id is contained in the cache file
		if strings.contains(contentToStr, idStr)
		{
			fmt.printfln("ID already exists in cache file")
			result = true
		}
		else
		{
			result = false
		}
		return result
}


/*upon cluster generation this proc will take the cluster id and store it in a file so that it can not be duplicated in the future
*/
OST_ADD_ID_TO_CACHE_FILE::proc(id:i64) -> int
{
	buf: [32]byte
	cacheFile,err := os.open("../../../bin/cluster_id_cache",os.O_APPEND | os.O_WRONLY, 0o666)
	
	idStr := strconv.append_int(buf[:], id, 10) //the 10 is the base of the number
	//there are several bases, 10 is decimal, 2 is binary, 16 is hex, 16 is octal, 32 is base32, 64 is base64, computer science is fun

	//converting stirng to byte array then writing to file
	transStr:= transmute([]u8)idStr
	writter, ok:= os.write(cacheFile, transStr)
	OST_NEWLINE_CHAR()
	os.close(cacheFile)
	return 0
}


/*
Creates and appends a new cluster to the specified .ost file
*/

OST_CREATE_CLUSTER_BLOCK ::proc (fileName: string, clusterID: i64) -> int
{
	C_BLOCK: []string = {"{\t\n\t_id : %s\n\t\n},\n"}//defines the base structure of a cluster block in a .ost file
	buf: [32]byte

	//step#1: open the file
	clusterFile, err:= os.open(fileName, os.O_APPEND | os.O_WRONLY, 0o666)

	//step#2: iterate over the C_BLOCK array and replace the %s with the passed in clusterID
	for i:=0; i<len(C_BLOCK); i+=1
	{
		//step#3: check if the string contains the %s placeholder if it does replace it with the clusterID
		if strings.contains(C_BLOCK[i], "%s")
		{
			//step#4: replace the %s with the clusterID that is now being converted to a string
			newBlock,ok:= strings.replace(C_BLOCK[i], "%s", strconv.append_int(buf[:], clusterID,10), -1)
			writeBlock,okay:= os.write(clusterFile, transmute([]u8)newBlock)
		}
	}

//todo might need to make sure there can be no duplicates

	//step#FINAL: close the file
	os.close(clusterFile)

	return 0	
}



/*
Used to add a newline character to the end of each id entry in the cluster cache file.
See usage in OST_ADD_ID_TO_CACHE_FILE()
*/
OST_NEWLINE_CHAR ::proc () 
{
	cacheFile, err:= os.open("../../../bin/cluster_id_cache", os.O_APPEND | os.O_WRONLY, 0o666)
	newLineChar:string= "\n"
	transStr:= transmute([]u8)newLineChar
	writter,ok:=os.write(cacheFile, transStr)
}
