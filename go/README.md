# Steps to get this shit working while testing it out.
A lot of OstrichDB core Odin  procedures  will not work while doing this because the pathing will be all messed up.
But luckily this is just for testing to get some things in order

Needs:
`go` dir
`shared` dir
Note: Both dirs need to be at the same level in the project structure
```
ostrichdb
                |
                |-bin
                |
                |-go
                |
                |-main
                |
                |-scripts
                |
                |-shared
```

1. Ensure a `.env` file exists in the `go` dir and add the following:
`OPENAI_API_KEY=<your_key_here>`

2. In the `shared` dir open the `shared.odin` file Create any Odin procedures you need and add the  `@(export)` tag above the declarations
```odin
//shared.odin
package shared

import "../src/core/engine/data"
import "core:c/libc"                                           //Must import core:c/libc
import "base:runtime"                                      //Must import base:runtime

@(export)                                                             //Dont forget to export!
some_procedure :: proc "c" () -> bool {         //Ensure all new procs have the "c" before the parens
    context = runtime.default_context()           //Esnure to create a default context because....reasons

    result:= data.DO_SOMETHING()                 //Call OstrichDB core procedures
    return  result
}
```
3. In the `shared` dir ensure a `sharedlib.h` header file exists with the following content:
```C
// sharedlib.h
#ifndef SHAREDLIB_H
#define SHAREDLIB_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

bool DO_SOMETHING();
//Add other lib procedures that you make in the next step here

#ifdef __cplusplus
}
#endif

#endif // SHAREDLIB_H
```

4. In the terminal change directories to the `shared` dir then run the following command:
```bash
odin build shared.odin -file -define:DEV_MODE=true -build-mode:shared -out:shared.dylib //Change the lib extension depending on architecture/OS
```
*IMPORTANT Note*: If any changes are made to the `shared.odin` file you must follow step 3 again

5. Ensure the `go/main.go` file is set up to use the shared library:
```go
// main.go
package main
/*																																													//Notice that this section is in a multiline comment, keep it that way!
#include <stdlib.h>                                                         //Ensure any additional needed C libs are included :)
#cgo LDFLAGS: ${SRCDIR}/../shared/shared.dylib  //Change the library extension based on architecture/os
#include "../shared/sharedlib.h"                                    Must include the shared lib
*/
import "C"																																						//This import MUST be directly below the end of the multiline comment
```


4. In your terminal `cd` into the `go` dir then run the following command:
`go run main.go`

For debugging the CGo code run:
`CGO_DEBUG=1 go run main.go` //Change file name if there are others