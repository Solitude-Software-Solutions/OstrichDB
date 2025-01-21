package engine

import "../const"
import "../types"
import "core:fmt"
import "core:os"
import "core:strings"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//

OST_IS_VALID_MODIFIER :: proc(token: string) -> bool {
	using const
	validModifiers := []string{OF_TYPE, TO}
	for modifier in validModifiers {
		if strings.to_upper(token) == modifier {
			return true
		}
	}
	return false
}

OST_PARSE_COMMAND :: proc(input: string) -> types.Command {
	capitalInput := strings.to_upper(input)
	tokens := strings.split(strings.trim_space(capitalInput), " ")
	//dot notation allows for accessing context like this: <action> grandparent.parent.child or <action> parent.child
	cmd := types.Command {
		l_token            = make([dynamic]string),
		p_token            = make(map[string]string),
		isUsingDotNotation = false,
		t_token            = "",
	}

	if len(tokens) == 0 {
		return cmd
	}

	cmd.c_token = tokens[0] //setting the command token
	state := 0 //state machine exclusively used for parameter token shit
	currentModifier := "" //stores the current modifier such as TO
	collectingString := false
	stringValue := ""

	//iterate over remaining ATOM tokens and set/append them to the cmd
	for i := 1; i < len(tokens); i += 1 {
		token := tokens[i]

		if collectingString {
			if stringValue != "" {
				stringValue = strings.concatenate([]string{stringValue, " ", token})
			} else {
				stringValue = token
			}
			continue
		}


		switch state {
		case 0:
			// Expecting target
			switch (cmd.c_token) 
			{
			case const.SET:
				if token == const.CONFIG {
					cmd.t_token = token
				} else {
					cmd.t_token = cmd.t_token
					if strings.contains(token, ".") {
						cmd.isUsingDotNotation = true
						objTokensSepByDot := strings.split(strings.trim_space(token), ".")
						for obj in objTokensSepByDot {
							append(&cmd.l_token, obj)
						}
					}
				}
				state = 1
				break
			case const.WHERE, const.HELP:
				cmd.t_token = token
				break
			case const.COUNT:
				switch (token) {
				case const.COLLECTIONS:
					cmd.t_token = token
					break
				case const.CLUSTERS, const.RECORDS:
					cmd.t_token = token
					if strings.contains(token, ".") {
						cmd.isUsingDotNotation = true
						objTokensSepByDot := strings.split(strings.trim_space(token), ".")
						for obj in objTokensSepByDot {
							append(&cmd.l_token, obj)
						}
					}
					break
				}
				state = 1
			case:
				cmd.t_token = cmd.t_token
				if strings.contains(token, ".") {
					cmd.isUsingDotNotation = true
					objTokensSepByDot := strings.split(strings.trim_space(token), ".")
					for obj in objTokensSepByDot {
						append(&cmd.l_token, obj)
					}
				} else {
					append(&cmd.l_token, token)
				}

				state = 1
			}
		case 1:
			// Expecting object or modifier
			if OST_IS_VALID_MODIFIER(token) {
				currentModifier = token
				state = 2
			} else {
				if strings.contains(token, ".") {
					cmd.isUsingDotNotation = true
					objTokensSepByDot := strings.split(strings.trim_space(token), ".")
					for obj in objTokensSepByDot {
						append(&cmd.l_token, obj)
					}
				} else {
					append(&cmd.l_token, token)
				}
			}
		case 2:
			stringValue = token
			collectingString = true
		}

	}

	// If we collected a string value, store it
	if collectingString && stringValue != "" {
		cmd.p_token[currentModifier] = stringValue
	}

	return cmd
}
