package data
import "../../../utils"
import "../../const"
import "../../types"
import "../data"
import "core:fmt"
import "core:strconv"
import "core:strings"
import "core:unicode/utf8"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            Contains logic for how OstrichDB handles'complex' data types.
            This includes arrays, dates, times, datetimes, and UUIDs.
*********************************************************/

//split the passed in "array" which is actually a string from the command line at each comma, store into a slice and return it
OST_PARSE_ARRAY :: proc(strArr: string) -> []string {
	result := strings.split(strArr, ",")
	return result
}

//checks that array values the user wants to store in a record is the correct type
OST_VERIFY_ARRAY_VALUES :: proc(rType, strArray: string) -> bool {
	using const

	verified := false
	//retrieve the record type
	arrayValues := OST_PARSE_ARRAY(strArray)

	switch (rType) {
	case INTEGER_ARRAY:
		for i in arrayValues {
			_, parseSuccess := strconv.parse_int(i)
			verified = parseSuccess
		}
		return verified
	case FLOAT_ARRAY:
		for i in arrayValues {
			_, parseSuccess := strconv.parse_f64(i)
			verified = parseSuccess
		}
		return verified
	case BOOLEAN_ARRAY:
		for i in arrayValues {
			_, parseSuccess := strconv.parse_bool(i)
			verified = parseSuccess
		}
		return verified
	case DATE_ARRAY:
		for i in arrayValues {
			_, parseSuccess := OST_PARSE_DATE(i)
			verified = parseSuccess
		}
		return verified
	case TIME_ARRAY:
		for i in arrayValues {
			_, parseSuccess := OST_PARSE_TIME(i)
			verified = parseSuccess
		}
		return verified
	case DATETIME_ARRAY:
		for i in arrayValues {
			_, parseSuccess := OST_PARSE_DATETIME(i)
			verified = parseSuccess
		}
		return verified
	case STRING_ARRAY, CHAR_ARRAY:
		verified = true
		return verified
	case UUID_ARRAY:
		for i in arrayValues {
			_, parseSuccess := OST_PARSE_UUID(i)
			verified = parseSuccess
		}
		return verified
	}

	return verified
}


//makes sure the date is in the correct format & length. then returns the date as a string
OST_PARSE_DATE :: proc(date: string) -> (string, bool) {
	dateStr := ""
	parts, err := strings.split(date, "-")

	//check length reqs
	if len(parts[0]) != 4 || len(parts[1]) != 2 || len(parts[2]) != 2 {
		fmt.println("Invalid date format. Use: YYYY-MM-DD (example: 2024-03-14)")
		return dateStr, false
	}

	year, yearOk := strconv.parse_int(parts[0])
	month, monthOk := strconv.parse_int(parts[1])
	day, dayOk := strconv.parse_int(parts[2])

	if !yearOk || !monthOk || !dayOk {
		fmt.println("Invalid date: contains non-numeric characters")
		return dateStr, false
	}

	//validate month range
	if month < 1 || month > 12 {
		fmt.println("Invalid month: must be between 01-12")
		return dateStr, false
	}

	//Calculate days in month
	daysInMonth := 31
	switch month {
	case 4, 6, 9, 11:
		daysInMonth = 30
	case 2:
		// Leap year calculation
		isLeapYear := (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
		daysInMonth = isLeapYear ? 29 : 28
	}

	// Validate day range
	if day < 1 || day > daysInMonth {
		fmt.println("Invalid day for the specified month")
		return dateStr, false
	}

	// Format with leading zeros
	monthStr := fmt.tprintf("%02d", month)
	dayStr := fmt.tprintf("%02d", day)
	yearStr := fmt.tprintf("%04d", year)

	dateStr = fmt.tprintf("%s-%s-%s", yearStr, monthStr, dayStr)
	return dateStr, true
}

OST_PARSE_TIME :: proc(time: string) -> (string, bool) {
	timeStr := ""
	timeArr, err := strings.split(time, ":")

	#partial switch (err) {
	case .None:
		break
	case:
		fmt.println("Incorrect time format detected. Please use HH:MM:SS")
		return timeStr, false
	}

	if len(timeArr[0]) != 2 || len(timeArr[1]) != 2 || len(timeArr[2]) != 2 {
		fmt.println("Invalid time format. Use: HH:MM:SS (example: 13:45:30)")
		return timeStr, false
	}

	// Convert strings to integers for validation
	hour, hourOk := strconv.parse_int(timeArr[0])
	minute, minuteOk := strconv.parse_int(timeArr[1])
	second, secondOk := strconv.parse_int(timeArr[2])

	if !hourOk || !minuteOk || !secondOk {
		fmt.println("Invalid time: contains non-numeric characters")
		return timeStr, false
	}

	// Validate ranges
	if hour < 0 || hour > 23 {
		fmt.println("Invalid hour: must be between 00-23")
		return timeStr, false
	}
	if minute < 0 || minute > 59 {
		fmt.println("Invalid minute: must be between 00-59")
		return timeStr, false
	}
	if second < 0 || second > 59 {
		fmt.println("Invalid second: must be between 00-59")
		return timeStr, false
	}

	// Format with leading zeros
	timeStr = fmt.tprintf("%02d:%02d:%02d", hour, minute, second)
	return timeStr, true
}

