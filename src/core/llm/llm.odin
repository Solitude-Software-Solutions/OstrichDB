package llm
import "core:c"
foreign import go "llm.dylib"
foreign go {
	hello :: proc() ---
	bye :: proc() ---
}

main :: proc() {
	hello()
	bye()
}
