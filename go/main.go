package main

/*
#include <stdlib.h>
#cgo LDFLAGS: ${SRCDIR}/../shared/shared.so
#include "../shared/sharedlib.h"
*/
import "C"

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strings"
	"unsafe"

	"github.com/joho/godotenv"
	"github.com/openai/openai-go"
	"github.com/openai/openai-go/option"
)

/*********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            The main entry point for the OstrichDB AI Assistant.
*********************************************************/

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

func main() {
	err := godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	OPENAI_API_KEY := os.Getenv("OPENAI_API_KEY")
	client := openai.NewClient(
		option.WithAPIKey(OPENAI_API_KEY),
	)

	// Read the file content
	data, err := os.ReadFile("SYS_INSTRUCTIONS")
	if err != nil {
		panic(err.Error())
	}

	// Convert file content to string
	content := string(data)

	// Create a chat completion request with system instructions
	chatCompletion, err := client.Chat.Completions.New(context.TODO(), openai.ChatCompletionNewParams{
		Messages: []openai.ChatCompletionMessageParamUnion{
			openai.SystemMessage(content),
			openai.UserMessage("Create a new database called users with two clusters"),
		},
		Model: openai.ChatModelGPT4oMini,
	})
	if err != nil {
		panic(err.Error())
	}

	storeResponseError := store_response(chatCompletion.Choices[0].Message.Content)
	if storeResponseError != nil {
		fmt.Println("SOMETHING TERRIBLE HAS HAPPENED")
		return
	}
	res := chatCompletion.Choices[0].Message.Content
	println(res)
	var payload []AgentResonse
	if err := json.Unmarshal([]byte(res), &payload); err != nil {
		panic(err)
	}

	for _, obj := range payload {
		fmt.Println(obj)
	}
}

// func do_thing(command Command, collectionNames , clusterNames, recordNames, recordTypes, recordValues []string)(bool){
// 	success:= false

// 	return success
// }

// looks for all files containing `response.json` in the root dir, returns the num
func get_file_count() int {
	count := 0
	entries, _ := os.ReadDir("./")
	for _, entry := range entries {
		if strings.Contains(entry.Name(), "response.json") {
			count++
		}
	}

	return count
}

// Stores the passed in response from the AI into a num_response.json file
func store_response(resp string) error {
	current_count := get_file_count()
	// create a new filewith response count
	file, creationError := os.Create(fmt.Sprintf("%d_response.json", current_count))
	if creationError != nil {
		return creationError
	}

	// open the file
	_, openError := os.Open(file.Name())
	if openError != nil {
		return openError
	}
	data := []byte(resp)
	writeError := os.WriteFile(file.Name(), data, os.ModeAppend)
	if writeError != nil {
		return writeError
	}

	return nil
}

func CallOdinFunction(dbName string) bool {
	// Convert Go string to C string
	cDbName := C.CString(dbName)

	// Remember to free C allocations
	defer C.free(unsafe.Pointer(cDbName))

	// Call the Odin function (which Go sees as a C function)
	result := C.create_database(cDbName)

	// Convert C bool to Go bool
	return bool(result)
}
