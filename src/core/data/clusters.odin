package data
import "./metadata"
import "../../utils/errors"
import "../../utils/logging"
import "../../utils/misc"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:math/rand"
import "core:strconv"
//=========================================================//
//Author: Marshall Burns aka @SchoolyB
//Desc: This file handles the creation and manipulation of
//			cluster files and their data within the db engine
//=========================================================//


MAX_FILE_NAME_LENGTH_AS_BYTES :[512]byte
OST_CLUSTER_PATH :: "../bin/clusters/"
OST_SECURE_CLUSTER_PATH :: "../bin/secure/"
OST_FILE_EXTENSION ::".ost"
cluster: Cluster
Cluster :: struct {
	_id:     int, //unique identifier for the record cannot be duplicated
	record: struct{}, //allows for multiple records to be stored in a cluster
}

main:: proc() {
	OST_CREATE_CACHE_FILE()
	os.make_directory(OST_CLUSTER_PATH)
	// OST_CREATE_OST_FILE("test",0)
	// OST_CHOOSE_DB()

}

//creates a file in the bin directory used to store the all used cluster ids
OST_CREATE_CACHE_FILE :: proc() {
	cacheFile,err := os.open("../bin/cluster_id_cache", os.O_CREATE, 0o666)
	if err != 0{
		errors.throw_utilty_error(1, "Error creating cluster id cache file", "OST_CREATE_CACHE_FILE")
		logging.log_utils_error("Error creating cluster id cache file", "OST_CREATE_CACHE_FILE")
	}
	os.close(cacheFile)
}



/*
Creates a new Cluster file with metadata within the DB 
Clusters are collections of records stored in a .ost file
Params: fileName - the desired file(cluster) name
				type - the type of file to create, 0 is standard, 1 is secure
*/
OST_CREATE_OST_FILE :: proc(fileName:string, type:int) -> int {
	// concat the path and the file name into a string depending on the type of file to create
	pathAndName:string
	switch(type)
		{
		case 0: //standard cluster file
			pathAndName:= strings.concatenate([]string{OST_CLUSTER_PATH, fileName })
			if OST_PREFORM_CLUSTER_NAME_CHECK(fileName) == 1
			{
				return 1
			}
			pathNameExtension:= strings.concatenate([]string{pathAndName, OST_FILE_EXTENSION})
			createFile, creationErr := os.open(pathNameExtension, os.O_CREATE, 0o666 )
			metadata.OST_APPEND_METADATA_HEADER(pathNameExtension)
			if creationErr != 0
			{
				errors.throw_utilty_error(1, "Error creating .ost file", "OST_CREATE_OST_FILE")
				logging.log_utils_error("Error creating .ost file", "OST_CREATE_OST_FILE")
				return 1
			}
			metadata.OST_METADATA_ON_CREATE(pathNameExtension)
			defer os.close(createFile)
			break 
		case 1: //secure file
			pathAndName:= strings.concatenate([]string{OST_SECURE_CLUSTER_PATH, fileName })
			if OST_PREFORM_CLUSTER_NAME_CHECK(fileName) == 1
			{
				return 1
			}
  		pathNameExtension:= strings.concatenate([]string{pathAndName, OST_FILE_EXTENSION})
			createFile, creationErr := os.open("../bin/secure/_secure_.ost", os.O_CREATE, 0o666 )
			metadata.OST_APPEND_METADATA_HEADER(pathNameExtension)
			if creationErr != 0
			{
				errors.throw_utilty_error(1, "Error creating .ost file", "OST_CREATE_OST_FILE")
				logging.log_utils_error("Error creating .ost file", "OST_CREATE_OST_FILE")
				return 1
			}
			metadata.OST_METADATA_ON_CREATE(pathNameExtension)
			defer os.close(createFile)

		}
	// If all checks pass then create the file with read/write permissions
	//on Linux the permissions are octal. 0o666 is read/write
	
	//append and set the metadata header for the file
	

	//generate a unique cluster id and create a new cluster block in the file
	ID:=OST_GENERATE_CLUSTER_ID()
	return 0
}


