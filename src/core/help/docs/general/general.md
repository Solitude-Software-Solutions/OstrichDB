# OstrichDB Combined Documentation

OstrichDB is a versatile, multi-user Database Management System that uses a JSON-like hierarchical data structure. It can be run serverless from the command line or in server mode, making it adaptable for various use cases. Designed for macOS and Linux systems, OstrichDB operates through a command-line interface. This document combines the general, simple, and advanced help documentation for OstrichDB.

OstrichDB allows for the use of dot notation to quickly perform actions on data objects. The DBMS is organized into collections, clusters, and records, with records being the smallest unit of data. The command structure is based on four types of tokens: Actions, Targets, Objects, and Modifiers.

## General Commands

### AGENT
Starts the OstrichDB Natural Language Processor agent(Server must be running in another terminal)

### SERVER
Starts the OstrichDB http server

### HELP
Displays information about OstrichDB. Use `HELP` alone for general info or `HELP <command>` for specific details about a token. The verbosity level of the help shown can be set in `/bin/private/config.ostrichdb` or by using `SET CONFIG HELP TO VERBOSE/SIMPLE`.

### VERSION
Shows the current OstrichDB version. Format: `release type._major.minor.patch_build type` (e.g., `Pre_Rel_v0.4.0_dev`).

### EXIT
Safely closes OstrichDB. Preferred over using CTRL+C, which exits unsafely.

### LOGOUT
Logs out the current user without closing OstrichDB. Useful for switching users. Auto-logout occurs after 3 days.

### RESTART
Restarts OstrichDB.

### REBUILD
Rebuilds the database and restarts OstrichDB. Useful if you are making changes to source code.

### CLEAR
Clears the screen, helping to keep the command line organized.

### TEST
Runs the test suite for OstrichDB.

### TREE
Displays a tree view all collections and thier clusters within OstrichDB

### HISTORY
Displays all previous commands entered by the current user.

### DESTROY
Deletes all data, users and configuartions from OstrichDB. Use with caution.

## Object Management Commands

### NEW
Creates new objects or users.
Example: `NEW <collection_name>.<cluster_name>`
or
`NEW USER`

### FETCH
Retrieves and displays data from the specified object.
Example: `FETCH <collection_name>.<cluster_name>.<record_name>`

### SET
Sets a value for a record or config.
Example: `SET <collection_name>.<cluster_name>.<record_name> TO <value>`
or
`SET CONFIG <config_name> TO <value>`

### RENAME
Changes object names.
Example: `RENAME <old_collection_name> TO <new_collection_name>`

### ERASE
Deletes objects completely.
Example: `ERASE <collection_name>.<cluster_name>`

### BACKUP
Creates a backup of data. Currently only supports collections.
Syntax: `BACKUP <collection_name>`
Backups are stored in `/bin/backups` with `.ost` extension.

### PURGE
Removes all data from an object while maintaining the object structure.
Example: `PURGE <collection_name>`

### COUNT
Returns the number of objects within a scope. Paired with the plural form of the object type (e.g., `RECORDS`, `CLUSTERS`).
Example: `COUNT <collection_name>`

### SIZE_OF
Returns the size in bytes of an object.
Example: `SIZE_OF <collection_name>`

### TYPE_OF
Returns the data type of a record.
Example: `TYPE_OF <collection_name>.<cluster_name>.<record_name>`

### CHANGE_TYPE
Changes the data type of a record.
Example: `CHANGE_TYPE <collection_name>.<cluster_name>.<record_name> TO <new_data_type>`

### WHERE
Either searches all or a specific collection for the location of a cluster or record.
Example: `WHERE <cluster_name>`
or
`WHERE <object_name>`

### ISOLATE
Isolates a collection from the DBMS making it un-writtable.

## Data Structure Concepts

### DBMS Overview
OstrichDB is a Document-based NoSQL Database Management System that organizes data in a hierarchical structure:

### COLLECTION
- Individual databases within the DBMS
- Stored as `.ostrichdb` files in `/bin/public/standard`
- Equivalent to a database instance in traditional DBMS systems

### CLUSTER
- Groups of related records within a collection
- Similar to objects in JSON
- Must have a cluster name (user-defined) and cluster ID (auto-generated)

### RECORD
- Individual pieces of data stored in clusters
- Similar to key-value pairs in JSON
- Composed of a record name (user-defined) and a record value (the stored data)
- Smallest unit of data in OstrichDB

## Modifiers

### TO
Used with RENAME to specify the new name.
Example: `RENAME COLLECTION <old_name> TO <new_name>`


### OF_TYPE
Used with NEW to specify the data type of a record.
Example: `NEW RECORD <collection_name>.<cluster_name>.<record_name> OF_TYPE <data_type>`
Supported data types: `INT`, `STR`, `BOOL`, `FLOAT`

## DBMS Architecture

### Overview
OstrichDB is designed as a local-first Document-based NoSQL DBMS that prioritizes:
- Data integrity and consistency
- Simple yet powerful command interface
- JSON-like data structures
- Built-in security features
- Comprehensive backup and recovery

### Components
1. **Command Processor**: Handles user interactions and command parsing
2. **Storage Engine**: Manages data persistence and retrieval
3. **Security Layer**: Handles authentication and access control
4. **Backup System**: Manages data backup and recovery
5. **Integrity Checker**: Ensures data consistency and validation

### Data Flow
1. Commands are processed through the CLI
2. The DBMS validates and parses the command
3. Security checks are performed
4. Data operations are executed
5. Changes are persisted to storage
6. Results are returned to the user
