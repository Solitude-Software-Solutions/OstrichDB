# OstrichDB

OstrichDB is a lightweight, document-based, key-value NoSQL database designed for ease of use and local application data testing/manipulation. Written in the Odin programming language, it offers a flexible architecture and a simple command syntax, making it ideal for developers and users who need a simple yet versatile database solution.

## Features

- Serverless architecture (current implementation)
- User authentication
- JSON-like hierarchical data structures
- Intuitive yet simple command syntax with multi-token and single-token commands
- Basic CRUD operations
- Focus mode for streamlined operations within a context

## Data Structure

OstrichDB uses a hierarchical data structure:

- **Records**: Individual sets of data
- **Clusters**: Groups of related records
- **Collections**: Files containing clusters (also known as a database)

## Command Structure

Commands in OstrichDB are parsed into tokens also called ATOMs. This structured approach allows for complex operations while maintaining readability. Here's a breakdown of the command structure as ATOM(s):

- **(A)ction token**: Specifies the operation to be performed (e.g., NEW, ERASE, RENAME)
- **(T)arget token**: Indicates the type of object the action is performed on (e.g., CLUSTER, RECORD)
- **(O)bject token**: Represents the name or identifier of the target
- **(M)odifier**: Additional parameters that modify the command's behavior (e.g., WITHIN)

Note: Not all commands require all ATOMs. The number of ATOMs required depends on the command and its context.

Example: `NEW CLUSTER foo WITHIN COLLECTION bar`

In this example:
- `NEW` is the Action token
- `CLUSTER` is the Target token
- `foo` is the Object token (name of the cluster) given by the user
- `WITHIN` is a special modifier called a scope modifier
- `COLLECTION bar` specifies where the new cluster should be created

## Supported Commands

### Single Token Commands

- `VERSION`: Display current version
- `LOGOUT`: Log out current user
- `EXIT`: Exit database session
- `UNFOCUS`: Remove focus from current data structure
- `CLEAR`: Clear the screen of clutter
- `HELP`: Display general help information
- `TREE`: Display the hierarchical structure of the database
- `HISTORY`: Display OStrichDB usage command history
**Note: The `HELP` command can also be a multi-token command to get more detailed information**

### Multi-Token Commands

**Note: Multi-token commands require both a Target and Object token**

- `NEW`: Create new collection, cluster, or record
- `ERASE`: Delete collection, cluster, or record
- `RENAME`: Change name of collection, cluster, or record
- `FETCH`: Retrieve data from collection, cluster, or record
- `SET`: Set the value of a record or config
- `BACKUP`: Create a backup of a collection
- `FOCUS`: Set the current context to on specific collection, cluster, or record
- `HELP`: Display detailed information when chained with a specific token such as COLLECTION, FETCH, NEW, ATOMS, etc.

**Note: Some commands CANNOT be used while focusing on a specific object**

Example usage of multi-token commands:
```bash
NEW CLUSTER <cluster_name> WITHIN COLLECTION <collection_name> //Creates a new cluster within the specified collection
ERASE CLUSTER <cluster_name> WITHIN COLLECTION <collection_name> //Erase the cluster with the specified name
RENAME RECORD <old_name> TO <new_name> //Renames the record with the specified old name to the new name
FETCH COLLECTION <collection_name> //Fetches all data within the collection of specified name
SET RECORD <record_name> TO <value> //Sets the value of the specified record
BACKUP COLLECTION <collection_name> //Creates a backup of the specified collection
HELP COLLECTION //Displays information about collections
NEW RECORD <record_name> OF_TYPE <record_type>
FOCUS CLUSTER <cluster_name> WITHIN COLLECTION <collection_name>  //Focuses on the specified cluster within the specified collection
```

**Note: The `FOCUS` command is used to set the current context to a specific object. ALL subsequent commands will be executed in the context of the focused object.**

### Modifiers

Modifiers are additional parameters that modify the behavior of a command:

- `WITHIN`: A scope modifier used to specify the parent object of the target object
- `TO`: Used with the RENAME and SET command to specify the new name or value of the object
- `ATOMS`: A special modifier ONLY used with the HELP command to display detailed information about the command's ATOMs
- `OF_TYPE`: ONLY used with the NEW RECORD command to specify the type of record being created

**Note: Currently, the only supported record types are `STRING`, `INTEGER`, `BOOL`, and `FLOAT`. Although when setting a record type, you can use shorthand such as `STR`, `INT`, `BOOL`, and `FLT`.**

## Installation

### Prerequisites

- Unix-like operating system (Linux, macOS)
- Clang and LLVM
- Odin programming language (properly built and in PATH)

### Steps

1. Clone the repository:
   ```bash
   git clone https://github.com/Solitude-Software-Solutions/OstrichDB.git
   ```

2. Navigate to the project's src directory:
   ```bash
   cd your/path/to/OstrichDB/src
   ```

3. Build and run OstrichDB:
   ```bash
   odin build main && ./main.bin
   ```

## Contributing

Please refer to [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on contributing to OstrichDB.

## License

OstrichDB is released under the Apache License 2.0. For full license text, see [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).

## Future Plans

- More data operations on records
- Enhanced user interface
- Improved configuration options
- Database file compression and zipping
- Multi-user support with role-based access control
- Several new command tokens:
  - `STATS`: Display database statistics
  - `PURGE`: Clear data while retaining structure
  - `SIZE`: Show object size in bytes
  - `SORT`: Sort records or clusters by field
  - `IMPORT`: Load data from external sources(JSON, CSV, etc.)
  - `EXPORT`: Export data to various formats
  - `VALIDATE`: Check data integrity
  - `LOCK`: Prevent data modification
  - `UNLOCK`: Allow data modification
  - `RESTORE`: Undo recent changes
  - `COUNT`: Display the number of objects within a scope
  - `MERGE`: Combine multiple collections or clusters into one
  - `ALL`: Perform operations on all objects within a scope
  - `AND`: Execute multiple operations in one command
  - `INTO`: Specify the destination for data operations
- Support for additional data types
- Enhanced security (database encryption/decryption, secure deletion)
- Performance optimizations
- External API support for popular programming languages
- Windows & macOS compatibility
- Integration with the planned Ostrich query language!
