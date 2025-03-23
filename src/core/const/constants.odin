package const
import "core:fmt"
import "core:time"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            Contains all constants used throughout the OstrichDB project.
*********************************************************/

//Defines is a command line constant pfor file paths
//Read more about this here: https://odin-lang.org/docs/overview/#command-line-defines
OST_DEV_MODE :: #config(OST_DEV_MODE, false)

//Conditional file path constants thanks to the install debacle of Feb 2025 - Marshall
//See more here: https://github.com/Solitude-Software-Solutions/OstrichDB/issues/223
//DO NOT TOUCH MF - Marshall
when OST_DEV_MODE == true {
	OST_TMP_PATH :: "./tmp/"
	OST_PRIVATE_PATH :: "./private/"
	OST_PUBLIC_PATH :: "./public/"
	OST_PUBLIC_STANDARD_COLLECTION_PATH :: "./public/standard/"
	OST_SECURE_COLLECTION_PATH :: "./private/secure/"
	OST_BACKUP_PATH :: "./public/backups/"
	OST_CONFIG_PATH :: "./private/config.ost"
	OST_ID_PATH :: "./private/ids.ost"
	OST_HISTORY_PATH :: "./private/history.ost"
	OST_BENCHMARK_PATH :: "./private/benchmark/"
	LOG_DIR_PATH :: "./logs/"
	RUNTIME_LOG_PATH :: "./logs/runtime.log"
	ERROR_LOG_PATH :: "./logs/errors.log"
	OST_QUARANTINE_PATH :: "./public/quarantine/"
	OST_RESTART_SCRIPT_PATH :: "../scripts/restart.sh"
	OST_BUILD_SCRIPT_PATH :: "../scripts/local_build_run.sh"
} else {
	OST_TMP_PATH :: "./.ostrichdb/tmp/"
	OST_PRIVATE_PATH :: "./.ostrichdb/private/"
	OST_PUBLIC_PATH :: "./.ostrichdb/public/"
	OST_PUBLIC_STANDARD_COLLECTION_PATH :: "./.ostrichdb/public/standard/"
	OST_SECURE_COLLECTION_PATH :: "./.ostrichdb/private/secure/"
	OST_BACKUP_PATH :: "./.ostrichdb/public/backups/"
	OST_CONFIG_PATH :: "./.ostrichdb/private/config.ost"
	OST_ID_PATH :: "./.ostrichdb/private/ids.ost"
	OST_HISTORY_PATH :: "./.ostrichdb/private/history.ost"
	OST_BENCHMARK_PATH :: "./.ostrichdb/private/benchmark/"
	LOG_DIR_PATH :: "./.ostrichdb/logs/"
	RUNTIME_LOG_PATH :: "./.ostrichdb/logs/runtime.log"
	ERROR_LOG_PATH :: "./.ostrichdb/logs/errors.log"
	OST_QUARANTINE_PATH :: "./.ostrichdb/public/quarantine/"
	OST_RESTART_SCRIPT_PATH :: "./.ostrichdb/restart.sh"
	OST_BUILD_SCRIPT_PATH :: "./.ostrichdb/build_run.sh"
}

//Non-changing PATH CONSTANTS

OST_FFVF_PATH :: "ost_file_format_version.tmp"
CONFIG_CLUSTER :: "OSTRICH_CONFIGS"
CLUSTER_ID_CLUSTER :: "CLUSTER__IDS"
USER_ID_CLUSTER :: "USER__IDS"
OST_FILE_EXTENSION :: ".ost"
VERBOSE_HELP_FILE :: "../src/core/help/docs/verbose/verbose.md"
SIMPLE_HELP_FILE :: "../src/core/help/docs/simple/simple.md"
GENERAL_HELP_FILE :: "../src/core/help/docs/general/general.md"
CLPS_HELP_FILE :: "../src/core/help/docs/clps/clps.txt"


//CONFIG FILE CONSTANTS
CONFIG_ONE :: "ENGINE_INIT"
CONFIG_TWO :: "ENGINE_LOGGING"
CONFIG_THREE :: "USER_LOGGED_IN"
CONFIG_FOUR :: "HELP_IS_VERBOSE"
CONFIG_FIVE :: "AUTO_SERVE" //whenever cli tool starts it runs the server if this is set to true
CONFIG_SIX :: "ERROR_SUPPRESSION" //whether errors are printed to the console or not
CONFIG_SEVEN :: "LIMIT_HISTORY" //whether or not to limit how the number of commands are stored in the users history cluster


