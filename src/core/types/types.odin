package types
import "core:time"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//


//=================================================/src/core/commands/=================================================//
/*
Type: Command
Desc: Used to define the tokens that make up an Ostrich Command
Helpful Hint: Commands are built of ATOMs (A)ction, (T)arget, (O)bject, (M)odifier(s), or (S)cope
Usage Locations: commands.odin & parser.odin
*/
Command :: struct {
	c_token:            string, //command token
	l_token:            [dynamic]string, //location token
	p_token:            map[string]string, //parameter token
	isUsingDotNotation: bool, //if the command is using dot notation
	t_token:            string, //target token only needed for very specific commands like WHERE,HELP, and NEW USER
}
//=================================================/src/core/data/=================================================//
/*
Type: Record
Desc: Used to define the structure of a record withinin the Ostrich Database
      Records are the smallest unit of data within the Ostrich Database
Usage Locations: records.odin
*/
Record :: struct {
	name:  string,
	type:  string,
	value: string,
}

//=================================================/src/core/engine/=================================================//
/*
Type: Engine
Desc: Used to define the overall structure of the Ostrich Engine
      The engine is the core of the Ostrich Database and WILL
        be used to control *most* operations within the database
Usage Locations: NOT YET FULLY IMPLEMENTED but will be used engine.odin
*/
engine: Engine
Engine :: struct {
	EngineRuntime: time.Duration, // The amount of time the engine has been running
	Status:        int, // 0, 1, 2
	StatusName:    string, // Idle, Running, Stopped mostly for logging purposes
	Initialized:   bool, // if the engine has been initialized , important for first run and user setup
	UserLoggedIn:  bool, // if a user is logged in...NO ACTION CAN BE PERFORMED WITHOUT A USER LOGGED IN
}

//=================================================/src/core/security/=================================================//
/*

Type: User_Credential
Desc: Used to define the structure of a user credential within the Ostrich Database
      User credentials are used to authenticate a user within the database
Usage Locations: credentials.odin
*/
User_Credential :: struct {
	Value:  string, //username
	Length: int, //length of the username
}

/*
Type: User
Desc: Used to define the structure of a user within the Ostrich Database
      Users are the entities that interact with the Ostrich Database
Usage Locations: credentials.odin
*/
user: User
current_user: User //used to track the user of the current session
new_user: User //used for creating new accounts post initialization
User :: struct {
	user_id:        i64, //randomly generated user id
	role:           User_Credential,
	username:       User_Credential,
	password:       User_Credential, //will never be stored as plain text

	//below this line is for encryption purposes
	salt:           []u8,
	hashedPassword: []u8, //this is the hashed password without the salt
	store_method:   int,
	//below is literally for the users command HISTORY
	commandHistory: CommandHistory,
}

//a users command history
CommandHistory :: struct {
	cHistoryNamePrefix: string, //will always be "history_"
	cHistoryValues:     [dynamic]string,
	cHistoryCount:      int, //the total
	cHistoryIndex:      int, //the current index of the history array
	cHistoryPrevious:   string,
}

id: Ids
Ids :: struct {
	clusterIdCount: int,
	userIdCount:    int,
}

help_mode: Help_Mode
Help_Mode :: struct {
	verbose: bool, //if its false then its simple
}


// =================================================/src/core/data/=================================================//
/*
Type: Data_Integrity_Checks
Desc: Used to ensure data integrity within the Ostrich Database
Usage Locations: records.odin, clusters.odin, collections.odin
*/
data_integrity_checks: Data_Integrity_Checks


Data_Integrity_Checks :: struct {
	File_Size:           Data_Integrity_Info, //ensure file size isnt larger than const.MAX_FILE_SIZE. LOW SEVERITY
	File_Format:         Data_Integrity_Info, //ensure proper format of the file ie closing brackets, commas, etc... HIGH SEVERITY
	File_Format_Version: Data_Integrity_Info, //ensure that the file format version is compliant with the current version. MEDIUM SEVERITY
	Cluster_IDs:         Data_Integrity_Info, //ensure that the value of all cluster ids within a collection are in the cache. HIGH SEVERITY
	Data_Types:          Data_Integrity_Info, //ensure that all records have a data type and that its an approved one  HIGH SEVERITY
	//possibly add number of checks failed vs checks passed/ran
}

Data_Integrity_Info :: struct {
	Compliant:     bool,
	Severity:      Data_Integrity_Severity,
	Error_Message: string,
}

Data_Integrity_Severity :: enum {
	LOW    = 0,
	MEDIUM = 1,
	HIGH   = 2,
}


//some gloables because fuck cyclical importation problems in Odin
USER_SIGNIN_STATUS: bool
Message_Color: string //used in checks.odin
Severity_Code: int //used in checks.odin


schema: Collection_File_Schema
Collection_File_Schema :: struct {
	Metadata_Header_Body: [5]string, //doesnt count the header start and end lines
}


//Server Stuff Below
//Server Stuff Below
//Server Stuff Below

Server_Config :: struct {
	port: int,
}

HttpStatusCode :: enum {
	OK           = 200,
	BAD_REQUEST  = 400,
	NOT_FOUND    = 404,
	SERVER_ERROR = 500,
}

HttpStatus :: struct {
	code: HttpStatusCode,
	text: string,
}

HttpMethod :: enum {
	HEAD,
	GET,
	POST,
	PUT,
	DELETE,
}

// m -  method p - path h - headers
RouteHandler :: proc(
	m: string,
	p: string,
	h: map[string]string,
	params: ..string,
) -> (
	HttpStatus,
	string,
)


Route :: struct {
	m: HttpMethod, //method
	p: string, //path
	h: RouteHandler, //handler
}
Router :: struct {
	routes: [dynamic]Route,
}

//IDk what the fuck #sparse does but the language server stopped yelling at me when I added it so fuck it - Marshall aka SchoolyB
HttpStatusText :: #sparse[HttpStatusCode]string {
	.OK           = "OK",
	.BAD_REQUEST  = "Bad Request",
	.NOT_FOUND    = "Not Found",
	.SERVER_ERROR = "Internal Server Error",
}


//BATCH OPERATION STUFF
//BATCH OPERATION STUFF
//BATCH OPERATION STUFF


// OST_BATCH_OPERATION :: proc(batch: BatchRequest, params: [dynamic]string) -> int
OST_BATCH_COLLECTION_PROC :: proc(names: []string, operation: BatchOperation) -> int //Used for batch operations on collections using the NEW/ERASE/FETCH tokens
//used when multiple operations are to be performed

BatchOperations :: enum {
	//Rename is not uncluded because that token will require 2 inputs...ie the old name and new name. these only need 1
	NEW   = 1,
	ERASE = 2,
	FETCH = 3,
}

BatchRequest :: struct {
	operations: []BatchOperation,
	atomic:     bool,
}


BatchOperation :: struct {
	operation:      string,
	collectionName: string,
	clusterName:    string,
	recordName:     string,
	record:         Record, //this will allow for the name,type and value of the record
}

errSupression: ErrorSuppression
ErrorSuppression :: struct {
	enabled: bool, //uses the OST_READ_CONFIG_VALUE to get the value of the error suppression config then set true or false
}

TESTING: bool // Global flag to indicate if running in test mode