//parses the passed in string ensuring proper format and length
//Example datetime: 2024-03-14T09:30:00
OST_PARSE_DATETIME :: proc(dateTime: string) -> (string, bool) {
	dateTimeStr := ""
	dateTimeArr, err := strings.split(dateTime, "T")

	#partial switch (err) {
	case .None:
		break
	case:
		fmt.println("Incorrect datetime format detected. Please use YYYY-MM-DDTHH:MM:SS")
		return dateTimeStr, false
	}

	dateStr, dateErr := OST_PARSE_DATE(dateTimeArr[0])
	if dateErr != true {
		return dateTimeStr, false
	}

	timeStr, timeErr := OST_PARSE_TIME(dateTimeArr[1])
	if timeErr != true {
		return dateTimeStr, false
	}

	dateTimeStr = fmt.tprintf("%sT%s", dateStr, timeStr)
	return dateTimeStr, true
}


//parses the passed in string ensuring proper format and length
//Must be in the format: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
//Only allows 0-9 and a-f
OST_PARSE_UUID :: proc(uuid: string) -> (string, bool) {
	uuidStr := ""
	isValidChar := false

	possibleChars: []string = {
		"0",
		"1",
		"2",
		"3",
		"4",
		"5",
		"6",
		"7",
		"8",
		"9",
		"a",
		"b",
		"c",
		"d",
		"e",
		"f",
	}
	uuidArr, err := strings.split(uuid, "-")

	#partial switch (err) {
	case .None:
		break
	case:
		fmt.println(
			"Incorrect UUID format detected. Please use XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
		)
		return uuidStr, false
	}

	if len(uuidArr[0]) != 8 ||
	   len(uuidArr[1]) != 4 ||
	   len(uuidArr[2]) != 4 ||
	   len(uuidArr[3]) != 4 ||
	   len(uuidArr[4]) != 12 {
		fmt.println("Invalid UUID format. Please use XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX")
		return uuidStr, false
	}

	// Validate each section of the UUID
	for section in uuidArr {
		for value in section {
			// Convert the rune to a lowercase string
			runeArr := make([]rune, 1)
			runeArr[0] = value
			charLower := strings.to_lower(utf8.runes_to_string(runeArr))
			isValidChar = false

			// Check if the character is in the allowed set
			for c in possibleChars {
				if charLower == c {
					isValidChar = true
					break
				}
			}

			if !isValidChar {
				fmt.println("Char is not a valid char: ", charLower)
				fmt.println(
					"Invalid UUID: contains invalid characters. Only 0-9 and a-f are allowed",
				)
				return uuidStr, false
			}
		}
	}

	uuidStr = fmt.tprintf(
		"%s-%s-%s-%s-%s",
		uuidArr[0],
		uuidArr[1],
		uuidArr[2],
		uuidArr[3],
		uuidArr[4],
	)
	return strings.to_lower(uuidStr), true
}

//No need to parse NULL data type but if there was it would have been here :)


//TODO DONT DELETE THESE..THEY CAN BE USEDFUL IN THE TRANSFER package
// OST_FORMAT_DATE :: proc(date: types.__Date) -> string {
// 	return fmt.tprintf("%04d-%02d-%02d", date.year, date.month, date.day)
// }

// OST_FORMAT_TIME :: proc(time: types.__Time) -> string {
// 	return fmt.tprintf("%02d:%02d:%02d", time.hour, time.minute, time.second)
// }

// OST_FORMAT_DATETIME :: proc(dateTime: types.__DateTime) -> string {
// 	return fmt.tprintf("%sT%s", OST_FORMAT_DATE(dateTime.date), OST_FORMAT_TIME(dateTime.time))
// }

// OST_APPEND_DATE_TO_ARRAY :: proc(arr: ^types.Date_Array, date: types.__Date) {
// 	value := types.Date_Value {
// 		raw       = date,
// 		formatted = OST_FORMAT_DATE(date),
// 	}
// 	append(&arr.values, value)
// }
