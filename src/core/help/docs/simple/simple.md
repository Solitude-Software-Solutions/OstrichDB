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

### WHERE START
Either searches all or a specific collection for the location of a cluster or record. Use: `WHERE <object_name>`.
### WHERE END

### BACKUP START
Creates a backup of DBMS data and configurations. Use: `BACKUP COLLECTION <name>`.
### BACKUP END

### COLLECTION START
A database instance within the DBMS containing related clusters and records.
### COLLECTION END

### CLUSTER START
Organizational units within a DBMS collection used to group related records.
### CLUSTER END

### RECORD START
The fundamental data storage unit within the DBMS, stored in clusters.
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
