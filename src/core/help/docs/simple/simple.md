# OstrichDB Simplified Help Documentation

### HELP
Shows information about OstrichDB. Use `HELP <command>` for specific details.

### VERSION
Displays the current OstrichDB version.

### EXIT
Safely closes OstrichDB.

### LOGOUT
Logs out the current user without closing OstrichDB.

### CLEAR
Clears the screen of clutter.

### NEW
Creates new objects. Use: `NEW <object_type> <name>`.

### ERASE
Deletes objects. Use: `ERASE <object_type> <name>`.

### FETCH
Retrieves data. Use: `FETCH <object_type> <name>`.

### RENAME
Changes object names. Use: `RENAME <object_type> <old_name> TO <new_name>`.

### FOCUS
Sets the current working context. Use: `FOCUS <object_type> <name>`.

### UNFOCUS
Removes the current focus.

### BACKUP
Creates a backup of data. Use: `BACKUP COLLECTION <name>`.

### COLLECTION
A database containing clusters. Stored as `.ost` files.

### CLUSTER
Groups of related records within a collection.

### RECORD
Individual pieces of data stored in clusters.

### WITHIN
Specifies location. Use: `<action> <object> WITHIN <parent_object>`.

### TO
Used with RENAME to specify the new name.