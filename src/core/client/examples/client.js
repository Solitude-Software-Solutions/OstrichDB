/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            This client Javascript file contains examples of how
            to interact with the OstrichDB REST API.
*********************************************************/

/*
Developer Notes: At the present time OstrichDBs server creates ALL routes
meant to do work on a database(collection) itself of its subcomponents dynamically.
This means that request paths need to be constructed the way they are below to work...
This might or might not change in the future.

TL;DR Store you db information in to variables and pass them to the fetch calls.

- Marshall Burns
*/

const collectionName = "js_collection";
const clusterName = "test";
const recordName = "test_record";
const recordType = "STRING";
const path = `http://localhost:8042`;
let data;

//Uncomment the method you want to use
const method = "GET";
// const method = "POST";
// const method = "DELETE";

function ost_get_version() {
  fetch(`${path}/version`)
    .then((response) => {
      if (response.ok) {
        // Instead of parsing as JSON, handle as OstrichDB's native format
        return response.text();
      } else {
        return response.text();
      }
    })
    .then((data) => {
      // Process the OstrichDB data format
      console.log("Received data from OstrichDB:", data);
      // Add parsing logic specific to OstrichDB's format here
    })
    .catch((error) => {
      console.error("Error fetching from OstrichDB:", error);
    });
}

//Object containing POST request functions
const requestAction = {
  // Create a new collection
  0: async (collectionName) => {
    try {
      const response = await fetch(`${path}/c/${collectionName}`, {
        method: `${method}`,
        headers: { "Content-Type": "text/plain" },
      });
      console.log(
        `${method} Request On Collection Response Status:`,
        response.status,
      );
      if (response.ok) {
        if (method == "GET") {
          let data = await response.text();
          console.log("Received data from OstrichDB:", data);
        }
        return data;
      }
    } catch (error) {
      console.error(
        `Error Occured using method ${method} on a collection`,
        error,
      );
    }
  },
  // Create a new cluster
  1: async () => {
    try {
      const response = await fetch(
        `${path}/c/${collectionName}/cl/${clusterName}`,
        {
          method: `${method}`,
          headers: {
            "Content-Type": "text/plain",
          },
        },
      );
      console.log(
        `${method} Request On Cluster Response Status:`,
        response.status,
      );
      if (response.ok) {
        if (method == "GET") {
          let data = await response.text();
          console.log("Received data from OstrichDB:", data);
        }
        return data;
      }
    } catch (error) {
      console.error(`Error Occured using method ${method} on a cluster`, error);
    }
  },
  // Create a new record
  2: async () => {
    if (method == "POST") {
      fullFetchPath = `${path}/c/${collectionName}/cl/${clusterName}/r/${recordName}?type=${recordType}`;
    } else if (method == "GET") {
      fullFetchPath = `${path}/c/${collectionName}/cl/${clusterName}/r/${recordName}`;
    }
    console.log(fullFetchPath);

    try {
      const response = await fetch(fullFetchPath, {
        method: `${method}`,
        headers: {
          "Content-Type": "text/plain",
        },
      });
      console.log(
        `${method} Request On Record Response Status:`,
        response.status,
      );
      if (response.ok) {
        if (method == "GET") {
          let data = await response.text();
          console.log("Received data from OstrichDB:", data);
        }
        return data;
      }
    } catch (error) {
      console.error(`Error Occured using method ${method}on a record`, error);
    }
  },
};
// Get the version of OstrichDB
// ost_get_version();

// These 3 calls can handle: GET & POST requests
// requestAction[0](collectionName); //action on a collection
// requestAction[1](collectionName, clusterName); //action on a cluster
requestAction[2](collectionName, clusterName, recordName, recordType); //action on a record
