package transfer

import "../../../utils"
import "../../const"
import "../data"
import "../data/metadata"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright 2024 - Present Marshall A Burns & Solitude Software Solutions LLC
*********************************************************/

//takes in a date of different formats and converts it to the format that OstrichDB uses YYYY-MM-DD
OST_CONVERT_DATE :: proc(date: string) -> string {
	buf: [32]byte

	//==== CHECK FOR FORMAT USING "-" AS SEPARATOR ====//

	//YYYY-MM-DD
	if strings.contains(date, "-") {
		dateParts := strings.split(date, "-")
		if len(dateParts[0]) == 4 {
			if len(dateParts[1]) == 2 {
				if len(dateParts[2]) == 2 {
					return fmt.tprintf("%s-%s-%s", dateParts[0], dateParts[1], dateParts[2])
				}
			}
		}
	}

	//DD-MM-YYYY or MM-DD-YYYY
	if strings.contains(date, "-") {
		dateParts := strings.split(date, "-")
		if dateParts[0] > strconv.itoa(buf[:], 12) {
			return fmt.tprintf("%s-%s-%s", dateParts[2], dateParts[1], dateParts[0])
		} else {
			return fmt.tprintf("%s-%s-%s", dateParts[2], dateParts[0], dateParts[1])
		}
	}

	//==== CHECK FOR FORMAT USING "/" AS SEPARATOR ====//

	//YYYY/MM/DD
	if strings.contains(date, "/") {
		dateParts := strings.split(date, "/")
		return fmt.tprintf("%s-%s-%s", dateParts[0], dateParts[1], dateParts[2])
	}

	//MM/DD/YYYY or DD/MM/YYYY
	if strings.contains(date, "/") {
		dateParts := strings.split(date, "/")
		if dateParts[0] > strconv.itoa(buf[:], 12) {
			return fmt.tprintf("%s-%s-%s", dateParts[2], dateParts[1], dateParts[0])
		} else {
			return fmt.tprintf("%s-%s-%s", dateParts[2], dateParts[0], dateParts[1])
		}
	}

	//==== CHECK FOR FORMAT WITH NO SEPARATOR ====//

	//YYYYMMDD
	if len(date) == 8 {
		return fmt.tprintf("%s-%s-%s", date[0:4], date[4:6], date[6:8])
	}

	//DDMMYYYY
	if len(date) == 8 {
		return fmt.tprintf("%s-%s-%s", date[4:8], date[2:4], date[0:2])
	}

	//MMDDYYYY
	if len(date) == 8 {
		return fmt.tprintf("%s-%s-%s", date[4:8], date[0:2], date[2:4])
	}

	//==== CHECK FOR FORMAT USING "." AS SEPARATOR ====//
	//YYYY.MM.DD
	if strings.contains(date, ".") {
		dateParts := strings.split(date, ".")
		if len(dateParts[0]) == 4 {
			if len(dateParts[1]) == 2 {
				if len(dateParts[2]) == 2 {
					return fmt.tprintf("%s-%s-%s", dateParts[0], dateParts[1], dateParts[2])
				}
			}
		}
	}


	//DD.MM.YYYY or MM.DD.YYYY
	if strings.contains(date, ".") {
		dateParts := strings.split(date, ".")
		if dateParts[0] > strconv.itoa(buf[:], 12) {
			return fmt.tprintf("%s-%s-%s", dateParts[2], dateParts[1], dateParts[0])
		} else {
			return fmt.tprintf("%s-%s-%s", dateParts[2], dateParts[0], dateParts[1])
		}
	}

	//==== CHECK FOR FORMAT USING " " AS SEPARATOR ====//

	//YYYY MM DD
	if strings.contains(date, " ") {
		dateParts := strings.split(date, " ")
		if len(dateParts[0]) == 4 {
			if len(dateParts[1]) == 2 {
				if len(dateParts[2]) == 2 {
					return fmt.tprintf("%s-%s-%s", dateParts[0], dateParts[1], dateParts[2])
				}
			}
		}
	}

	//DD MM YYYY or MM DD YYYY
	if strings.contains(date, " ") {
		dateParts := strings.split(date, " ")
		if dateParts[0] > strconv.itoa(buf[:], 12) {
			return fmt.tprintf("%s-%s-%s", dateParts[2], dateParts[1], dateParts[0])
		} else {
			return fmt.tprintf("%s-%s-%s", dateParts[2], dateParts[0], dateParts[1])
		}
	}
	return ""
}
