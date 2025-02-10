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

### TEST START
Runs the test suite for OstrichDB.
### TEST END

### TREE START
Used to display all collections and the cluster within them. Use: `TREE`.
### TREE END

### HISTORY START
Displays previous commands entered by the user. Use: `HISTORY`.
### HISTORY END

### DESTROY START
Deletes all data, configurations, and users from the DBMS. Use: `DESTROY`.
### DESTROY END

### NEW START
Creates new objects. Use: `NEW <col_name>`.
### NEW END

### FETCH START
Retrieves data. Use: `FETCH <col_name>.<clu_name>.<rec_name>`.
### FETCH END

### SET START
Sets the value of a record or config. Use: `SET <col_name>.<clu_name>.<rec_name> TO <value>` or `SET CONFIG <config_name> TO <value>`.
### SET END

### RENAME START
Changes object names. Use: `RENAME <old_name> TO <new_name>`.
### RENAME END

### ERASE START
Deletes objects. Use: `ERASE <object_name>`.
### ERASE END

### PURGE START
Removes all data from an object while maintaining the object structure. Use: `PURGE <object_name>`.
### PURGE END

### COUNT START
Returns the number of objects within a scope. Use: `COUNT RECORDS <col_name> `.
### COUNT END

### SIZE_OF START
Returns the size in bytes of an object. Use: `SIZE_OF <object_name>`.
### SIZE_OF END

### TYPE_OF START
Returns the type of a a record. Use: `TYPE_OF <col_name>.<clu_name>.<rec_name>`.

### CHANGE_TYPE START
Changes the type of a record. Use: `CHANGE_TYPE <col_name>.<clu_name>.<rec_name> TO <new_type>`.
### CHANGE_TYPE END

### WHERE START
Either searches all or a specific collection for the location of a cluster or record. Use: `WHERE <object_name>`.
### WHERE END

### BACKUP START
Creates a backup of DBMS data and configurations. Use: `BACKUP COLLECTION <object_name>`.
### BACKUP END

### ISOLATE START
Isolates a collection from the DBMS. Use: `ISOLATE <col_name>`.
### ISOLATE END

### BENCHMARK START
Runs a benchmark test on the DBMS. Use: `BENCHMARK` or `BENCHMARK <num>`, `BENCHMARK <num>.<num>`, `BENCHMARK <num>.<num>.<num>`. Where num is the number of iterations.
### BENCHMARK END

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
Modifier used with RENAME or SET.
### TO END

### OF_TYPE START
Specifies the type of a new record. Use: `NEW <col_name>.<clu_name>.<rec_name> OF_TYPE <type>`.
### OF_TYPE END

### CLPS START
Used with `HELP` to show information about CLPS.
### CLPS END
