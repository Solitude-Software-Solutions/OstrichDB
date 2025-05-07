package main

type AgentResonse struct {
	HTTPRequestMethod     string        `json:"http_request_method"`
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