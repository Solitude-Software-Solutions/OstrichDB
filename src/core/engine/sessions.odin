package engine

import "../../utils"
import "../config"
import "../const"
import "../types"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//

stopWatch: time.Stopwatch

OST_START_SESSION_TIMER :: proc() {
	time.stopwatch_start(&stopWatch)
}

OST_STOP_SESSION_TIMER :: proc() {
	time.stopwatch_stop(&stopWatch)
}

OST_GET_SESSION_DURATION :: proc() -> time.Duration {
	sessionDuration := time.stopwatch_duration(stopWatch)
	return sessionDuration
}

//simply checks if the session duration has met the maximum allowed session time yet
OST_CHECK_SESSION_DURATION :: proc(sessionDuration: time.Duration) -> bool {

	maxDurationMet := false
	if sessionDuration > const.MAX_SESSION_TIME {
		maxDurationMet = true
	}
	return maxDurationMet
}


OST_HANDLE_MAX_SESSION_DURATION_MET :: proc() {
	fmt.printfln(
		"Maximum session time of %s1 Day%s has been met. You will be automatically logged out. Please log back in.",
		utils.BOLD,
		utils.RESET,
	)
	//force logout
	OST_USER_LOGOUT(0)
	utils.log_runtime_event(
		"Max Session Time Met",
		" User has been forced logged out due to reaching maximum session time.",
	)
}
