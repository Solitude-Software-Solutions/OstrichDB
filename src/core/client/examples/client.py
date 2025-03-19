'''
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            This is an example client to show how to use Python
            to interact with the OstrichDB API layer.
*********************************************************/
'''

'''
Developer Notes: At the present time OstrichDBs server creates ALL routes
meant to do work on a database(collection) itself of its subcomponents dynamically.
This means that request paths need to be constructed the way they are below to work...
This might or might not change in the future.

TL;DR Store your db information in variables and pass them to the request calls

- Marshall Burns
'''

import requests

# Default values. Feel free to change them or create your own variables for your own use case.
collection_name = "python_collection"
cluster_name = "python_cluster"
record_name = "python_record"
record_type = "STRING"
record_value = "Hello-World!"

path_root = "http://localhost:8042"  # DO NOT CHANGE THIS

# Note: Uncomment the method you want to use or set the method variable
# before calling the respective function

# method = "HEAD"
# method = "POST"
# method = "PUT"
# method = "GET"
# method = "DELETE"


def ost_get_version():
    """Simply fetch the current version of OstrichDB on the server"""
    try:
        response = requests.get(f"{path_root}/version")
        print(f"Response Status: {response.status_code}")
        if response.ok:
            print(f"Received data from OstrichDB: {response.text}")
        return response.text
    except Exception as error:
        print(f"Error fetching from OstrichDB: {error}")
        return None


def collection_action(method="GET"):
    """Action to be performed on a collection"""
    try:
        response = requests.request(
            method,
            f"{path_root}/c/{collection_name}",
            headers={"Content-Type": "text/plain"}
        )
        print(f"{method} Request On Collection Response Status: {response.status_code}")
        
        if response.ok:
            if method == "GET":
                print(f"Received data from OstrichDB: {response.text}")
            elif method == "HEAD":
                print(f"Received data from OstrichDB: {dict(response.headers)}")
            return response.text
    except Exception as error:
        print(f"Error occurred using method {method} on a collection: {error}")
        return None


def cluster_action(method="GET"):
    """Action to be performed on a cluster"""
    try:
        response = requests.request(
            method,
            f"{path_root}/c/{collection_name}/cl/{cluster_name}",
            headers={"Content-Type": "text/plain"}
        )
        print(f"{method} Request On Cluster Response Status: {response.status_code}")
        
        if response.ok:
            if method == "GET":
                print(f"Received data from OstrichDB: {response.text}")
            elif method == "HEAD":
                print(f"Received data from OstrichDB: {dict(response.headers)}")
            return response.text
    except Exception as error:
        print(f"Error occurred using method {method} on a cluster: {error}")
        return None


def record_action(method="GET"):
    """Action to be performed on a record"""
    # Depending on the request method the path for the request is constructed differently for records
    if method == "POST":
        full_path = f"{path_root}/c/{collection_name}/cl/{cluster_name}/r/{record_name}?type={record_type}"
    elif method in ["GET", "DELETE", "HEAD"]:
        full_path = f"{path_root}/c/{collection_name}/cl/{cluster_name}/r/{record_name}"
    elif method == "PUT":
        full_path = f"{path_root}/c/{collection_name}/cl/{cluster_name}/r/{record_name}?type={record_type}&value={record_value}"
    else:
        print(f"Unsupported method: {method}")
        return None
    
    print(f"Full Request Path: {full_path}")
    
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
                print(f"Received data from OstrichDB: {dict(response.headers)}")
            return response.text
    except Exception as error:
        print(f"Error occurred using method {method} on a record: {error}")
        return None


def main():
    # Get OstrichDB version
    ost_get_version()
    
    # Note: Uncomment the function call you want to use
    # collection_action("GET")  # action on a collection
    # cluster_action("GET")     # action on a cluster
    # record_action("GET")      # action on a record


if __name__ == "__main__":
    main()