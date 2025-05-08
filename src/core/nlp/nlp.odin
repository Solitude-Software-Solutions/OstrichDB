package nlp

import "core:c"
import "core:c/libc"
import "core:fmt"
import "core:strings"
import "core:encoding/json"
import "../../utils"
import "../const"
import "../engine/data"
import "../engine/security"
import "../engine/data/metadata"
import T "../types"

when ODIN_OS == .Linux {
    foreign import go "nlp.so"

    foreign go {
        init_nlp :: proc() -> cstring ---
    }
} else when ODIN_OS == .Darwin {
    foreign import go "nlp.dylib"
    foreign go {
        init_nlp:: proc() -> cstring ---
    }
}
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            This file is used to achieve 2 things.
            1. Call Golang functions from within Odin code
            2. Ensure the NLP builds correctly to be used within the core
*********************************************************/
main ::proc(){
    //Don't touch me :)
}

// needs to be placed in a different file, probably in engine/
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

runner :: proc() ->int {
    agentResponseType: int
    agentResponses: [dynamic]T.AgentResponse
    response := string(init_nlp())
    fmt.println("res is: ", string(response))
    if strings.contains(response, "is_general_ostrichdb_information_query") {
        agentResponseType = 0
        // Try to parse as a general information response
        generalInfoResponses: []T.AgentGeneralInformationQueryResponse
        if err := json.unmarshal_string(response, &generalInfoResponses); err != nil {
            fmt.eprintln(err)
            panic("error")
        }

        // Create AgentResponse objects from the parsed general info responses
        for infoResp in generalInfoResponses {
            fmt.println(infoResp.GeneralInformationQueryResponse)
            append(&agentResponses, T.AgentResponse{
                GeneralInformationQueryResponse = infoResp,
            })
        }
    } else {
        // Parse as an operation response
        agentResponseType = 1
        operationResponses: []T.AgentOperationQueryResponse
        if err := json.unmarshal_string(response, &operationResponses); err != nil {
            fmt.eprintln(err)
            panic("error")
        }

        // Create AgentResponse objects from the parsed operation responses
        for opResp in operationResponses {
            append(&agentResponses, T.AgentResponse{
                OperationQueryResponse = opResp,
            })
        }
        handle_payload_response(agentResponses, agentResponseType)
    }
    return 0
}


// Takes the passed in payload and  prepares it to be sent to the OstrichDB core functions
gather_data :: proc(payload: [dynamic]T.AgentResponse) {
    defer delete(payload)
	for val in payload {

		// Setup the operation
		op := val.OperationQueryResponse

		fmt.println("Command:", op.Command)

		isBatchRequest := op.IsBatchRequest
		totalCollectionCount := op.TotalCollectionCount
		totalClusterCount := op.TotalClusterCount
		totalRecordCount := op.TotalRecordCount

		fmt.println(isBatchRequest, totalClusterCount, totalCollectionCount, totalRecordCount)

		// Iterate over collection, cluster and record names
		for collectionName in op.CollectionNames {
			fmt.println("Collection:", collectionName)
		}

		// Iterate over cluster names if needed
        for clusterName in op.ClusterNames {
            fmt.println("Cluster:", clusterName)
        }

		// Iterate over record names if needed
        for recordName in op.RecordNames {
            fmt.println("Record:", recordName)
        }

		// Iterate over record types if needed
        for recordType in op.RecordTypes {
            fmt.println("Record type:", recordType)
        }

		// Iterate over record values if needed
        for recordValue in op.RecordValues {
            fmt.println("Record value:", recordValue)
        }
	}
}

handle_payload_response :: proc(payload: [dynamic]T.AgentResponse, payloadType: int) {
	switch payloadType {
	case 0: // If its a general information query just print it
		fmt.println(payload)
		break
	case 1: // If its an operation query do more work
		gather_data(payload)
        // TODO: Need to condense this and remove redundancy with
        // the same calls in commands.odin
        for val in payload {
            op := val.OperationQueryResponse
            for collection in op.CollectionNames {
                if len(op.ClusterNames) == 0 {
                    handle_collection_creation(strings.to_upper(collection))
                }
                // will not loop if len is 0, so no else needed
                for cluster in op.ClusterNames {
                    handle_cluster_creation(strings.to_upper(collection), strings.to_upper(cluster))
                }
            }
        }
        break
	}
}


