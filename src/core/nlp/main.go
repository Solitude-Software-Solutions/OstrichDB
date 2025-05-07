package main

import (
	"C"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strings"
	"bufio"

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

func run_agent() ([]AgentResponse, int) {
	var agentResponses []AgentResponse
	var agentResponseType int

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

	reader := bufio.NewReader(os.Stdin)
	fmt.Println("OstrichDB AI Assistant ready. Type 'exit' to quit.")
	for {
		fmt.Print("\nEnter your prompt for OstrichDB AI: ")
		input, _ := reader.ReadString('\n')
		input = strings.TrimSpace(input)

		if input == "exit" {
			break
		}

		// Create a chat completion request with system instructions
		chatCompletion, err := client.Chat.Completions.New(context.TODO(), openai.ChatCompletionNewParams{
			Messages: []openai.ChatCompletionMessageParamUnion{
				openai.SystemMessage(content),
				openai.UserMessage(input),
			},
			Model: openai.ChatModelGPT4oMini,
		})
		if err != nil {
			panic(err.Error())
		}

		response := chatCompletion.Choices[0].Message.Content

		storeResponseError := store_response(response)
		if storeResponseError != nil {
			panic(storeResponseError)
		}

		// Determine if the response is a general information query or an operation query
		if strings.Contains(response, "is_general_ostrichdb_information_query") {
			agentResponseType = 0
			// Try to parse as a general information response
			var generalInfoResponses []AgentGeneralInformationQueryResponse
			if err := json.Unmarshal([]byte(response), &generalInfoResponses); err != nil {
				panic(err)
			}

			// Create AgentResponse objects from the parsed general info responses
			for _, infoResp := range generalInfoResponses {
				fmt.Println(infoResp.GeneralInformationQueryResponse) // Print for user feedback
				agentResponses = append(agentResponses, AgentResponse{
					GeneralInformationQueryResponse: &infoResp,
				})
			}
		} else {
			//Parse as an operation response
			var operationResponses []AgentOperationQueryResponse
			if err := json.Unmarshal([]byte(response), &operationResponses); err != nil {
				panic(err)
			}

			// Create AgentResponse objects from the parsed operation responses
			for _, opResp := range operationResponses {
				fmt.Println(opResp) // Print for user feedback
				agentResponses = append(agentResponses, AgentResponse{
					OperationQueryResponse: &opResp,
				})
			}
		}
	}

	return agentResponses, agentResponseType
}


// A helper function that stores the passed in response from the AI into a new num_response.json file
func store_response(resp string) error {
	current_count := get_file_count()
	file, creationError := os.Create(fmt.Sprintf("%d_response.json", current_count))
	if creationError != nil {
		return creationError
	}

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

// Helper function that looks for all files containing `response.json` in the root dir, returns the num
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


//EXPORTED FUNCTIONS BELOW

//export init_nlp
func init_nlp(){
	payload, responseType := run_agent()
	switch(responseType){
		case 0: //If its a general information query just print it
				fmt.Println(payload)
			break
		case 1: //If its an operation query do more work
			break
	}

}

func main() {} // must be kept blank
