package const
import "core:time"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//

//PATH CONSTANTS
OST_FFVF :: "ost_file_format_version.tmp"
OST_TMP_PATH :: "./tmp/"
OST_COLLECTION_PATH :: "./collections/"
OST_SECURE_COLLECTION_PATH :: "./secure/"
OST_BACKUP_PATH :: "./backups/"
OST_CORE_PATH :: "./core/"
OST_CONFIG_PATH :: "./core/config.ost"
OST_ID_PATH :: "./core/ids.ost"
OST_HISTORY_PATH :: "./core/history.ost"
CONFIG_CLUSTER :: "OSTRICH_CONFIGS"
CLUSTER_ID_CLUSTER :: "CLUSTER__IDS"
USER_ID_CLUSTER :: "USER__IDS"
OST_BIN_PATH :: "./"
OST_FILE_EXTENSION :: ".ost"
VERBOSE_HELP_FILE :: "../src/core/help/docs/verbose/verbose.md"
SIMPLE_HELP_FILE :: "../src/core/help/docs/simple/simple.md"
GENERAL_HELP_FILE :: "../src/core/help/docs/general/general.md"
ATOMS_HELP_FILE :: "../src/core/help/docs/atoms/atoms.txt"
OST_QUARANTINE_PATH :: "./quarantine/"
//CONFIG FILE CONSTANTS
configOne :: "OST_ENGINE_INIT"
configTwo :: "OST_ENGINE_LOGGING"
configThree :: "OST_USER_LOGGED_IN"
configFour :: "OST_HELP"
configFive :: "OST_SERVER_MODE_ON"
configSix :: "OST_ERROR_SUPPRESSION" //whether errors are printed to the console or not
//ATOM TOKEN CONSTANTS
VERSION :: "VERSION"
HELP :: "HELP" //help can also be a multi token command.
WHERE :: "WHERE"
EXIT :: "EXIT"
RESTART :: "RESTART"
REBUILD :: "REBUILD"
LOGOUT :: "LOGOUT"
TEST :: "TEST"
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
//These follow ISO 8601 format
DATE :: "DATE" //YYYY-MM-DD
TIME :: "TIME" //HH:MM:SS
DATETIME :: "DATETIME" //YYYY-MM-DDTHH:MM:SS
//SPECIAL HELP TOKENS
ATOMS :: "ATOMS"
ATOM :: "ATOM"
//INPUT CONFIRMATION CONSTANTS
YES :: "YES"
NO :: "NO"
CONFIRM :: "CONFIRM"
CANCEL :: "CANCEL"
//FOR DOT NOTATION
DOT :: "."

VALID_TYPES: []string : {
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
	DATE,
	TIME,
	DATETIME,
}
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
	DATE,
	TIME,
	DATETIME,
}

METADATA_START :: "@@@@@@@@@@@@@@@TOP@@@@@@@@@@@@@@@\n"
METADATA_END :: "@@@@@@@@@@@@@@@BTM@@@@@@@@@@@@@@@\n"

MAX_SESSION_TIME: time.Duration : 86400000000000 //1 day in nanoseconds
MAX_COLLECTION_TO_DISPLAY :: 20 // for TREE command, max number of constants before prompting user to print
// MAX_SESSION_TIME: time.Duration : 60000000000 //1 minute in nano seconds only used for testing
MAX_FILE_SIZE: i64 : 10000000 //10MB max database file size
// MAX_FILE_SIZE_TEST: i64 : 10 //10 bytes max file size for testing

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
}

//TEST CONSTANTS
TEST_ID: i64 : 100000000000
TEST_COLLECTION: string : "test_collection"
TEST_CLUSTER: string : "test_cluster"
TEST_RECORD: string : "test_record"
TEST_NEW_COLLECTION :: "test_new_collection"
TEST_NEW_CLUSTER: string : "test_new_cluster"
TEST_NEW_RECORD: string : "test_new_record"
TEST_BACKUP_COLLECTION: string : "test_collection_backup"

TEST_USERNAME: string : "testing_foobar"
TEST_PASSWORD: string : "@Foobar1"
TEST_ROLE: string : "user"
