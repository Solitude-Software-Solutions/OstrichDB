import requests
#Ensure you have the requests lib or whatever other lib you plan on making HTTP requests from your Python code

'''
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            This is an example vanilla PYTHON client that demonstrates how
            to interact with the OstrichDB API layer. You can use this client in
            whole OR as a reference to create your own client if you wish.
            For more information about OstrichDB example clients see the README.md file
            in the 'client' directory.
*********************************************************/
'''

'''
Developer Note: At the present time OstrichDBs server creates ALL routes
meant to do work on a database(collection) itself or its subcomponents dynamically.
This means that request paths need to be constructed the way they are below to work...
This might or might not change in the future. These examples are crude and do not represent
the best way to do things nor do they represent the final product of working with OstrichDBs API.


TL;DR:
Store you db information in to variables and pass them to the fetch calls, The API might change
drastically in the future so dont get to comfortable with this for now.

  - Marshall Burns
'''

# Default values. Feel free to change them or create your own variables for your own use case.
collectionName = "python_collection"
clusterName = "python_cluster"
recordName = "python_record"
recordType = "STRING"
recordValue = "Hello-World!"

pathRoot = "http://localhost:8042"  # DO NOT CHANGE THIS

# Note: Uncomment the method you want to use or set the method variable
# before calling the respective function

# method = "HEAD"
# method = "POST"
# method = "PUT"
# method = "GET"
# method = "DELETE"


# Simply fetch the current version of OstrichDB on the server
def ost_get_version():
    try:
        response = requests.get(f"{pathRoot}/version")
        print(f"Response Status: {response.status_code}")
        if response.ok:
            print(f"Received data from OstrichDB: {response.text}")
        return response.text
    except Exception as error:
        print(f"Error fetching from OstrichDB: {error}")
        return None


# Perform an action on a database(collection) as a whole
def collection_action(method):
    try:
        response = requests.request(
            method,
            f"{pathRoot}/c/{collectionName}",
            headers={"Content-Type": "text/plain"}
        )
        print(f"{method} Request On Collection Response Status: {response.status_code}")

        if response.ok:
            if method == "GET":
                print(f"Received data from OstrichDB: {response.text}")
            elif method == "HEAD":
                print(f"Received data from OstrichDB: {response.headers}")
            return response.text
    except Exception as error:
        print(f"Error occurred using method {method} on a collection: {error}")
        return None

# Perform an action on a specific cluster within a database(collection)
def cluster_action(method):
    try:
        response = requests.request(
            method,
            f"{pathRoot}/c/{collectionName}/cl/{clusterName}",
            headers={"Content-Type": "text/plain"}
        )
        print(f"{method} Request On Cluster Response Status: {response.status_code}")

        if response.ok:
            if method == "GET":
                print(f"Received data from OstrichDB: {response.text}")
            elif method == "HEAD":
                print(f"Received data from OstrichDB: {response.headers}")
            return response.text
    except Exception as error:
        print(f"Error occurred using method {method} on a cluster: {error}")
        return None

# Perform an action on a specific record within a specific cluster within a database(collection)
def record_action(method):
    # Depending on the request method the path for the request is constructed differently for records
    if method == "POST":
        full_path = f"{pathRoot}/c/{collectionName}/cl/{clusterName}/r/{recordName}?type={recordType}"
    elif method in ["GET", "DELETE", "HEAD"]:
        full_path = f"{pathRoot}/c/{collectionName}/cl/{clusterName}/r/{recordName}"
    elif method == "PUT":
        full_path = f"{pathRoot}/c/{collectionName}/cl/{clusterName}/r/{recordName}?type={recordType}&value={recordValue}"
    else:
        print(f"Unsupported method: {method}")
        return None


    try:
        response = requests.request(
            method,
            full_path,
            headers={"Content-Type": "text/plain"}
        )
        print(f"{method} Request On Record Response Status: {response.status_code}")

        if response.ok:
            if method == "GET":
                print(f"Received data from OstrichDB: {response.text}")
            elif method == "HEAD":
                print(f"Received data from OstrichDB: {response.headers}")
            return response.text
    except Exception as error:
        print(f"Error occurred using method {method} on a record: {error}")
        return None


def main():
    # Note: Uncomment the function call you want to use
    # ost_get_version() # Gets current local version of OstrichDB
    # collection_action(method)  # action on a collection
    # cluster_action(method)     # action on a cluster
    # record_action(method)      # action on a record


if __name__ == "__main__":
    main()