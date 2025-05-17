package operations 

import "core:os"
import "core:fmt"
import "core:strings"
import "core:encoding/json"
import "../../../utils"
import "../../const"
import "../../engine/data"
import "../../engine/security"
import "../../engine/data/metadata"
import T "../../types"

handle_collection_creation :: proc(collectionName: string) {
    exists := data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0)
    switch (exists) {
    case false:
        fmt.printf("Creating collection: %s%s%s\n", utils.BOLD_UNDERLINE, collectionName, utils.RESET)
        success := data.CREATE_COLLECTION(collectionName, T.CollectionType.STANDARD_PUBLIC)
        if success {
            fmt.printf(
                "Collection: %s%s%s created successfully.\n",
                utils.BOLD_UNDERLINE,
                collectionName,
                utils.RESET,
            )
            fileName := utils.concat_standard_collection_name(collectionName)
            metadata.UPDATE_METADATA_UPON_CREATION(fileName)

            security.ENCRYPT_COLLECTION(
                collectionName,
                T.CollectionType.STANDARD_PUBLIC,
                T.current_user.m_k.valAsBytes,
                false,
            )
        } else {
            fmt.printf(
                "Failed to create collection %s%s%s.\n",
                utils.BOLD_UNDERLINE,
                collectionName,
                utils.RESET,
            )
            utils.log_runtime_event(
                "Failed to create collection",
                "User tried to create a collection but failed.",
            )
            utils.log_err("Failed to create new collection", #procedure)
        }
        break
    case true:
        fmt.printf(
            "Collection: %s%s%s already exists. Please choose a different name.\n",
            utils.BOLD_UNDERLINE,
            collectionName,
            utils.RESET,
        )
        utils.log_runtime_event(
            "Duplicate collection name",
            "User tried to create a collection with a name that already exists.",
        )
        break
    }
}

handle_cluster_creation :: proc(collectionName: string, clusterName: string) -> int {
    if !data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
        fmt.printfln(
            "Collection: %s%s%s does not exist.",
            utils.BOLD_UNDERLINE,
            collectionName,
            utils.RESET,
        )
        if data.confirm_auto_operation(T.Token[.NEW],[]string{collectionName}) == -1{
           return -1
        }else{
         data.AUTO_CREATE(T.COLLECTION_TIER, []string{collectionName})
        }
    }

    security.EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(
        collectionName,
        T.Token[.NEW],
       T.CollectionType.STANDARD_PUBLIC,
    )

    fmt.printf(
        "Creating cluster: %s%s%s within collection: %s%s%s\n",
        utils.BOLD_UNDERLINE,
        clusterName,
        utils.RESET,
        utils.BOLD_UNDERLINE,
        collectionName,
        utils.RESET,
    )
    // checks := data.HANDLE_INTEGRITY_CHECK_RESULT(collectionName)
    // switch (checks)
    // {
    // case -1:
    // 	return -1
    // }

    id := data.GENERATE_ID(true)
    result := data.CREATE_CLUSTER(collectionName, clusterName, id)
    data.APPEND_ID_TO_ID_COLLECTION(fmt.tprintf("%d", id), 0)

    switch (result)
    {
    case -1:
        fmt.printfln(
            "Cluster with name: %s%s%s already exists within collection %s%s%s. Failed to create cluster.",
            utils.BOLD_UNDERLINE,
            clusterName,
            utils.RESET,
            utils.BOLD_UNDERLINE,
            collectionName,
            utils.RESET,
        )
        security.ENCRYPT_COLLECTION(
            collectionName,
           T.CollectionType.STANDARD_PUBLIC,
            T.current_user.m_k.valAsBytes,
            false,
        )
        break
    case 1, 2, 3:
    errorLocation:= utils.get_caller_location()
        error1 := utils.new_err(
            utils.ErrorType.CANNOT_CREATE_CLUSTER,
            utils.get_err_msg(utils.ErrorType.CANNOT_CREATE_CLUSTER),
            errorLocation
        )
        utils.throw_custom_err(
            error1,
            "Failed to create cluster due to internal OstrichDB error.\n Check logs for more information.",
        )
        utils.log_err("Failed to create new cluster.", #procedure)
        break
    }
    fmt.printfln(
        "Cluster: %s%s%s created successfully.\n",
        utils.BOLD_UNDERLINE,
        clusterName,
        utils.RESET,
    )
    fn := utils.concat_standard_collection_name(collectionName)
    metadata.UPDATE_METADATA_AFTER_OPERATIONS(fn)

    security.ENCRYPT_COLLECTION(
        collectionName,
        T.CollectionType.STANDARD_PUBLIC,
        T.current_user.m_k.valAsBytes,
        false,
    )
    return 1
}

