package main

import (
	"fmt"
	"io"
	"net/http"
)
/*********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            This is an example vanilla GOLANG client that demonstrates how
            to interact with the OstrichDB API layer. You can use this client in
            whole OR as a reference to create your own client if you wish.
			For more information about OstrichDB example clients see the README.md file
            in the 'client' directory.
*********************************************************/

/*
Developer Note: At the present time OstrichDBs server creates ALL routes
meant to do work on a database(collection) itself or its subcomponents dynamically.
This means that request paths need to be constructed the way they are below to work...
This might or might not change in the future. These examples are crude and do not represent
the best way to do things nor do they represent the final product of working with OstrichDBs API.


TL;DR:
Store you db information in to variables and pass them to the fetch calls, The API might change
drastically in the future so dont get to comfortable with this for now.

  - Marshall Burns
*/


// Default values. Feel free to change them or create your own variables for your own use case.
const (
	collectionName = "go_collection"
	clusterName    = "go_cluster"
	recordName     = "go_record"
	recordType     = "STRING"
	recordValue    = "Hello-World!"
	pathRoot       = "http://localhost:8042" // DO NOT CHANGE THIS
)

// ost_get_version fetches the current version of OstrichDB on the server
func ost_get_version() (string, error) {
	resp, err := http.Get(pathRoot + "/version")
	if err != nil {
		return "", fmt.Errorf("error fetching from OstrichDB: %v", err)
	}
	defer resp.Body.Close()

	fmt.Printf("Response Status: %d\n", resp.StatusCode)
	if resp.StatusCode == http.StatusOK {
		body, err := io.ReadAll(resp.Body)
		if err != nil {
			return "", fmt.Errorf("error reading response: %v", err)
		}
		fmt.Printf("Received data from OstrichDB: %s\n", string(body))
		return string(body), nil
	}
	return "", fmt.Errorf("unexpected status code: %d", resp.StatusCode)
}

// collection_action performs an action on a database(collection) as a whole
func collection_action(method string) (string, error) {
	client := &http.Client{}
	req, err := http.NewRequest(method, fmt.Sprintf("%s/c/%s", pathRoot, collectionName), nil)
	if err != nil {
		return "", fmt.Errorf("error creating request: %v", err)
	}
	req.Header.Set("Content-Type", "text/plain")

	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("error performing request: %v", err)
	}
	defer resp.Body.Close()

	fmt.Printf("%s Request On Collection Response Status: %d\n", method, resp.StatusCode)
	if resp.StatusCode == http.StatusOK {
		if method == "GET" {
			body, err := io.ReadAll(resp.Body)
			if err != nil {
				return "", fmt.Errorf("error reading response: %v", err)
			}
			fmt.Printf("Received data from OstrichDB: %s\n", string(body))
			return string(body), nil
		} else if method == "HEAD" {
			fmt.Printf("Received data from OstrichDB: %v\n", resp.Header)
		}
	}
	return "", nil
}

// cluster_action performs an action on a specific cluster within a database(collection)
func cluster_action(method string) (string, error) {
	client := &http.Client{}
	req, err := http.NewRequest(method, fmt.Sprintf("%s/c/%s/cl/%s", pathRoot, collectionName, clusterName), nil)
	if err != nil {
		return "", fmt.Errorf("error creating request: %v", err)
	}
	req.Header.Set("Content-Type", "text/plain")

	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("error performing request: %v", err)
	}
	defer resp.Body.Close()

	fmt.Printf("%s Request On Cluster Response Status: %d\n", method, resp.StatusCode)
	if resp.StatusCode == http.StatusOK {
		if method == "GET" {
			body, err := io.ReadAll(resp.Body)
			if err != nil {
				return "", fmt.Errorf("error reading response: %v", err)
			}
			fmt.Printf("Received data from OstrichDB: %s\n", string(body))
			return string(body), nil
		} else if method == "HEAD" {
			fmt.Printf("Received data from OstrichDB: %v\n", resp.Header)
		}
	}
	return "", nil
}

// record_action performs an action on a specific record within a specific cluster
func record_action(method string) (string, error) {
	var fullPath string
	switch method {
	case "POST":
		fullPath = fmt.Sprintf("%s/c/%s/cl/%s/r/%s?type=%s", pathRoot, collectionName, clusterName, recordName, recordType)
	case "GET", "DELETE", "HEAD":
		fullPath = fmt.Sprintf("%s/c/%s/cl/%s/r/%s", pathRoot, collectionName, clusterName, recordName)
	case "PUT":
		fullPath = fmt.Sprintf("%s/c/%s/cl/%s/r/%s?type=%s&value=%s", pathRoot, collectionName, clusterName, recordName, recordType, recordValue)
	default:
		return "", fmt.Errorf("unsupported method: %s", method)
	}

	client := &http.Client{}
	req, err := http.NewRequest(method, fullPath, nil)
	if err != nil {
		return "", fmt.Errorf("error creating request: %v", err)
	}
	req.Header.Set("Content-Type", "text/plain")

	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("error performing request: %v", err)
	}
	defer resp.Body.Close()

	fmt.Printf("%s Request On Record Response Status: %d\n", method, resp.StatusCode)
	if resp.StatusCode == http.StatusOK {
		if method == "GET" {
			body, err := io.ReadAll(resp.Body)
			if err != nil {
				return "", fmt.Errorf("error reading response: %v", err)
			}
			fmt.Printf("Received data from OstrichDB: %s\n", string(body))
			return string(body), nil
		} else if method == "HEAD" {
			fmt.Printf("Received data from OstrichDB: %v\n", resp.Header)
		}
	}
	return "", nil
}

func main() {
	// Uncomment the blocks below to test the different actions.
	// version, err := ost_get_version() // Get the version of OstrichDB
	// if err != nil {
	// 	fmt.Printf("Error: %v\n", err)
	// } else {
	// 	fmt.Printf("OstrichDB Version: %s\n", version)
	// }

	// For these latter 3 blocks pass one of the following methods: "GET", "POST", "PUT", "DELETE", "HEAD"
	// Each action func call returns 'result' and 'error' values.
	// If you want to handle the result, you can do so. Currently, the 'result' is not being handled.
	// if _, err := collection_action("POST"); err != nil { // Perform an action on the collection
	// fmt.Printf("Error: %v\n", err)
	// 	}

	// 	if _, err := cluster_action("POST"); err != nil { // Perform an action on the cluster
	// 		fmt.Printf("Error: %v\n", err)
	// 	}

	// if _, err := record_action("POST"); err != nil { // Perform an action on the record
	//
	//		fmt.Printf("Error: %v\n", err)
	//	}
}
