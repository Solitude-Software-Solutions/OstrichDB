# Getting The OstrichDB Bindings Working

Executed within the src/bindings directory
```sh
odin build bindings.odin -file -out:bindings.o -no-entry-point -build-mode:obj -reloc-mode:pic -define:DEV_MODE=true
```

This will compile a .obj file which can be used from C as you would expect.

