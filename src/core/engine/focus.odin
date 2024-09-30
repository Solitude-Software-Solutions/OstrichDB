package engine

import "../const"
import "../types"
import "core:strings"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//

//t - target
//o - object(name of the target)
//p - the parent object of the target to focus on.
//only used to focus collection and clusters
OST_FOCUS :: proc(t: string, o: string, p: ..string) -> (string, string, string) {
	types.focus.t_ = t
	types.focus.o_ = o
	for p in p {
		types.focus.p_o = p
	}
	return strings.clone(
		types.focus.t_,
	), strings.clone(types.focus.o_), strings.clone(types.focus.p_o)
}

// only used to focus records
OST_FOCUS_RECORD :: proc(t: string, o: string, rO: string) -> (string, string, string) {
	types.focus.t_ = t
	types.focus.o_ = o
	types.focus.ro_ = rO
	return strings.clone(
		types.focus.t_,
	), strings.clone(types.focus.o_), strings.clone(types.focus.ro_)
}

//Clears the focus
OST_UNFOCUS :: proc() {
	types.focus.t_ = ""
	types.focus.o_ = ""
}
