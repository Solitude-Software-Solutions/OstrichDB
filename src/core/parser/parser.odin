package parser

import "../types"
import "core:fmt"
import "core:os"
import "core:strings"

OST_PARSE_COMMAND :: proc(input: string) -> types.OST_Command {
	//split the input into parts, and convert them to uppercase to ease of parsing, trim whitespace
	parts := strings.split(strings.to_upper(strings.trim_space(input)), " ")
	//create a new command struct and initialize the modifiers  with an empty map
	cmd := types.OST_Command {
		m_token = make(map[string]string),
	}

	//if there is less than 3 parts, return the the empty command
	if len(parts) < 3 {
		return cmd
	}

	cmd.a_token = parts[0] //assign the first part to the action
	cmd.o_token = parts[1] //assign the second part to the object
	cmd.t_token = parts[2] //assign the third part to the target


	//if there are more than 3 parts, assign the rest of the parts as modifiers
	for i := 3; i < len(parts); i += 2 {
		if i + 1 < len(parts) {
			cmd.m_token[parts[i]] = parts[i + 1]
		}
	}

	return cmd
}
