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

## **Data Structure Overview**

OstrichDB organizes data into three levels:

- **Records**: The smallest unit of data (e.g., user name, age, or product details).
- **Clusters**: Groups of related records (e.g., related information about a person or product).
- **Collections**: Files that hold multiple clusters (e.g., a database holding multiple product categories).

This structure makes it easy to store and retrieve logically grouped data.

---

## **Command Structure (ATOMs)**

In ObstrichDB, commands are typically broken into **four types of tokens**, called **ATOMs**, to improve readability and ensure clear instructions.

**Note:** Not all commands require all four tokens.

1. **(A)ction Token**: Specifies the operation to perform (e.g., `NEW`, `ERASE`, `RENAME`).
2. **(T)arget Token**: The type of object that the action is being performed on (e.g., `CLUSTER`, `RECORD`).
3. **(O)bject Token**: The name of the target object (e.g., `foo`, `bar`).
4. **(M)odifier Token**: Additional parameters that change the behavior of the command (e.g.,`TO`, `OF_TYPE`).

---

### **Command Example**

```bash
NEW CLUSTER foo.bar
```

Explanation:
- **`NEW`**: Create a new object (Action token).
- **`CLUSTER`**: The type of object to be created (Target token).
- **`foo`**: The parent object that the new cluster will be created in (Object token).
- **`bar`**: The name of the new cluster (Object token).

---

## **Supported Commands**

### **Single-Token Actions**
These actions perform simple tasks without needing additional arguments.

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
- **`TEST`**: A temporary command to run the built-in test suite. (Will be removed in future versions)

---

### **Multi-Token Actions**
These actions allow you to perform more complex operations.

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
- **`HELP`**: Displays help information for a specific ATOM.
- **`ISOLATE`**: Quarentines a collection file. Preventing any further changes to the file
- **`WHERE`**: Searches for a record or cluster by name. DOES NOT WORK WITH COLLECTIONS.
---

### **Modifiers in Commands**

Modifiers adjust the behavior of commands. The current supported modifiers are:
- **`TO`**: Used to assign a new value or name (e.g., renaming an object or setting a record's value).
- **`OF_TYPE`**: Specifies the type of a new record (e.g., INT, STR).


## **Supported Record Data Type Tokens**
When setting a record value, you must specify the records data type by using the `OF_TYPE` modifier. Most types have a shorthand notation for convenience.
Primary supported data types include:
  - **`INTEGER`**: Integer values. Short-hand: `INT`.
  - **`STRING`**: Any text value longer than 1 character. Short-hand: `STR`.
  - **`FLOAT`**: Floating-point numbers. Short-hand: `FLT`.
  - **`BOOLEAN`**: true or false values. Short-hand: `BOOL`.

Complex data types include:
NOTE: When setting array values, separate each element with a comma WITHOUT spaces.
  - **`[]STRING`**: String arrays. Short-hand: `[]STR`.
  - **`[]INTEGER`**: Integer arrays. Short-hand: `[]INT`.
  - **`[]FLOAT`**: Float arrays. Short-hand: `[]FLT`.
  - **`[]BOOLEAN`**: Boolean arrays. Short-hand: `[]BOOL`.

Other supported data types include:
  - **`CHAR`**: Single character values.
  - **`DATE`**: Date values in the format `YYYY-MM-DD`.
  - **`TIME`**: Time values in the format `HH:MM:SS`.
  - **`DATETIME`**: Date and time values in the format `YYYY-MM-DDTHH:MM:SS`

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

3. **Run The Build Script**:
   ```bash
   ./scripts/build.sh
   ```

---

## **Usage Examples**

   ```bash
   # Create a new collection:
   NEW COLLECTION staff
   # Create a new cluster:
   NEW CLUSTER staff.engineering
   # Create a new record:
   NEW RECORD staff.engineering.team_one OF_TYPE []STRING
   # Set a record value:
   SET RECORD staff.engineers.team_one TO Alice,Bob,Charlie
   # Fetch the record value:
   FETCH RECORD staff.engineers.team_one
   # Rename a cluster:
   RENAME CLUSTER staff.engineering TO HR
   # Get the size of a cluster:
   SIZE_OF CLUSTER staff.HR
   # Erase a record:
   ERASE RECORD staff.HR.team_one
   # Get a count of all collections in the database:
   COUNT COLLECTIONS
   # Get help on a specific ATOM
   HELP RECORD
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
  - `SORT`: Sort records or clusters by field
  - `IMPORT`: Load data from external sources(JSON, CSV, etc.)
  - `EXPORT`: Export data to various formats
  - `VALIDATE`: Check data integrity
  - `LOCK`: Prevent data modification
  - `UNLOCK`: Allow data modification
  - `RESTORE`: Restores a collection backup in the place of the original collection
  - `MERGE`: Combine multiple collections or clusters into one
  - `ALL`: Perform operations on all objects within a scope
- Support for additional data types
- Enhanced security (database encryption/decryption, secure deletion)
- Commnad chaining for complex operations
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

---