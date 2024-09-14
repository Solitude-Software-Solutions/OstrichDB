# This file contains all verbose help documentation for OstrichDB

### HELP
The `HELP` command displays helpful information about OstrichDB.'
`HELP `Can be used alone to display general information or chained with specific tokens to display detailed information about that token. For example: `HELP COLLECTION` will display detailed information about collections. The `HELP` command can produce different levels of information depending on if the `OST_HELP` value in the `/bin/ostrich.config` file is set to `simple` or `verbose`. Currently it is set to `verbose`. If you'd like the help information that us shown to be more simple, set the `OST_HELP` value to `simple`.

### VERSION START
The `VERSION` command fetches the current installed version of OstrichDB. The versioning scheme for OstrichDB is `release type._major version.minor version.patch version_build type`.
For example: `Pre_Rel_v0.2.0_dev`.
### VERSION END

### EXIT START
The `EXIT` command safely exits OstrichDB. Execution of this command will safely log the user out and close the application. Note: using `CTRL+C` will UNSAFELY exit the application so it is recommended to use the `EXIT` command.
### EXIT END

### LOGOUT START
The `LOGOUT` command logs out the current user WITHOUT closing OstrichDB. This command is useful for switching between users without closing the application. NOTE: Users will be logged out automatically after 3 days.
### LOGOUT END

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
The `NEW` token is an multi-token action. It is used to create new objects within OstrichDB. `NEW` MUST be followed by a target token such as `COLLECTION`, `CLUSTER`, or `RECORD` and an object name. This tells the parser exactly what object to create and what to name it. For example: `NEW COLLECTION <collection_name>` will create a new collection with the specified name.
### NEW END

### FETCH START
The `FETCH` token is a multi-token action. It is used to retrieve objects within OstrichDB. `FETCH` MUST be followed by a target token such as `COLLECTION`, `CLUSTER`, or `RECORD` and an object name. This tells the parser where to look and what data to retrieve. For example: `FETCH COLLECTION <collection_name>` will retrieve ALL the data from collection with the specified name.
### FETCH END

### SET START
The `SET` token is a multi-token action. It is used to set the value of a record or config. `SET` MUST be followed by a target token such as `RECORD` and the object name. This tells the parser exactly what object to set the value of and what to set it to. For example: `SET RECORD <record_name> TO <record_value>` will set the value of the record with the specified name to the specified value.
### SET END

### RENAME START
The `RENAME` token is a multi-token action. It is used to change the name of objects within OstrichDB. `RENAME` MUST be followed by a target token such as `COLLECTION`, `CLUSTER`, or `RECORD` and an object name. This tells the parser exactly what object to rename and what to name it. For example: `RENAME COLLECTION <collection_name> TO <new_collection_name>` will rename the collection with the specified name to the new specified name.
### RENAME END

### ERASE START
The `ERASE` token is a multi-token action. It is used to delete objects within OstrichDB. `ERASE` MUST be followed by a target token such as `COLLECTION`, `CLUSTER`, or `RECORD` and an object name. This tells the parser exactly what object to delete and what to name it. For example: `ERASE COLLECTION <collection_name>` will delete the collection with the specified name.
### ERASE END

### FOCUS START
The `FOCUS` token is a multi-token action. It is used to change the current context of "focus" of the target within OstrichDB. `FOCUS` MUST be followed by a target token such as `COLLECTION`, `CLUSTER`, or `RECORD` and an object name. This tells the parser exactly what object to focus on. For example: `FOCUS COLLECTION <collection_name>` will change the current focus to the collection with the specified name. Once focus has been set all subsequent actions will be preformed on the focused object. Using the example above, if you wanted to create a new cluster within the focused collection you would use the command `NEW CLUSTER <cluster_name>` as opposed to `NEW CLUSTER <cluster_name> WITHIN COLLECTION <collection_name>`.
### FOCUS END

### UNFOCUS START
The `UNFOCUS` token is a single-token action. It is used to remove the current context or "focus" of the target within OstrichDB. This tells the parser to stop focusing on the current object. For example: `UNFOCUS` will remove the current focus from the object that is currently being focused on. And the user will be returned to the default context to use the command line as normal.
### UNFOCUS END

### BACKUP START
The `BACKUP` token is a multi-token action. It is used to create a backup of all data within OstrichDB. `BACKUP` MUST be followed by the target token `COLLECTION` and an object name. For example: `BACKUP COLLECTION <collection_name>` will create a backup of the collection with the specified name. Backups are stored in the `/bin/backups` directory and end with the `.ost` file extension.
### BACKUP END

### COLLECTION START
Collections are individual databases that are "collections" of smaller data objects called "clusters". Collection files are stored in the `/bin/collections` and end with the `.ost` file extension. Within the OstrichDB command line `COLLECTION`is a target token. This is used to specify that an action will be preformed on a collection. For example: `NEW COLLECTION <collection_name>` will create a new collection with the specified name.
### COLLECTION END

### CLUSTER START
Clusters are objects made up of related data called "records". Clusters are stored within collections. If you are familiar with JSON, clusters are similar to "objects" in JSON. To maintain data integrity, clusters MUST have a cluster name and cluster ID. Cluster names are created by the user and cluster IDs are automatically generated by OstrichDB. Within the OstrichDB command line `CLUSTER` a target token. This is used to specify that an action will be preformed on a cluster. For example: `NEW CLUSTER <cluster_name> WITHIN COLLECTION <collection_name>` will create a new cluster with the specified name within the specified collection.
### CLUSTER END

### RECORD START
Records are individual pieces of data that are stored within clusters. Records are similar to "key-value pairs" in JSON. Records are made up of a record name and a record value. Record names are created by the user and record values are the data that is stored within the record itself. Records are the smallest unit of data that can be stored in OstrichDB.
### RECORD END

### WITHIN START
The `WITHIN` token is a special modifier token called a scope modifier. It is used to specify the location of an object(target) within another object(parent). `WITHIN` MUST be followed by a target token such as `COLLECTION` or `CLUSTER` and an object name. This tells the parser to set the scope of the target that the action will be performed on. For example: `NEW CLUSTER <cluster_name> WITHIN COLLECTION <collection_name>` will create a new cluster with the specified name within the specified collection.
### WITHIN END

### TO START
The `TO` token is used with the `RENAME` token to specify the new name of an object. `TO` MUST be followed by the new name of the object. For example: `RENAME COLLECTION <collection_name> TO <new_collection_name>` will rename the collection with the specified name to the new specified name.
### TO END

### ATOMS START
The `ATOMS` token is a special token that is only used with the `HELP` command to display a table of all the available ATOMs within OstrichDB. Atoms are the building blocks OstrichDB commands. When the command `HELP ATOMS` is entered a table of all the available atoms within OstrichDB will display.
### ATOMS END
