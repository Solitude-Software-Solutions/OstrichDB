package nlp

import "core:c"
foreign import go "nlp.dylib"
foreign go {
	run_agent :: proc() ---
}

main :: proc() {
    run_agent()
}
