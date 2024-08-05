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

### Multi-Token Commands

**Note: Multi-token commands require both a Target and Object token**

- `NEW`: Create new collection, cluster, or record
- `ERASE`: Delete collection, cluster, or record
- `RENAME`: Change name of collection, cluster, or record
- `FETCH`: Retrieve data from collection, cluster, or record
- `BACKUP`: Create a backup of a collection
- `FOCUS`: Set the current context to on specific collection, cluster, or record

**Note: Some commands CANNOT be used while focusing on a specific object**

Example usage for each multi-token command:
```
ERASE CLUSTER <cluster name> //Erase the cluster with the specified name
FETCH COLLECTION <collection name> //Fetches all data within the collection of specified name
NEW CLUSTER <cluster name> WITHIN COLLECTION <collection name> //Creates a new cluster within the specified collection 
FOCUS CLUSTER <cluster_name> WITHIN COLLECTION <collection name>  //Focuses on the specified cluster within the specified collection
BACKUP COLLECTION <collection name> //Creates a backup of the specified collection
```
**Note: The `FOCUS` command is used to set the current context to a specific object. ALL subsequent commands will be executed in the context of the focused object.**

### Modifiers

Modifiers are additional parameters that modify the behavior of a command:

- `WITHIN`: A scope modifier used to specify the parent object of the target object
- `TO`: Used with the RENAME command to specify the new name of the object

## Installation

### Prerequisites

- Linux environment
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

3. Build the project:
   ```bash
   odin build main
   ```

4. Run OstrichDB:
   ```bash
   ./main.bin
   ```

## Contributing

Please refer to [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on contributing to OstrichDB.

## License

OstrichDB is released under the Apache License 2.0. For full license text, see [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).

## Future Plans

- Enhanced user interface
- Improved configuration options
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
  - `OF_TYPE`: Filter operations by record type
  - `INTO`: Specify the destination for data operations
- Support for additional data types
- Data validation
- Enhanced security (database encryption/decryption, secure deletion)
- Performance optimizations
- External API support for popular programming languages
- Windows & macOS compatibility
- Integration with the planned Ostrich query language!