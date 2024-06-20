package data
import "core:fmt"
import "core:os"
import "core:strings"

MAX_FILE_NAME_LENGTH :int: 256 //maximum length of a file/cluster name
OST_CLUSTER_PATH :: "../../../bin/"
OST_FILE_EXTENSION ::".ost" //todo: maybe change to .cluster???

Cluster :: struct {
	_id:     []u8, //unique identifier for the record cannot be duplicated
	// Records: []Record, //allows for multiple records to be stored in a cluster
}

//for testing purposes todo: remove later
main::proc() {
	os.make_directory("../../../bin")
	OST_CREATE_CLUSTER("test")
}

/*
Create a new empty Cluster within the DB
Clusters are files with the .ost extension
Params: fileName - the desired file(cluster) name
*/
OST_CREATE_CLUSTER :: proc(fileName: string) -> int {
// concat the path and the file name into a string 
	pathAndName:= strings.concatenate([]string{OST_CLUSTER_PATH, fileName })
	//concat the new string with the file extension
	pathNameExtension:= strings.concatenate([]string{pathAndName, OST_FILE_EXTENSION})
	fmt.printfln("Path Name Extension: %s", pathNameExtension)


	//create the cluster file
	clusterFile, ok := os.open(pathNameExtension, os.O_CREATE)
	if ok == 1 {
		return 1
	}
	os.close(clusterFile)
	return 0
}
