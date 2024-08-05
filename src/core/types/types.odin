package types

import "core:time"


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
Usage Locations: NOT YET IMPLEMENTED but will be in records.odin and possibly clusters.odin
*/
Record :: struct {
	_name: string,
	_type: any,
	_data: any,
}

/*
Type: Cluster
Desc: Used to define the structure of a cluster within the Ostrich Database
      Clusters are a collection of records
Usage Locations: NOT YET IMPLEMENTED but will be in clusters.odin
*/
Cluster :: struct {
	cluster_name: string,
	cluster_id:   int, //unique identifier for the record cannot be duplicated
	record:       [dynamic]Record, //so that the cluster can hold multiple records
}

//NOTE THERE IS NOT A TYPE FOR A COLLECTION :^)


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
}

//=================================================/src/core/security/=================================================//
/*
Type: User_Role
Desc: Used to define the roles that a user can have within the Ostrich Database
      Roles are used to define the permissions that a user has within the database
*/
User_Role :: enum {
	ADMIN,
	USER,
	GUEST,
}

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
User :: struct {
	user_id:        i64, //randomly generated user id
	role:           User_Role,
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
	// The related target and object are used to provide futher context for the focus
	rt_:  string, // The related target (e.g., "RECORD")
	ro_:  string, // The related object (e.g., "myRecord")
	flag: bool, // If the focus is active
}
//some gloables because fuck cyclical importation problems in Odin
USER_SIGNIN_STATUS: bool