handle_record_creation :: proc(collectionName, clusterName, recordName: string, p_token: map[string]string) -> int {
    rValue: string
    if !data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
        fmt.printfln(
            "Collection: %s%s%s does not exist.",
            utils.BOLD_UNDERLINE,
            collectionName,
            utils.RESET,
        )
        if data.confirm_auto_operation(T.Token[.NEW],[]string{collectionName, clusterName}) == -1{
           return -1
        }else{
         data.AUTO_CREATE(T.COLLECTION_TIER, []string{collectionName})
         data.AUTO_CREATE(T.CLUSTER_TIER, []string{collectionName, clusterName})
        }
    }

    security.EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(collectionName, T.Token[.NEW], .STANDARD_PUBLIC)


    if len(recordName) > 64 {
        fmt.printfln(
            "Record name: %s%s%s is too long. Please choose a name less than 64 characters.",
            utils.BOLD_UNDERLINE,
            recordName,
            utils.RESET,
        )
        return -1
    }
    colPath := utils.concat_standard_collection_name(collectionName)

    if T.Token[.OF_TYPE] in p_token {
        rType, typeSuccess := data.SET_RECORD_TYPE(p_token[T.Token[.OF_TYPE]])
        if typeSuccess == 0 {
            fmt.printfln(
                "Creating record: %s%s%s of type: %s%s%s",
                utils.BOLD_UNDERLINE,
                recordName,
                utils.RESET,
                utils.BOLD_UNDERLINE,
                rType,
                utils.RESET,
            )

            if T.Token[.WITH] in p_token  && len(p_token[T.Token[.WITH]]) != 0{
               rValue = p_token[T.Token[.WITH]]
            } else if T.Token[.WITH] in p_token  && len(p_token[T.Token[.WITH]]) == 0{
               fmt.println("%s%sWARNING%s When using the WITH token there must be a value of the assigned type after. Please try again")
                return 1
            }
            //TODO: Need to work on ensuring the value that is provided when using the WITH token is the appropriate type.
            //Just like i am doing in the SET_RECORD_VALUE() proc....

            recordCreationSuccess := data.CREATE_RECORD(
                colPath,
                clusterName,
                recordName,
                rValue,
                rType,
            )
            switch (recordCreationSuccess)
            {
            case 0:
                fmt.printfln(
                    "Record: %s%s%s of type: %s%s%s created successfully",
                    utils.BOLD_UNDERLINE,
                    recordName,
                    utils.RESET,
                    utils.BOLD_UNDERLINE,
                    rType,
                    utils.RESET,
                )

                //IF a records type is NULL, technically it cant hold a value, the word NULL in the value slot
                // of a record is mostly a placeholder
                if rType == T.Token[.NULL] {
                    data.SET_RECORD_VALUE(colPath, clusterName, recordName, T.Token[.NULL])
                }

                fn := utils.concat_standard_collection_name(collectionName)
                metadata.UPDATE_METADATA_AFTER_OPERATIONS(fn)
                break
            case -1, 1:
                fmt.printfln(
                    "Failed to create record: %s%s%s of type: %s%s%s",
                    utils.BOLD_UNDERLINE,
                    recordName,
                    utils.RESET,
                    utils.BOLD_UNDERLINE,
                    rType,
                    utils.RESET,
                )
                utils.log_runtime_event(
                    "Failed to create record",
                    "User requested to create a record but failed.",
                )
                utils.log_err("Failed to create a new record.", #procedure)
                break
            }
        } else {
            fmt.printfln(
                "Failed to create record: %s%s%s of type: %s%s%s. Please try again.",
                utils.BOLD_UNDERLINE,
                recordName,
                utils.RESET,
                utils.BOLD_UNDERLINE,
                rType,
                utils.RESET,
            )
        }
        security.ENCRYPT_COLLECTION(
            collectionName,
            .STANDARD_PUBLIC,
            T.current_user.m_k.valAsBytes,
            false,
        )
    } else {
        fmt.printfln(
            "Incomplete command. Correct Usage: NEW <collection_name>.<cluster_name>.<record_name> OF_TYPE <record_type>",
        )
        utils.log_runtime_event(
            "Incomplete NEW RECORD command",
            "User did not provide a record name or type to create.",
        )
    }
    return 1
}

