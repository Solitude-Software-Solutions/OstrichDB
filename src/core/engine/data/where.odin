package data
import "core:os"
import "core:strings"
import "core:fmt"
import "../../const"
import "../../types"
import "../../../utils"


//Contains all logic for the WHERE command
//where allows for quick searching where 2nd or 3rd layer data (clusters & records)
//example use case `WHERE cluster foo` would show the location of every instance of a cluster foo
//another example:
//`WHERE foo` would show the location of every 2nd or 3rd layer data object with the name foo

//handles WHERE {target} {target name}
OST_WHERE_OBJECT :: proc(target, targetName:string) -> (int, bool){

    // if target == const.COLLECTION{
    //     return 1, false
    // }

    // collectionsDir, errOpen := os.open(const.OST_COLLECTION_PATH)
	// defer os.close(collectionsDir)
	// foundFiles, dirReadSuccess := os.read_dir(collectionsDir, -1)
	// collectionNames := make([dynamic]string)
	// defer delete(collectionNames)

	// for file in foundFiles {
	// 	if strings.contains(file.name, const.OST_FILE_EXTENSION) {
	// 		append(&collectionNames, file.name)
	// 	}

    //     for collection in collectionNames{

    //     if target == const.CLUSTER{
    //         if OST_CHECK_IF_CLUSTER_EXISTS(file.name, targetName){
    //             fmt.printfln("Found cluster %s in collection %s using WHERE command", targetName, file.name)
    //             return 0, true
    //         }
    //     }else if target == const.RECORD{
    //         colName, cluName, success := OST_SCAN_COLLECTION_FOR_RECORD(file.name, targetName)
    //         if success{
    //             fmt.printfln("Found record %s in collection %s and cluster %s using WHERE command", targetName, colName, cluName)
    //             return 0, true
    //         }
    //     }
    // }
	// }


    return 0, true
}

//handles WHERE {target name}
OST_WHERE_ANY ::proc(){}