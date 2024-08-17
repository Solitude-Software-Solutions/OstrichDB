package const
import "core:time"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//

//PATH CONSTANTS
OST_FFVF :: "ost_file_format_version.tmp"
OST_TMP_PATH :: "../bin/tmp/"
OST_COLLECTION_PATH :: "../bin/collections/"
OST_SECURE_COLLECTION_PATH :: "../bin/secure/"
SEC_FILE_PATH :: "../bin/secure/_secure_.ost"
OST_SECURE_CLUSTER_PATH :: "../bin/secure/"
OST_BACKUP_PATH :: "../bin/backups/"
OST_CONFIG_PATH :: "../bin/ostrich.config"
OST_FILE_EXTENSION :: ".ost"
VERBOSE_HELP_FILE :: "./core/help/docs/verbose/verbose.md"
SIMPLE_HELP_FILE :: "./core/help/docs/simple/simple.md"
GENERAL_HELP_FILE :: "./core/help/docs/general/general.md"
ATOMS_HELP_FILE :: "./core/help/docs/atoms/atoms.txt"

//CONFIG FILE CONSTANTS
configOne :: "OST_ENGINE_INIT"
configTwo :: "OST_ENGINE_LOGGING"
configThree :: "OST_USER_LOGGED_IN"
configFour :: "OST_HELP"

//ATOM TOKEN CONSTANTS
VERSION :: "VERSION"
HELP :: "HELP"
EXIT :: "EXIT"
LOGOUT :: "LOGOUT"
CLEAR :: "CLEAR"
//Action Tokens
NEW :: "NEW"
BACKUP :: "BACKUP"
ERASE :: "ERASE"
FETCH :: "FETCH"
RENAME :: "RENAME"
FOCUS :: "FOCUS"
UNFOCUS :: "UNFOCUS"
//Target Tokens
COLLECTION :: "COLLECTION"
CLUSTER :: "CLUSTER"
RECORD :: "RECORD"
ALL :: "ALL"
//Modifier Tokens
AND :: "AND"
OF_TYPE :: "OF_TYPE"
TYPE :: "TYPE"
ALL_OF :: "ALL OF"
TO :: "TO"
//Scope Tokens
WITHIN :: "WITHIN"
IN :: "IN"
//Type Tokens
STRING :: "STRING"
INT :: "INT"
FLOAT :: "FLOAT"
BOOL :: "BOOL"
//SPECIAL HELP TOKENS
ATOMS :: "ATOMS"
ATOM :: "ATOM"
//INPUT CONFIRMATION CONSTANTS
YES :: "YES"
NO :: "NO"

//MISC CONSTANTS
ost_carrot :: "OST>>>"
SEC_CLUSTER_NAME :: "user_credentials"
VALID_RECORD_TYPES: []string : {STRING, INT, FLOAT, BOOL}
MAX_SESSION_TIME: time.Duration : 259200000000000000 //3 days in nanoseconds
// MAX_SESSION_TIME: time.Duration : 60000000000 //1 minute in nano seconds only used for testing


//NON CONSTANTS BUT GLOBAL
ConfigHeader := "#This file was generated by OstrichDB\n#Do NOT modify this file unless you know what you are doing\n#For more information on the Ostrich Database Engine visit: https://github.com/Solitude-Software-Solutions/OstrichDB\n\n\n\n"
