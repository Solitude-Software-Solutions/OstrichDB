package main

import (
	"C"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strings"

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

//export run_agent
func run_agent() {

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

func main() {} // must be kept blank
