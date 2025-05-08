package nlp

import "core:c"
import "core:c/libc"
import "core:fmt"
import "core:strings"
import "core:encoding/json"

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

AgentResponse :: struct {
    OperationQueryResponse:        AgentOperationQueryResponse,
	GeneralInformationQueryResponse: AgentGeneralInformationQueryResponse,
}

AgentOperationQueryResponse :: struct {
    HTTPRequestMethod:     string   `json:"http_request_method"`,
    IsBatchRequest:        bool     `json:"is_batch_request"`,
    BatchDataStructures:   []string `json:"batch_data_structures"`,
    TotalCollectionCount:  int      `json:"total_collection_count"`,
    TotalClusterCount:     int      `json:"total_cluster_count"`,
    TotalRecordCount:      int      `json:"total_record_count"`,
    ClustersPerCollection: int      `json:"clusters_per_collection"`,
    RecordsPerCluster:     int      `json:"records_per_cluster"`,
    CollectionNames:       []string `json:"collection_names"`,
    ClusterNames:          []string `json:"cluster_names"`,
    RecordNames:           []string `json:"record_names"`,
    RecordTypes:           []string `json:"record_types"`,
    RecordValues:          []any    `json:"record_values"`,
}

AgentGeneralInformationQueryResponse :: struct {
    IsGeneralInformationQuery:       bool   `json:"general_ostrichdb_information_query_made"`,
	GeneralInformationQueryResponse: string `json:"general_query_answer"`,
}

runner :: proc() ->int {
    agentResponseType: int
    agentResponses: [dynamic]AgentResponse
    response := string(init_nlp())
    fmt.println("res is: ", string(response))
    if strings.contains(response, "is_general_ostrichdb_information_query") {
        agentResponseType = 0
        // Try to parse as a general information response
        generalInfoResponses: []AgentGeneralInformationQueryResponse
        if err := json.unmarshal_string(response, &generalInfoResponses); err != nil {
            fmt.eprintln(err)
            panic("error")
        }

        // Create AgentResponse objects from the parsed general info responses
        for infoResp in generalInfoResponses {
            fmt.println(infoResp.GeneralInformationQueryResponse)
            append(&agentResponses, AgentResponse{
                GeneralInformationQueryResponse = infoResp,
            })
        }
    } else {
        // Parse as an operation response
        agentResponseType = 1
        operationResponses: []AgentOperationQueryResponse
        if err := json.unmarshal_string(response, &operationResponses); err != nil {
            fmt.eprintln(err)
            panic("error")
        }

        // Create AgentResponse objects from the parsed operation responses
        for opResp in operationResponses {
            append(&agentResponses, AgentResponse{
                OperationQueryResponse = opResp,
            })
        }
        handle_payload_response(agentResponses, agentResponseType)
    }
    return 0
}


