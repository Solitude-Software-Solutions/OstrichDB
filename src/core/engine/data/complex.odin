package data
import "core:fmt"
import "core:strconv"
import "core:strings"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//

//This file is used to define the structure of the complex data types and how OstrichDB will handle them

//essentially will look over the passed in string and as long as its encased in [] it will split the string into an array based on the commas
OST_PARSE_ARRAY :: proc(strArr: string) -> []string {
	result := strings.split(strArr, ",")
	for i in result {
		fmt.println(i)
	}
	return result
}

// OST_PARSE_OBJECT :: proc(strObj: string) -> map[string]string {
// 	obj: map[string]string

// 	return obj
// }

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

	if len(dateArr[0]) != 4 {
		return dateStr, -1
	}
	if len(dateArr[1]) != 2 {
		return dateStr, -1
	}
	if len(dateArr[2]) != 2 {
		return dateStr, -1
	}

	year := dateArr[0]
	month := dateArr[1]
	day := dateArr[2]

	dateStr = fmt.tprintf("%s-%s-%s", year, month, day)
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

	if len(timeArr[0]) != 2 {
		return timeStr, -1
	}
	if len(timeArr[1]) != 2 {
		return timeStr, -1
	}
	if len(timeArr[2]) != 2 {
		return timeStr, -1
	}

	hour := timeArr[0]
	minute := timeArr[1]
	second := timeArr[2]

	timeStr = fmt.tprintf("%s:%s:%s", hour, minute, second)
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
