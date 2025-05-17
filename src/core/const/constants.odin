package const
import "core:fmt"
import "core:time"
import "../types"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB

Contributors:
    @CobbCoding1

License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            Contains all constants used throughout the OstrichDB project.
*********************************************************/

//Defines is a command line constant pfor file paths
//Read more about this here: https://odin-lang.org/docs/overview/#command-line-defines
DEV_MODE :: #config(DEV_MODE, false)

//Conditional file path constants thanks to the install debacle of Feb 2025 - Marshall
//See more here: https://github.com/Solitude-Software-Solutions/OstrichDB/issues/223
//DO NOT TOUCH MF - Marshall
when DEV_MODE == true {
	ROOT_PATH :: "./"
	TMP_PATH :: "./tmp/"
	PRIVATE_PATH :: "./private/"
	PUBLIC_PATH :: "./public/"
	STANDARD_COLLECTION_PATH :: "./public/standard/"
	USERS_PATH :: "./private/users/"
	BACKUP_PATH :: "./public/backups/"
	SYSTEM_CONFIG_PATH :: "./private/ostrich.config.ostrichdb"
	ID_PATH :: "./private/ids.ostrichdb"
	BENCHMARK_PATH :: "./private/benchmark/"
	LOG_DIR_PATH :: "./logs/"
	RUNTIME_LOG_PATH :: "./logs/runtime.log"
	ERROR_LOG_PATH :: "./logs/errors.log"
	SERVER_LOG_PATH :: "./logs/server_events.log"
	QUARANTINE_PATH :: "./public/quarantine/"
	RESTART_SCRIPT_PATH :: "../scripts/restart.sh"
	BUILD_SCRIPT_PATH :: "../scripts/local_build_run.sh"
} else {
	ROOT_PATH :: "./.ostrichdb/"
	TMP_PATH :: "./.ostrichdb/tmp/"
	PRIVATE_PATH :: "./.ostrichdb/private/"
	PUBLIC_PATH :: "./.ostrichdb/public/"
	STANDARD_COLLECTION_PATH :: "./.ostrichdb/public/standard/"
	USERS_PATH :: "./private/users/"
	BACKUP_PATH :: "./.ostrichdb/public/backups/"
	SYSTEM_CONFIG_PATH :: "./.ostrichdb/private/config.ostrichdb"
	ID_PATH :: "./.ostrichdb/private/ids.ostrichdb"
	BENCHMARK_PATH :: "./.ostrichdb/private/benchmark/"
	LOG_DIR_PATH :: "./.ostrichdb/logs/"
	RUNTIME_LOG_PATH :: "./.ostrichdb/logs/runtime.log"
	ERROR_LOG_PATH :: "./.ostrichdb/logs/errors.log"
	SERVER_LOG_PATH :: "./.ostrichdb/logs/server_events.log"
	QUARANTINE_PATH :: "./.ostrichdb/public/quarantine/"
	RESTART_SCRIPT_PATH :: "./.ostrichdb/restart.sh"
	BUILD_SCRIPT_PATH :: "./.ostrichdb/build_run.sh"
}

//Non-changing PATH CONSTANTS
FFVF_PATH :: "ost_file_format_version.tmp"
SYSTEM_CONFIG_CLUSTER :: "OSTRICH_SYSTEM_CONFIGS"
CLUSTER_ID_CLUSTER :: "CLUSTER__IDS"
USER_ID_CLUSTER :: "USER__IDS"
OST_EXT :: ".ostrichdb"
VERBOSE_HELP_FILE :: "../src/core/help/docs/verbose/verbose.md"
SIMPLE_HELP_FILE :: "../src/core/help/docs/simple/simple.md"
GENERAL_HELP_FILE :: "../src/core/help/docs/general/general.md"
CLPS_HELP_FILE :: "../src/core/help/docs/clps/clps.txt"

//All users share these names just in their own dirs
USER_CREDENTIAL_FILE_NAME:: "user.credentials.ostrichdb"
USER_CONFIGS_FILE_NAME ::"user.configs.ostrichdb"
USER_HISTORY_FILE_NAME:: "user.history.ostrichdb"

//CONFIG FILE CONSTANTS
ENGINE_INIT :: "ENGINE_INIT"
ENGINE_LOGGING :: "ENGINE_LOGGING"
USER_LOGGED_IN :: "USER_LOGGED_IN"
HELP_IS_VERBOSE :: "HELP_IS_VERBOSE"
AUTO_SERVE :: "AUTO_SERVE" //whenever cli tool starts it runs the server if this is set to true
SUPPRESS_ERRORS :: "SUPPRESS_ERRORS" //whether errors are printed to the console or not
LIMIT_HISTORY :: "LIMIT_HISTORY" //whether or not to limit how the number of commands are stored in the users history cluster
LIMIT_SESSION_TIME:: "LIMIT_SESSION_TIME" //whether or not the 24hr session time limit is on or off. default is `true`

