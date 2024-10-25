# OstrichDB Combined Documentation

OstrichDB is a serverless, multi-user database management system that uses a JSON-like hierarchical data structure. It is designed for macOS and Linux systems and operates through a command-line interface. This document combines the general, simple, and advanced help documentation for OstrichDB.

OstrichDB allows for the use of dot notation to quickly perform actions on data objetcs. The database is organized into collections, clusters, and records, with records being the smallest unit of data. The command structure is based on four types of tokens: Actions, Targets, Objects, and Modifiers.

## General Commands

### HELP
Displays information about OstrichDB. Use `HELP` alone for general info or `HELP <command>` for specific details about a token. The verbosity level of the help shown can be set in `/bin/ostrich.config` or by using `SET CONFIG HELP TO VERBOSE/SIMPLE`.

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

### TREE
Displays a tree view all collections and thier clusters within OstrichDB

### HISTORY
Displays all previous commands entered by the current user.



## Object Management Commands

### NEW
Creates new objects or users.
Example: `NEW CLUSTER <collection_name>.<cluster_name>` 
or
`NEW USER`

### FETCH
Retrieves and displays data from the specified object.
Example: `FETCH RECORD <collection_name>.<cluster_name>.<record_name>` 

### SET
Sets a value for a record or config.
Example: `SET RECORD <collection_name>.<cluster_name>.<record_name> TO <value>` 
or 
`SET CONFIG <config_name> TO <value>`

### RENAME
Changes object names.
Example: `RENAME COLLECTION <old_collection_name> TO <new_collection_name>`

### ERASE
Deletes objects completely.
Example: `ERASE CLUSTER <collection_name>.<cluster_name>`

### BACKUP
Creates a backup of data. Currently only supports collections.
Syntax: `BACKUP COLLECTION <collection_name>`
Backups are stored in `/bin/backups` with `.ost` extension.

### PURGE
Removes all data from an object while maintaining the object structure.
Example: `PURGE COLLECTION <collection_name>`

### COUNT
Returns the number of objects within a scope. Paired with the plural form of the object type (e.g., `RECORDS`, `CLUSTERS`).
Example: `COUNT CLUSTERS <collection_name>`

### SIZE_OF
Returns the size in bytes of an object.
Example: `SIZE_OF COLLECTION <collection_name>`


## Data Structure Concepts

### COLLECTION
- Individual databases containing clusters
- Stored as `.ost` files in `/bin/collections`
- Equivalent to a database in traditional systems

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
