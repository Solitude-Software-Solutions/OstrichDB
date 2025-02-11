package transfer

import "../../../utils"
import "../../const"
import "core:encoding/csv"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
*********************************************************/

/*
    This file holds all source code for inferencing data types from imported data files.
    For .csv files, the inferencing is done by reading the first row of the file. Record
    names such as "id", "name", "age", etc. are used to infer the data type of the records

    if a record name is date,datetime, time or any variation of those, the record is inferred
    then passed to the ./transfer/external_conversion.odin file to be converted to the format that OstrichDB
    uses for that particular data type.

    Extremely ugly but until MVP is reached, this is the way it will be done.
*/


commonInts := []string {
	"id",
	"age",
	"year",
	"month",
	"day",
	"hour",
	"minute",
	"second",
	"count",
	"quantity",
	"number",
	"num",
	"int",
	"integer",
	"index",
	"position",
	"pos",
	"size",
	"length",
	"len",
	"index",
	"idx",
	"int",
	"integer",
	"int8",
	"int16",
	"int32",
	"int64",
	"bigint",
	"long",
	"short",
	"byte",
	"uint",
	"uint8",
	"uint16",
	"uint32",
	"uint64",
	"smallint",
	"tinyint",
	"total",
	"sum",
	"offset",
	"limit",
	"max",
	"min",
	"level",
	"rank",
	"order",
	"priority",
	"status",
	"type",
	"flag",
	"counter",
	"increment",
	"decrement",
	"step",
}

commonFloats := []string {
	"float",
	"double",
	"decimal",
	"real",
	"float32",
	"float64",
	"single",
	"number",
	"long_double",
	"half",
	"fixed",
	"numeric",
	"currency",
	"price",
	"amount",
	"rate",
	"percentage",
	"percent",
	"ratio",
	"average",
	"avg",
	"balance",
	"score",
	"temp",
	"latitude",
	"lat",
	"longitude",
	"lng",
	"lon",
}

commonBools := []string {
	"is",
	"has",
	"can",
	"should",
	"will",
	"was",
	"had",
	"enabled",
	"disabled",
	"active",
	"inactive",
	"valid",
	"invalid",
	"visible",
	"hidden",
	"success",
	"error",
	"done",
	"completed",
	"finished",
	"started",
	"running",
	"paused",
	"stopped",
	"ready",
	"busy",
	"available",
	"exists",
	"found",
	"matched",
	"verified",
	"approved",
	"confirmed",
	"accepted",
	"rejected",
	"blocked",
	"locked",
	"empty",
	"full",
	"open",
	"closed",
	"connected",
	"disconnected",
	"loaded",
	"initialized",
	"configured",
	"signed_in",
	"logged_in",
	"remembered",
	"forgotten",
	"selected",
	"checked",
	"flagged",
	"marked",
	"deleted",
	"archived",
	"published",
	"draft",
	"debug",
	"production",
	"testing",
	"cached",
	"dirty",
	"synced",
}
//Everything else will be interpreted as a string


// Takes the passed in record names, iterates over them and infers a data type, returns a map of the inferred data types
// NOTE: Only used on the first row of a .csv file
OST_INFER_CSV_RECORD_TYPES :: proc(
	csvRecordNames: [dynamic]string,
) -> (
	success: bool,
	typeMap: map[string]string,
) {
	using const
	success = false

	intRes, intNames := check_if_common__(csvRecordNames, commonInts)
	if intRes {
		for name in intNames {
			typeMap[name] = INTEGER
			success = true
		}
	}

	floatRes, floatNames := check_if_common__(csvRecordNames, commonFloats)
	if floatRes {
		for name in floatNames {
			typeMap[name] = FLOAT
			success = true
		}
	}

	boolRes, boolNames := check_if_common__(csvRecordNames, commonBools)
	if boolRes {
		for name in boolNames {
			typeMap[name] = BOOLEAN
			success = true
		}
	}

	//Anything else is defaulted to a string data type
	for name in csvRecordNames {
		if _, ok := typeMap[name]; !ok {
			typeMap[name] = STRING
			success = true
		}
	}

	// fmt.printfln("TypeMap: %v", typeMap) //debugging
	return success, typeMap
}


//UTILS

//takes in the passed in string and converts it to:
//Capital, Uppercase, lowercase, camelCase, snake_case, kebab-case, UpperCamelCase, UPPER_SNAKE_CASE, UPPER_KEBAB_CASE
convert_case :: proc(str: string) -> [dynamic]string {
	arr: [dynamic]string
	C: string
	if !is_first_letter_capital(str) {
		C = to_capital(str)
	}

	U := strings.to_upper(str)
	l := strings.to_lower(str)
	cml := strings.to_camel_case(str)
	snk := strings.to_snake_case(str)
	keb := strings.to_kebab_case(str)
	CML := strings.to_upper_camel_case(str)
	SNK := strings.to_upper_snake_case(str)
	KEB := strings.to_upper_kebab_case(str)


	append(&arr, C)
	append(&arr, U)
	append(&arr, l)
	append(&arr, cml)
	append(&arr, snk)
	append(&arr, keb)
	append(&arr, CML)
	append(&arr, SNK)
	append(&arr, KEB)

	// fmt.printfln("Arr: %v", arr) //debugging
	return arr
}

is_first_letter_capital :: proc(s: string) -> bool {
	if len(s) == 0 {
		return false
	}
	// Check if first character is in range of uppercase ASCII letters
	return s[0] >= 'A' && s[0] <= 'Z'
}
to_capital :: proc(str: string) -> string {
	//This is shit. I need to find a new hobby for God's Sake
	//convert the first letter to uppercase
	C := strings.to_upper(strings.truncate_to_byte(str, str[1]))
	lowC := strings.to_lower(C)

	//split the string at the first letter
	cut := strings.split(str, lowC)

	//append the rest of the string to the first letter
	newCapStr := strings.concatenate([]string{C, cut[1]})
	return newCapStr
}


check_if_common__ :: proc(
	csvRecordNames: [dynamic]string,
	arr: []string,
) -> (
	bool,
	[dynamic]string,
) {
	isCommon := false
	retNames: [dynamic]string
	for name in csvRecordNames {
		for i in arr {
			for j in convert_case(name) {
				if fmt.tprintf("%s", j) == fmt.tprintf("%s", i) {
					isCommon = true
					append(&retNames, name)
				}
			}
		}

	}
	return isCommon, retNames
}