//MISC CONSTANTS
ostCarrat :: "OstrichDB>>"
VALID_RECORD_TYPES: []string : {
	"CHAR",
	"STR",
	"INT",
	"FLT",
	"BOOL",
	"STRING",
	"INTEGER",
	"FLOAT",
	"BOOLEAN",
	"DATE",
	"TIME",
	"DATETIME",
	"UUID",
	"NULL",
	"[]CHAR",
	"[]STR",
	"[]STRING",
	"[]INT",
	"[]INTEGER",
	"[]FLT",
	"[]FLOAT",
	"[]BOOL",
	"[]BOOLEAN",
	"[]CHAR",
	"[]DATE",
	"[]TIME",
	"[]DATETIME",
	"[]UUID",
}


NO :: "NO"
YES :: "YES"
CANCEL :: "CANCEL"
CONFIRM :: "CONFIRM"

METADATA_START :: "@@@@@@@@@@@@@@@TOP@@@@@@@@@@@@@@@\n"
METADATA_END :: "@@@@@@@@@@@@@@@BTM@@@@@@@@@@@@@@@\n"

METADATA_HEADER: []string : {
	METADATA_START,
	"# Encryption State: %es\n", //0 = decrypted/1 = encrypted
	"# File Format Version: %ffv\n",
	"# Permission: %perm\n", //Read-Only/Read-Write/Inaccessible
	"# Date of Creation: %fdoc\n",
	"# Date Last Modified: %fdlm\n",
	"# File Size: %fs Bytes\n",
	"# Checksum: %cs\n",
	METADATA_END,
}


SYS_MASTER_KEY := []byte {
	0x8F,
	0x2A,
	0x1D,
	0x5E,
	0x9C,
	0x4B,
	0x7F,
	0x3A,
	0x6D,
	0x0E,
	0x8B,
	0x2C,
	0x5F,
	0x9A,
	0x7D,
	0x4E,
	0x1B,
	0x3C,
	0x6A,
	0x8D,
	0x2E,
	0x5F,
	0x7C,
	0x9B,
	0x4A,
	0x1D,
	0x8E,
	0x3F,
	0x6C,
	0x9B,
	0x2A,
	0x5,
}


MAX_COLLECTION_NAME_LENGTH :: [64]byte
MAX_SESSION_TIME: time.Duration : 86400000000000 //1 day in nanoseconds
MAX_COLLECTION_TO_DISPLAY :: 20 // for TREE command, max number of constants before prompting user to print
MAX_FILE_SIZE: i64 : 10000000 //10MB max database file size
MAX_HISTORY_COUNT: int : 100 //max number of commands to store in the history cluster

FIRST_DESC:: "A NoSQL Database Management System"
SECOND_DESC:: "A NoJSON Database Management System"
THIRD_DESC:: "You're All In One Backend Solution"
FOURTH_DESC :: "A Lightweight Document-Based Database Management System"
FIFTH_DESC:: "A Natural Language Database Management System"

project_descriptions :[]string:{
    FIRST_DESC,
    SECOND_DESC,
    THIRD_DESC,
    FOURTH_DESC,
    FIFTH_DESC
}

//if a user created an account with these names it would break the auth system. Might come back and look at this again.. - SchoolyB
BannedUserNames := []string {
	"admin",
	"user",
	"guest",
	"root",
	"system",
	"sys",
	"administrator",
	"superuser",
	"OstrichDB",
}

//SERVER DYNAMIC ROUTE CONSTANTS
BATCH_C_DYNAMIC_BASE :: "batch/c/*"
BATCH_CL_DYNAMIC_BASE::"batch/c/*/cl/*"
BATCH_R_DYNAMIC_BASE::"batch/c/*/cl/*/r/*"

C_DYNAMIC_BASE :: "/c/*"
CL_DYNAMIC_BASE :: "/c/*/cl/*"
R_DYNAMIC_BASE :: "/c/*/cl/*/r/*"
R_DYNAMIC_TYPE_QUERY :: "/c/*/cl/*/r/*?type=*" //Only used for creating a new record without a value...POST request
R_DYNAMIC_TYPE_VALUE_QUERY :: "/c/*/cl/*/r/*?type=*&value=*" //Used for setting an already existing records value...PUT request

Server_Ports:[]int:{8042,8044,8046,8048,8050}