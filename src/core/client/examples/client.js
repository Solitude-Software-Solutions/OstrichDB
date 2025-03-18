/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            This client Javascript file contains examples of how
            to interact with the OstrichDB REST API.
*********************************************************/

const collectionName = "js_collection";
const clusterName = "js_cluster";
const recordName = "js_record";
const recordType = "STRING";
const path = `http://localhost:8042`;
// const record

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
const postReqAction = {
  // Create a new collection
  0: async (collectionName) => {
    try {
      const response = await fetch(`${path}/c/${collectionName}`, {
        method: "POST",
        headers: { "Content-Type": "text/plain" },
      });
      console.log(
        "Collection Creation POST Request Response Status:",
        response.status,
      );
      if (response.ok) {
        return response.text();
      }
    } catch (error) {
      console.error("Error creating collection:", error);
    }
  },
  // Create a new cluster
  1: async () => {
    try {
      const response = await fetch(
        `${path}/c/${collectionName}/cl/${clusterName}`,
        {
          method: "POST",
          headers: {
            "Content-Type": "text/plain",
          },
        },
      );
      console.log(
        "Cluster Creation POST Request Response Status:",
        response.status,
      );
      if (response.ok) {
        return response.text();
      }
    } catch (error) {
      console.error("Error creating cluster:", error);
    }
  },
  // Create a new record
  2: async () => {
    try {
      const response = await fetch(
        `${path}/c/${collectionName}/cl/${clusterName}/r/${recordName}?type=${recordType}`,
        {
          method: "POST",
          headers: {
            "Content-Type": "text/plain",
          },
        },
      );
      console.log(
        "Record Creation POST Request Response Status:",
        response.status,
      );
      if (response.ok) {
        return response.text();
      }
    } catch (error) {
      console.error("Error creating record:", error);
    }
  },
};

ost_get_version(); // Get the version of OstrichDB
postReqAction[0](collectionName); // create a new collection
postReqAction[1](collectionName, clusterName); // create a new cluster
postReqAction[2](collectionName, clusterName, recordName, recordType); // create a new record
