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
// const record

const dataObjCreation = {
  // Create a new collection
  0: async (collectionName) => {
    try {
      const response = await fetch(`${path}/c/${collectionName}`, {
        method: "POST",
        headers: { "Content-Type": "text/plain" },
      });
      console.log("Response status:", response.status);
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
      console.log("Response status:", response.status);
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
      if (response.ok) {
        return response.text();
      }
    } catch (error) {
      console.error("Error creating record:", error);
    }
  },
};

path = `http://localhost:8042`;

ost_get_version(); // Get the version of OstrichDB

dataObjCreation[0](collectionName);
dataObjCreation[1](collectionName, clusterName);
dataObjCreation[2](collectionName, clusterName, recordName);

// ost_create(0, collectionName); // Create a new collection, cluster, or record
// ost_create(1, collectionName, clusterName);
// ost_create(2, collectionName, clusterName, recordName);

// ost_delete(); // Delete a new collection, cluster, or record

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

//dataObjTier: 0 = collection, 1 = cluster, 2 = record
//dataObjName: name of the collection[0], cluster[1], or record[2]
function ost_create(dataObjTier, ...dataObjName) {
  let fullPath;
  switch (dataObjTier) {
    case 0:
      fullPath = `${path}/c/${dataObjName[0]}`;
      break;
    case 1:
      fullPath = `${path}/c/${dataObjName[0]}/cl/${dataObjName[1]}`;
      break;
    case 2:
      fullPath = `${path}/c/${dataObjName[0]}/cl/${dataObjName[1]}/r/${dataObjName[2]}`;
      break;
    default:
      console.error("Invalid data object type");
      console.log("Please enter 0,1 or 2");
      return;
  }
  fetch(fullPath, {
    method: "POST",
    headers: {
      "Content-Type": "text/plain",
    },
  })
    .then((response) => {
      console.log("Response status:", response.status);
      if (response.ok) {
        return response.text();
      } else {
        throw new Error(`Failed to create collection: ${response.status}`);
      }
    })
    .then((data) => {
      console.log("Collection creation response:", data);
    })
    .catch((error) => {
      console.error("Error creating collection:", error);
    });
}
