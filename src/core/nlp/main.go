package main

import (
	"fmt"
	"os"
	"time"
)

func main() {
	start := time.Now()
	msg := Message{
		Role:    "user",
		Content: "Why is the sky blue?",
	}
	req := Request{
		Model:    "llama2",
		Stream:   false,
		Messages: []Message{msg},
	}
	resp, err := talkToOllama(defaultOllamaURL, req)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	fmt.Println(resp.Message.Content)
	fmt.Printf("Completed in %v", time.Since(start))
}
