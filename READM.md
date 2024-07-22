# OstrichDB

OstrichDB is a document-based NoSQL database designed and built for ease of use and local application data testing/manipulation. It is written in the Odin programming language and is currently a work in progress.

## Current Features

- User authentication
- Serverless architecture (current implementation)
- Backend command parsing
- Comprehensive set of database operations

## Data Structure

OstrichDB uses a hierarchical data structure:

- **Records**: Individual sets of data
- **Clusters**: Groups of related records
- **Collections**: Files containing clusters (also known as a database)

## Command Structure

Commands in OstrichDB are parsed into components called ATOMs. This structured approach allows for complex operations while maintaining readability. Here's a breakdown of the command structure as ATOMs:

- **(A)ction token**: Specifies the operation to be performed (e.g., NEW, ERASE, RENAME)
- **(T)arget token**: Indicates the type of object the action is performed on (e.g., CLUSTER, RECORD)
- **(O)bject token**: Represents the name or identifier of the target
- **(M)odifier**: Additional parameters that modify the command's behavior (e.g., WITHIN)

Example: `NEW CLUSTER foo WITHIN COLLECTION bar`

In this example:
- NEW is the Action token
- CLUSTER is the Target token
- foo is the Object token (name of the cluster) given by the user
- WITHIN is a scoped modifier
- COLLECTION bar specifies where the new cluster should be created

## Supported Commands

OstrichDB supports several single token and multi-token commands:

### Single Token Commands

- `VERSION`: Displays the current version of OstrichDB
- `LOGOUT`: Logs out the current user
- `EXIT`: Exits the database session
- `UNFOCUS`: Removes focus from the current document or collection

### Multi-Token Commands

**Note: Multi-token commands require both a Target and Object token**

- `NEW`: Creates a new collection, cluster, or record
- `ERASE`: Deletes a collection, cluster, or record
- `RENAME`: Changes the name of a collection, cluster, or record
- `FETCH`: Retrieves data from a collection, cluster, or record
- `FOCUS`: Sets focus on a specific collection, cluster, or record

Example usage for each multi-token command:
```
NEW CLUSTER ...
ERASE COLLECTION ...
RENAME RECORD ...
FETCH CLUSTER ...
FOCUS CLUSTER ... WITHIN COLLECTION ...
```

### Modifiers

Modifiers are additional parameters that modify the behavior of a command:

- `WITHIN`: Specifies the parent collection of a cluster or record
- `TO`: Used with the RENAME command to specify the new name of the object

## Installation

**Note: This project assumes that you are using Linux**

### Prerequisites:

- Clang and LLVM installed on your machine
- The Odin programming language installed and properly built (See [Installing Odin](https://odin-lang.org/docs/install/))
- Ensure Odin is in your PATH

### Steps:

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

4. Run the project:
   ```bash
   ./main.bin
   ```

Voila! You now have OstrichDB running on your local machine.

## Contributing

Contributions to OstrichDB are welcome! Please refer to the [CONTRIBUTING.md](CONTRIBUTING.md) file for detailed guidelines on how to contribute to this project.

## License

OstrichDB is released under the Apache License 2.0. This is a permissive license that allows you to use, modify, and distribute the software, even for commercial purposes, under certain conditions.

For the full license text, please see the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0) page.

## Future Plans

More features and improvements are planned for OstrichDB, including:
- Improved error handling
- Enhanced user authentication
- Support for more complex queries
- Additional database operations
- Better documentation and user guides
- Bug fixes and performance improvements
- API support for external applications
- Support for more data types
- Enhanced security features
- And much more!
