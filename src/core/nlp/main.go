package main

import (
	"bufio"
		"context"
		"fmt"
		"os"
		"strings"

	"github.com/go-logr/zapr"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
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
	ctx := context.Background()

	config := zap.NewDevelopmentConfig()
	config.EncoderConfig.EncodeLevel = zapcore.CapitalColorLevelEncoder
	zLogger, err := config.Build()
	if err != nil {
		panic(err)
	}

	logger := zapr.NewLogger(zLogger)

	//Get users input
	reader := bufio.NewReader(os.Stdin)
	fmt.Println("OstrichDB AI Assistant ready. Type 'exit' to quit.")
	for {
		fmt.Print("\nEnter your prompt for OstrichDB AI: ")
		input, _ := reader.ReadString('\n')
		input = strings.TrimSpace(input)

		if input == "exit" {
			break
		}

		// Process regular queries
		response, err := ProcessQuery(ctx, input)
		if err != nil {
			logger.Error(err, "Failed to process query")
			fmt.Println("Sorry, I couldn't understand that query. Please try again.")
			continue
		}
		fmt.Println("OstrichDB AI Response:", response)
	}
}

