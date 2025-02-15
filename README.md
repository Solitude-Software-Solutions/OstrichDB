# **OstrichDB**

OstrichDB is a lightweight, document-based NoSQL DBMS written in the Odin programming language. It can be run serverless from the command line or deployed in server mode, offering flexibility for different use cases. With a focus on simplicity and straightforward setup, OstrichDB provides an intuitive command structure for managing data using both single and multi-token commands.


---

## **Features**

- Dual Operation Modes:
  - Serverless Command-line Interface
  - Server Mode with HTTP API
- User Authentication
- Multi-User Support
- JSON-like Hierarchical Data Structure
- Command Based Operations
- Dot Notation Syntax
- Basic CRUD Operations
- macOS & Linux Support
---

## **Installation**

### **Prerequisites:**
- A Unix-based system (macOS, Linux).
- Clang & LLVM installed on your system.
- The Odin programming language installed, built, and properly set in the system's PATH.


### **Steps:**

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/Solitude-Software-Solutions/OstrichDB.git
   ```

2. **Navigate to the OstrichDB Directory**:
   ```bash
   cd path/to/OstrichDB
   ```

3. **Make the Build & Restart Scripts Executable**:
   ```bash
   chmod +x scripts/build.sh scripts/restart.sh
   ```

4. **Run The Build Script**:
   ```bash
   ./scripts/build.sh
   ```
---


## **Data Structure Overview**

OstrichDB organizes data into three levels:

- **Records**: The smallest unit of data (e.g., user name, age, or product details).
- **Clusters**: Groups of related records (e.g., related information about a person or product).
- **Collections**: Files that hold multiple clusters (e.g., a database holding multiple product categories).

---

## **Command Structure (CLPs)**

In OstrichDB, commands are typically broken into **three types of tokens**, called **CLPs**, to improve readability and ensure clear instructions.

**Note:** Not all commands require all 3 tokens.


1. **(C)ommand Token**: Specifies the operation to perform (e.g., `NEW`, `ERASE`, `RENAME`).
2. **(L)ocation Token**: The dot notation path that the command will be performed on (e.g., `foo.bar.baz`).
3. **(P)arameter Token(s)**: Additional parameters that change the behavior of the command (e.g., `TO`, `OF_TYPE`).

---

### **Command Walkthrough**

```bash
NEW foo.bar.baz OF_TYPE []STRING
```
Explanation:
- **`NEW`**: Create a new object (Command token).
- **`foo`**: The fisrt object always points to a collection. (Location token). Note: If there is only 1 object given, its a collection.
- **`bar`**: The second object always to a cluster within the collection. (Location token).
- **`baz`**: The third object is always a record within the cluster. (Location token).
- **`OF_TYPE`**: Specifies the data type of the record (Parameter token). Note: Only records are given data types.
- **`[]STRING`**: The record will be an array of strings (Parameter token).

---

## **Supported Commands**

### **Single-Token Operations**
These operations perform simple tasks without needing additional arguments.

- **`VERSION`**: Displays the current version of OstrichDB.
- **`LOGOUT`**: Logs out the current user.
- **`EXIT`**: Ends the session and closes the DBMS.
- **`RESTART`**: Restarts the program.
- **`REBUILD`**: Rebuilds the DBMS and restarts the program.
- **`HELP`**: Displays general help information or detailed help when chained with specific tokens.
- **`TREE`**: Displays the entire data structure in a tree format.
- **`CLEAR`**: Clears the console screen.
- **`HISTORY`**: Shows the current users command history.
- **`DESTROY`**: Completley destorys the entire DBMS. Including all databases, users, configs, and logs.
- **`BENCHMARK`**: Runs a benchmark test on the DBMS to test performance. Can be run with or without parameters.

---

### **Multi-Token Operations**
These operations allow you to perform more complex operations.

- **`NEW`**: Create a new collection, cluster, record, or user.
- **`ERASE`**: Delete a collection, cluster, or record.
- **`RENAME`**: Rename an existing object.
- **`FETCH`**: Retrieve data from a collection, cluster, or record.
- **`SET`**: Assign a value to a record or configuration.
- **`BACKUP`**: Create a backup of a specific collection.
- **`PURGE`**: Removes all data from an object while maintining the object structure.
- **`COUNT`**: Returns the number of objects within a scope. Paired with the plural form of the object type (e.g., `RECORDS`, `CLUSTERS`).
- **`SIZE_OF`**: Returns the size in bytes of an object.
- **`TYPE_OF`**: Returns the type of a record.
- **`CHANGE_TYPE`**: Allows you to change the type of a record.
- **`HELP`**: Displays help information for a specific token.
- **`ISOLATE`**: Quarentines a collection file. Preventing any further changes to the file
- **`WHERE`**: Searches for the location of a single or several record(s) or cluster(s). DOES NOT WORK WITH COLLECTIONS.
- **`VALIDATE`**: Validates a collection file for any errors or corruption.
- **`BENCHMARK`**: Runs a benchmark test on the DBMS to test performance. Can be run with or without parameters.
---

### **Parameters**

Modifiers adjust the behavior of commands. The current supported modifiers are:
- **`TO`**: Used to assign a new value or name (e.g., renaming an object or setting a record's value).
- **`OF_TYPE`**: Specifies the type of a new record (e.g., INT, STR, []BOOL).


## **Supported Record Data Type Tokens**
When setting a record value, you must specify the records data type by using the `OF_TYPE` modifier. Some types have a shorthand notation for convenience.

### Primary data types include:
  - **`INTEGER`**: Integer values. Short-hand: `INT`.
  - **`STRING`**: Any text value longer than 1 character. Short-hand: `STR`.
  - **`FLOAT`**: Floating-point numbers. Short-hand: `FLT`.
  - **`BOOLEAN`**: true or false values. Short-hand: `BOOL`.
  - **`CHAR`**: Single character values. No short-hand.

### Complex data types include:
*NOTE: When setting array values, separate each element with a comma WITHOUT spaces.*
  - **`[]STRING`**: String arrays. Short-hand: `[]STR`.
  - **`[]INTEGER`**: Integer arrays. Short-hand: `[]INT`.
  - **`[]FLOAT`**: Float arrays. Short-hand: `[]FLT`.
  - **`[]BOOLEAN`**: Boolean arrays. Short-hand: `[]BOOL`.
  - **`[]CHAR`**: Character arrays. No short-hand.


### Other supported data types include:
  - **`DATE`**: Must be in `YYYY-MM-DD` format. No short-hand.
  - **`TIME`**: Must be in `HH:MM:SS` format. No short-hand.
  - **`DATETIME`**: Must be in `YYYY-MM-DDTHH:MM:SS` format. No short-hand.
  - **`[]DATE`**: Date arrays. Each value must follow the above format. No short-hand.
  - **`[]TIME`**: Time arrays. Each value must follow the above format. No short-hand.
  - **`[]DATETIME`**: Date and time arrays. Each value must follow the above format. No short-hand.
  - **`NULL`**: Null value. No short-hand.

    *Note: UUIDs can only have `0-9` and `a-f` characters and must be in the format `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`.*
  - **`UUID`**: Universally unique identifier. Must follow the above format. No short-hand.
  - **`[]UUID`**: UUID arrays. Each value must follow the above format. No short-hand.

---

## **Usage Examples**
   ```bash
   # Create a new collection:
   NEW staff
   # Create a new cluster:
   NEW staff.engineering
   # Create a new record:
   NEW staff.engineering.team_one OF_TYPE []STRING
   # Set a record value:
   SET staff.engineers.team_one TO Alice,Bob,Charlie
   # Fetch the record value:
   FETCH staff.engineers.team_one
   # Rename a cluster:
   RENAME staff.engineering TO HR
   # Get the size of a cluster:
   SIZE_OF staff.HR
   # Erase a record:
   ERASE staff.HR.team_one
   # Get a count of all collections in the database:
   COUNT COLLECTIONS
   #Get help information for a specific token:
   HELP {TOKEN_NAME}
   # Get general help information
   HELP
   # Create a new user
   NEW USER
   ```
---

## **Future Plans**

- More configuration options
- Database file compression and zipping
- Several new command tokens:
  - `IMPORT`: Load data from external sources(JSON, CSV, etc.)
  - `EXPORT`: Export data to various formats
  - `LOCK`: Prevent data modification
  - `UNLOCK`: Allow data modification
  - `RESTORE`: Restores a collection backup in the place of the original collection
  - `MERGE`: Combine multiple collections or clusters into one
- Enhanced security (database encryption/decryption, secure deletion)
- Command chaining for complex operations
- Server-based architecture improvements
- External API support for popular programming languages
- Windows support
- Integration with the planned Feather query language!


---


## **Contributing**

Please refer to the [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines on how to contribute.

---

## **License**

OstrichDB is released under the **Apache License 2.0**. For the full license text, see [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).
