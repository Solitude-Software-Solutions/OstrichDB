package main

import (
	"context"
	"encoding/json"
	"fmt"
)

/*********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            This file contains the code that creates the OstrichDB AI agent.
            The agent will be able to answer questions based on the OstrichDB documentation,
            and perform queries on through OstrichDB.
*********************************************************/

// Takes a natural language query, sends it to the LLM, and returns the response.
func process_nlp_query(ctx context.Context, query string) (string, error) {
	// Prepare the system message with schema context
	docs, err := load_training_docs()
	if err != nil {
		return "", fmt.Errorf("error loading documentation: %w", err)
	}

	// fmt.Println("Documentation loaded, size:", len(docs), "bytes")// debugging

	// Create a simple, direct system prompt that requests JSON responses
	systemPrompt := "You are OstrichDB AI, an assistant for OstrichDB. Answer questions based on the OstrichDB documentation. Format your responses as valid JSON with fields for 'command', 'target', and 'parameters'. Any information that is missing from the users prompt you can generate yourself."

	// Create messages for the LLM
	systemMsg := Message{
		Role:    "system",
		Content: systemPrompt,
	}

	// Add documentation as context
	docsMsg := Message{
		Role:    "user",
		Content: "Here is the OstrichDB documentation:\n\n" + docs,
	}

	// Add acknowledgment
	ackMsg := Message{
		Role:    "assistant",
		Content: "I've received the OstrichDB documentation and will use it to answer questions.",
	}

	// Add the user query
	userMsg := Message{
		Role:    "user",
		Content: query,
	}

	// Create the request
	req := Request{
		Model:    "ostrichdb1",
		Stream:   false,
		Messages: []Message{systemMsg, docsMsg, ackMsg, userMsg},
	}

	fmt.Println("Sending request to Ollama...")

	// Send to LLM
	resp, err := talk_to_ollama(defaultOllamaURL, req)
	if err != nil {
		return "Error communicating with LLM: " + err.Error(), nil
	}

	if resp == nil {
		return "Received nil response from Ollama", nil
	}

	fmt.Println("Received response from Ollama")
	keyDataMap,e:=gather_key_data(resp)
	if e != nil{
		fmt.Println("HEY FUCKFACE THIS BROKE!!!")
		return "",nil
	}
	fmt.Printf("Printing Key Data map: \n\n")
	fmt.Println(keyDataMap)


	return resp.Message.Content, nil
}

func gather_key_data(agentResponse *Response) (map[string]interface{}, error) {
	fmt.Printf("Received the following response from the AI Agent:\n %s\n", agentResponse.Message.Content)

	// Create a map to store the parsed JSON data
	var responseData map[string]interface{}

	// Attempt to parse the JSON response
	err := json.Unmarshal([]byte(agentResponse.Message.Content), &responseData)
	if err != nil {
		fmt.Printf("failed to parse agent response as JSON: %v\n", err)
		return nil, err
	}

	// Extract collection information
	if collectionName, ok := responseData["collection_name"].(string); ok {
		fmt.Printf("Collection Name: %s\n", collectionName)
	}

	// Extract cluster information
	if clusters, ok := responseData["clusters"].([]interface{}); ok {
		fmt.Printf("Number of Clusters: %d\n", len(clusters))

		for i, cluster := range clusters {
			clusterMap, ok := cluster.(map[string]interface{})
			if !ok {
				continue
			}

			if clusterName, ok := clusterMap["cluster_name"].(string); ok {
				fmt.Printf("Cluster %d Name: %s\n", i+1, clusterName)
			}

			// Extract records from this cluster
			if records, ok := clusterMap["records"].([]interface{}); ok {
				fmt.Printf("  Number of Records in Cluster %d: %d\n", i+1, len(records))

				for j, record := range records {
					recordMap, ok := record.(map[string]interface{})
					if !ok {
						continue
					}

					name, _ := recordMap["name"].(string)
					dataType, _ := recordMap["type"].(string)
					value := recordMap["value"]

					fmt.Printf("  Record %d: Name=%s, Type=%s, Value=%v\n",
						j+1, name, dataType, value)
				}
			}
		}
	}

	return responseData, nil
}
