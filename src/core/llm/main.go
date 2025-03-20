package main

import "C"
import "fmt"

//export hello
func hello() {
	fmt.Println("Hello, world! I am running Go-lang code within a program written in Odin-lang!")
}

//export bye
func bye() {
	fmt.Println("Goodbye, world...")
}

func main() {}
