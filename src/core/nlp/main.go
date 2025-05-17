package main

import (
	"C"
	"bufio"
	"context"
	_ "embed"
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

Contributors:
    @CobbCoding1

License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-2025 Marshall A Burns and Solitude Software Solutions LLC
Copyright (c) 2025-Present Archetype Dynamics, Inc.

File Description:
            The main entry point for the OstrichDB AI Assistant.
*********************************************************/

//go:embed SYS_INSTRUCTIONS
var data []byte

func run_agent(database []*C.char) *C.char {
	database_str := c_strings_to_single_string(database, "")
	// navigate outside of bin directory (when running using local_build_run.sh)
	err := godotenv.Load("./.env")
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	OPENAI_API_KEY := os.Getenv("OPENAI_API_KEY")
	client := openai.NewClient(
		option.WithAPIKey(OPENAI_API_KEY),
	)

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
				openai.SystemMessage(database_str),
				openai.UserMessage(input),
			},
			Model: openai.ChatModelGPT4oMini,
		})
		if err != nil {
			panic(err.Error())
		}

		response := chatCompletion.Choices[0].Message.Content

		return C.CString(response)
	}

	return C.CString("")
}

func c_strings_to_single_string(cstrs []*C.char, sep string) string {
	parts := make([]string, len(cstrs))
	for i, cs := range cstrs {
		parts[i] = C.GoString(cs)
	}
	return strings.Join(parts, sep)
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

// EXPORTED FUNCTIONS BELOW
//
//export init_nlp
func init_nlp(database []*C.char) *C.char {
	res := run_agent(database)
	return res
}

func main() {} // must be kept blank
