package data

import "core:fmt"
import "../../types"
import "../../../utils"
import "core:strings"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            This file contains the logic for performing automatic
            operations within the DBMS. r example:
            When the user wants to create record within a cluster or collection
            that does not exist yet, so OstrichDB will create it automatically
            with the values provided via the command
*********************************************************/

//Creates the given tier data structure with the given name
// tier = the data structure tier to create
// providedNames = a list of data structure names to be created
AUTO_CREATE ::proc(tier:int, providedNames:[]string) -> bool{
    using types

    collectionName:= providedNames[0]
    clusterName:string

    if len(providedNames) > 1{
        clusterName = providedNames[1]
    }

    switch(tier){
    case COLLECTION_TIER:
        CREATE_COLLECTION(collectionName,CollectionType.STANDARD_PUBLIC)
        break
    case CLUSTER_TIER:
        id:= GENERATE_ID(false)
        CREATE_CLUSTER(collectionName, clusterName, id)
        break
    case:
        return false
    }
    return true
}


confirm_auto_operation::proc(operation:string, objNames:[]string) -> i32{
    using utils
    confirmation:i32

    fmt.printfln("%s%sWARNING%s For the requested operation: %s%s%s to be performed the following parent objects must first exist: \n", BOLD_UNDERLINE, YELLOW, RESET, BOLD_UNDERLINE, operation, RESET)
    for name , index in objNames{
        if index == 0{
        fmt.printfln("Collection: %s%s%s", BOLD_UNDERLINE, name, RESET)
        }else if index == 1{
            fmt.printfln("Cluster: %s%s%s", BOLD_UNDERLINE, name, RESET)
        }
    }

    fmt.printfln("OstrichDB is about to perform an automatic %s%s%s operation on your behalf, would you like to continue? [Y/N] ", BOLD_UNDERLINE, operation, RESET)
    input:= get_input(false)

    if input == "y" || input == "Y"{
        confirmation = 0
    }else if input == "n" || input == "N"{
        fmt.println("")
        confirmation = -1
    }
    return confirmation
}
