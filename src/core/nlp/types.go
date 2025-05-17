package main
/*********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB

Contributors:
    @CobbCoding1

License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-2025 Marshall A Burns and Solitude Software Solutions LLC
Copyright (c) 2025-Present Archetype Dynamics, Inc.

File Description:
            The main entry point for the OstrichDB AI Assistant.
*********************************************************/

type AgentResponse struct {
	OperationQueryResponse        AgentOperationQueryResponse
	GeneralInformationQueryResponse AgentGeneralInformationQueryResponse
}

type AgentOperationQueryResponse struct {
	Command     string        `json:"command"`
	IsBatchRequest        bool          `json:"is_batch_request"`
	BatchDataStructures   []string      `json:"batch_data_structures"`
	TotalCollectionCount  int           `json:"total_collection_count"`
	TotalClusterCount     int           `json:"total_cluster_count"`
	TotalRecordCount      int           `json:"total_record_count"`
	ClustersPerCollection int           `json:"clusters_per_collection"`
	RecordsPerCluster     int           `json:"records_per_cluster"`
	CollectionNames       []string      `json:"collection_names"`
	ClusterNames          []string      `json:"cluster_names"`
	RecordNames           []string      `json:"record_names"`
	RecordTypes           []string      `json:"record_types"`
	RecordValues          []interface{} `json:"record_values"`
}

//In the event a user asks for information about OstrichDB rather than attempting to make a request
type AgentGeneralInformationQueryResponse struct {
	IsGeneralInformationQuery      bool   `json:"general_ostrichdb_information_query_made"`
	GeneralInformationQueryResponse string `json:"general_query_answer"`
}