OST_PREFORM_CLUSTER_NAME_CHECK::proc(fn:string) ->int
{
	nameAsBytes:= transmute([]byte)fn
	if len(nameAsBytes) > len(MAX_FILE_NAME_LENGTH_AS_BYTES)
	{
		fmt.printfln("Given file name is too long, Cannot exceed 512 bytes")
		return 1
	}
	//CHECK#2: check if the file already exists
	existenceCheck,exists := os.read_entire_file_from_filename(fn)
	if exists {
		logging.log_utils_error(".ost file already exists", "OST_CREATE_OST_FILE")
		return 1
	}
	//CHECK#3: check if the file name is valid
	invalidChars := "[]{}()<>;:.,?/\\|`~!@#$%^&*+-="
	for c:=0; c<len(fn); c+=1
	{
		if strings.contains_any(fn, invalidChars)
		{
			fmt.printfln("Invalid character(s) found in file name: %s", fn)
			return 1
		}
	}
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
		errors.throw_utilty_error(1, "ID already exists in cache file", "OST_GENERATE_CLUSTER_ID")
		logging.log_utils_error("ID already exists in cache file", "OST_GENERATE_CLUSTER_ID")
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
	openCacheFile,err:=os.open("../bin/cluster_id_cache", os.O_RDONLY, 0o666)
	if err != 0
	{
		errors.throw_utilty_error(1, "Error opening cluster id cache file", "OST_CHECK_CACHE_FOR_ID")
		logging.log_utils_error("Error opening cluster id cache file", "OST_CHECK_CACHE_FOR_ID")
	}
	//step#1 convert the passed in i64 id number to a string
	idStr := strconv.append_int(buf[:], id, 10) 

	
	//step#2 read the cache file and compare the id to the cache file
	readCacheFile,ok:=os.read_entire_file(openCacheFile)
	if ok == false
	{
		errors.throw_utilty_error(1, "Error reading cluster id cache file", "OST_CHECK_CACHE_FOR_ID")
		logging.log_utils_error("Error reading cluster id cache file", "OST_CHECK_CACHE_FOR_ID")
	}

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
	os.close(openCacheFile)
		return result
}


/*upon cluster generation this proc will take the cluster id and store it in a file so that it can not be duplicated in the future
*/
OST_ADD_ID_TO_CACHE_FILE::proc(id:i64) -> int
{
	buf: [32]byte
	cacheFile,err := os.open("../bin/cluster_id_cache",os.O_APPEND | os.O_WRONLY, 0o666)
	if err != 0
	{
		errors.throw_utilty_error(1, "Error opening cluster id cache file", "OST_ADD_ID_TO_CACHE_FILE")
		logging.log_utils_error("Error opening cluster id cache file", "OST_ADD_ID_TO_CACHE_FILE")
	}
	
	idStr := strconv.append_int(buf[:], id, 10) //the 10 is the base of the number
	//there are several bases, 10 is decimal, 2 is binary, 16 is hex, 16 is octal, 32 is base32, 64 is base64, computer science is fun

	//converting stirng to byte array then writing to file
	transStr:= transmute([]u8)idStr
	writter, ok:= os.write(cacheFile, transStr)
	if ok != 0
	{
		errors.throw_utilty_error(1, "Error writing to cluster id cache file", "OST_ADD_ID_TO_CACHE_FILE")
		logging.log_utils_error("Error writing to cluster id cache file", "OST_ADD_ID_TO_CACHE_FILE")
	}
	OST_NEWLINE_CHAR()
	os.close(cacheFile)
	return 0
}


/*
Creates and appends a new cluster to the specified .ost file
*/

