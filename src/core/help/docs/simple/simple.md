# OstrichDB Simplified Help Documentation

### HELP START
Shows information about OstrichDB. Use `HELP <command>` for specific details.
### HELP END

### VERSION START
Displays the current OstrichDB version.
### VERSION END

### EXIT START
Safely closes OstrichDB.
### EXIT END

### LOGOUT START
Logs out the current user without closing OstrichDB.
### LOGOUT END

### RESTART START
Restarts OstrichDB.
### RESTART END

### REBUILD START
Rebuilds the database and restarts OstrichDB.
### REBUILD END

### CLEAR START
Clears the screen of clutter.
### LOGOUT END

### TREE START
Used to display all collections and the cluster within them. Use: `TREE`.
### TREE END

### HISTORY START
Displays previous commands entered by the user. Use: `HISTORY`.
### HISTORY END

### NEW START
Creates new objects. Use: `NEW <object_type> <name>`.
### NEW END

### FETCH START
Retrieves data. Use: `FETCH <object_type> <collection>.<cluster>.<record>`.
### FETCH END

### SET START
Sets the value of a record or config. Use: `SET <target> <collection>.<cluster>.<record> TO <value>` or `SET CONFIG <config_name> TO <value>`.
### SET END

### RENAME START
Changes object names. Use: `RENAME <object_type> <old_name> TO <new_name>`.
### RENAME END

### ERASE START
Deletes objects. Use: `ERASE <object_type> <name>`.
### ERASE END

### PURGE START
Removes all data from an object while maintaining the object structure. Use: `PURGE <object_type> <name>`.
### PURGE END

### COUNT START
Returns the number of objects within a scope. Use: `COUNT <object_type>`.
### COUNT END

### SIZE_OF START
Returns the size in bytes of an object. Use: `SIZE_OF <object_type>`.
### SIZE_OF END

### BACKUP START
Creates a backup of data. Use: `BACKUP COLLECTION <name>`.
### BACKUP END

### COLLECTION START
A database containing clusters. Stored as `.ost` files.
### COLLECTION END

### CLUSTER START
Groups of related records within a collection.
### CLUSTER END

### RECORD START
Individual pieces of data stored in clusters.
### RECORD END

### TO START
Used with RENAME to specify the new name.
### TO END

### OF_TYPE START
Specifies the type of a new record. Use: `NEW RECORD <record_name> OF_TYPE <type>`.
### OF_TYPE END

### ATOMS START
Used with `HELP` to show information about atoms.
### ATOMS END
