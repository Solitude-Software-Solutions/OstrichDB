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
	fmt.println("Token recieved while checking if is valid modifer: ", token)
	using const
	validModifiers := []string{AND, WITHIN, IN, OF_TYPE, TYPE, ALL_OF, TO}
	for modifier in validModifiers {
		if strings.to_upper(token) == modifier {
			return true
		}
	}
	return false
}

//the params arg is only used when in FOCUS mode to pass the focus targets and objects
OST_PARSE_COMMAND :: proc(input: string) -> types.Command {
	capitalInput := strings.to_upper(input)
	tokens := strings.split(strings.trim_space(capitalInput), " ")
	sepByDot := strings.split(strings.trim_space(capitalInput), ".")
	cmd := types.Command{}
	switch (len(sepByDot) > 1) {
	//IF THE COMMAND US USING DOT NOTATION example: new cluster foo.bar
	case true:
		cmd = types.Command {
			o_token            = make([dynamic]string),
			m_token            = make(map[string]string),
			s_token            = make(map[string]string),
			isUsingDotNotation = true,
		}
		fmt.println("Tokens: ", tokens)
		fmt.println("SepByDot: ", sepByDot)
		if len(tokens) == 0 {
			return cmd
		}
		cmd.a_token = strings.to_upper(tokens[0]) //i dont think i need to do this anymore

		state := 0
		current_modifier := ""

		for i := 1; i < len(tokens); i += 1 {
			token := strings.to_upper(tokens[i])
			switch state {
			case 0:
				// Expecting target
				cmd.t_token = tokens[i]
				state = 1
			case 1:
				// Expecting object or modifier
				if OST_IS_VALID_MODIFIER(tokens[i]) {
					current_modifier = token
					fmt.println("Current Modifier: ", current_modifier)
					state = 2
				} else {
					dotSplit := strings.split(tokens[i], ".")
					switch (len(dotSplit)) 
					{
					case 2:
						fmt.println("Dot Split: ", dotSplit)
						fmt.println("Dot Split Length: ", len(dotSplit))
						for j := 0; j < len(dotSplit); j += 1 {
							append(&cmd.o_token, dotSplit[j]) // Preserve original case for objects
						}
					case 3:
						fmt.println("Dot Split: ", dotSplit)
						fmt.println("Dot Split Length: ", len(dotSplit))
						for j := 0; j < len(dotSplit); j += 1 {
							append(&cmd.o_token, dotSplit[j]) // Preserve original case for objects
						}
					case:
						fmt.println("There can only be 2 or 3 parts to a dot notation command")
					}


				}
			case 2:
				// Expecting object after modifier
				cmd.m_token[current_modifier] = sepByDot[i] // Preserve original case for modifier values
				state = 1
			}
			// return cmd
		}

	//IF THIS IS A NORMAL COMMAND example: new cluster foo within collecion bar
	case false:
		cmd = types.Command {
			o_token            = make([dynamic]string),
			m_token            = make(map[string]string),
			s_token            = make(map[string]string),
			isUsingDotNotation = false,
		}
		if len(tokens) == 0 {
			return cmd
		}

		cmd.a_token = strings.to_upper(tokens[0])

		state := 0
		current_modifier := ""

		for i := 1; i < len(tokens); i += 1 {
			token := strings.to_upper(tokens[i])

			switch state {
			case 0:
				// Expecting target
				cmd.t_token = token
				state = 1
			case 1:
				// Expecting object or modifier
				if OST_IS_VALID_MODIFIER(token) {
					current_modifier = token
					state = 2
				} else {
					append(&cmd.o_token, tokens[i]) // Preserve original case for objects
				}
			case 2:
				// Expecting object after modifier
				cmd.m_token[current_modifier] = tokens[i] // Preserve original case for modifier values
				state = 1
			}
		}
		return cmd
	}
	return cmd
}
