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
            Ah yes... the parser. Within you can find a poorly written
            state machine that parses the users input into a command.
            Commands are then returned to the caller in engine.odin,
            then executed.
*********************************************************/

//Takes the users input and parser it into a command. The command is then returned to the caller in engine.odin
PARSE_COMMAND :: proc(input: string) -> types.Command {
	using const
	using types

	// Check if the input contains command chaining
	if strings.contains(input, "&&") {
		// This is a chained command, but we'll only parse the first one
		// The engine will handle executing the chain
		cmd := Command {
			l_token            = make([dynamic]string),
			p_token            = make(map[string]string),
			t_token            = "",
			isChained         = true,
			rawInput          = strings.clone(input),
		}

		// Set the first command as the c_token
		parts := strings.split(input, "&&")
		if len(parts) > 0 {
			firstCmd := strings.trim_space(parts[0])
			firstTokens := strings.split(strings.trim_space(firstCmd), " ")
			if len(firstTokens) > 0 {
				cmd.c_token = convert_string_to_ostrichdb_token(firstTokens[0])
			}
		}

		return cmd
	}

	capitalInput := strings.to_upper(input)
	tokens := strings.split(strings.trim_space(capitalInput), " ")
	//dot notation allows for accessing context like this: <action> grandparent.parent.child or <action> parent.child
	cmd := Command {
		l_token            = make([dynamic]string),
		p_token            = make(map[string]string),
		t_token            = "",
		isChained         = false,
		rawInput          = strings.clone(input),
	}

	if len(tokens) == 0 {
		return cmd
	}

	// Convert first token to TokenType
	cmd.c_token = convert_string_to_ostrichdb_token(tokens[0])
	state := 0 //state machine exclusively used for parameter token shit
	currentParameterToken := "" //stores the current modifier such as TO
	collectingString := false
	stringValue := ""

	//iterate over remaining CLP tokens and set/append them to the cmd
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
			#partial switch (cmd.c_token)
			{
			case TokenType.SET:
				if token == Token[.CONFIG] {
					cmd.t_token = token
				} else {
					cmd.t_token = cmd.t_token
					if strings.contains(token, ".") {
						objTokensSepByDot := strings.split(strings.trim_space(token), ".")
						for obj in objTokensSepByDot {
							append(&cmd.l_token, obj)
						}
					}
				}
				state = 1
				break
			case TokenType.WHERE:
				if token == Token[.CLUSTER] || token == Token[.RECORD] {
					cmd.t_token = token
				} else {
					append(&cmd.l_token, token)
					break
				}
				break
			case TokenType.HELP:
				cmd.t_token = token
				break
			case TokenType.COUNT:
				switch (token) {
				case Token[.COLLECTIONS]:
					cmd.t_token = token
					break
				case Token[.CLUSTERS], Token[.RECORDS]:
					cmd.t_token = token
					if strings.contains(token, ".") {
						objTokensSepByDot := strings.split(strings.trim_space(token), ".")
						for obj in objTokensSepByDot {
							append(&cmd.l_token, obj)
						}
					}
					break
				}
				state = 1
				break
			case TokenType.BENCHMARK:
				if strings.contains(token, ".") {
					iterations := strings.split(strings.trim_space(token), ".")
					for i in iterations {
						append(&cmd.l_token, i)
					}
				} else {
					append(&cmd.l_token, token)
				}
			case: //Every other command token
				cmd.t_token = cmd.t_token
				if strings.contains(token, ".") {
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
			if check_if_param_token_is_valid(token) {
				currentParameterToken = token
				state = 2
			} else {
				if strings.contains(token, ".") {
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
		cmd.p_token[currentParameterToken] = stringValue

		// If the current parameter token is OF_TYPE and the c_token is NEW
		// Check if the string value contains the WITH token to handle record values
		if currentParameterToken == types.Token[.OF_TYPE] && cmd.c_token == types.TokenType.NEW {
			// Split the string to check for WITH token
			parts := strings.split(stringValue, " ")
			if len(parts) >= 2 && strings.to_upper(parts[1]) == types.Token[.WITH] {

				// Store the type in the OF_TYPE map value slot
				cmd.p_token[currentParameterToken] = parts[0]

				// Store everything after the WITH token in the WITH map value slot
				if len(parts) > 2 {
					withValue := strings.join(parts[2:], " ")
					cmd.p_token[types.Token[.WITH]] = withValue
				} else {
					// Handle case where WITH is the last token with no value
					cmd.p_token[types.Token[.WITH]] = ""
				}
			}
		}
	}
	return cmd
}


//checks if a token is a valid modifier only used in the parser
check_if_param_token_is_valid :: proc(token: string) -> bool {
	using const
	using types

	validParamTokens := []string{Token[.WITH],Token[.OF_TYPE], Token[.TO]}
	for paramToken in validParamTokens {
		if strings.to_upper(token) == paramToken {
			return true
		}
	}
	return false
}

//take the string representation of a token and returns the token itself
convert_string_to_ostrichdb_token :: proc(str: string) -> types.TokenType {
	using types

	upperStr := strings.to_upper(str)
	for tokenStrRepresentation, index in Token {
		if upperStr == tokenStrRepresentation { 	//if the passed in string and the token string representation are the same return the enum
			return index
		}
	}
	return TokenType.INVALID
}
