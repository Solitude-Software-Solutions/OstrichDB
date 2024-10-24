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
	validModifiers := []string{AND, OF_TYPE, TYPE, ALL_OF, TO}
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
	//dot notation will allow for accessing context like this: <action> <target> child.parent.grandparent or <action> <target> child.parent
	cmd := types.Command {
		o_token            = make([dynamic]string),
		m_token            = make(map[string]string),
		s_token            = make(map[string]string),
		isUsingDotNotation = false,
	}

	if len(tokens) == 0 {
		return cmd
	}

	cmd.a_token = tokens[0] //setting the action token
	state := 0 //state machine exclusively used for modifier token shit
	currentModifier := "" //stores the current modifier such as TO

	//iterate over remaining ATOM tokens and set/append them to the cmd
	for i := 1; i < len(tokens); i += 1 {
		token := tokens[i]

		switch state {
		case 0:
			// Expecting target
			cmd.t_token = token
			state = 1
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
						append(&cmd.o_token, obj)
					}
				} else {
					append(&cmd.o_token, token)
				}
			}
		case 2:
			// Expecting object after modifier
			cmd.m_token[currentModifier] = token // Preserve original case for modifier values
			state = 1
		}
	}

	return cmd
}
