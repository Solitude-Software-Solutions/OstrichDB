# OstrichDB Combined Documentation

## General Commands

### HELP
Displays information about OstrichDB. Use `HELP` alone for general info or `HELP <command>` for specific details. The verbosity level can be set in `/bin/ostrich.config`.

### VERSION
Shows the current OstrichDB version. Format: `release type._major.minor.patch_build type` (e.g., `Pre_Rel_v0.2.0_dev`).

### EXIT
Safely closes OstrichDB. Preferred over using CTRL+C, which exits unsafely.

### LOGOUT
Logs out the current user without closing OstrichDB. Useful for switching users. Auto-logout occurs after 3 days.

### CLEAR
Clears the screen, helping to keep the command line organized.

## Object Management Commands

### NEW
Creates new objects. Syntax: `NEW <object_type> <name>`.
Example: `NEW COLLECTION <collection_name>`

### ERASE
Deletes objects. Syntax: `ERASE <object_type> <name>`.
Example: `ERASE COLLECTION <collection_name>`

### FETCH
Retrieves data. Syntax: `FETCH <object_type> <name>`.
Example: `FETCH COLLECTION <collection_name>` (retrieves ALL data from the specified collection)

### RENAME
Changes object names. Syntax: `RENAME <object_type> <old_name> TO <new_name>`.
Example: `RENAME COLLECTION <collection_name> TO <new_collection_name>`

### FOCUS
Sets the current working context. Syntax: `FOCUS <object_type> <name>`.
Example: `FOCUS COLLECTION <collection_name>`
After setting focus, subsequent actions apply to the focused object without needing to specify it each time.

### UNFOCUS
Removes the current focus, returning to the default context.

### BACKUP
Creates a backup of data. Currently only supports collections.
Syntax: `BACKUP COLLECTION <name>`
Backups are stored in `/bin/backups` with `.ost` extension.

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

### WITHIN
A scope modifier specifying location.
Syntax: `<action> <object> WITHIN <parent_object>`
Example: `NEW CLUSTER <cluster_name> WITHIN COLLECTION <collection_name>`

### TO
Used with RENAME to specify the new name.
Example: `RENAME COLLECTION <old_name> TO <new_name>`

Note: This documentation combines simple and verbose descriptions. For more detailed information on specific commands, use the `HELP <command>` feature within OstrichDB.
