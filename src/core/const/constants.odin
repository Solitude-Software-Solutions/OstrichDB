package const


//used in clusters.odin
OST_COLLECTION_PATH :: "../bin/collections/"
OST_SECURE_CLUSTER_PATH :: "../bin/secure/"
OST_FILE_EXTENSION :: ".ost"

//used in engine.odin
ost_carrot :: "OST>>>\t"

// used in auth.odin
SEC_FILE_PATH :: "../bin/secure/_secure_.ost"
SEC_CLUSTER_NAME :: "user_credentials"

// used in credentials.odin
MAX_SIGN_IN_ATTEMPTS :: 10
ATTEMPTS_BEFORE_TIMER :: 5


//used in config.odin
configOne :: "OST_ENGINE_INIT" //values: true, false...has the engine been initialized
configTwo :: "OST_ENGINE_LOGGING" //values: simple, verbose, none???
configThree :: "OST_ENGINE_HELP" //values: true, false...helpful hints for users... might delete once I incorporate athe help command


//used in commands.odin
//Standard Command Tokens
VERSION :: "VERSION"
HELP :: "HELP"
EXIT :: "EXIT"
LOGOUT :: "LOGOUT"

//Action Tokens-- Require a space before and after the prefix and atleast one argument
NEW :: "NEW" //used to create a new record, cluster, or collection
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
//might add more...doubtful though
