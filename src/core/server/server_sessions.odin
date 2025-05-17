package server

import "../../utils"
import "../const"
import "../types"
import "core:time"
import "core:strconv"
import "core:strings"
import "core:math/rand"

/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-2025 Marshall A Burns and Solitude Software Solutions LLC
Copyright (c) 2025-Present Archetype Dynamics, Inc.

File Description:
            Contains logic for server session information tracking
*********************************************************/

//Ceate and return a new server session, sets default session info. takes in the current user
CREATE_SERVER_SESSION ::proc(user: types.User) -> ^types.Server_Session{
    newSession := new(types.Server_Session)
	newSession.Id  = rand.int63_max(1e16 + 1)
    newSession.start_timestamp = time.now()
    newSession.user = user
    //newSession.end_timestamp is set when the kill switch is activated or server loop ends
    return newSession
}

//Checks if the current server session duration has met the max session time, returns true if it has
SERVER_SESSION_LIMIT_MET :: proc(session: ^types.Server_Session) ->(maxDurationMet: bool){
    maxDurationMet = false
    if session.total_runtime >= const.MAX_SESSION_TIME{
        maxDurationMet = true
    }
    return maxDurationMet
}

