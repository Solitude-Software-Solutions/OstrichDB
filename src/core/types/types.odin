package types
import "../types"
import "core:crypto/aes"
import "core:time"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2024-Present Marshall A Burns and Solitude Software Solutions LLC

File Description:
            Contains most but not all of the types used in OstrichDB.
*********************************************************/


Command :: struct {
	c_token:            TokenType, //command token
	l_token:            [dynamic]string, //location token
	p_token:            map[string]string, //parameter token
	isUsingDotNotation: bool, //if the command is using dot notation
	t_token:            string, //target token only needed for very specific commands like WHERE,HELP, and NEW USER
}

TokenType :: enum {
	//Command tokens
	INVALID,
	EXIT,
	LOGOUT,
	RESTART,
	REBUILD,
	DESTROY,
	AGENT,
	VERSION,
	HELP,
	SERVE,
	SERVER,
	CLEAR,
	TREE,
	HISTORY,
	WHERE,
	NEW,
	BACKUP,
	ERASE,
	RENAME,
	FETCH,
	COUNT,
	SET,
	PURGE,
	SIZE_OF,
	TYPE_OF,
	CHANGE_TYPE,
	ISOLATE,
	VALIDATE,
	BENCHMARK,
	IMPORT,
	EXPORT,
	LOCK,
	UNLOCK,
	ENC,
	ENCRYPT,
	DEC,
	DECRYPT,
	USER,
	CONFIG,
	//Parameter tokens
	OF_TYPE,
	TO,
	//Shorthand and traditional basic type tokens
	STR,
	STRING,
	INT,
	INTEGER,
	FLT,
	FLOAT,
	BOOL,
	BOOLEAN,
	CHAR,
	//shorthand and traditional complex types
	STR_ARRAY,
	STRING_ARRAY,
	INT_ARRAY,
	INTEGER_ARRAY,
	FLT_ARRAY,
	FLOAT_ARRAY,
	BOOL_ARRAY,
	BOOLEAN_ARRAY,
	CHAR_ARRAY,
	//More advance complex types...They follow ISO 8601 format
	DATE,
	TIME,
	DATETIME,
	DATE_ARRAY,
	TIME_ARRAY,
	DATETIME_ARRAY,
	//Misc types
	UUID,
	UUID_ARRAY,
	NULL,
	// Lesser used target tokens
	COLLECTION,
	COLLECTIONS,
	CLUSTER,
	CLUSTERS,
	RECORD,
	RECORDS,
	// General purpose misc tokens
	CLPS,
	CLP,
	YES,
	NO,
	CONFIRM,
	CANCEL,
	//Not using any tokens below this point yet... - Marshall
	// TEST,
	// ALL,
	// AND,
	// ALL_OFF,
}

//Used partial because INVALID is not an actual token to be used
Token := #partial [TokenType]string {
	.EXIT           = "EXIT",
	.LOGOUT         = "LOGOUT",
	.RESTART        = "RESTART",
	.REBUILD        = "REBUILD",
	.DESTROY        = "DESTROY",
	.AGENT          = "AGENT",
	.VERSION        = "VERSION",
	.HELP           = "HELP",
	.SERVE          = "SERVE",
	.SERVER         = "SERVER",
	.CLEAR          = "CLEAR",
	.TREE           = "TREE",
	.HISTORY        = "HISTORY",
	.WHERE          = "WHERE",
	//Command Tokens
	.NEW            = "NEW",
	.BACKUP         = "BACKUP",
	.ERASE          = "ERASE",
	.RENAME         = "RENAME",
	.FETCH          = "FETCH",
	.COUNT          = "COUNT",
	.SET            = "SET",
	.PURGE          = "PURGE",
	.SIZE_OF        = "SIZE_OF",
	.TYPE_OF        = "TYPE_OF",
	.CHANGE_TYPE    = "CHANGE_TYPE",
	.ISOLATE        = "ISOLATE",
	.VALIDATE       = "VALIDATE",
	.BENCHMARK      = "BENCHMARK",
	.IMPORT         = "IMPORT",
	.EXPORT         = "EXPORT",
	.LOCK           = "LOCK",
	.UNLOCK         = "UNLOCK",
	.ENC            = "ENC",
	.ENCRYPT        = "ENCRYPT",
	.DEC            = "DEC",
	.DECRYPT        = "DECRYPT",
	.USER           = "USER",
	.CONFIG         = "CONFIG",
	//Parameter tokens
	.OF_TYPE        = "OF_TYPE",
	.TO             = "TO",
	//Shorthand and traditional basic type tokens
	.CHAR           = "CHAR",
	.STR            = "STR",
	.STRING         = "STRING",
	.INT            = "INT",
	.INTEGER        = "INTEGER",
	.FLT            = "FLT",
	.FLOAT          = "FLOAT",
	.BOOL           = "BOOL",
	.BOOLEAN        = "BOOLEAN",
	//shorthand and traditional complex types
	.CHAR_ARRAY     = "[]CHAR",
	.STR_ARRAY      = "[]STR",
	.STRING_ARRAY   = "[]STRING",
	.INT_ARRAY      = "[]INT",
	.INTEGER_ARRAY  = "[]INTEGER",
	.FLT_ARRAY      = "[]FLT",
	.FLOAT_ARRAY    = "[]FLOAT",
	.BOOL_ARRAY     = "[]BOOL",
	.BOOLEAN_ARRAY  = "[]BOOLEAN",
	//More advance complex types...They follow ISO 8601 format
	.DATE           = "DATE",
	.TIME           = "TIME",
	.DATETIME       = "DATETIME",
	.DATE_ARRAY     = "[]DATE",
	.TIME_ARRAY     = "[]TIME",
	.DATETIME_ARRAY = "[]DATETIME",
	//Misc types
	.UUID           = "UUID",
	.UUID_ARRAY     = "[]UUID",
	.NULL           = "NULL",
	// Lesser used target tokens
	.COLLECTION     = "COLLLECTION",
	.COLLECTIONS    = "COLLECTIONS",
	.CLUSTER        = "CLUSTER",
	.CLUSTERS       = "CLUSTERS",
	.RECORD         = "RECORD",
	.RECORDS        = "RECORDS",
	// General purpose misc tokens
	.CLP            = "CLP",
	.CLPS           = "CLPS",
	.YES            = "YES",
	.NO             = "NO",
	.CONFIRM        = "CONFIRM",
	.CANCEL         = "CANCEL",
	//Not using any tokens below this point yet... - Marshall
	// .TEST = "TEST",
	// .ALL = "ALL",
	// .AND = "AND",
	// .ALL_OFF = "ALL_OFF",
}

