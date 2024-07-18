package parser

import "../commands "
import "../types"
import "core:fmt"
import "core:os"
import "core:strings"

OST_IS_VALID_MODIFIER :: proc(token: string) -> bool {
	validModifiers := []string {
		commands.AND,
		commands.WITHIN,
		commands.OF_TYPE,
		commands.ALL_OF,
		commands.TO,
	}
	for modifier in validModifiers {
		if strings.to_upper(token) == modifier {
			return true
		}
	}
	return false
}


OST_PARSE_COMMAND :: proc(input: string) -> types.OST_Command {
	capitalInput := strings.to_upper(input)
	tokens := strings.split(strings.trim_space(capitalInput), " ")
	cmd := types.OST_Command {
		o_token = make([dynamic]string),
		m_token = make(map[string]string),
		s_token = make(map[string]string),
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
