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
OST_WHERE_OBJECT :: proc(target, targetName: string) -> (int, bool) {
    // Early return for invalid target
    if target == const.COLLECTION {
        return 1, false
    }

    collectionsDir, errOpen := os.open(const.OST_COLLECTION_PATH)
    defer os.close(collectionsDir)
    foundFiles, dirReadSuccess := os.read_dir(collectionsDir, -1)
    collectionNames := make([dynamic]string)
    defer delete(collectionNames)

    // Collect all valid collection files
    for file in foundFiles {
        if strings.contains(file.name, const.OST_FILE_EXTENSION) {
            append(&collectionNames, file.name)
        }
    }

    found := false  // Track if we found any matches

    // Search through collections
    for collection in collectionNames {
        if target == const.CLUSTER {
            collectionPath := fmt.tprintf("%s%s", const.OST_COLLECTION_PATH, collection)
            if OST_CHECK_IF_CLUSTER_EXISTS(collectionPath, targetName) {
                fmt.printfln("Cluster: %s -> Collection: %s", targetName, collection)
                found = true
                // Remove the return here to continue searching
            }
        } else if target == const.RECORD {
            colName, cluName, success := OST_SCAN_COLLECTION_FOR_RECORD(collection, targetName)
            if success {
                fmt.printfln("Record: %s -> Cluster: %s -> Collection: %s", targetName, cluName, colName)
                found = true
                // Remove the return here to continue searching
            }
        }
    }

    // Return true if we found any matches
    return 0, found
}

//handles WHERE {target name}
OST_WHERE_ANY ::proc(){}