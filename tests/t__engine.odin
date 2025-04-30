package tests

import "core:testing"
import "../src/core/types"
import "../src/core/const"
import "../src/core/engine"
import "core:strings"


//This test ensures the OstrichDB parser is parsing the users input correctly.
// We first make a test input: input which matches all those same testCommand values
 //Next we make our own command: testCommand and assign its members values
//We then parse the input and check that its been parsed correctly
//Lastly check the the parsed command: resultCommand matches our expected testCommand
@(test)
test_parse_command ::proc(test: ^testing.T){

    input:="NEW FOO.BAR.BAZ OF_TYPE []INT WITH  1,2,3,4,5"

    locationStringArr:=make([dynamic]string)
    append(&locationStringArr, "FOO")
    append(&locationStringArr, "BAR")
    append(&locationStringArr, "BAZ")
    defer delete(locationStringArr)

    testCommand:types.Command
    testCommand.c_token = .NEW
    testCommand.l_token = locationStringArr
    testCommand.p_token["TYPE_OF"] = "[]INT"
    testCommand.isChained = false
    testCommand.rawInput = strings.clone(input)

    resultCommand := engine.PARSE_COMMAND(input)

    testing.expect_value(test, resultCommand.c_token, testCommand.c_token)
    testing.expect_value(test, resultCommand.l_token, testCommand.l_token)
    testing.expect_value(test, resultCommand.p_token, testCommand.p_token)
    testing.expect_value(test, resultCommand.isChained, testCommand.isChained)
    testing.expect_value(test, resultCommand.rawInput, testCommand.rawInput)

}
