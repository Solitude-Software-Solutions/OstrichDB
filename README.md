# **OstrichDB**

OstrichDB is a lightweight, document-based NoSQL JSON-esque database written in the Odin programming language. It focuses on simplicity and is designed for local data testing and manipulation, making it an ideal solution for developers looking for a straightforward database without the need for complex setups. With a flexible command structure, OstrichDB makes it easy to manage data using both single and multi-token commands.

---

## **Features**

- Serverless Architecture
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

---

## **Command Structure (ATOMs)**

In ObstrichDB, commands are broken into **four types of tokens**, called **ATOMs**, to improve readability and ensure clear instructions.

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

### **Single-Token Commands**
These commands perform simple tasks without needing additional arguments.

- **`VERSION`**: Displays the current version of OstrichDB.
- **`LOGOUT`**: Logs out the current user.
- **`EXIT`**: Ends the session and closes the database.
- **`RESTART`**: Restarts the program. 
- **`REBUILD`**: Rebuilds the database and restarts the program.
- **`HELP`**: Displays general help information or detailed help when chained with specific tokens.
- **`TREE`**: Displays the entire data structure in a tree format.
- **`CLEAR`**: Clears the console screen.
- **`HISTORY`**: Shows the current users command history.

---

### **Multi-Token Commands**
These commands allow you to perform more complex operations.

- **`NEW`**: Create a new collection, cluster, record, or user.
- **`ERASE`**: Delete a collection, cluster, or record.
- **`RENAME`**: Rename an existing object.
- **`FETCH`**: Retrieve data from a collection, cluster, or record.
- **`SET`**: Assign a value to a record or configuration.
- **`BACKUP`**: Create a backup of a specific collection.
- **`PURGE`**: Removes all data from an object while maintining the object structure.
- **`COUNT`**: Returns the number of objects within a scope. Paired with the plural form of the object type (e.g., `RECORDS`, `CLUSTERS`).
- **`SIZE_OF`**: Returns the size in bytes of an object.
---

### **Modifiers in Commands**

Modifiers adjust the behavior of commands. The current supported modifiers are:
- **`TO`**: Used to assign a new value or name (e.g., renaming an object or setting a record's value).
- **`OF_TYPE`**: Specifies the type of a new record (e.g., INT, STR).

Examples:
```bash
NEW RECORD foo.bar.baz OF_TYPE INT
RENAME CLUSTER foo.bar TO foo.baz
SET CONFIG help TO verbose
```


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


## **Usage Examples**
   ```bash
   # Create a new collection:
   NEW COLLECTION staff
   # Create a new cluster:
   NEW CLUSTER staff.engineers
   # Create a new record:
   NEW RECORD staff.engineers.lead OF_TYPE STR
   # Set a record value:
   SET RECORD staff.engineers.lead TO "John Doe"
   # Fetch the record value:
   FETCH RECORD staff.engineers.lead
   # Rename a cluster:
   RENAME CLUSTER staff.engineers TO developers
   # Get the size of a cluster:
   SIZE_OF CLUSTER staff.developers
   # Erase a record:
   ERASE RECORD staff.developers.lead
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
  - `RESTORE`: Undo recent changes
  - `MERGE`: Combine multiple collections or clusters into one
  - `ALL`: Perform operations on all objects within a scope
- Support for additional data types
- Enhanced security (database encryption/decryption, secure deletion)
- Commnad chaining for complex operations
- Server-based architecture
- External API support for popular programming languages
- Windows support
- Integration with the planned FeatherQL query language!

---


## **Contributing**

Please refer to the [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines on how to contribute.

---

## **License**

OstrichDB is released under the **Apache License 2.0**. For the full license text, see [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).
