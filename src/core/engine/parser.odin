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
	validModifiers := []string{AND, WITHIN, IN, OF_TYPE, TYPE, ALL_OF, TO, DOT}
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
	fmt.println("tokens: ", tokens)

	//dot notation will allow for accessing context like this: <action> <target> child.parent.grandparent or <action> <target> child.parent
	grandparent: string
	parent: string
	child: string
	objTokensSepByDot: []string
	cmd: types.Command

	if len(tokens) == 0 {
		return cmd
	}

	//Firstly checking if appropriate token contains a dot.
	//if so then recognize that we are using dot notation
	for i := 0; i < len(tokens); i += 1 {
		switch strings.contains(tokens[i], ".") {
		//USING DOT NOTATION // USING DOT NOTATION // USING DOT NOTATION
		case true:
			//dont fucking ask me why I did this or why it works - Marshall Burns aka SchoolyB
			if !strings.contains(tokens[0], ".") {
				objTokensSepByDot = strings.split(strings.trim_space(tokens[i]), ".")
				fmt.println("SeperatedByDot: ", objTokensSepByDot)
				fmt.println("len(objTokensSepByDot): ", len(objTokensSepByDot))

				switch (len(objTokensSepByDot)) 
				{
				case 1:
					fmt.println("ERROR, something went wrong when trying to use dot notation...")
				case 2:
					parent = objTokensSepByDot[0]
					child = objTokensSepByDot[1]
					fmt.println("Getting parent: ", parent)
					fmt.println("Getting child: ", child)

				case 3:
					grandparent = objTokensSepByDot[0]
					parent = objTokensSepByDot[1]
					child = objTokensSepByDot[2]

				}
			}

			cmd = types.Command {
				o_token            = make([dynamic]string),
				m_token            = make(map[string]string),
				s_token            = make(map[string]string),
				isUsingDotNotation = true,
			}

			currentModifier := "" //stores the current modifier such as TO or WITHIN
			state := 0 //state machine exclusivley used for modifier token shit

			cmd.a_token = tokens[0] //setting the action token
			//iterate over remaing ATOM tokens and set/append them to the cmd
			for j := 1; j < len(tokens); j += 1 {
				token := tokens[j]
				switch (state) {
				case 0:
					cmd.t_token = token
					fmt.println("token: ", token)
					state = 1
				case 1:
					//checking if the current token is a modifier; if it is add it to the modifer map
					if OST_IS_VALID_MODIFIER(token) {
						currentModifier = token
						fmt.println("current modifier: ", currentModifier)
						state = 2
					} else {
						for k := 0; k < len(objTokensSepByDot); k += 1 {
							append(&cmd.o_token, objTokensSepByDot[k])
						}
					}
				case 2:
					for m := 0; m < len(objTokensSepByDot); m += 1 {
						cmd.m_token[currentModifier] = token // Preserve original case for modifier values
						state = 1

					}
				}
			}
		//NOT USING DOT NOTATION // NOT USING DOT NOTATION // NOT USING DOT NOTATION
		case false:
			cmd = types.Command {
				o_token            = make([dynamic]string),
				m_token            = make(map[string]string),
				s_token            = make(map[string]string),
				isUsingDotNotation = false,
			}

			cmd.a_token = tokens[0]

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
	}
	return cmd
}
