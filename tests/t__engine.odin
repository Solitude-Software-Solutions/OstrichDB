package tests

import "core:testing"
import "../src/core/types"
import "../src/core/const"
import "../src/core/engine"
import "core:strings"
import "core:slice"
import "core:fmt"

/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            Tests for procedures in: src/core/engine/engine.odin
*********************************************************/

//Tests that the data integrity check system can be initialized
@(test)
test_data_integrity_check_system ::proc(test: ^testing.T){
    result:= engine.INIT_DATA_INTEGRITY_CHECK_SYSTEM(&types.data_integrity_checks)
    testing.expect_value(test, result, 0)
}

//Todo: For the following tests the test package has to have access to the   `nlp.lib` or `nlp.so` files....
//This is literally all because of the the nlp.main() proc call in commands.odin....
@(test)
test_start_ostrichdb_engine::proc(test: ^testing.T){
result := engine.START_OSTRICHDB_ENGINE()
testing.expect_value(test,result, 0)

}

@(test)
test_start_command_line::proc(test: ^testing.T){
result := engine.START_COMMAND_LINE()
testing.expect_value(test,result, 0)

}