package engine

import "core:fmt"
import "core:os"
import "core:time"
import "../data"


ost_engine: Ost_Engine

// Flags specifically for the tasking system
Ost_Task_Flag :: enum {
	None      = 0,
	Queued    = 10,
	Running   = 20,
	Completed = 30,
	Failed    = 40,
}

Ost_Engine_Error :: struct {
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
/*Commands that will be used to interact with the engine by way of the API
these commands can be used interchangeably with records and clusters
for more on intechangability see TODO: add link or info here
*/
Ost_Command :: struct {
	_CREATE: string, //acts as an INSERT statement
	_DELETE: string,
	_GET:    string, //acts as a SELECT statement
	_UPDATE: string,
}

Ost_Engine :: struct {
	EngineRuntime:   time.Duration, // The amount of time the engine has been running
	Status:          int, // 0, 1, 2
	StatusName:      string, // Idle, Running, Stopped mostly for logging purposes

	// Records are individual data items within a Cluster
	RecordsCreated:  int,
	RecordsDeleted:  int,
	RecordsUpdated:  int,


	// Clusters are essentially tables in a sql database or collections in a NoSQL database
	/*Comprised of multiple records*/
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
		Error:          Ost_Engine_Error,
		StatusOfTask:   Ost_Task_Flag,
	},
}


OST_GET_ENGINE_STATUS :: proc() -> int {
	switch (ost_engine.Status) 
	{
	case 0:
		ost_engine.StatusName = "Idle"
		break
	case 1:
		ost_engine.StatusName = "Running"
		break
	case 2:
		ost_engine.StatusName = "Stopped"
		break
	}

	return ost_engine.Status
}


OST_START_ENGINE :: proc() -> int {
	engineStatus := OST_GET_ENGINE_STATUS()
	switch (engineStatus) {
	case 0, 2:
		ost_engine.Status = 1
		ost_engine.StatusName = "Running"
		break
	case 1:
		fmt.println("Engine is already running")
		break
	}
	return 0
}
