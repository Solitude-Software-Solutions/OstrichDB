# OstrichDB Architecture

## Detailed Overview

OstrichDB is a lightweight NoSQL, NoJSON, document-based database management system.
It is written primarily in the Odin programming language, with some parts such as the NLP written in Go.
OstrichDB is designed to be a simple, easy-to-use, and blazingly fast. OstrichDB
uses its own custom databse format and file extendion `.ost` to store data.
Data within OstrichDB is stored in 3 components, Collections, Clusters, and Records.
Collections are the top-level data structures in OstrichDB, they are the actual
database files. Collections can be made up of a single or several Clusters.
Clusters are the middle-level data structureare JSON-like objects. Each Cluster has a name
and an ID. Clusters can be made up of a single or serveral Records. Records are the lowest-level
and most granular data structure in OstrichDB. Records are similiar to key-value pairs in
other databases but with a twist; each record is given and explicit data type in addition
to a name and value. This allows for better data integrity and type checking. OstrichDB
also has a built-in NLP engine that allows for natural language queries to be made against
any collection.

## Components

### Data Structures Within OstrichDB
- **Collections**:
  - The top-level data structure in OstrichDB. Collections are the actual database files.
  - Collections are encrypted using AES-256 encryption while at rest.
  - Before any "constructive" operation on a collection, it is decrypted and its data and metadata is validated.

- **Clusters**:
  - The middle-level data structure in OstrichDB. In plaintext Clusters resemble JSON-like objects but act almost like tables in a relational database.
  - Each Cluster MUST has a name and an ID. The name is typically a classifier for data to be stored in the cluster.
  - Clusters can be made up of a single or serveral Records.

- **Records**:
  - The lowest-level and most granular data structure in OstrichDB.
  - Records are given a name, data type, and value. Example of a record: `foo :STRING: "Hello, World!"`.

### The Command Line Interface (CLI)
- The CLI is written in Odin and is the main entry point for interacting with OstrichDB.
- There are a plethora of commands available in the CLI to interact with OstrichDB.
- Commands are a group of tokens that are parsed via the built-in parser. Once parsed, the command is checked for validity and then executed.
- Commands follow an internal structure called "CLPs"( Command Token, Location Token(s), Parameter Token(s) ).
- Each "constructive" or "destructive" command must follow the CLP structure and be valid.
- There are some commands that are niether "constructive" nor "destructive"
- The OstrichDB command line uses dot notation to traverse the database structure. For example, `use mydb` would be the same as `NEW foo.bar`, would create a new cluster `bar` in the collection `foo`.
- If a command is not valid, the CLI will return an error message and the user will have to re-enter the command.
- "Destructive" commands must be confirmed by the user before they are executed.
- The built-in `HELP` command can be used to get simple or detailed help on any and all commands.

### The OstrichDB HTTP Server
- OstrichDB has a built-in HTTP server. Although very crude, it enables users to interact with OstrichDB via its API layer.
- The HTTP server runs on port `8042`.
- There are example clients in the `clients` directory that can be used to interact with the HTTP server.
