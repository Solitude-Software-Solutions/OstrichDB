package data
import "core:fmt"
import "core:os"
import "core:strings"
import "core:math/rand"
import "core:strconv"

MAX_FILE_NAME_LENGTH :int: 64 //maximum length of a file/cluster name
OST_CLUSTER_PATH :: "../../../bin/"
OST_FILE_EXTENSION ::".ost" //todo: maybe change to .cluster???

	Cluster :: struct {
	_id:     int, //unique identifier for the record cannot be duplicated
	// Records: []Record, //allows for multiple records to be stored in a cluster
}

cluster: Cluster

//for testing purposes todo: remove later
main::proc() {
	os.make_directory("../../../bin") //Todo make this an actual proc in the engine
	OST_CREATE_CACHE_FILE()
	OST_CREATE_CLUSTER_FILE("test")
	OST_GENERATE_CLUSTER_ID()
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
OST_CREATE_CLUSTER_FILE :: proc(fileName: string) -> int {
// concat the path and the file name into a string 
	pathAndName:= strings.concatenate([]string{OST_CLUSTER_PATH, fileName })
	//concat the new string with the file extension
	pathNameExtension:= strings.concatenate([]string{pathAndName, OST_FILE_EXTENSION})
	
	//CHECK#1: check if the file name is too long
	if len(fileName) > MAX_FILE_NAME_LENGTH 
	{
		fmt.printfln("Given file name is too long, Cannot be longer than %d characters", MAX_FILE_NAME_LENGTH)
		return 1
	}
	//CHECK#2: check if the file already exists
	existenceCheck,exists := os.read_entire_file_from_filename(pathNameExtension)
	if exists {
		fmt.printfln("File already exists")
		return 1
	}
	//CHECK#3: check if the file name is valid
	validChars := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"
	for c:=0; c<len(fileName); c+=1
	{
		if !strings.contains(validChars, fileName)
		{
			fmt.printfln("Invalid character in file name: %s", fileName)
			return 1
		}
	}

	// If all checks pass then create the file with read/write permissions
	//on Linux the permissions are octal. 0o666 is read/write
	createFile, creationErr := os.open(pathNameExtension, os.O_CREATE, 0o666 )
	if creationErr == 1 {
		fmt.printfln("Error creating file: %d", fileName)
		return 1
	}
	os.close(createFile)
	return 0
}




/*
Creates and appends a new cluster to the specified .ost file
*/

OST_CREATE_CLUSTER ::proc (fileName: string, clusterName: string) -> int
{



return 0
}


/*
Generates the unique cluster id for a new cluster
then returns it to the caller, relies on OST_ADD_ID_TO_BIN_DIR() to store the retuned id in a file
*/
OST_GENERATE_CLUSTER_ID :: proc() -> i64
{
	//ensure the generated id length is 16 digits
		ID:=rand.int63_max(1e16 + 1)
		fmt.printfln("ID: %d", ID) //todo remove later

		// todo: need to check if the id already exists in the bin directory
    OST_ADD_ID_TO_CACHE_FILE(ID)
		return ID
}


// checks if a cluster exists within a specific .ost file
//can be checked by cluster name or cluster id
// Params - fileName: the name of the .ost file, param: the cluster name or id
OST_CHECK_CLUSTER_EXISTS:: proc(fileName: string, param: ..any) -> bool
{
	result:= false

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