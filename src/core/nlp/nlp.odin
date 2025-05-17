package nlp

import "core:os"
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
import "../engine/operations"

when ODIN_OS == .Linux {
    foreign import go "nlp.so"

    foreign go {
        init_nlp :: proc([dynamic]cstring) -> cstring ---
    }
} else when ODIN_OS == .Darwin {
    foreign import go "nlp.dylib"
    foreign go {
        init_nlp:: proc([dynamic]cstring) -> cstring ---
    }
}
/********************************************************
Authors: Marshall A Burns
GitHub: @SchoolyB

Contributors:
    @CobbCoding1

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


runner :: proc() ->int {
    agentResponseType: int
    agentResponses: [dynamic]T.AgentResponse

	dir, _ := os.open(const.STANDARD_COLLECTION_PATH)
	collections, _ := os.read_dir(dir, 1)
    database_data: [dynamic]cstring
	for collection, index in collections {
		nameWithoutExtension := strings.trim_suffix(collection.name, const.OST_EXT)
        col := operations.handle_collection_fetch(nameWithoutExtension)
        if col != "" {
            // allocates
            append(&database_data, strings.clone_to_cstring(collection.name))
            append(&database_data, strings.clone_to_cstring(col))
            security.ENCRYPT_COLLECTION(
                nameWithoutExtension,
                .STANDARD_PUBLIC,
                T.current_user.m_k.valAsBytes,
            )
        }
	}

    response := string(init_nlp(database_data))
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

		isBatchRequest := op.IsBatchRequest
		totalCollectionCount := op.TotalCollectionCount
		totalClusterCount := op.TotalClusterCount
		totalRecordCount := op.TotalRecordCount

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

handle_payload_operations :: proc(val: T.AgentResponse) {
    str: string
    op := val.OperationQueryResponse
    for collection, collection_index in op.CollectionNames {
        if len(op.ClusterNames) == 0 {
            switch (op.Command) {
            case "POST":
                operations.handle_collection_creation(strings.to_upper(collection))
                break
            case "FETCH":
                str = operations.handle_collection_fetch(collection)
                break
            case "DELETE":
                operations.handle_collection_delete(collection)
                break
            }
        }
        // will not loop if len is 0, so no else needed
        cluster_start := collection_index * op.ClustersPerCollection
        for cluster_index in cluster_start..<cluster_start+op.ClustersPerCollection {
            cluster := op.ClusterNames[cluster_index]
            if len(op.RecordNames) == 0 {
                switch (op.Command) {
                case "POST":
                        operations.handle_cluster_creation(strings.to_upper(collection), strings.to_upper(cluster))
                        break
                case "FETCH":
                        str = operations.handle_cluster_fetch(collection, cluster)
                        break
                case "DELETE":
                        operations.handle_cluster_delete(collection, cluster)
                        break
                }
            }
            record_start := cluster_index * op.RecordsPerCluster
            for record_index in record_start..<record_start+op.RecordsPerCluster {
                record := op.RecordNames[record_index]
                switch (op.Command) {
                case "POST":
                    for value in op.RecordValues[record_index] {
                        fn := utils.concat_standard_collection_name(collection)
                        // need to modify some code so that the decryption and re-encryption are not done every time
                        security.EXECUTE_COMMAND_LINE_PERMISSIONS_CHECK(collection, T.Token[.NEW], .STANDARD_PUBLIC)
                        exists := data.CHECK_IF_SPECIFIC_RECORD_EXISTS(fn, strings.to_upper(cluster), strings.to_upper(record))
                        security.ENCRYPT_COLLECTION(
                            collection,
                            .STANDARD_PUBLIC,
                            T.current_user.m_k.valAsBytes,
                        )
                        // need to update so that an error message is not printed if false
                        // (which would be on record creation)
                        if exists {
                            // if found then update the value
                            operations.handle_record_update(strings.to_upper(collection), strings.to_upper(cluster), strings.to_upper(record), value)
                        } else {
                            // If not found, then create it
                            record_info: map[string]string
                            if len(op.RecordValues) > record_index {
                                record_info[T.Token[.WITH]] = value
                                // if values are present the types will be as well
                                record_info[T.Token[.OF_TYPE]] = op.RecordTypes[record_index]
                            }
                            operations.handle_record_creation(strings.to_upper(collection), strings.to_upper(cluster), strings.to_upper(record), record_info)
                        }
                    }
                    break
                case "FETCH":
                    r, found := operations.handle_record_fetch(collection, cluster, record)
                    if found {
                        fmt.printfln("\t%s :%s: %s\n", r.name, r.type, r.value)
                        fmt.println("\t^^^\t^^^\t^^^")
                        fmt.println("\tName\tType\tValue\n\n")
                    }
                    break
                case "DELETE":
                    operations.handle_record_delete(collection, cluster, record)
                    break
                }
            }
        }
        if op.Command == "FETCH" || op.Command == "DELETE" {
            security.ENCRYPT_COLLECTION(
                collection,
                .STANDARD_PUBLIC,
                T.current_user.m_k.valAsBytes,
            )
            fmt.println(str)
        }
    }
}

handle_payload_response :: proc(payload: [dynamic]T.AgentResponse, payloadType: int) {
	switch payloadType {
	case 0: // If its a general information query just print it
		fmt.println(payload)
		break
	case 1: // If its an operation query do more work
        // TODO: need to abstract some of the code here away
        for val in payload {
            handle_payload_operations(val)
        }
        break
	}
}


