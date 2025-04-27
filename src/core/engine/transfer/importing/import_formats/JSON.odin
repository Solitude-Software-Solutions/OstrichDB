package import_formats

import "../../../utils"
import "../../const"
import "../../types"
import "../data"
import "../data/metadata"
import "../security"
import "core:encoding/csv"
import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            This file contains the logic for importing JSON data into OstrichDB
*********************************************************/

// Represents a flattened JSON value with type information
// Move to types.odin when done testing this shit
FlattenedValue :: struct {
    valueType: string,  // "string", "integer", "float", "boolean", "array", etc.
    value: string,      // String representation of the value
}

JSON__IMPORT_JSON_FILE ::proc(name:string, fullPath:..string) -> (success:bool){
    using data
    success = false

    fmt.println("Please enter the desired name for the new OstrichDB collection.")
	desiredColName := utils.get_input(false)

	fmt.printfln(
		"Is the name %s%s%s correct?[Y/N]",
		utils.BOLD_UNDERLINE,
		desiredColName,
		utils.RESET,
	)
	colNameConfirmation := utils.get_input(false)

	if colNameConfirmation == "y" || colNameConfirmation == "Y" {

	} else if colNameConfirmation == "n" || colNameConfirmation == "N" {
		fmt.println("Please try again")
		JSON__IMPORT_JSON_FILE(name, fullPath[0])
	} else {
		fmt.println("Invalid repsonse given. Please try again")
		JSON__IMPORT_JSON_FILE(name, fullPath[0])
	}

}


//flattens a JSON value into a map with dot notation. this helps with
JSON__FLATTEN_JSON_VALUE::proc(prefix:string ,value: json.Value, result: ^map[string]FlattenedValue){

    switch v in value.(json.String){
    case json.Object:
        for key, val in v{
            newPrefix := prefix == "" ? key : fmt.tprintf("%s%s", prefix, key)
            JSON__FLATTEN_JSON_VALUE(newPrefix, val, result)
        }
    case json.Array:
        if len(v) > 0 {
            arrayType:= ""
            isHomogeneous := true
            isSimpleType := true

            for i := 0; i < len(v); i +=1{
                currentType:= JSON__GET_SIMPLE_JSON_TYPE(v[i])

                if i ==  0 {
                    arrayType = currentType
                }else if currentType != arrayType {
                    isHomogeneous = false
                    break
                }
            }

            if isHomogeneous && isSimpleType {
                arrayValues:= make([dynamic]string)
                defer delete(arrayValues)

                for element in v {
                    append(&arrayValues, JSON__GET_JSON_VALUE_AS_STRING(element))
                }
                arrayStr:= strings.join(arrayValues[:], ",")
                result[prefix] = FlattenedValue{
                    valueType = fmt.tprintf("%s_ARRAY", strings.to_upper(arrayType)), //todo: this is wrong
                    value = arrayStr,
                }
            } else {
                // Flatten with indices
                for i := 0; i < len(v); i += 1 {
                    newPrefix := fmt.tprintf("%s[%d]", prefix, i)
                    JSON__FLATTEN_JSON_VALUE(newPrefix, v[i], result)
                }
            }
        }
    case:
    // Handle primitive types
        simpleType := JSON__GET_SIMPLE_JSON_TYPE(value)
        if simpleType != "" {
            result[prefix] = FlattenedValue{
                valueType = strings.to_upper(simpleType),
                value = JSON__GET_JSON_VALUE_AS_STRING(value),
            }
        }
    }
}


// Gets the simple type name of a JSON value
JSON__GET_SIMPLE_JSON_TYPE :: proc(value: json.Value) -> string {
    using json

    #partial switch v in value.value {
    case String:
        return "string"
    case Integer:
        return "integer"
    case Float:
        return "float"
    case Boolean:
        return "boolean"
    case Null:
        return "null"
    case:
        return ""  // Complex types return empty string
    }
}

// Converts a JSON value to a string representation
JSON__GET_JSON_VALUE_AS_STRING:: proc(value: json.Value) -> string {
    using json

    #partial switch v in value.value {
    case String:
        return v
    case Integer:
        return fmt.tprintf("%d", v)
    case Float:
        return fmt.tprintf("%f", v)
    case Boolean:
        return v ? "true" : "false"
    case Null:
        return "null"
    case:
        return ""
    }
}

