package shared

import "../src/core/engine/data"
import "../src/core/types"
import "../src/core/const"
import "core:c/libc"
import "core:strings"
import "core:strconv"
import "base:runtime"

@(export)
create_database :: proc "c" (name: cstring) -> bool {
    context = runtime.default_context()

    fn:= strings.clone_from_cstring(name)
    return data.CREATE_COLLECTION(fn, types.CollectionType.STANDARD_PUBLIC)
}

// odin build shared.odin -file -build-mode:shared -out:shared.dylib
//
//
//
//
//