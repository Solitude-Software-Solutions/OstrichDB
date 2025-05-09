#!/bin/bash

echo "Building NLP library.....Please wait....."

go build -buildmode c-shared -o nlp.dylib

odin build nlp.odin -file

echo "Done building NLP library!"
