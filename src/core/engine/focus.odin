package engine

import "../const"
import "../types"
//this file contains the code that is used for the FOCUS and UNFOCUS commands

//t - target(cluster, collection)
//o - object to focus on(name of the target)
//p - the parent object of the object to focus on. NOTE: COLLECTIONS DO NOT HAVE PARENTS
//only used to focus collection and clusters
OST_FOCUS :: proc(t: string, o: string, p: ..string) -> (string, string, string) {
	types.focus.t_ = t
	types.focus.o_ = o
	for p in p {
		types.focus.p_o = p
	}
	return types.focus.t_, types.focus.o_, types.focus.p_o
}

// only used to focus records
OST_FOCUS_RECORD :: proc(t: string, o: string, rO: string) -> (string, string, string) {
	types.focus.t_ = t
	types.focus.o_ = o
	types.focus.ro_ = rO
	return types.focus.t_, types.focus.o_, types.focus.ro_
}


OST_UNFOCUS :: proc() {
	types.focus.t_ = ""
	types.focus.o_ = ""
}
