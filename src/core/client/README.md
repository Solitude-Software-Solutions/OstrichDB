# OstrichDB API Client Examples

This directory contains example clients demonstrating how to interact with the OstrichDB API layer in various programming languages. These examples are meant to serve as references and starting points for building your own client implementations.

## Available Examples:

- [Python Client](./examples/python-client.py)
- [JavaScript Client](./examples/js-client.js)
- [Go Client](./examples/go-client.go)

## Future Client Examples Written In:

- Rust
- C/C++
- Swift
- Ruby
- PHP

## Prerequisites
Some current examples and possibly future examples require additional libraries or dependencies.
Please ensure that you have the proper dependencies installed for each example.


### Python
- [-requests](https://pypi.org/project/requests/)

### JavaScript
No additional dependencies are required as it useds the built-in [fetch](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch) API.

### Go
No additional dependencies are required as it uses the built-in [net/http](https://pkg.go.dev/net/http) package.

### Odin
No additional dependencies are required as it uses the built-in [core:net](https://pkg.odin-lang.org/core/net/) package.

## Usage
1. Ensure the OstrichDB server is running. It runs on: `localhost:8042`
2. Choose the example in your preferred language.
3. If necessary, install the required dependencies.
4. If necessary, modify the examples code to match your specific use case.
5. Follow any instructions provided in the example.
6. Run the example client.


# Building Your Own Client
The above examples demonstrate the basic patterns for:
- Making HTTP requests to OstrichDB endpoints
- Handling responses and errors from the server
- Working with OstrichDB collections, clusters, and records

Key points to remember when building your own client:
- Use appropriate HTTP methods (GET, POST, PUT, DELETE, HEAD)
- Set content-type headers to "text/plain"
- Follow the URL pattern structure:
    - Collections: `/c/{collection_name}`
    - Clusters: `/c/{collection_name}/cl/{cluster_name}`
    - Records: `/c/{collection_name}/cl/{cluster_name}/r/{record_name}` sometimes with query parameters
