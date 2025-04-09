/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            This is an example vanilla JAVASCRIPT client that demonstrates how
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

//Default values. Feel freee to change them or creatte your own variables for your own use case.
const collectionName = "js_collection";
const clusterName = "js_cluster";
const recordName = "js_record";
const recordType = "STRING";
const recordValue = "Hello-World!";

const pathRoot = `http://localhost:8042`; //DO NOT CHANGE THIS
let data;

// Note: Uncomment the method you want to use or hard code the particular one you want into the 'method' key in the
// respective fetch call in the 'requestAction' object below. Learn more here:
// https://developer.mozilla.org/en-US/docs/Web/API/Window/fetch

// const method = "HEAD";
// const method = "POST";
// const method = "PUT";
// const method = "GET";
// const method = "DELETE";

//Simply fetch the current version of OstrichDB on the server
async function ost_get_version() {
  try {
    const response = fetch(`${pathRoot}/version`, {
      method: "GET",
      headers: { "Content-Type": "text/plain" },
    });
    console.log("Fetching OstrichDB Version...");
    if (response.ok) {
      let data = await response.text();
      console.log("Received data from OstrichDB:", data);
    }
  } catch (error) {
    console.error("Error fetching OstrichDB Version:", error);
  }
}

// This object contains 3 anonymous functions that are called based on the key passed to it.
// Handle GET, POST, HEAD, PUT, DELETE requests on the server.
// Note: PUT requests only work on records. To be used when setting a records value.

const requestAction = {
  0: async () => {
    //Action to be performed on a collection
    try {
      const response = await fetch(`${pathRoot}/c/${collectionName}`, {
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
          console.log(response.headers);
        } else if (method == "HEAD") {
          console.log("Received data from OstrichDB:", response.headers);
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
  1: async () => {
    //Action to be performed on a cluster
    try {
      const response = await fetch(
        `${pathRoot}/c/${collectionName}/cl/${clusterName}`,
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
        } else if (method == "HEAD") {
          console.log("Received data from OstrichDB:", response.headers);
        }
        return data;
      }
    } catch (error) {
      console.error(`Error Occured using method ${method} on a cluster`, error);
    }
  },
  2: async () => {
    //Action to be performed on a record
    if (method === "POST") {
      //Depending on the request method the path for the fetch request is constructed differently for records
      fullFetchPath = `${pathRoot}/c/${collectionName}/cl/${clusterName}/r/${recordName}?type=${recordType}`;
    } else if (method === "GET" || method === "DELETE" || method === "HEAD") {
      fullFetchPath = `${pathRoot}/c/${collectionName}/cl/${clusterName}/r/${recordName}`;
    } else if (method === "PUT") {
      fullFetchPath = `${pathRoot}/c/${collectionName}/cl/${clusterName}/r/${recordName}?type=${recordType}&value=${recordValue}`;
    }
    console.log("Full Fetch Path:", fullFetchPath);

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
        } else if (method == "HEAD") {
          console.log("Received data from OstrichDB:", response.headers);
        }
        return data;
      }
    } catch (error) {
      console.error(`Error Occured using method ${method} on a record`, error);
    }
  },
};

// Note: Uncomment the function call you want to use.

// ost_get_version(); //Gets current local version of OstrichDB
// requestAction[0](); //action on a collection
// requestAction[1](); //action on a cluster
// requestAction[2](); //action on a record