//CLP TOKEN CONSTANTS
//Todo: Just use an enum for this
VERSION :: "VERSION"
HELP :: "HELP" //help can also be a multi token command.
WHERE :: "WHERE"
EXIT :: "EXIT"
RESTART :: "RESTART"
REBUILD :: "REBUILD"
SERVE :: "SERVE"
SERVER :: "SERVER" //same as SERVE
LOGOUT :: "LOGOUT"
CLEAR :: "CLEAR"
TREE :: "TREE"
HISTORY :: "HISTORY"
//Command Tokens
NEW :: "NEW"
BACKUP :: "BACKUP"
ERASE :: "ERASE"
RENAME :: "RENAME"
FETCH :: "FETCH"
COUNT :: "COUNT"
SET :: "SET"
PURGE :: "PURGE"
SIZE_OF :: "SIZE_OF"
TYPE_OF :: "TYPE_OF" //not the same as OF_TYPE. This is used as an command token to get the type of a record
CHANGE_TYPE :: "CHANGE_TYPE"
DESTROY :: "DESTROY"
ISOLATE :: "ISOLATE"
VALIDATE :: "VALIDATE"
BENCHMARK :: "BENCHMARK"
IMPORT :: "IMPORT"
EXPORT :: "EXPORT"
LOCK :: "LOCK"
UNLOCK :: "UNLOCK"
TEST :: "TEST" //Useful for testing new procdures for command line. i.e TEST FOO could just call a procedure you want to perform on the collection FOO
ENC :: "ENC" //Encrypt a collection
DEC :: "DEC" //Decrypt a collection
//Target Tokens
COLLECTION :: "COLLECTION"
CLUSTER :: "CLUSTER"
RECORD :: "RECORD"
USER :: "USER"
ALL :: "ALL"
CONFIG :: "CONFIG" //special target exclusive to SET command
//Special Target Tokens for the COUNT command
COLLECTIONS :: "COLLECTIONS"
CLUSTERS :: "CLUSTERS"
RECORDS :: "RECORDS"
//Modifier Tokens
AND :: "AND"
OF_TYPE :: "OF_TYPE"
TYPE :: "TYPE"
ALL_OF :: "ALL_OF"
TO :: "TO"

//Type Tokens
STRING :: "STRING"
STR :: "STR"
//------------
INTEGER :: "INTEGER"
INT :: "INT"
//------------
FLOAT :: "FLOAT"
FLT :: "FLT"
//------------
BOOLEAN :: "BOOLEAN"
BOOL :: "BOOL"
//------------
CHAR :: "CHAR"
//------------
//COMPLEX TYPES
STRING_ARRAY :: "[]STRING"
STR_ARRAY :: "[]STR"
INTEGER_ARRAY :: "[]INTEGER"
INT_ARRAY :: "[]INT"
FLOAT_ARRAY :: "[]FLOAT"
FLT_ARRAY :: "[]FLT"
BOOLEAN_ARRAY :: "[]BOOLEAN"
BOOL_ARRAY :: "[]BOOL"
CHAR_ARRAY :: "[]CHAR"
//These follow ISO 8601 format
DATE :: "DATE" //YYYY-MM-DD
TIME :: "TIME" //HH:MM:SS
DATETIME :: "DATETIME" //YYYY-MM-DDTHH:MM:SS
DATE_ARRAY :: "[]DATE"
TIME_ARRAY :: "[]TIME"
DATETIME_ARRAY :: "[]DATETIME"
//MISC TYPES
UUID :: "UUID"
UUID_ARRAY :: "[]UUID"
NULL :: "NULL"

//SPECIAL HELP TOKENS
CLPS :: "CLPS"
CLP :: "CLP"
//INPUT CONFIRMATION CONSTANTS
YES :: "YES"
NO :: "NO"
CONFIRM :: "CONFIRM"
CANCEL :: "CANCEL"
//FOR DOT NOTATION
DOT :: "."
//MISC CONSTANTS
ost_carrot :: "OST>>>"
VALID_RECORD_TYPES: []string : {
	STRING,
	INTEGER,
	FLOAT,
	BOOLEAN,
	STR,
	INT,
	FLT,
	BOOL,
	CHAR,
	STRING_ARRAY,
	STR_ARRAY,
	INTEGER_ARRAY,
	INT_ARRAY,
	FLOAT_ARRAY,
	FLT_ARRAY,
	BOOLEAN_ARRAY,
	BOOL_ARRAY,
	CHAR_ARRAY,
	DATE,
	TIME,
	DATETIME,
	DATE_ARRAY,
	TIME_ARRAY,
	DATETIME_ARRAY,
	UUID,
	UUID_ARRAY,
	NULL,
}

METADATA_START :: "@@@@@@@@@@@@@@@TOP@@@@@@@@@@@@@@@\n"
METADATA_END :: "@@@@@@@@@@@@@@@BTM@@@@@@@@@@@@@@@\n"


METADATA_HEADER: []string : {
	METADATA_START,
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
// MAX_SESSION_TIME: time.Duration : 60000000000 //1 minute in nano seconds only used for testing
MAX_FILE_SIZE: i64 : 10000000 //10MB max database file size
// MAX_FILE_SIZE_TEST: i64 : 10 //10 bytes max file size for testing
MAX_HISTORY_COUNT: int : 100 //max number of commands to store in the history cluster
// MAX_HISTORY_COUNT: int : 5 //max number of commands for testing

//NON CONSTANTS BUT GLOBAL
ConfigHeader := "#This file was generated by OstrichDB\n#Do NOT modify this file unless you know what you are doing\n#For more information on OstrichDB visit: https://github.com/Solitude-Software-Solutions/OstrichDB\n\n\n\n"
QuarantineStr: string = "\n# [QUARANTINED] [QUARANTINED] [QUARANTINED] [QUARANTINED]\n"

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


//IMPORT CONSTANTS
//suffix that is added to the cluster name when a .csv file is imported
CSV_CLU :: "_CSV_IMPORT"


//SERVER DYNAMIC ROUTE CONSTANTS
C_DYNAMIC_BASE :: "/c/*"
CL_DYNAMIC_BASE :: "/c/*/cl/*"
R_DYNAMIC_BASE :: "/c/*/cl/*/r/*"
R_DYNAMIC_TYPE_QUERY :: "/c/*/cl/*/r/*?type=*" //Only used for creating a new record without a value...POST request
R_DYNAMIC_TYPE_VALUE_QUERY :: "/c/*/cl/*/r/*?type=*&value=*" //Used for setting an already existing records value...PUT request
