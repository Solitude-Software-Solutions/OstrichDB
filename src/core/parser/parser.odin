package parser

import "../types"
import "core:fmt"
import "core:os"
import "core:strings"

OST_PARSE_COMMAND :: proc(input: string) -> types.OST_Command {
	//split the input into parts, and convert them to uppercase to ease of parsing, trim whitespace
	parts := strings.split(strings.to_upper(strings.trim_space(input)), " ")
	cmd := types.OST_Command {
		//create a new command struct and initialize the modifiers  with an empty map
		m_token = make(map[string]string),
	}
	//if empty command dont do shit
	if len(parts) == 0 {
		return cmd
	}

	/* this always sets the action part to the first entered command
	this allows for single word commands like EXIT, LOGOUT, HELP*/
	cmd.a_token = parts[0]

	//only sets the object if there are atleast 2 parts of a command. this helps with the above comment^^^
	if len(parts) >= 2 {
		cmd.o_token = parts[1]
	}

	//only set the target if there are atleast 3 parts of a command
	if len(parts) >= 3 {
		cmd.t_token = parts[2]
	}


	//if there are more than 3 parts, assign the rest of the parts as modifiers
	for i := 3; i < len(parts); i += 2 {
		if i + 1 < len(parts) {
			cmd.m_token[parts[i]] = parts[i + 1]
		}
	}

	return cmd
}
