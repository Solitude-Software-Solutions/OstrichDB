package data

import "core:fmt"
import "core:os"

//A record is Ostrich is essentially an entry into the database. It is a struct that contains the data and the type of the data.
Record::struct
{
  _id: []u8 //unique identifier for the record cannot be duplicated
  _type: type //todo not sure if this is possible if not use type "any"
  _data: _type 
}






