package engine

import "../const"
import "../types"
import "core:fmt"
import "core:os"
import "core:strings"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            Ah yes... the parser. Within you can find a poorlu written
            state machine that parses the users input into a command.
            Commands are then returned to the caller in engine.odin,
            then executed.
*********************************************************/

//checks if a token is a valid modifier only used in the parser
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

//Takes the users input and parser it into a command. The command is then returned to the caller in engine.odin
OST_PARSE_COMMAND :: proc(input: string) -> types.Command {
	using const

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
			case SET:
				if token == CONFIG {
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
			case WHERE:
				if token == CLUSTER || token == RECORD {
					cmd.t_token = token
				} else {
					append(&cmd.l_token, token)
					break
				}
				break
			case HELP:
				cmd.t_token = token
				break
			case COUNT:
				switch (token) {
				case COLLECTIONS:
					cmd.t_token = token
					break
				case CLUSTERS, RECORDS:
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
				break
			case BENCHMARK:
				if strings.contains(token, ".") {
					cmd.isUsingDotNotation = true
					iterations := strings.split(strings.trim_space(token), ".")
					for i in iterations {
						append(&cmd.l_token, i)
					}
				} else {
					append(&cmd.l_token, token)
				}
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