OST_CREATE_CLUSTER_BLOCK ::proc (fileName: string, clusterID: i64, clusterName:string) -> int
{

	clusterExists:= OST_CHECK_IF_CLUSTER_EXISTS(fileName, clusterName)

	if clusterExists == true
	{
		errors.throw_utilty_error(1, "Cluster already exists in file", "OST_CREATE_CLUSTER_BLOCK")
		logging.log_utils_error("Cluster already exists in file", "OST_CREATE_CLUSTER_BLOCK")
		return 1
	}
	FIRST_HALF:[]string = {"{\n\tcluster_name : %n"}
	LAST_HALF:[]string= {"\n\tcluster_id : %i\n\t\n},\n"}//defines the base structure of a cluster block in a .ost file
	buf: [32]byte
	//step#1: open the file
	clusterFile, err:= os.open(fileName, os.O_APPEND | os.O_WRONLY, 0o666)
	if err != 0
	{
		errors.throw_utilty_error(1, "Error opening cluster file", "OST_CREATE_CLUSTER_BLOCK")
		logging.log_utils_error("Error opening cluster file", "OST_CREATE_CLUSTER_BLOCK")
	}


	for i:=0; i<len(FIRST_HALF); i+=1
	{
		if(strings.contains(FIRST_HALF[i], "%n"))
		{
			//step#5: replace the %n with the cluster name
		newClusterName,alright:= strings.replace(FIRST_HALF[i], "%n",clusterName,-1)	
		writeClusterName,ight:= os.write(clusterFile, transmute([]u8)newClusterName)
		}
	}
	//step#2: iterate over the FIRST_HALF array and replace the %s with the passed in clusterID
	for i:=0; i<len(LAST_HALF); i+=1
	{
		//step#3: check if the string contains the %s placeholder if it does replace it with the clusterID
		if strings.contains(LAST_HALF[i], "%i")
		{
			//step#4: replace the %s with the clusterID that is now being converted to a string
			newClusterID,ok:= strings.replace(LAST_HALF[i], "%i", strconv.append_int(buf[:], clusterID,10), -1)
			if ok == false
			{
				errors.throw_utilty_error(1, "Error placing id and name into cluster template", "OST_CREATE_CLUSTER_BLOCK")
				logging.log_utils_error("Error placing id into cluster template", "OST_CREATE_CLUSTER_BLOCK")
			}
			writeClusterID,okay:= os.write(clusterFile, transmute([]u8)newClusterID)
			if okay!= 0
			{
				errors.throw_utilty_error(1, "Error writing cluster block to file", "OST_CREATE_CLUSTER_BLOCK")
				logging.log_utils_error("Error writing cluster block to file", "OST_CREATE_CLUSTER_BLOCK")
			}
		}
	}

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
	cacheFile, err:= os.open("../bin/cluster_id_cache", os.O_APPEND | os.O_WRONLY, 0o666)
	if err != 0
	{
		errors.throw_utilty_error(1, "Error opening cluster id cache file", "OST_NEWLINE_CHAR")
		logging.log_utils_error("Error opening cluster id cache file", "OST_NEWLINE_CHAR")
	}
	newLineChar:string= "\n"
	transStr:= transmute([]u8)newLineChar
	writter,ok:=os.write(cacheFile, transStr)
	if ok != 0
	{
		errors.throw_utilty_error(1, "Error writing newline character to cluster id cache file", "OST_NEWLINE_CHAR")
		logging.log_utils_error("Error writing newline character to cluster id cache file", "OST_NEWLINE_CHAR")
	}
	os.close(cacheFile)
}


// =====================================DATA INTERACTION=====================================//
//This section holds procs that deal with user/data interation within the Ostrich Engine

//handle logic for choosing which .ost file the user wants to interact with
OST_CHOOSE_DB:: proc() 
{
	buf:[256]byte
	input:string
	ext:=".ost" //concat this to end of input to prevent user from having to type it each time

	fmt.printfln("Enter the name of database that you would like to interact with")

	n, err := os.read(os.stdin, buf[:])
	if n > 0 {
		//todo add option for user to enter a command that lists current dbs
        input := string(buf[:n]) 
				//trim the string of any whitespace or newline characters 

				//Shoutout to the OdinLang Discord for helping me with this...
        input = strings.trim_right_proc(input, proc(r: rune) -> bool {
            return r == '\r' || r == '\n'
					})
				dbName:= strings.concatenate([]string{input,ext})
				dbExists:=OST_CHECK_IF_DB_EXISTS(dbName,1)
				switch(dbExists)
				{
					case true:
						fmt.printfln("%sFound database%s: %s%s%s",misc.GREEN,misc.RESET,misc.BOLD, input, misc.RESET) 
						//do stuff
						//todo what would the user like to do with this database?
						break
					case false:
						fmt.printfln("Database with name:%s%s%s does not exist", misc.BOLD,input, misc.RESET) 
						fmt.printfln("please try again")
						OST_CHOOSE_DB()
						break
				}
			}
}

