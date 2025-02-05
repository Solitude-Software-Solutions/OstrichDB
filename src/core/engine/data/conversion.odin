package data
import "../../../utils"
import "../../const"
import "../data"
import "core:fmt"
import "core:strconv"
import "core:strings"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//


//The following conversion procs are used to convert the passed in record value to the correct data type
//Originally these where all in one single proce but that was breaking shit.
OST_CONVERT_RECORD_TO_INT :: proc(rValue: string) -> (int, bool) {
	val, ok := strconv.parse_int(rValue)
	if ok {
		return val, true
	} else {
		fmt.printfln("Failed to parse int")
		return 0, false
	}
}

OST_CONVERT_RECORD_TO_FLOAT :: proc(rValue: string) -> (f64, bool) {
	val, ok := strconv.parse_f64(rValue)
	if ok {
		return val, true
	} else {
		fmt.printfln("Failed to parse float")
		return 0.0, false
	}
}

OST_CONVERT_RECORD_TO_BOOL :: proc(rValue: string) -> (bool, bool) {
	lower_str := strings.to_lower(strings.trim_space(rValue))
	if lower_str == "true" {
		return true, true
	} else if lower_str == "false" {
		return false, true
	} else {
		//no need to do anything other than return here. Once false is returned error handling system will do its thing
		return false, false
	}
}


//The following converstion procs take in the string from the command line, splits it by commas
//appends each split value to an array. Easy Day
//Note: Memory is freed in the procecudure that calls these conversion procs
OST_CONVERT_RECORD_TO_INT_ARRAY :: proc(rValue: string) -> ([dynamic]int, bool) {
	newArray := make([dynamic]int)
	strValue := OST_PARSE_ARRAY(rValue)
	for i in strValue {
		val, ok := strconv.parse_int(i)
		append(&newArray, val)
	}
	return newArray, true
}


OST_CONVERT_RECORD_TO_FLT_ARRAY :: proc(rValue: string) -> ([dynamic]f64, bool) {
	newArray := make([dynamic]f64)
	strValue := OST_PARSE_ARRAY(rValue)
	for i in strValue {
		val, ok := strconv.parse_f64(i)
		append(&newArray, val)
	}
	return newArray, true
}

OST_CONVERT_RECORD_TO_BOOL_ARRAY :: proc(rValue: string) -> ([dynamic]bool, bool) {
	newArray := make([dynamic]bool)
	strValue := OST_PARSE_ARRAY(rValue)
	for i in strValue {
		lower_str := strings.to_lower(strings.trim_space(i))
		if lower_str == "true" {
			append(&newArray, true)
		} else if lower_str == "false" {
			append(&newArray, false)
		} else {
			fmt.printfln("Failed to parse bool array")
			return newArray, false
		}
	}
	return newArray, true
}

OST_CONVERT_RECORD_TO_STRING_ARRAY :: proc(rValue: string) -> ([dynamic]string, bool) {
	newArray := make([dynamic]string)
	strValue := OST_PARSE_ARRAY(rValue)
	for i in strValue {
		append(&newArray, i)
	}
	return newArray, true
}

//Dont really need the following 3 procs, could just call the parse procs where needed but fuck it - Marshall Burns
OST_CONVERT_RECORD_TO_DATE :: proc(rValue: string) -> (string, bool) {
	date, err := OST_PARSE_DATE(rValue)
	if err == 0 {
		return date, true
	} else {
		return "", false
	}
}

OST_CONVERT_RECORD_TO_TIME :: proc(rValue: string) -> (string, bool) {
	time, err := OST_PARSE_TIME(rValue)
	if err == 0 {
		return time, true
	} else {
		return "", false
	}
}

OST_CONVERT_RECORD_TO_DATETIME :: proc(rValue: string) -> (string, bool) {
	dateTime, err := OST_PARSE_DATETIME(rValue)
	if err == 0 {
		return dateTime, true
	} else {
		return "", false
	}
}

//Handles the conversion of a record value from an old type to a new type
//this could also go into the records.odin file but will leave it here for now
OST_CONVERT_VALUE_TO_NEW_TYPE :: proc(value, oldT, newT: string) -> (string, bool) {
	if len(value) == 0 {
		return "", true
	}
	oldVIsArray := strings.has_prefix(oldT, "[]")
	newVIsArray := strings.has_prefix(newT, "[]")


	//handle array conversion
	if oldVIsArray && newVIsArray { 	//if both are arrays
		values := OST_PARSE_ARRAY(value) //parse the array
		newValues := make([dynamic]string) //create a new array to store the converted values
		defer delete(newValues)

		for val in values { 	//for each value in the array
			converted, ok := OST_CONVERT_SINGLE_VALUE(val, oldT, newT) //convert the value
			if !ok {
				return "", false
			}
			append(&newValues, converted) //append the converted value to the new array
		}
		return strings.join(newValues[:], ","), true
	}

	//handle single value conversion
	if !oldVIsArray && newVIsArray { 	//if the old value is not an array and the new value is
		converted, ok := OST_CONVERT_SINGLE_VALUE(value, oldT, newT) //convert the single value
		if !ok {
			return "", false
		}
		return converted, true
	}

	//handle array to single value conversion
	if oldVIsArray && !newVIsArray { 	//if the old value is an array and the new value is not
		values := OST_PARSE_ARRAY(value) //parse the array
		if len(values) > 0 { 	//if there are values in the array
			firstValue := OST_STRIP_ARRAY_BRACKETS(values[0])
			return OST_CONVERT_SINGLE_VALUE(firstValue, oldT, newT)
		}
		return "", true
	}

	//if both are single values
	return OST_CONVERT_SINGLE_VALUE(value, oldT, newT)
}


