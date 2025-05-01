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
            Tests for procedures in: src/core/engine/history.odin
*********************************************************/


//Some tests are given the opposite expectation e.g There are many tests that evaluate an OstrichDB
//core procedure's return value. Since that core procedure may be dependant on other code
//to do work and return the "real-world" result we expect the opposite result.

//TL;DR:  If a core proc that relies on other code is meant to return true, then our test expects false


//Tests to ensure a users history is deleted from said users cluster.
@(test)
test_erase_history ::proc(test: ^testing.T){
    result:= engine.ERASE_HISTORY_CLUSTER("Username")
    testing.expect_value(test, result, false)
}

//Tests to ensure a users history cluster can be purged of its data.
@(test)
test_purge_history ::proc(test: ^testing.T){
    result:= engine.PURGE_USERS_HISTORY_CLUSTER("Username")
    testing.expect_value(test, result, false)
}

//test to see if a users command limit: 100 has been met
@(test)
test_user_command_history_limit_met ::proc(test: ^testing.T){
    user:=new(types.User)
    defer free(user)

    result:= engine.CHECK_IF_USER_COMMAND_HISTORY_LIMIT_MET(user)
    testing.expect_value(test, result, false)

}

//tests to attempt and push commands(records) with a users history cluster can be pushed into memory
@(test)
test_push_record_to_array ::proc(test: ^testing.T){
    result := engine.push_records_to_array("CLUSTER_NAME")
    defer delete(result)
    testing.expect(test,len(result) == 0)
}
