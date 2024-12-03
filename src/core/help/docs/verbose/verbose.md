# This file contains all verbose help documentation for OstrichDB

### HELP
The `HELP` command displays helpful information about OstrichDB.'
`HELP `Can be used alone to display general information or chained with specific tokens to display detailed information about that token. For example: `HELP COLLECTION` will display detailed information about collections. The `HELP` command can produce different levels of information depending on if the `OST_HELP` value in the `/bin/ostrich.config` file is set to `simple` or `verbose`. Currently it is set to `verbose`. If you'd like the help information that us shown to be more simple, set the `OST_HELP` value to `simple`.

### VERSION START
The `VERSION` command fetches the current installed version of OstrichDB. The versioning scheme for OstrichDB is `release type._major version.minor version.patch version_build type`.
For example: `Pre_Rel_v0.4.0_dev`.
### VERSION END

### EXIT START
The `EXIT` command safely exits OstrichDB. Execution of this command will safely log the user out and close the application. Note: using `CTRL+C` will UNSAFELY exit the application so it is recommended to use the `EXIT` command.
### EXIT END

### LOGOUT START
The `LOGOUT` command logs out the current user WITHOUT closing OstrichDB. This command is useful for switching between users without closing the application. NOTE: Users will be logged out automatically after 3 days.
### LOGOUT END

### RESTART START
The `RESTART` command restarts OstrichDB. This command makes a function call that then calls the built-in restart script. 
### RESTART END

### REBUILD START
The `REBUILD` command rebuilds the database and restarts OstrichDB. This command is useful for making changes to the source code and rebuilding the database.
### REBUILD END

### CLEAR START
The `CLEAR` command clears the screen of clutter. This command is useful for clearing the screen of previous commands and outputs assisting in keeping the command line clean and organized.
### CLEAR END

### TREE START
The `TREE` token is a single-token action. It is used to display a tree like structure of all the collections and clusters within OstrichDB. This command is useful for visualizing the structure of the database. Example: `TREE`.
### TREE END

### HISTORY START
THe `HISTORY` token is a single-token action. It is used to display a history of all the commands that have been used in the current sesssion of the OstrichDB command line. This command is useful for tracking the commands that have been entered and repeating them. Example: `HISTORY`.
### HISTORY END

### NEW START
The `NEW` token is a multi-token action. It is used to create new objects within OstrichDB. `NEW` MUST be followed by a target token such as `COLLECTION`, `CLUSTER`, or `RECORD` and an object name. This tells the parser exactly what object to create and what to name it. For example: `NEW COLLECTION <collection_name>` will create a new collection with the specified name. For clusters and records, use dot notation: `NEW CLUSTER <collection_name>.<cluster_name>` or `NEW RECORD <collection_name>.<cluster_name>.<record_name>`.
### NEW END

### FETCH START
The `FETCH` token is a multi-token action. It is used to retrieve objects within OstrichDB. `FETCH` MUST be followed by a target token such as `COLLECTION`, `CLUSTER`, or `RECORD` and an object name using dot notation. This tells the parser where to look and what data to retrieve. For example: `FETCH COLLECTION <collection_name>` will retrieve ALL the data from the collection with the specified name. For clusters and records: `FETCH CLUSTER <collection_name>.<cluster_name>` or `FETCH RECORD <collection_name>.<cluster_name>.<record_name>`.
### FETCH END

### SET START
The `SET` token is a multi-token action. It is used to set the value of a record or config. `SET` MUST be followed by a target token such as `RECORD` or `CONFIG` and the object name using dot notation for records. This tells the parser exactly what object to set the value of and what to set it to. For example: `SET RECORD <collection_name>.<cluster_name>.<record_name> TO <record_value>` will set the value of the record with the specified name to the specified value. For configs: `SET CONFIG <config_name> TO <value>`.
### SET END

