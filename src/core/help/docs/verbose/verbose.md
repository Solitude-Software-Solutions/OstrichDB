# This file contains all verbose help documentation for OstrichDB

### HELP
The `HELP` command token is a single-token action. It Displays helpful information about OstrichDB.'
`HELP `Can be used alone to display general information or chained with specific tokens to display detailed information about that token. For example: `HELP COLLECTION` will display detailed information about collections. The `HELP` command can produce different levels of information depending on if the `OST_HELP` value in the `/bin/config` file is set to `simple` or `verbose`. Currently it is set to `verbose`. If you'd like the help information that us shown to be more simple, set the `OST_HELP` value to `simple`.

### AGENT
The `AGENT` command token is a single-token action. It starts the OstrichDB natural language processing agent. This agent allows the user to "in plain English" interact with the DBMS and perform queries.
### AGENT END

### SERVER START
The `SERVER` command token is a single-token action. It starts the OstrichDB http server allowing the user to access the API layer and interact with the DBMS.
### SERVER END

### VERSION START
The `VERSION` command tokenis a single-token action. It fetches the current version of OstrichDB. The versioning scheme for OstrichDB is `Release_Type_vMajor.Minor.Patch_Status`.
For example: `Pre_Rel_v0.4.0_dev`.
### VERSION END

### EXIT START
The `EXIT` command token is a single-token action. It is used to safely exit OstrichDB. Execution of this command will safely log the user out and close the application. Note: using `CTRL+C` will UNSAFELY exit the application so it is recommended to use the `EXIT` command.
### EXIT END

### LOGOUT START
The `LOGOUT` command token is a single-token action. It is used to log out the current user WITHOUT closing OstrichDB. This command is useful for switching between users without closing the application. NOTE: Users will be logged out automatically after 24 hours of runtime.
### LOGOUT END

### RESTART START
The `RESTART` command token is a single-token action. It is used to restart OstrichDB. This command makes a function call that then calls the built-in restart script.
### RESTART END

### REBUILD START
The `REBUILD` command token is a single-token action. It is used to rebuild and restart OstrichDB. This command is useful when making changes to the source code or in the event that OstrichDB is not functioning properly.
### REBUILD END

### CLEAR START
The `CLEAR` command token is a single-token action. It is used to clear the screen of clutter. This command is useful for clearing the screen of previous commands and outputs assisting in keeping the command line clean and organized.
### CLEAR END

### TREE START
The `TREE` command token is a single-token action. It is used to display a tree like structure of all the collections and clusters within OstrichDB. This command is useful for visualizing the structure of the database. Example: `TREE`.
### TREE END

### HISTORY START
The `HISTORY` command token is a single-token action. It is used to display a history of all the commands that have been used in the current sesssion of the OstrichDB command line. This command is useful for tracking the commands that have been entered and repeating them. Example: `HISTORY`.
### HISTORY END

### DESTROY START
The `DESTROY` command token is a single-token action. It is used to delete all data, configurations, and users from the OstrichDB database. This command is useful for starting fresh with a clean database. Example: `DESTROY`.

### NEW START
The `NEW` command token is a multi-token action. It is used to create new objects within OstrichDB. This tells the parser exactly what object to create and what to name it. For example: `NEW <col_name>` will create a new collection with the specified name. For clusters and records, use dot notation: `NEW CLUSTER <col_name>.<clu_name>` or `NEW RECORD <col_name>.<clu_name>.<rec_name>`. You cannot create a sub data object without creating the parent object first.
For example, you cannot create a record without creating a cluster first.
### NEW END

### FETCH START
The `FETCH` command token is a multi-token action. It is used to retrieve objects within OstrichDB. This tells the parser where to look and what data to retrieve. For example: `FETCH <col_name>` will retrieve ALL the data from the collection with the specified name. For clusters and records: `FETCH CLUSTER <col_name>.<clu_name>` or `FETCH RECORD <col_name>.<clu_name>.<rec_name>`.
### FETCH END

### SET START
The `SET` command token is a multi-token action. It is used to set the value of a record or config.For example: `SET <col_name>.<clu_name>.<rec_name> TO <rec_value>` will set the value of the record with the specified name to the specified value. For configs: `SET CONFIG <config_name> TO <value>`.
### SET END

### RENAME START
The `RENAME` command token is a multi-token action. It is used to change the name of objects within OstrichDB. This tells the parser exactly what object to rename and what to name it. For example: `RENAME COLLECTION <current_col_name> TO <new_col_name>` will rename the collection with the specified name to the new specified name.
### RENAME END

### ERASE START
The `ERASE` command token is a multi-token action. It is used to delete objects within OstrichDB. This tells the parser exactly what object to delete and what to name it. For example: `ERASE COLLECTION <col_name>` will delete the collection with the specified name.
### ERASE END

### PURGE START
The `PURGE` command token is a multi-token action. Similar to the `ERASE` command  It is used to remove all data from an object while maintaining the object structure. For example: `PURGE <col_name>.<clu_name>` will remove all data from the cluster with the specified name. But the cluster will still exist.
### PURGE END

### COUNT START
The `COUNT` command token is a multi-token action. It is used to return the number of objects within a scope. `COUNT` MUST be followed by a special target token: `RECORDS`, `CLUSTERS`, or `COLLECTIONS` and an object name using dot notation where applicable. For example: `COUNT CLUSTERS <col_name>` will return the number of clusters in the specified collection.
### COUNT END

