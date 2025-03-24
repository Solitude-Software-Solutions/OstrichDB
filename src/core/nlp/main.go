package main

import (
	"bufio"
	"context"
	"fmt"
	"net/http"
	"os"
	"strings"
	"io"


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
		_, err := process_nlp_query(ctx, input)
		if err != nil {
			logger.Error(err, "Failed to process query")
			fmt.Println("Sorry, I couldn't understand that query. Please try again.")
			continue
		}
		// fmt.Println("OstrichDB AI Response as plaintext:", response)




	}
}

//----------CLIENT CODE----------//
//----------CLIENT CODE----------//
//----------CLIENT CODE----------//
const pathRoot = "http://localhost:8042"

//create a new NLP client that will allow for the AI agent to interact with the OstrichDB API layer
func new_nlp_client() http.Client{
	OstrichNLPClient := http.Client{}
	return OstrichNLPClient
}

//Create a new client http request that will be sent over the OstrichDB server. Returns a request
func new_nlp_request(method, path string) (*http.Request, error){
	request,requestError:= http.NewRequest(method , path, nil)
	if requestError != nil{
		return request, fmt.Errorf("Error creating request: %v", requestError)
	}

	request.Header.Set("Content-Type", "test/plain")
	request.Host = "OstrichDB" //Todo: might not need to do this???
	return request, requestError
}

//takes in a requests and sends it to OstruichDB server. Returns a response
func send_request_to_server(request *http.Request)(*http.Response,error){
	client:= new_nlp_client()
	response, responseError := client.Do(request)
	if responseError != nil{
		return response, fmt.Errorf("Error performing request %v", responseError)
	}

	return response, responseError
}

//takes in a response from the server then handles depending on it status
func handle_server_response(response *http.Response, method string) int {
	if response.StatusCode != http.StatusOK{
		fmt.Println("OstrichDB Response status: ", response.StatusCode)
		return -1
	}else{
		fmt.Println("OstrichDB Response status: ", response.StatusCode)
	}

	if method ==  "GET"{
		body, err := io.ReadAll(response.Body)
		if err != nil{
			fmt.Printf("Error reading response %v\n",err )
			return -2
		}
		fmt.Printf("Recieved response from OstrichDB: %s", string(body) )
	}else if method == "HEAD" {
		fmt.Printf("Received data from OstrichDB: %v\n", response.Header)
	}
	return 0
}


func run() int{
	path:= ""
	method:= "POST"
	request, reqError := new_nlp_request(path,method)
	if reqError != nil{
		return -1
	}

	response, resError:= send_request_to_server(request)
	if resError != nil{
		return -2
	}

	responseSuccess:= handle_server_response(response, method)
	if responseSuccess != 0{
		return -3
	}

	return 0
}

