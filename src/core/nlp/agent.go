package main

import (
	"encoding/json"
	"fmt"
	"os"
)

/*
********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:

	This file contains the code that creates the OstrichDB AI agent.
	The agent will be able to answer questions based on the OstrichDB documentation,
	and perform queries on through OstrichDB.

********************************************************
*/

const responseFile = "./response.json"

// Takes a natural language query, sends it to the LLM, and returns the response.
func process_nlp_query(query string) (string, error) {

	// Add the user query message
	userMsg := Message{
		Role:    "user",
		Content: query,
	}

	// Create the request
	req := Request{
		Model:    "ostrichdb:v2.7",
		Stream:   false,
		Messages: []Message{userMsg},
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

	//store the response so further work can be done with it
	store_response(resp.Message.Content)

	return "Successfully recieved and stored AI response.", nil
}

// stores the llms response as json in the response.json file
func store_response(resp string) int {
	data := []byte(resp)
	err := os.WriteFile(responseFile, data, 0644)
	if err != nil {
		fmt.Println("There was an issue creating the response.json file")
		return -1
	}
	fmt.Println("Successfully stored response.")
	return 0
}

// called whenever work with the response.json file is completed.
func delete_response() int {
	deleteErr := os.Remove(responseFile)
	if deleteErr != nil {
		fmt.Println("There was an issue deleting the response.json file")
		return -1
	}
	fmt.Println("Successfully deleted response.")
	return 0
}

// looks over the response.json file and parses it.
// The parsed data is store into an interface then returned along with a success value
func parse_response() (parsedData interface{}, success bool) {
	success = false
	content, err := os.ReadFile(responseFile)
	if err != nil {
		return "", false
	}

	// Parse into a generic interface{}
	var data interface{}
	err = json.Unmarshal(content, &data)
	if err != nil {
		return "", false
	}

	return data, true
}

func print_json_response(v interface{}, indent string) {
	switch val := v.(type) {
	//in the event of an interface of type string
	case map[string]interface{}:
		fmt.Println("{")
		for k, v := range val {
			fmt.Printf("%s  %q: ", indent, k)
			print_json_response(v, indent+"  ")
		}
		fmt.Printf("%s}\n", indent)
		//in the event of an generic interface
	case []interface{}:
		fmt.Println("[")
		for _, item := range val {
			fmt.Printf("%s  ", indent)
			print_json_response(item, indent+"  ")
		}
		fmt.Printf("%s]\n", indent)
	default:
		fmt.Println(val)
	}
}

// Helper returns the value of the passed in key by traversing the nested JSON structure
func get_value(data interface{}, key string) (interface{}, bool) {
	// First check if we're dealing with a map
	if m, ok := data.(map[string]interface{}); ok {
		// Try to get the value directly
		if val, exists := m[key]; exists {
			return val, true
		}

		// If not found directly, search recursively in each nested object
		for _, v := range m {
			// If the value is a map or slice, search within it
			if nestedMap, ok := v.(map[string]interface{}); ok {
				if result, found := get_value(nestedMap, key); found {
					return result, true
				}
			} else if nestedSlice, ok := v.([]interface{}); ok {
				for _, item := range nestedSlice {
					if result, found := get_value(item, key); found {
						return result, true
					}
				}
			}
		}
	} else if s, ok := data.([]interface{}); ok {
		// If we're dealing with a slice, search each element
		for _, item := range s {
			if result, found := get_value(item, key); found {
				return result, true
			}
		}
	}

	// Key not found - return empty string instead of nil
	return "", false
}