handle_record_update :: proc(collectionName, clusterName, recordName, rValue: string) -> int {
    if !data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
        fmt.printfln(
            "Collection: %s%s%s does not exist.",
            utils.BOLD_UNDERLINE,
            collectionName,
            utils.RESET,
        )
        return -1
    }

    security.EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(
        collectionName,
        T.Token[.SET],
        .STANDARD_PUBLIC,
    )

    fmt.printfln(
        "Setting record: %s%s%s to %s%s%s",
        utils.BOLD_UNDERLINE,
        recordName,
        utils.RESET,
        utils.BOLD_UNDERLINE,
        rValue,
        utils.RESET,
    )

    file := utils.concat_standard_collection_name(collectionName)

    setValueSuccess := data.SET_RECORD_VALUE(
        file,
        clusterName,
        recordName,
        strings.clone(rValue),
    )

    //if that records type is one of the following 'special' arrays:
    // []CHAR, []DATE, []TIME, []DATETIME,etc scan for that type and remove the "" that
    // each value will have(THANKS ODIN...)
    rType, _ := data.GET_RECORD_TYPE(file, clusterName, recordName)

    /*
    Added this because of: https://github.com/Solitude-Software-Solutions/OstrichDB/issues/203
    I guess its not neeeded, if a user wants to have a single character string record who am I to stop them?
    Remove at any time if needed - Marshall
    */
    if rType == T.Token[.STRING] && len(rValue) == 1 {
        conversionSuccess := data.CHANGE_RECORD_TYPE(
            file,
            clusterName,
            recordName,
            rValue,
            T.Token[.CHAR],
        )
        if conversionSuccess {
            fmt.printfln(
                "Record with name: %s%s%s converted to type: %sCHAR%s",
                utils.BOLD_UNDERLINE,
                recordName,
                utils.RESET,
                utils.BOLD_UNDERLINE,
                utils.RESET,
            )
        }
    }


    if rType == T.Token[.NULL] {
        fmt.printfln(
            "Cannot a value assign to record: %s%s%s of type %sNULL%s",
            utils.BOLD_UNDERLINE,
            recordName,
            utils.RESET,
            utils.BOLD_UNDERLINE,
            utils.RESET,
        )

        return 0
    }

    if rType == T.Token[.CHAR_ARRAY] ||
       rType == T.Token[.DATE_ARRAY] ||
       rType == T.Token[.TIME_ARRAY] ||
       rType == T.Token[.DATETIME_ARRAY] ||
       rType == T.Token[.UUID_ARRAY] {
        data.MODIFY_ARRAY_VALUES(file, clusterName, recordName, rType)
    }

    if setValueSuccess {
        fmt.printfln(
            "Successfully set record: %s%s%s to %s%s%s",
            utils.BOLD_UNDERLINE,
            recordName,
            utils.RESET,
            utils.BOLD_UNDERLINE,
            rValue,
            utils.RESET,
        )
    } else {
        fmt.printfln(
            "Failed to set record: %s%s%s to %s%s%s",
            utils.BOLD_UNDERLINE,
            recordName,
            utils.RESET,
            utils.BOLD_UNDERLINE,
            rValue,
            utils.RESET,
        )
    }

    fn := utils.concat_standard_collection_name(collectionName)
    metadata.UPDATE_METADATA_AFTER_OPERATIONS(fn)
    security.ENCRYPT_COLLECTION(
        collectionName,
        .STANDARD_PUBLIC,
        T.current_user.m_k.valAsBytes,
        false,
    )
    return 1
}

handle_collection_fetch :: proc(collectionName: string) -> string {
    //check that the collection even exists
    if !data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
        fmt.printfln(
            "Collection: %s%s%s does not exist.",
            utils.BOLD_UNDERLINE,
            collectionName,
            utils.RESET,
        )
        return "" 
    }

    security.EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(
        collectionName,
        T.Token[.FETCH],
        .STANDARD_PUBLIC,
    )

    return data.FETCH_COLLECTION(collectionName)
}


handle_cluster_fetch :: proc(collectionName, clusterName: string) -> string {
    if !data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
        fmt.printfln(
            "Collection: %s%s%s does not exist.",
            utils.BOLD_UNDERLINE,
            collectionName,
            utils.RESET,
        )
        return "" 
    }

    security.EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(
        collectionName,
        T.Token[.FETCH],
        .STANDARD_PUBLIC,
    )

    return data.FETCH_CLUSTER(collectionName, clusterName)
}


handle_record_fetch :: proc(collectionName, clusterName, recordName: string) -> (T.Record, bool) {
    if !data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
        fmt.printfln(
            "Collection: %s%s%s does not exist.",
            utils.BOLD_UNDERLINE,
            collectionName,
            utils.RESET,
        )
        return T.Record{}, false 
    }

    security.EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(
        collectionName,
        T.Token[.FETCH],
        .STANDARD_PUBLIC,
    )

    record, found := data.FETCH_RECORD(collectionName, clusterName, recordName)
    fmt.printfln(
        "Succesfully retrieved record: %s%s%s from cluster: %s%s%s within collection: %s%s%s\n\n",
        utils.BOLD_UNDERLINE,
        recordName,
        utils.RESET,
        utils.BOLD_UNDERLINE,
        clusterName,
        utils.RESET,
        utils.BOLD_UNDERLINE,
        collectionName,
        utils.RESET,
    )
    return record, found
}