### RENAME START
The `RENAME` token is a multi-token action. It is used to change the name of objects within OstrichDB. `RENAME` MUST be followed by a target token such as `COLLECTION`, `CLUSTER`, or `RECORD` and an object name. This tells the parser exactly what object to rename and what to name it. For example: `RENAME COLLECTION <collection_name> TO <new_collection_name>` will rename the collection with the specified name to the new specified name.
### RENAME END

### ERASE START
The `ERASE` token is a multi-token action. It is used to delete objects within OstrichDB. `ERASE` MUST be followed by a target token such as `COLLECTION`, `CLUSTER`, or `RECORD` and an object name. This tells the parser exactly what object to delete and what to name it. For example: `ERASE COLLECTION <collection_name>` will delete the collection with the specified name.
### ERASE END

### PURGE START
The `PURGE` token is a multi-token action. It is used to remove all data from an object while maintaining the object structure. `PURGE` MUST be followed by a target token such as `COLLECTION`, `CLUSTER`, or `RECORD` for example: `PURGE COLLECTION <collection_name>` will remove all data from the collection with the specified name.
### PURGE END

### COUNT START
The `COUNT` token is a multi-token action. It is used to return the number of objects within a scope. `COUNT` MUST be followed by a target token such as `RECORDS`, `CLUSTERS`, or `COLLECTIONS` and an object name using dot notation where applicable. For example: `COUNT CLUSTERS <collection_name>` will return the number of clusters in the specified collection.
### COUNT END

### SIZE_OF START
The `SIZE_OF` token is a multi-token action. It is used to return the size in bytes of an object. `SIZE_OF` MUST be followed by a target token such as `RECORD`, `CLUSTER`, or `COLLECTION` and an object name. For example: `SIZE_OF COLLECTION <collection_name>` will return the size in bytes of the collection with the specified name.
### SIZE_OF END

### WHERE START
The `WHERE` token is a multi-token action. It is used to search for the location of a cluster or record within OstrichDB. `WHERE` can be followed by the target token ie `CLUSTER` or `RECORD` then the target object name or just the object name. For example: `WHERE RECORD <record_name>` will search all collections for the location of any record with the specified name.
### WHERE END

### BACKUP START
The `BACKUP` token is a multi-token action. It is used to create a backup of all data within OstrichDB. `BACKUP` MUST be followed by the target token `COLLECTION` and an object name. For example: `BACKUP COLLECTION <collection_name>` will create a backup of the collection with the specified name. Backups are stored in the `/bin/backups` directory and end with the `.ost` file extension.
### BACKUP END

### COLLECTION START
Collections are individual databases that are "collections" of smaller data objects called "clusters". Collection files are stored in the `/bin/collections` and end with the `.ost` file extension. Within the OstrichDB command line `COLLECTION`is a target token. This is used to specify that an action will be preformed on a collection. For example: `NEW COLLECTION <collection_name>` will create a new collection with the specified name.
### COLLECTION END

### CLUSTER START
Clusters are objects made up of related data called "records". Within the OstrichDB DBMS, clusters are stored within collections. If you are familiar with JSON, clusters are similar to "objects" in JSON. To maintain data integrity, clusters MUST have a cluster name and cluster ID. Cluster names are created by the user and cluster IDs are automatically generated by the DBMS.
### CLUSTER END

### RECORD START
Records are individual pieces of data that are stored within clusters. Records are similar to "key-value pairs" in JSON. Records are made up of a record name and a record value. Record names are created by the user and record values are the data that is stored within the record itself. Records are the smallest unit of data that can be stored in OstrichDB.
### RECORD END

### TO START
The `TO` token is used with the `RENAME` token to specify the new name of an object. `TO` MUST be followed by the new name of the object. For example: `RENAME COLLECTION <collection_name> TO <new_collection_name>` will rename the collection with the specified name to the new specified name.
### TO END

### ATOMS START
The `ATOMS` token is a special token that is only used with the `HELP` command to display a table of all the available ATOMs within OstrichDB. Atoms are the building blocks OstrichDB commands. When the command `HELP ATOMS` is entered a table of all the available atoms within OstrichDB will display.
### ATOMS END
