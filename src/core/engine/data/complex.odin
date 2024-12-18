package data
import "core:fmt"
import "core:strings"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//

//This file is used to define the structure of the complex data types and how OstrichDB will handle them


//create a new array that will be used to store the values of an array typed record
// NewArray := new(OST_ARRAY)
// OST_ARRAY :: struct {
// 	values: [dynamic]string,
// }

//create a new object that will be used to store the values of an object typed record
// NewObject := new(OST_OBJECT)
// OST_OBJECT :: struct {
// 	values: map[string]string,
// }

//essentially will look over the passed in string and as long as its encased in [] it will split the string into an array based on the commas
OST_PARSE_ARRAY :: proc(strArr: string) -> []string {
	result := strings.split(strArr, ",")
	for i in result {
		fmt.println(i)
	}
	return result
}

//TODO: I'd didnt end up using any of the shit below lol
//cretaes an array that Odin understands
// OST_CONSTRUCT_ARRAY :: proc() -> ^OST_ARRAY {
// 	NewArray := new(OST_ARRAY)
// 	return NewArray
// }


// OST_STORE_VALUE_IN_ARRAY :: proc(NewArray: ^OST_ARRAY, value: string) {
// 	values := append(&NewArray.values, value)
// }

// //converts the array that Odin understands into a string that can be stored in a database
// OST_DECONSTRUCT_ARRAY :: proc(arr: ^OST_ARRAY) -> string {
// 	for value in arr.values {
// 		return strings.clone(value)
// 	}
// 	OST_DELETE_ARRAY(arr.values)
// 	return ""
// }

// //frees the memory that the passed in array is using DONT FORGET TO CALL THIS!!!!
// OST_DELETE_ARRAY :: proc(arr: [dynamic]string) {
// 	delete(arr)
// }
//takes in a key and a value string and adds it to a map then returns the map
// OST_CONSTRUCT_OBJECT :: proc(key, value: string) -> map[string]string {
// 	//ensure all values are all the same type i.e  string,bool,int, etc

// 	return map[string]string{}
// }

// //takes in a map of strings and returns it as one string.
// //this will then be stored as the value for a record in a database
// //although the db deconstructs this as a string to store it,
// //it will interepret the string as an array when reading the value back out
// OST_DECONSTRUCT_OBJECT :: proc(obj: map[string]string) -> string {
// 	for key, value in arr {
// 		return value
// 	}
// }
