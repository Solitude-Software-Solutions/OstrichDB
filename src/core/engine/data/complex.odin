package data
import "../../../utils"
import "../../const"
import "../data"
import "core:fmt"
import "core:strconv"
import "core:strings"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
*********************************************************/
//This file is used to define the structure of the complex data types and how OstrichDB will handle them


//essentially will look over the passed in string and as long as its encased in [] it will split the string into an array based on the commas
OST_PARSE_ARRAY :: proc(strArr: string) -> []string {
	result := strings.split(strArr, ",")
	// for i in result { 	//debugging
	// 	fmt.println(i)
	// }
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
	}

	return verified
}


//makes sure the date is in the correct format & length. then returns the date as a string
OST_PARSE_DATE :: proc(date: string) -> (string, int) {
	dateStr := ""
	dateArr, err := strings.split(date, "-")

	#partial switch (err) {
	case .None:
		break
	case:
		fmt.println("Incorrect date format detected. Please use YYYY-MM-DD")
		return dateStr, -1
	}

	//check length reqs
	if len(dateArr[0]) != 4 || len(dateArr[1]) != 2 || len(dateArr[2]) != 2 {
		fmt.println("Invalid date format. Use: YYYY-MM-DD (example: 2024-03-14)")
		return dateStr, -1
	}

	year, yearOk := strconv.parse_int(dateArr[0])
	month, monthOk := strconv.parse_int(dateArr[1])
	day, dayOk := strconv.parse_int(dateArr[2])

	if !yearOk || !monthOk || !dayOk {
		fmt.println("Invalid date: contains non-numeric characters")
		return dateStr, -1
	}

	//validate month range
	if month < 1 || month > 12 {
		fmt.println("Invalid month: must be between 01-12")
		return dateStr, -1
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
		return dateStr, -1
	}

	// Format with leading zeros
	monthStr := fmt.tprintf("%02d", month)
	dayStr := fmt.tprintf("%02d", day)
	yearStr := fmt.tprintf("%04d", year)

	dateStr = fmt.tprintf("%s-%s-%s", yearStr, monthStr, dayStr)
	return dateStr, 0
}

OST_PARSE_TIME :: proc(time: string) -> (string, int) {
	timeStr := ""
	timeArr, err := strings.split(time, ":")

	#partial switch (err) {
	case .None:
		break
	case:
		fmt.println("Incorrect time format detected. Please use HH:MM:SS")
		return timeStr, -1
	}

	if len(timeArr[0]) != 2 || len(timeArr[1]) != 2 || len(timeArr[2]) != 2 {
		fmt.println("Invalid time format. Use: HH:MM:SS (example: 13:45:30)")
		return timeStr, -1
	}

	// Convert strings to integers for validation
	hour, hourOk := strconv.parse_int(timeArr[0])
	minute, minuteOk := strconv.parse_int(timeArr[1])
	second, secondOk := strconv.parse_int(timeArr[2])

	if !hourOk || !minuteOk || !secondOk {
		fmt.println("Invalid time: contains non-numeric characters")
		return timeStr, -1
	}

	// Validate ranges
	if hour < 0 || hour > 23 {
		fmt.println("Invalid hour: must be between 00-23")
		return timeStr, -1
	}
	if minute < 0 || minute > 59 {
		fmt.println("Invalid minute: must be between 00-59")
		return timeStr, -1
	}
	if second < 0 || second > 59 {
		fmt.println("Invalid second: must be between 00-59")
		return timeStr, -1
	}

	// Format with leading zeros
	timeStr = fmt.tprintf("%02d:%02d:%02d", hour, minute, second)
	return timeStr, 0
}

//parses the passed in string ensuring proper format and length
//Example datetime: 2024-03-14T09:30:00
OST_PARSE_DATETIME :: proc(dateTime: string) -> (string, int) {
	dateTimeStr := ""
	dateTimeArr, err := strings.split(dateTime, "T")

	#partial switch (err) {
	case .None:
		break
	case:
		fmt.println("Incorrect datetime format detected. Please use YYYY-MM-DDTHH:MM:SS")
		return dateTimeStr, -1
	}

	dateStr, dateErr := OST_PARSE_DATE(dateTimeArr[0])
	if dateErr != 0 {
		return dateTimeStr, -1
	}

	timeStr, timeErr := OST_PARSE_TIME(dateTimeArr[1])
	if timeErr != 0 {
		return dateTimeStr, -1
	}

	dateTimeStr = fmt.tprintf("%sT%s", dateStr, timeStr)
	return dateTimeStr, 0
}