### SIZE_OF START
The `SIZE_OF` command token is a multi-token action. It is used to return the size in bytes of an object. For example: `SIZE_OF COLLECTION <col_name>` will return the size in bytes of the collection with the specified name.
### SIZE_OF END

### TYPE_OF START
The `TYPE_OF` command token is a multi-token action. It is used to return the data type of a record. `TYPE_OF` For example: `TYPE_OF RECORD <col_name>.<clu_name>.<rec_name>` will return the type of the record with the specified name.
### TYPE_OF END

### CHANGE_TYPE START
The `CHANGE_TYPE` command token is a multi-token action. It is used to change the data type of a record. `CHANGE_TYPE`. For example: `CHANGE_TYPE <col_name>.<clu_name>.<rec_name> TO <new_data_type>` will change the data type of the record with the specified name to the new specified data type.

### LOCK START
The `LOCK` command token is a multi-token action. It is used to set a database's permssions to either Read-Only or Inaccessible mode. Only an admin can perfor this action. For example: `LOCK <collection_name> -n` Will set the permission mode to `Inaccessible` meaning no one aside from the creator can access or modify the contents of the collection.
### LOCK END

### UNLOCK START
The `LOCK` command token is a multi-token action. It is used to set a database's permssions to Read-Write mode. Only an admin user can unlock a collection and only collections that are currently locked can be unlocked. For example: `UNLOCK <collection_name>`
### UNLOCK END

### ENC START
The `ENC` command token is a multi-token action. Short for ENCRYPT It is used to encrpyt a collection using AES-256 making your data more secure. All collections are encrypted upon creation and while at rest. For example: `ENC <collection_name>`
### ENC END

### DEC START
The `DEC` command token is a multi-token action. Short for DECRYPT It is used to decrpyt an already encrypted collection. For example: `DEC <collection_name>`
### DEC END

### WHERE START
The `WHERE` command token is a multi-token action. It is used to search for the location of a cluster or record within OstrichDB. `WHERE` can be followed by the target token ie `CLUSTER` or `RECORD` then the target object name or just the object name. For example: `WHERE RECORD <rec_name>` will search all collections for the location of any record with the specified name.
### WHERE END

### BACKUP START
The `BACKUP` command token is a multi-token action. It is used to create a backup of a collection file. For example: `BACKUP COLLECTION <col_name>` will create a backup of the collection with the specified name. Backups are stored in the `/bin/backups` directory and end with the `.ostrichdb` file extension. This command can only be used to create a backup of a collection file.
### BACKUP END

### ISOLATE START
The `ISOLATE` command token is a multi-token action. It is used to isolate a collection from the rest of the database. For example: `ISOLATE <col_name>` will isolate the collection with the specified name from the rest of the database. This is useful for testing and debugging.
### ISOLATE END

### BENCHMARK START
The `BENCHMARK` command token can be used as a single or multi-token command. It is used to test the performance of OstrichDB. For example: `BENCHMARK` will test the default performance of OstrichDB. `BENCHMARK <num>.<num>` will test the performance of OstrichDB with the specified number of collections and clusters. The first number is the number of collections and the second number is the number of clusters each collection will have.
### BENCHMARK END

### COLLECTION START
Collections are individual databases that are "collections" of smaller data objects called "clusters". Collection files are stored in the `/bin/public/standard` and end with the `.ostrichdb` file extension. Within the OstrichDB command line `COLLECTION`is a target token. This is used to specify that an action will be preformed on a collection. For example: `NEW COLLECTION <col_name>` will create a new collection with the specified name.
### COLLECTION END

### CLUSTER START
Clusters are objects made up of related data called "records". Within the OstrichDB DBMS, clusters are stored within collections. If you are familiar with JSON, clusters are similar to "objects" in JSON. To maintain data integrity, clusters MUST have a cluster name and cluster ID. Cluster names are created by the user and cluster IDs are automatically generated by the DBMS.
### CLUSTER END

### RECORD START
Records are individual pieces of data that are stored within clusters. Records are similar to "key-value pairs" in JSON. Records are made up of a record name and a record value. Record names are created by the user and record values are the data that is stored within the record itself. Records are the smallest unit of data that can be stored in OstrichDB.
### RECORD END

### TO START
The `TO` parameter token is used with the `RENAME` token to specify the new name of an object. `TO` MUST be followed by the new name of the object. For example: `RENAME <col_name> TO <new_col_name>` will rename the collection with the specified name to the new specified name.
### TO END

### WITH START
The `WITH` parameter token is used witht the `NEW` token to assign a records value at the same time as you create it. This prevents the need for 2 seperate commands to create a record and assign its value. For example: `NEW <col_name>.<clu_name>.<rec_name> OF_TYPE <data_type> WITH <value>`
### WITH END

### OF_TYPE START
The `OF_TYPE` parameter token is used with the `NEW` token to specify the data type of a new record. `OF_TYPE` MUST be followed by the data type of the new record. For example: `NEW <col_name>.<clu_name>.<rec_name> OF_TYPE <data_type>` will create a new record with the specified name and data type.
### OF_TYPE END

### CLPS START
The `CLPS` command token is a special parameter token used with the `HELP` command to display information about CLPs.
### CLPS END