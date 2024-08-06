package const
import "core:time"
//used in metadata.odin
OST_FFVF :: "ost_file_format_version.tmp"
OST_TMP_PATH :: "../bin/tmp/"
//used in clusters.odin
OST_COLLECTION_PATH :: "../bin/collections/"
OST_SECURE_CLUSTER_PATH :: "../bin/secure/"
OST_BACKUP_PATH :: "../bin/backups/"
OST_FILE_EXTENSION :: ".ost"

VERBOSE_HELP_FILE :: "./core/help/docs/verbose/verbose.md"
SIMPLE_HELP_FILE :: "./core/help/docs/simple/simple.md"
GENERAL_HELP_FILE :: "./core/help/docs/general/general.md"
ATOMS_HELP_FILE :: "./core/help/docs/atoms/atoms.txt"

//used in engine.odin
ost_carrot :: "OST>>>"

// used in auth.odin
SEC_FILE_PATH :: "../bin/secure/_secure_.ost"
SEC_CLUSTER_NAME :: "user_credentials"

// used in credentials.odin
MAX_SIGN_IN_ATTEMPTS :: 10
ATTEMPTS_BEFORE_TIMER :: 5


//used in config.odin
configOne :: "OST_ENGINE_INIT" //values: true, false...has the engine been initialized
//is logging simple or verbose
configTwo :: "OST_ENGINE_LOGGING"
//is user logged in
configThree :: "OST_USER_LOGGED_IN"
//is help documentation simple or verbose
configFour :: "OST_HELP"

//used in commands.odin
//Standard Command Tokens
VERSION :: "VERSION"
HELP :: "HELP"
EXIT :: "EXIT"
LOGOUT :: "LOGOUT"
CLEAR :: "CLEAR" //clears the screen
//Action Tokens-- Require a space before and after the prefix and atleast one argument
NEW :: "NEW" //used to create a new record, cluster, or collection
BACKUP :: "BACKUP" //used to create backup collections
ERASE :: "ERASE" //used to delete a record, cluster, or collection
FETCH :: "FETCH" //used to get the data from a record, cluster, or collection
RENAME :: "RENAME" //used to change the name of a record, cluster, or collection
FOCUS :: "FOCUS" //used change the focus/scope that commands are being executed in
UNFOCUS :: "UNFOCUS" //unfocus the scope that commands are being executed in....Might make it to where you can UNFOCUS a single layer rather than the entire scope. example: UNFOCUS CLUSTER foo (could still preform actions on the COLLECTION)
//Target Tokens -- Require a data to be used
COLLECTION :: "COLLECTION" //Targets a collection to be manupulated
CLUSTER :: "CLUSTER" //Targets a cluster to be manipulated
RECORD :: "RECORD" //Targets a record to be manipulated
ALL :: "ALL" //Targets all records, clusters, or collections that are specified

//Modifier Tokens
AND :: "AND" //used to specify that there is another record, cluster, or collection to be created
OF_TYPE :: "OF_TYPE" //ONLY used to specify the type of data that is going to be stored in a record...see types below
ALL_OF :: "ALL OF" //ONLY used with FETCH and ERASE.
TO :: "TO" //ONLY used with RENAME

//Scope Tokens
WITHIN :: "WITHIN" //used to specify where the record, cluster, or collection is going to be created


//Type Tokens -- Requires a special datas as a prefix
STRING :: "STRING"
INT :: "INT"
FLOAT :: "FLOAT"
BOOL :: "BOOL"

//Used with the HELP command
ATOMS :: "ATOMS"
ATOM :: "ATOM"

//3 days in nanoseconds
MAX_SESSION_TIME: time.Duration : 259200000000000000

//1 minute in nano seconds only used for testing
// MAX_SESSION_TIME: time.Duration : 60000000000

//used for confirming user actions. Input will be capitalized in the engine
YES :: "YES"
NO :: "NO"
