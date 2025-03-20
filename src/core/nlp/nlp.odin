package llm
import "core:c"
foreign import go "nlp.dylib"
foreign go {
	do_stuff :: proc() ---
}

main :: proc() {
	do_stuff()
}