Operation_Permssion_Requirement :: enum {
	READ_ONLY,
	READ_WRITE,
	INACCESSABLE,
}


CommandOperation :: struct {
	name:          string,
	permission:    [dynamic]Operation_Permssion_Requirement,
	permissionStr: [dynamic]string,
}

CollectionType :: enum {
	STANDARD_PUBLIC = 0, //Enc/Dec with users master key
	SECURE_PRIVATE  = 1, //Enc/Dec with users master key even though its private
	CONFIG_PRIVATE  = 2, //Enc/Dec with systems master key
	HISTORY_PRIVATE = 3, //Enc/Dec with systems master key
	ID_PRIVATE      = 4, //Enc/Dec with systems master key
	ISOLATE_PUBLIC  = 5, //Enc/Dec with users master key
	//Todo: Add backup, and benchmark
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
system_user: User = { 	//OstrichDB itself
	user_id = -1,
	username = User_Credential{Value = "OstrichDB", Length = 9},
	m_k = SpecialUserCred {
		valAsBytes = []u8 {
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
		},
		valAsStr = "8F2A1D5E9C4B7F3A6D0E8B2C5F9A7D4E1B3C6A8D2E5F7C9B4A1D8E3F6C9B2A5",
	},
}
User :: struct {
	user_id:        i64, //randomly generated user id
	role:           User_Credential,
	username:       User_Credential,
	password:       User_Credential, //will never be stored as plain text

	//below this line is for encryption purposes
	salt:           SpecialUserCred,
	hashedPassword: SpecialUserCred, //this is the hashed password without the salt
	store_method:   int,
	//below is literally for the users command HISTORY
	commandHistory: CommandHistory,
	m_k:            SpecialUserCred, //master key
}


SpecialUserCred :: struct {
	valAsBytes: []u8,
	valAsStr:   string,
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


ServerConfig := types.Server_Config {
	port = 8042, //default
}

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

//global error suppression
errSupression: ErrorSuppression
ErrorSuppression :: struct {
	enabled: bool, //uses the OST_READ_CONFIG_VALUE to get the value of the error suppression config then set true or false
}

//Server logging stuff
benchmark_result: Benchmark_Result
Benchmark_Result :: struct {
	op_name:        string,
	op_time:        time.Duration,
	ops_per_second: f64,
	total_ops:      int,
	success:        bool,
}

//Server logging stuff
new_event: ServerEvent
ServerEvent :: struct {
	Name:           string,
	Description:    string,
	Type:           ServerEventType,
	Timestamp:      time.Time,
	isRequestEvent: bool,
	Route:          Route,
	StatusCode:     HttpStatusCode,
}


ServerEventType :: enum {
	ROUTINE        = 1,
	WARNING        = 2,
	ERROR          = 3,
	CRITICAL_ERROR = 4,
}
