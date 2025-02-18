package types
import "core:time"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
*********************************************************/


Command :: struct {
	c_token:            string, //command token
	l_token:            [dynamic]string, //location token
	p_token:            map[string]string, //parameter token
	isUsingDotNotation: bool, //if the command is using dot notation
	t_token:            string, //target token only needed for very specific commands like WHERE,HELP, and NEW USER
}

Record :: struct {
	name:  string,
	type:  string,
	value: string,
}


OstrichEngine: Engine
Engine :: struct {
	EngineRuntime: time.Duration, // The amount of time the engine has been running
	Status:        int, // 0, 1, 2
	StatusName:    string, // Idle, Running, Stopped mostly for logging purposes
	Initialized:   bool, // if the engine has been initialized , important for first run and user setup
	UserLoggedIn:  bool, // if a user is logged in...NO ACTION CAN BE PERFORMED WITHOUT A USER LOGGED IN
}


User_Credential :: struct {
	Value:  string, //username
	Length: int, //length of the username
}

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
	m_k:            []u8, //master key
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

helpMode: Help_Mode
Help_Mode :: struct {
	isVerbose: bool, //if its false then its simple
}


data_integrity_checks: Data_Integrity_Checks
Data_Integrity_Checks :: struct {
	File_Size:           Data_Integrity_Info, //ensure file size isnt larger than const.MAX_FILE_SIZE. LOW SEVERITY
	File_Format:         Data_Integrity_Info, //ensure proper format of the file ie closing brackets, commas, etc... HIGH SEVERITY
	File_Format_Version: Data_Integrity_Info, //ensure that the file format version is compliant with the current version. MEDIUM SEVERITY
	Cluster_IDs:         Data_Integrity_Info, //ensure that the value of all cluster ids within a collection are in the cache. HIGH SEVERITY
	Data_Types:          Data_Integrity_Info, //ensure that all records have a data type and that its an approved one  HIGH SEVERITY
	Checksum:            Data_Integrity_Info, //ensure that the checksum of the file is correctly calculated and matches the value in the file. HIGH SEVERITY
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


Metadata_Header_Body := [5]string {
	"# File Format Version: ",
	"# Date of Creation: ",
	"# Date Last Modified: ",
	"# File Size: ",
	"# Checksum: ",
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

benchmark_result: Benchmark_Result
Benchmark_Result :: struct {
	op_name:        string,
	op_time:        time.Duration,
	ops_per_second: f64,
	total_ops:      int,
	success:        bool,
}
