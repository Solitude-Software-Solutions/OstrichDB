package types
import "core:time"
//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions
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
	a_token: string, //action token
	t_token: string, //object token
	o_token: [dynamic]string, //target token
	m_token: map[string]string, //modifier token
	s_token: map[string]string, //scope token
}
//=================================================/src/core/data/=================================================//
/*
Type: Record
Desc: Used to define the structure of a record withinin the Ostrich Database
      Records are the smallest unit of data within the Ostrich Database
Usage Locations: records.odin
*/
Record :: struct {
	name: string,
	type: string,
	data: string,
}


//=================================================/src/core/engine/=================================================//
/*
Type: Engine_Error
Desc: Used to define the structure of an ENGINE SPECIFIC utils. Not to
        be confused with the standard errors located in utils.odin
Usage Locations: NOT YET IMPLEMENTED but wil be used in several places
*/
Engine_Error :: struct {
	Code:      enum {
		None          = 0,
		InvalidRecord = 1,
		InvalidObject = 2,
		InvalidAction = 3,
	},
	Message:   string,
	Acion:     string, // the action/operation that caused the error
	Procedure: string, // the specific procedure that the error occurred in
}

/*
Type: Task_Flag
Desc: Used to define the status of a task within the Ostrich Engine
        Tasks are the operations run when a command is executed
*/
Task_Flag :: enum {
	None      = 0,
	Queued    = 10,
	Running   = 20,
	Completed = 30,
	Failed    = 40,
}


/*
Type: Engine
Desc: Used to define the overall structure of the Ostrich Engine
      The engine is the core of the Ostrich Database and WILL
        be used to control *most* operations within the database
Usage Locations: NOT YET FULLY IMPLEMENTED but will be used engine.odin
*/
engine: Engine
Engine :: struct {
	EngineRuntime:   time.Duration, // The amount of time the engine has been running
	Status:          int, // 0, 1, 2
	StatusName:      string, // Idle, Running, Stopped mostly for logging purposes
	Initialized:     bool, // if the engine has been initialized , important for first run and user setup
	UserLoggedIn:    bool, // if a user is logged in...NO ACTION CAN BE PERFORMED WITHOUT A USER LOGGED IN
	RecordsCreated:  int,
	RecordsDeleted:  int,
	RecordsUpdated:  int,
	ClustersCreated: int,
	ClustersDeleted: int,
	ClustersUpdated: int,
	//Tasking stuff
	Tasking:         struct {
		NameOfTask:     string,
		TaskNumber:     int,
		TaskElapsed:    time.Duration,
		ProgressOfTask: f32, // will be a percentage
		TargetDatabase: string, // will be the path to the database file
		Error:          Engine_Error,
		StatusOfTask:   Task_Flag,
	},
	// State: int //running or stopped 1 is running 0 is stopped
}

//=================================================/src/core/security/=================================================//
/*
Type: User_Role
Desc: Used to define the roles that a user can have within the Ostrich Database
      Roles are used to define the permissions that a user has within the database
*/


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
}


//=================================================/src/core/focus/=================================================//
/*
Type: Focus
Desc: Used to determin which layer of data the user is focusing on to shorten the
      amount of ATOM tokns that the user needs to enter when executing a command
Usage Locations: focus.odin
*/
focus: Focus
Focus :: struct {
	t_:   string, // The primary target (e.g., "CLUSTER" or "COLLECTION")
	o_:   string, // The primary object (e.g., "myCluster" or "myCollection")
	p_o:  string, // The parent object of the primary object (e.g., "myCluster" or "myCollection")
	// gp_o: string, // The grandparent object of the primary object (e.g.,"myCollection" in relation to a record in "myCluster")
	// The related target and object are used to provide futher context for the focus
	rt_:  string, // The related target (e.g., "RECORD")
	ro_:  string, // The related object (e.g., "myRecord")
	flag: bool, // If the focus is active
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
	File_Size:           Data_Integrity_Info, //ensure file size isnt larger thant const.MAX_FILE_SIZE. LOW SEVERITY
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


schema: Colletion_File_Schema
Colletion_File_Schema :: struct {
	Metadata_Header_Body: [5]string, //doesnt count the header start and end lines
}

