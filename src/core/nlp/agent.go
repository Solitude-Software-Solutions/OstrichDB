package main

import (
	"context"
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
func ProcessQuery(ctx context.Context, query string) (string, error) {
	// Prepare the system message with schema context
	docs, err := loadDocumentation()
	if err != nil {
		return "", fmt.Errorf("error loading documentation: %w", err)
	}

	fmt.Println("Documentation loaded, size:", len(docs), "bytes")// debugging

	// Create a simple, direct system prompt
	systemPrompt := "You are OstrichDB AI, an assistant for OstrichDB. Answer questions based on the OstrichDB documentation. Any information that is missing from the users prompt you can generate yourself."

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
	resp, err := talkToOllama(defaultOllamaURL, req)
	if err != nil {
		return "Error communicating with LLM: " + err.Error(), nil
	}

	if resp == nil {
		return "Received nil response from Ollama", nil
	}

	fmt.Println("Received response from Ollama")
	return resp.Message.Content, nil
}
