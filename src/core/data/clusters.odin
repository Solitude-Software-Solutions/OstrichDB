package data
import "core:fmt"
import "core:os"
import "core:strings"
import "core:math/rand"

MAX_FILE_NAME_LENGTH :int: 64 //maximum length of a file/cluster name
OST_CLUSTER_PATH :: "../../../bin/"
OST_FILE_EXTENSION ::".ost" //todo: maybe change to .cluster???

@(private)  
	MAX_ID_LENGTH:: 32 //made private because...reasons

	Cluster :: struct {
	_id:     []u8, //unique identifier for the record cannot be duplicated
	// Records: []Record, //allows for multiple records to be stored in a cluster
}

//for testing purposes todo: remove later
main::proc() {
	os.make_directory("../../../bin")
	OST_CREATE_CLUSTER_FILE("test")
	OST_GENERATE_CLUSTER_ID()
}

/*
Create a new empty Cluster file within the DB
Clusters are collections of records stored in a .ost file
Params: fileName - the desired file(cluster) name
*/
/*
todo need to add the following checks:
1. check if the file name is too long/DONE
2. check if the file name is already in use/DONE
3. check if the file name is valid
*/
OST_CREATE_CLUSTER_FILE :: proc(fileName: string) -> int {
// concat the path and the file name into a string 
	pathAndName:= strings.concatenate([]string{OST_CLUSTER_PATH, fileName })
	//concat the new string with the file extension
	pathNameExtension:= strings.concatenate([]string{pathAndName, OST_FILE_EXTENSION})
	fmt.printfln("Path Name Extension: %s", pathNameExtension)


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
OST_GENERATE_CLUSTER_ID :: proc() -> int
{
	nums: [10]int = {0,1,2,3,4,5,6,7,8,9}
	choice:int 
	for i:=0; i<MAX_ID_LENGTH; i+=1
	{
		choice= rand.choice(nums[:])
		fmt.print(choice) //todo: remove this later
	}

	return choice
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
OST_ADD_ID_TO_BIN_DIR::proc() -> int
{

	return 0
}