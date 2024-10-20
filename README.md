# **OstrichDB**

OstrichDB is a lightweight, document-based **NoSQL key-value database** written in the **Odin programming language**. It focuses on **simplicity** and is designed for **local data testing and manipulation**, making it an ideal solution for developers looking for a straightforward database without the need for complex setups. With a flexible command structure, OstrichDB makes it easy to manage data using both **single-token and multi-token commands**. 

---

## **Features**

1. **Serverless Architecture**:  
   OstrichDB does not require any server setup. You can run it locally without additional services, which makes it perfect for **local development environments**.

2. **User Authentication**:  
   Basic **user authentication** ensures that only authorized users can access or modify data.

3. **JSON-like Hierarchical Data Structure**:  
   The data is organized in a **nested hierarchy** of records, clusters, and collections, similar to JSON structures, allowing easy organization of data.

4. **Command-Based Operations**:  
   The use of intuitive **commands** helps you perform complex operations quickly, making it ideal for developers who want fast and readable commands.

5. **Focus Mode**:  
   OstrichDB allows setting a **context** for operations, meaning once you focus on a specific object, subsequent commands operate within that context until changed.

6. **Basic CRUD Operations**:  
   Supports **Create, Read, Update, Delete (CRUD)** operations for managing data.

7. **Ongoing Mac Support**:  
   While OstrichDB is designed for **Linux**, future versions will bring **Mac compatibility** with updates to the Odin Lang version.

---

## **Data Structure Overview**

OstrichDB organizes data into three levels:

- **Records**: The smallest unit of data (e.g., user name, age, or product details).  
- **Clusters**: Groups of related records (e.g., all information about a person or product).  
- **Collections**: Containers that hold multiple clusters (e.g., a database holding multiple product categories).

This structure makes it easy to store and retrieve logically grouped data.

---

## **Command Structure (ATOMs)**

In OstrichDB, **commands** are broken down into **four types of tokens**, called **ATOMs**, to improve readability and ensure clear instructions:

1. **(A)ction Token**: Specifies the operation to perform (e.g., `NEW`, `ERASE`, `RENAME`).  
2. **(T)arget Token**: Identifies the type of object being acted upon (e.g., `CLUSTER`, `RECORD`).  
3. **(O)bject Token**: The name or identifier of the target object (e.g., `foo`, `bar`).  
4. **(M)odifier**: Additional parameters that change the behavior of the command (e.g., `WITHIN`, `TO`).

---

### **Command Example**

```bash
NEW CLUSTER foo WITHIN COLLECTION bar
```

Explanation:  
- **`NEW`**: Create a new object (Action token).  
- **`CLUSTER`**: The type of object to be created (Target token).  
- **`foo`**: Name of the new cluster (Object token).  
- **`WITHIN`**: A modifier indicating that the cluster should belong to a collection.  
- **`COLLECTION bar`**: The collection where the new cluster will be created.

---

## **Supported Commands**

### **Single-Token Commands**  
These commands perform simple tasks without needing additional arguments.

- **`VERSION`**: Displays the current version of OstrichDB.
- **`LOGOUT`**: Logs out the current user.
- **`EXIT`**: Ends the session and closes the database.
- **`UNFOCUS`**: Removes focus from the current data structure, resetting the context.
- **`HELP`**: Displays general help information or detailed help when chained with specific tokens.
- **`TREE`**: Displays the entire data structure in a tree format.
- **`CLEAR`**: Clears the console screen.
- **`HISTORY`**: Shows the command history of the current session.

---

### **Multi-Token Commands**  
These commands allow you to perform more complex operations by specifying **targets and objects**.

- **`NEW`**: Create a new collection, cluster, or record.
- **`ERASE`**: Delete a collection, cluster, or record.
- **`RENAME`**: Rename an existing object.
- **`FETCH`**: Retrieve data from a collection, cluster, or record.
- **`SET`**: Assign a value to a record or configuration.
- **`BACKUP`**: Create a backup of a specific collection.
- **`FOCUS`**: Set the current context to a specific collection or cluster, limiting operations to that context.

---

### **Modifiers in Commands**

Modifiers adjust the behavior of commands, making them more precise. Some commonly used modifiers include:

- **`WITHIN`**: Specifies the parent object for a target (e.g., a cluster within a collection).  
- **`TO`**: Used to assign a new value or name (e.g., rename a record).  
- **`OF_TYPE`**: Specifies the type of a new record (e.g., INT, STR).

Example:
```bash
NEW RECORD age OF_TYPE INT WITHIN CLUSTER personal_info
```

---

## **Installation Guide**

### **Prerequisites:**
- A **Linux environment** (Mac support coming soon).
- **Clang and LLVM** installed.
- **Odin programming language** set up and added to the system PATH.

### **Installation Steps:**

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/Solitude-Software-Solutions/OstrichDB.git
   ```

2. **Navigate to the Source Directory**:
   ```bash
   cd OstrichDB/src
   ```

3. **Build and Run OstrichDB**:
   ```bash
   odin build main && ./main.bin
   ```

---

## **Usage Examples**

1. **Create a New Cluster**:
   ```bash
   NEW CLUSTER sales WITHIN COLLECTION business_data
   ```

2. **Fetch All Data from a Collection**:
   ```bash
   FETCH COLLECTION business_data
   ```

3. **Rename a Record**:
   ```bash
   RENAME RECORD old_name TO new_name
   ```

4. **Backup a Collection**:
   ```bash
   BACKUP COLLECTION business_data
   ```

5. **Set the Value of a Record**:
   ```bash
   SET RECORD age TO 30
   ```

---

## **Future Plans**

- **Enhanced Operations**: Add more advanced operations on records and clusters.
- **UI Improvements**: A more user-friendly interface with error handling.
- **File Compression**: Database file zipping and compression.
- **Role-Based Access Control**: Multi-user access with roles and permissions.
- **Windows and macOS Support**: Ensure compatibility across all platforms.
- **New Commands**:
  - **`STATS`**: Show database statistics.
  - **`IMPORT` / `EXPORT`**: Support for JSON, CSV, and other formats.
  - **`VALIDATE`**: Verify data integrity.
  - **`LOCK` / `UNLOCK`**: Manage write permissions.
  - **`RESTORE`**: Revert recent changes.
  - **`SORT`**: Sort clusters or records.
  - **`MERGE`**: Combine multiple collections or clusters.
  - **`COUNT`**: Display the number of objects within a scope.

---

## **Contributing**

We welcome contributions! Please refer to the [CONTRIBUTING.md](CONTRIBUTING.md) file for detailed guidelines on how to contribute.

---

## **License**

OstrichDB is released under the **Apache License 2.0**. For the full license text, see [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).

---

## **Support & Feedback**

For questions or issues, feel free to:

- Open an issue on the [GitHub Issues](https://github.com/Solitude-Software-Solutions/OstrichDB/issues) page.
- Join the discussion on our **community forums** (coming soon).

---

## **Acknowledgments**

Special thanks to **Marshall aka SchoolyB** for initiating and driving the development of OstrichDB.

_Last updated: October 20, 2024._
