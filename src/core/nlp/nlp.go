package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"
)
/*********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            This file contains the core Natural Language Processing (NLP)
            code for the OstrichDB AI Assistant.
*********************************************************/

type Request struct {
	Model    string    `json:"model"`
	Messages []Message `json:"messages"`
	Stream   bool      `json:"stream"`
}

type Message struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type Response struct {
	Model              string    `json:"model"`
	CreatedAt          time.Time `json:"created_at"`
	Message            Message   `json:"message"`
	Done               bool      `json:"done"`
	TotalDuration      int64     `json:"total_duration"`
	LoadDuration       int       `json:"load_duration"`
	PromptEvalCount    int       `json:"prompt_eval_count"`
	PromptEvalDuration int       `json:"prompt_eval_duration"`
	EvalCount          int       `json:"eval_count"`
	EvalDuration       int64     `json:"eval_duration"`
}

const defaultOllamaURL = "http://localhost:11434/api/chat"

func talkToOllama(url string, ollamaReq Request) (*Response, error) {
	js, err := json.Marshal(&ollamaReq)
	if err != nil {
		return nil, err
	}
	client := http.Client{}
	httpReq, err := http.NewRequest(http.MethodPost, url, bytes.NewReader(js))
	if err != nil {
		return nil, err
	}
	httpResp, err := client.Do(httpReq)
	if err != nil {
		return nil, err
	}
	defer httpResp.Body.Close()
	ollamaResp := Response{}
	err = json.NewDecoder(httpResp.Body).Decode(&ollamaResp)
	return &ollamaResp, err
}

func loadDocumentation() (string, error) {
	trainingDir := "./training_data"

	docFiles := []string{
		"architecture.md",
		"schema.md",
		"rules.md",
		"fun_facts.md",
  		//TODO: Add more documentation files
	}

	var allDocs strings.Builder
	allDocs.WriteString("# OSTRICHDB OFFICIAL DOCUMENTATION\n\n")

	// Load each documentation file
	for _, filename := range docFiles {
		filePath := filepath.Join(trainingDir, filename)
		content, err := os.ReadFile(filePath)
		if err != nil {
			return "", fmt.Errorf("error reading documentation file %s: %w", filename, err)
		}

		// Add file content to the combined documentation with clear section headers
		allDocs.WriteString("\n\n## DOCUMENTATION SECTION: " + filename + "\n\n")
		allDocs.Write(content)
	}

	allDocs.WriteString("\n\n## IMPORTANT INSTRUCTION\nThe above documentation contains ALL the information about OstrichDB. Do not make up or infer additional information.")

	return allDocs.String(), nil
}