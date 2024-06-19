package engine

import "core:fmt"
import "core:os"
import "core:time"

// Flags specifically for the tasking system
Ost_Engine_Flag:: enum
{
  None: 0
  Queued: 10
  Running: 20
  Completed: 30
  Failed: 40
}

Ost_Engine_Error:: struct
{
  Code: enum {
    None: 0
    InvalidRecord: 1
    InvalidObject: 2
    InvalidAction: 3
  }

  Message: string
  Acion: string
}

Ost_Engine::struct
{
  // Records are individual data items within objects
  RecordsCreated: int
  RecordsDeleted: int
  
  // Objects are essentially tables in a sql database
  ObjectsCreated: int
  ObjectsDeleted: int

  
  ElapsedTime: time.Duration
  
  State::union
  {
    Running: bool
    Stopped: bool
  }
  
  Tasking::struct
  {
    NameOfTask: string
    TaskNumber: int
    ProgressOfTask: float32
    TargetDatabase: string // will be the path to the database file
    Error: Ost_Engine_Error
    StatusOfTask: Ost_Engine_Flag
  }
}



