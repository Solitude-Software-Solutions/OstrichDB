const collectionName = "js_collection";
const clusterName = "js_cluster";
const port = 8042;


fetch_version();

function fetch_version() {
    fetch(`http://localhost:${port}/version`)
  .then((response) => {
    if(response.ok) {
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

};

// fetch(`http://localhost:${port}/c/${collectionName}/cl/${clusterName}`)
//   .then((response) => {
//     if(response.ok) {
//       // Instead of parsing as JSON, handle as OstrichDB's native format
//       return response.text();
//     } else {
//       return response.text();
//     }
//   })
//   .then((data) => {
//     // Process the OstrichDB data format
//     console.log("Received data from OstrichDB:", data);
//     // Add parsing logic specific to OstrichDB's format here
//   })
//   .catch((error) => {
//     console.error("Error fetching from OstrichDB:", error);
//   });