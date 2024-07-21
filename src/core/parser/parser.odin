package parser

import "../commands "
import "../types"
import "core:fmt"
import "core:os"
import "core:strings"
import "../const"

OST_IS_VALID_MODIFIER :: proc(token: string) -> bool {
	validModifiers := []string {
		const.AND,
		const.WITHIN,
		const.OF_TYPE,
		const.ALL_OF,
		const.TO,
	}
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
	cmd := types.Command {
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


OST_PARSE_FOCUS_COMMAND :: proc(input: string) -> types.Command {
    capitalInput := strings.to_upper(input)
    tokens := strings.split(strings.trim_space(capitalInput), " ")
    cmd := types.Command {
        o_token = make([dynamic]string),
        m_token = make(map[string]string),
        s_token = make(map[string]string),
    }

    if len(tokens) == 0 {
        return cmd
    }

    cmd.a_token = tokens[0]

    state := 0
    current_modifier := ""
    for i := 1; i < len(tokens); i += 1 {
        token := tokens[i]
        switch state {
        case 0:
            // Expecting target or object
            if OST_IS_VALID_MODIFIER(token) {
                current_modifier = token
                state = 1
            } else {
                if cmd.t_token == "" {
                    cmd.t_token = token
                } else {
                    append(&cmd.o_token, token)
                }
            }
        case 1:
            // Expecting object after modifier
            cmd.m_token[current_modifier] = token
            state = 0
        }
    }

    // Apply focus context if focus is set
    if types.focus.flag {
        if cmd.m_token["WITHIN"] == "" {
            // No WITHIN specified in the command, use the full focus context
            if types.focus.parent_t_ != "" {
                // Two-level focus
                cmd.m_token["WITHIN"] = types.focus.t_
                cmd.s_token[types.focus.t_] = types.focus.o_
                cmd.s_token["WITHIN"] = types.focus.parent_t_
                cmd.s_token[types.focus.parent_t_] = types.focus.parent_o_
            } else {
                // Single-level focus
                cmd.m_token["WITHIN"] = types.focus.t_
                cmd.s_token[types.focus.t_] = types.focus.o_
            }
        } else {
            // WITHIN specified in the command, use it as a refinement of the focus
            if cmd.m_token["WITHIN"] == types.focus.t_ {
                // Command WITHIN matches focus, add parent context if it exists
                if types.focus.parent_t_ != "" {
                    cmd.s_token["WITHIN"] = types.focus.parent_t_
                    cmd.s_token[types.focus.parent_t_] = types.focus.parent_o_
                }
            }
            // If WITHIN in command doesn't match focus, respect the command's WITHIN
        }
    }

    // If no object specified in the command, use the focused object
    if len(cmd.o_token) == 0 && types.focus.flag {
        append(&cmd.o_token, types.focus.o_)
    }

    return cmd
}