//filthy fucking code I am so sorry - Marshall Burns aka @SchoolyB
OST_CONVERT_SINGLE_VALUE :: proc(
	value: string,
	oldType: string,
	newType: string,
) -> (
	string,
	bool,
) {
	using const

	//if the types are the same, no conversion is needed
	if oldType == newType {
		return value, true
	}

	switch (newType) {
	case STRING:
		//New type is STRING
		switch (oldType) {
		case INTEGER, FLOAT, BOOLEAN:
			//Old type is INTEGER, FLOAT, or BOOLEAN
			value := utils.append_qoutations(value)
			return value, true
		case STRING_ARRAY:
			value := strings.trim_prefix(value, "[")
			value = strings.trim_suffix(value, "]")
			if len(value) > 0 {
				return utils.append_qoutations(value), true
			}
			return "\"\"", true
		case:
			return "", false
		}
	case INTEGER:
		//New type is INTEGER
		switch (oldType) {
		case STRING:
			//Old type is STRING
			_, ok := strconv.parse_int(value, 10)
			if !ok {
				return "", false
			}
			return value, true
		case:
			return "", false
		}
	case FLOAT:
		//New type is FLOAT
		switch (oldType) {
		case STRING:
			//Old type is STRING
			_, ok := strconv.parse_f64(value)
			if !ok {
				return "", false
			}
			return value, true
		case:
			return "", false
		}
	case BOOLEAN:
		//New type is BOOLEAN
		switch (oldType) {
		case STRING:
			//Old type is STRING
			lower_str := strings.to_lower(strings.trim_space(value))
			if lower_str == "true" || lower_str == "false" {
				return lower_str, true
			}
			return "", false
		case:
			return "", false
		}
	//ARRAY CONVERSIONS
	case STRING_ARRAY:
		// New type is STRING_ARRAY
		switch (oldType) {
		case STRING:
			// Remove any existing quotes
			value := strings.trim_prefix(strings.trim_suffix(value, "\""), "\"")
			// Format as array with proper quotes
			return value, true
		case:
			return "", false
		}
	case INTEGER_ARRAY:
		// New type is INTEGER_ARRAY
		switch (oldType) {
		case INTEGER:
			// Remove any existing quotes
			value := strings.trim_prefix(strings.trim_suffix(value, "\""), "\"")
			// Format as array with proper quotes
			return value, true
		case:
			return "", false
		}
	case BOOLEAN_ARRAY:
		// New type is BOOLEAN_ARRAY
		switch (oldType) {
		case BOOLEAN:
			// Remove any existing quotes
			value := strings.trim_prefix(strings.trim_suffix(value, "\""), "\"")
			// Format as array with proper quotes
			return value, true
		case:
			return "", false
		}
	case FLOAT_ARRAY:
		// New type is FLOAT_ARRAY
		switch (oldType) {
		case FLOAT:
			// Remove any existing quotes
			value := strings.trim_prefix(strings.trim_suffix(value, "\""), "\"")
			// Format as array with proper quotes
			return value, true
		case:
			return "", false
		}
	case:
		return "", false
	}

	return "", false
}


//handles a records type and value change
OST_HANDLE_TYPE_CHANGE :: proc(colPath, cn, rn, newType: string) -> bool {
	using data

	// fmt.printfln("%s is getting  newType: %s", #procedure, newType) //debugging
	oldType, _ := OST_GET_RECORD_TYPE(colPath, cn, rn)
	recordValue := OST_READ_RECORD_VALUE(colPath, cn, oldType, rn)

	new_value, success := OST_CONVERT_VALUE_TO_NEW_TYPE(recordValue, oldType, newType)
	if !success {
		utils.log_err("Could not convert value to new type", #procedure)
		return false
	} else {

		typeChangeSucess := OST_CHANGE_RECORD_TYPE(colPath, cn, rn, recordValue, newType)
		valueChangeSuccess := OST_SET_RECORD_VALUE(colPath, cn, rn, new_value)
		if !typeChangeSucess || !valueChangeSuccess {
			utils.log_err("Could not change record type or value", #procedure)
			return false
		} else if typeChangeSucess && valueChangeSuccess {
			return true
		}
	}

	return false
}

OST_STRIP_ARRAY_BRACKETS :: proc(value: string) -> string {
	value := strings.trim_prefix(value, "[")
	value = strings.trim_suffix(value, "]")
	return strings.trim_space(value)
}
