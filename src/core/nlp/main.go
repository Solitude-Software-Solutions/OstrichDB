package main

import (
	"C"
	"bufio"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"

	"github.com/go-logr/zapr"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

/*********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            The main entry point for the OstrichDB AI Assistant.
*********************************************************/

//export run_agent
func run_agent() {
	config := zap.NewDevelopmentConfig()
	config.EncoderConfig.EncodeLevel = zapcore.CapitalColorLevelEncoder
	zLogger, err := config.Build()
	if err != nil {
		panic(err)
	}

	logger := zapr.NewLogger(zLogger)

	// Get users input
	reader := bufio.NewReader(os.Stdin)
	fmt.Println("OstrichDB AI Assistant ready. Type 'exit' to quit.")
	for {
		fmt.Print("\nEnter your prompt for OstrichDB AI: ")
		input, _ := reader.ReadString('\n')
		input = strings.TrimSpace(input)

		if input == "exit" {
			break
		}

		// Process regular queries
		_, err := process_nlp_query(input)
		if err != nil {
			logger.Error(err, "Failed to process query")
			fmt.Println("Sorry, I couldn't understand that query. Please try again.")
			continue
		}

		// Do work
		run_ostrichdb_ai_agent()
	}
}

// ----------CLIENT CODE----------//
// ----------CLIENT CODE----------//
// ----------CLIENT CODE----------//
const pathRoot = "http://localhost:8042" // Todo: This port might be different if the default is in use..See https://github.com/Solitude-Software-Solutions/OstrichDB/issues/251

// create a new NLP client that will allow for the AI agent to interact with the OstrichDB API layer
func new_nlp_client() http.Client {
	OstrichNLPClient := http.Client{}
	return OstrichNLPClient
}

// Create a new client http request that will be sent over the OstrichDB server. Returns a request
func new_nlp_request(method string, path string) (*http.Request, error) {
	request, requestError := http.NewRequest(method, path, nil)
	if requestError != nil {
		return request, fmt.Errorf("Error creating request: %v", requestError)
	}

	request.Header.Set("Content-Type", "test/plain")
	request.Host = "OstrichDB" // Todo: might not need to do this???
	return request, requestError
}

// takes in a requests and sends it to OstrichDB server. Returns a response
func send_request_to_server(request *http.Request) (*http.Response, error) {
	client := new_nlp_client()
	response, responseError := client.Do(request)
	if responseError != nil {
		return response, fmt.Errorf("Error performing request %v", responseError)
	}

	return response, responseError
}

// takes in a response from the server then handles depending on it status
func handle_server_response(response *http.Response, method string) int {
	defer response.Body.Close()
	if response.StatusCode != http.StatusOK {
		fmt.Println("OstrichDB Response status: ", response.StatusCode)
		return -1
	} else {
		fmt.Println("OstrichDB Response status: ", response.StatusCode)
	}

	if method == "GET" {
		body, err := io.ReadAll(response.Body)
		if err != nil {
			fmt.Printf("Error reading response %v\n", err)
			return -2
		}
		fmt.Printf("Recieved response from OstrichDB: %s", string(body))
	} else if method == "HEAD" {
		fmt.Printf("Received data from OstrichDB: %v\n", response.Header)
	}
	return 0
}

func run_ostrichdb_ai_agent() int {
	// var path string

	// Find the response.json file and parse out its key data
	parsedData, success := parse_response()
	if !success {
		fmt.Println("JSON data was NOT parsed correctly.")
	}

	for _, val := range parsedData.([]interface{}) {
		// Retrieve the key information needed to build a path
		httpRequestMethod, _ := get_value(val, "http_request_method")
		isBatchRequest, _ := get_value(val, "is_batch_request")
		batchDataStructures, _ := get_value(val, "batch_data_structures")
		totalCollectionCount, _ := get_value(val, "total_collection_count")
		totalClusterCount, _ := get_value(val, "total_cluster_count")
		totalRecordCount, _ := get_value(val, "total_record_count")
		clustersPerCollection, _ := get_value(val, "clusters_per_collection")
		recordsPerCluster, _ := get_value(val, "records_per_cluster")
		collectionNames, _ := get_value(val, "collection_names")
		clusterNames, _ := get_value(val, "cluster_names")
		recordNames, _ := get_value(val, "record_names")
		recordTypes, _ := get_value(val, "record_types")
		recordValues, _ := get_value(val, "record_values")

		// fmt.Println("httpRequestMethod BEFORE conversion: ",httpRequestMethod)
		// fmt.Println("isBatchRequest BEFORE conversion: ",isBatchRequest)
		// fmt.Println("batchDataStructures BEFORE conversion: ",batchDataStructures)
		// fmt.Println("totalCollectionCount BEFORE conversion: ",totalCollectionCount)
		// fmt.Println("totalClusterCount BEFORE conversion: ",totalClusterCount)
		// fmt.Println("totalRecordCount BEFORE conversion: ",totalRecordCount)
		// fmt.Println("clustersPerCollection BEFORE conversion: ",clustersPerCollection)
		// fmt.Println("recordsPerCluster BEFORE conversion: ",recordsPerCluster)
		// fmt.Println("collectionNames BEFORE conversion: ",collectionNames)
		// fmt.Println("clusterNames BEFORE conversion: ",clusterNames)
		// fmt.Println("recordNames BEFORE conversion: ",recordNames)
		// fmt.Println("recordTypes BEFORE conversion: ",recordTypes)
		// fmt.Println("recordValues BEFORE conversion: ",recordValues)

		httpRequestMethod = httpRequestMethod.(string)
		isBatchRequest = isBatchRequest.(bool)
		batchDataStructures = batchDataStructures.([]interface{})
		totalCollectionCount = totalCollectionCount.(float64)
		totalClusterCount = totalClusterCount.(float64)
		totalRecordCount = totalRecordCount.(float64)
		clustersPerCollection = clustersPerCollection.(float64)
		recordsPerCluster = recordsPerCluster.(float64)
		collectionNames = collectionNames.([]interface{})
		clusterNames = clusterNames.([]interface{})
		recordNames = recordNames.([]interface{})
		recordTypes = recordTypes.([]interface{})
		recordValues = recordValues.([]interface{})

		// fmt.Println("httpRequestMethod AFTER conversion: ",httpRequestMethod)
		// fmt.Println("isBatchRequest AFTER conversion: ",isBatchRequest)
		// fmt.Println("batchDataStructures AFTER conversion: ",batchDataStructures)
		// fmt.Println("totalCollectionCount AFTER conversion: ",totalCollectionCount)
		// fmt.Println("totalClusterCount AFTER conversion: ",totalClusterCount)
		// fmt.Println("totalRecordCount AFTER conversion: ",totalRecordCount)
		// fmt.Println("clustersPerCollection AFTER conversion: ",clustersPerCollection)
		// fmt.Println("recordsPerCluster AFTER conversion: ",recordsPerCluster)
		// fmt.Println("collectionNames AFTER conversion: ",collectionNames)
		// fmt.Println("clusterNames AFTER conversion: ",clusterNames)
		// fmt.Println("recordNames AFTER conversion: ",recordNames)
		// fmt.Println("recordTypes AFTER conversion: ",recordTypes)
		// fmt.Println("recordValues AFTER conversion: ",recordValues)

		//Create a file that is updated per request that contains the information about each databse, i.e name, clusters within it, records within each cluster, etc., etc

		//handle potential batch request
		if isBatchRequest == true {
			fmt.Println("This is a batch request")
		}

		// switch v := val.(type) {
		//  			case string:
		//  			    // Handle string type
		//  			    foo:= val.(string)
		//  			case float64:
		//  			    // Handle float64 (common when parsing JSON)
		//  			    total:= val.(float64)
		//  			case []interface{}:
		//         			foo:= val.(types.Array)
		//            case bool:
		//            		foo:= val.(bool)
		//  			default:
		//  			    // Handle other types
		//  			    fmt.Printf("Unknown type: %T\n", v)
		//  			}

		// if len(clu.(string)) == 0 {
		// 	clu = ""
		// }

		// rec, _ := get_value(val, "record_name")
		// if len(rec.(string)) == 0 {
		// 	rec = ""
		// }

		// // Convert the interfaces to strings
		// method := m.(string)
		// colName := col.(string)
		// cluName := clu.(string)
		// recName := rec.(string)

		// // Not using yet, see comment in line 186
		// // recType:= recT.(string)
		// // recValue := recV.(string)

		// // If not collection name is provided that the request is invalid as all request need to have atleast a collection name
		// if len(colName) == 0 {
		// 	fmt.Println("Invalid path provided")
		// 	return 1
		// }

		// // if only a collectio name is provided then the user only wants
		// // to do work on that collection, set path accordingly
		// if len(colName) != 0 && len(cluName) == 0 && len(recName) == 0 {
		// 	path = pathRoot + "/c/" + colName
		// }

		// // if cluster name is provided BUT NO record name is provided
		// // then the user is only wanting to do work on a cluster, set path accordingly
		// if len(cluName) != 0 && len(recName) == 0 {
		// 	path = pathRoot + "/c/" + colName + "/cl/" + cluName
		// }

		// // if cluster name is provided AND A record name IS provided
		// // then the user wants to do work on a record. set path accordingly
		// if len(cluName) != 0 && len(recName) != 0 {
		// 	path = pathRoot + "/c/" + colName + "/cl/" + cluName + "/r/" + recName
		// }

		// Todo: Need to determine path when using query params. e.g c/[col_name]/cl/clu_name/r/[rec_name]?type=[rec_type]&value=[rec_value]

		// 	request, reqError := new_nlp_request(method, path)
		// 	if reqError != nil {
		// 		return -1
		// 	}

		// 	response, resError := send_request_to_server(request)
		// 	if resError != nil {
		// 		return -2
		// 	}

		// 	responseSuccess := handle_server_response(response, method)
		// 	if responseSuccess != 0 {
		// 		return -3
		// 	}

		// 	path = ""
		// }
		// Delete the response.json file when all work is done.
		delete_response()

	}
	return 0
}

func main() {} // must be kept blank
