package nlp

import "core:c"
import "core:c/libc"
when ODIN_OS == .Linux {
    foreign import go "nlp.so" 

    foreign go {
        run_agent :: proc() ---
    }
} else when ODIN_OS == .Darwin {
    foreign import go "nlp.dylib"
    foreign go {
        run_agent :: proc() ---
    }
}


/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            This file is used to achieve 2 things.
            1. Call Golang functions from within Odin code
            2. Ensure the NLP builds correctly to be used within the core
*********************************************************/

main :: proc() {
    run_agent() //See this Go function in main.go
}