handle_collection_delete :: proc(collectionName: string) -> int {
    if !data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
        fmt.printfln(
            "Collection: %s%s%s does not exist.",
            utils.BOLD_UNDERLINE,
            collectionName,
            utils.RESET,
        )
        return -1
    }

    security.EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(collectionName, T.Token[.ERASE], .STANDARD_PUBLIC)

    if data.ERASE_COLLECTION(collectionName, false) == true {
        fmt.printfln(
            "Collection: %s%s%s erased successfully",
            utils.BOLD_UNDERLINE,
            collectionName,
            utils.RESET,
        )
    } else {
        fmt.printfln(
            "Failed to erase collection: %s%s%s",
            utils.BOLD_UNDERLINE,
            collectionName,
            utils.RESET,
        )
    }
    return 1
}

handle_cluster_delete :: proc(collectionName, cluster: string) -> int {
    if !data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
        fmt.printfln(
            "Collection: %s%s%s does not exist.",
            utils.BOLD_UNDERLINE,
            collectionName,
            utils.RESET,
        )
        return -1
    }

    security.EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(
        collectionName,
        T.Token[.ERASE],
        .STANDARD_PUBLIC,
    )

    clusterID := data.GET_CLUSTER_ID(collectionName, cluster)

    if data.ERASE_CLUSTER(collectionName, cluster, false) == true {
        fmt.printfln(
            "Cluster: %s%s%s successfully erased from collection: %s%s%s",
            utils.BOLD_UNDERLINE,
            cluster,
            utils.RESET,
            utils.BOLD_UNDERLINE,
            collectionName,
            utils.RESET,
        )
        security.DECRYPT_COLLECTION("", .ID_PRIVATE, T.system_user.m_k.valAsBytes)
        if data.REMOVE_ID_FROM_ID_COLLECTION(fmt.tprintf("%d", clusterID), false) {
            security.ENCRYPT_COLLECTION(
                "",
                .ID_PRIVATE,
                T.system_user.m_k.valAsBytes,
                false,
            )
        } else {
            security.ENCRYPT_COLLECTION(
                "",
                .ID_PRIVATE,
                T.system_user.m_k.valAsBytes,
                false,
            )

            fmt.printfln(
                "Failed to erase cluster: %s%s%s from collection: %s%s%s",
                utils.BOLD_UNDERLINE,
                cluster,
                utils.RESET,
                utils.BOLD_UNDERLINE,
                collectionName,
                utils.RESET,
            )
        }
    } else {
        fmt.println(
            "Incomplete command. Correct Usage: ERASE <collection_name>.<cluster_name>",
        )
        utils.log_runtime_event(
            "Incomplete ERASE command",
            "User did not provide a valid cluster name to erase.",
        )
    }

    fn := utils.concat_standard_collection_name(collectionName)
    metadata.UPDATE_METADATA_AFTER_OPERATIONS(fn)
    return 1
}

handle_record_delete :: proc (collectionName, clusterName, recordName: string) -> int {
    if !data.CHECK_IF_COLLECTION_EXISTS(collectionName, 0) {
        fmt.printfln(
            "Collection: %s%s%s does not exist.",
            utils.BOLD_UNDERLINE,
            collectionName,
            utils.RESET,
        )
        return -1
    }

    security.EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(
        collectionName,
        T.Token[.ERASE],
        .STANDARD_PUBLIC,
    )

    clusterID := data.GET_CLUSTER_ID(collectionName, clusterName)
    // checks := data.HANDLE_INTEGRITY_CHECK_RESULT(collectionName)
    // switch (checks)
    // {
    // case -1:
    // 	return -1
    // }
    if data.ERASE_RECORD(collectionName, clusterName, recordName, false) == true {
        fmt.printfln(
            "Record: %s%s%s successfully erased from cluster: %s%s%s within collection: %s%s%s",
            utils.BOLD_UNDERLINE,
            recordName,
            utils.RESET,
            utils.BOLD_UNDERLINE,
            clusterName,
            utils.RESET,
            utils.BOLD_UNDERLINE,
            collectionName,
            utils.RESET,
        )
    } else {
        fmt.printfln(
            "Failed to erase record: %s%s%s from cluster: %s%s%s within collection: %s%s%s",
            utils.BOLD_UNDERLINE,
            recordName,
            utils.RESET,
            utils.BOLD_UNDERLINE,
            clusterName,
            utils.RESET,
            utils.BOLD_UNDERLINE,
            collectionName,
            utils.RESET,
        )
    }
    return 1
}