//checks if the passed in ost file exists in "../bin/clusters". see usage in OST_CHOOSE_DB()
//type 0 is for standard cluster files, type 1 is for secure files
OST_CHECK_IF_DB_EXISTS::proc(fn:string, type:int) -> bool
{
	dbExists:bool
	//need to cwd into bin
  os.set_current_directory("../bin/")
	dir:string
	switch(type)
	{
		case 0:
			dir="clusters/"
			break
		case 1:
			dir="secure/"
			break
	}
	
  clusterDir, errOpen := os.open(dir)
	
  defer os.close(clusterDir)
  foundFiles, errRead := os.read_dir(clusterDir, -1)
  for file in foundFiles {
		if(file.name == fn)
		{
			dbExists = true
		}
		else
		{
			dbExists =false
		}
  }

	return dbExists
}

//handles logic whehn the user chooses to interact with a specific cluster in a .ost file
OST_CHOOSE_CLUSTER_NAME :: proc(fn:string)
{
	buf:[256]byte
	n, err := os.read(os.stdin, buf[:])
	if n > 0 {
		fmt.printfln("Which cluster would you like to interact with?")
        input := string(buf[:n]) 
				//trim the string of any whitespace or newline characters 

				//Shoutout to the OdinLang Discord for helping me with this...
        input = strings.trim_right_proc(input, proc(r: rune) -> bool {
            return r == '\r' || r == '\n'
        })
			
			cluserExists:= OST_CHECK_IF_CLUSTER_EXISTS(fn, input)
			switch(cluserExists)
			{
				case true:
						//todo what would the user like to do with this cluster?
					break
				case false:
					fmt.printfln("Cluster with name:%s%s%s does not exist in database: %s",misc.BOLD, input,misc.RESET, fn)
					fmt.printfln("Please try again")
					OST_CHOOSE_CLUSTER_NAME(fn)
				//todo add a commands the lists all available cluster in the current db file.
					break
			}
		}
}

//exclusivley used for checking if the name of a cluster exists...NOT the ID
//fn- filename, cn- clustername
OST_CHECK_IF_CLUSTER_EXISTS:: proc(fn:string, cn:string) -> bool
{
	clusterFound:bool
	data, success :=os.read_entire_file(fn)
	if !success {
		fmt.println("Failed to read file:", fn)
		return false
	}
	defer delete(data)

	content := string(data)
	if strings.contains(content, cn)
	{
		clusterFound= true
	}
	else
	{
		clusterFound = false
	}
	return clusterFound
	
}

//.appends the passed in data to the passed in cluster
//fn-filename, cn-clustername,id-cluster id, dn-dataname, d-data
OST_APPEND_DATA_TO_CLUSTER :: proc(fn: string, cn: string, id: i64, dn: string, d: string) {
    data, success := os.read_entire_file(fn)
    if !success {
        fmt.println("Failed to read file:", fn)
        return
    }
    defer delete(data)

    content := string(data)
    lines := strings.split(content, "\n")
    defer delete(lines)

    cluster_start := -1
    closing_brace := -1

    // Find the cluster and its closing brace
    for i := 0; i < len(lines); i += 1 {
        if strings.contains(lines[i], cn) {
            cluster_start = i
        }
        if cluster_start != -1 && strings.contains(lines[i], "}") {
            closing_brace = i
            break
        }
    }

    if cluster_start == -1 || closing_brace == -1 {
        fmt.println("Cluster not found or invalid structure")
        return
    }

    // Create the new line
    new_line := fmt.tprintf("\t%s : %s,", dn, d)

    // Insert the new line and adjust the closing brace
    new_lines := make([dynamic]string, len(lines) + 1)
    copy(new_lines[:closing_brace], lines[:closing_brace])
    new_lines[closing_brace] = new_line
    new_lines[closing_brace + 1] = "}"
    if closing_brace + 1 < len(lines) {
        copy(new_lines[closing_brace + 2:], lines[closing_brace + 1:])
    }

    new_content := strings.join(new_lines[:], "\n")
    err := os.write_entire_file(fn, transmute([]byte)new_content)
    if err != true {
        fmt.println("Failed to write file:", fn, "Error:", err)
    } else {
        fmt.println("Successfully updated file")
    }
}