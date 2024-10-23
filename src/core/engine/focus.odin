package engine

import "../const"
import "../types"
import "core:fmt"
import "core:strings"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//

//t - target
//o - object(name of the target)
//p - the parent object of the target to focus on as well as the parent of the parent(grandparent)
//only used to focus collection and clusters
OST_FOCUS :: proc(t: string, o: string, p: ..string) -> (string, string, string, string) {
	types.focus.t_ = t
	types.focus.o_ = o
	types.focus.p_o = p[0]
	types.focus.gp_o = p[1] //the second passed in parent is the grandparent

	return strings.clone(
		types.focus.t_,
	), strings.clone(types.focus.o_), strings.clone(types.focus.p_o), strings.clone(types.focus.gp_o)
}

//Updates the context of the focus
//currently only useful in the event of a data objects rename
OST_REFRESH_FOCUS :: proc(t, o, p, gp: string) {
	types.focus.t_ = t
	types.focus.o_ = o
	types.focus.p_o = p
	types.focus.gp_o = gp

}
//Clears the focus
OST_UNFOCUS :: proc() {
	types.focus.t_ = ""
	types.focus.o_ = ""
	types.focus.p_o = ""
	types.focus.gp_o = ""
}
