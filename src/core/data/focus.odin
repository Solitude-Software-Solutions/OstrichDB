package data

import "../const"
import "../types"
//this file contains the code that is used for the FOCUS and UNFOCUS commands


//t - target(cluster, collection)
//o - object to focus on(name of the target)
OST_FOCUS :: proc(t: string, o:string) -> (string, string) {
	types.focus.t_ = t
	types.focus.o_ = o
	return types.focus.t_, types.focus.o_
}

OST_UNFOCUS :: proc() {
	types.focus.t_ = ""
	types.focus.o_ = ""
}
