package main
/*
#include <stdlib.h>
#cgo LDFLAGS: ${SRCDIR}/../shared/shared.dylib
#include "../shared/sharedlib.h"
*/
import "C"

import (
	"context"
	"fmt"
	"log"
	"strings"
	"unsafe"
	"os"
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
			openai.UserMessage("Create a new database with one cluster"),
		},
		Model: openai.ChatModelGPT4o,
	})

	if err != nil {
		panic(err.Error())
	}

	storeResponseError := store_response(chatCompletion.Choices[0].Message.Content)
	if storeResponseError != nil {
		fmt.Println("SOMETHING TERRIBLE HAS HAPPENED")
		return
	}
	println(chatCompletion.Choices[0].Message.Content)
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
	//create a new filewith response count
	file, creationError := os.Create(fmt.Sprintf("%d_response.json", current_count))
	if creationError != nil {
		return creationError
	}

	//open the file
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
