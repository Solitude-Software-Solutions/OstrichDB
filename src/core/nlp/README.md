# Getting The OstrichDB NLP Module Working

## Setup
1. Ensure Ollama is installed and setup properly
2. If it doesn't exist, create a `ModelFile` in the `OstrichDB/core/nlp` dir
3. Navigate to the directory where the `ModelFile` is located
3. Run `ollama create ostrichdb1 -f ModelFile` to generate the model

The next two stpes can be done depending on how you want to interact with the NLP module

### Using Go code
4. Build the Go code using `go build`
5. Run the generated Go executable `./main`

### Using Ollama Itself
4. Run `ollama run ostrichdb1` to run the model


# Importing Golang Code Into Odin Code For OstrichDB

## Setup

1. Ensure you have Go Installed and Setup properly
2. Run `go mod init main` (optional if the project is not already initialized)
3. Run `go mod tidy` to install dependencies(optional since there are no dependencies at this point)
4. Run `go build -buildmode c-shared -o nlp.dylib`(For macOS) **Note:** Ensure the package name in your go file is `main`
5. Run `odin build nlp.odin -file && ./nlp` (For macOS)

**Note:** When you make changes to either the Go or Odin code, you need to delete the following files:
- `nlp.dylib` (For macOS)
- `nlp.h` (For all platforms)
- `nlp` Or whatever executable file Odin built

Then you need to re-run steps 4 and 5 from above.

This file and its instructions will change as the project evolves. These are just my notes on how I got this working.
