package data

//A record is Ostrich is essentially an entry into the database. It is a struct that contains the data and the type of the data.

record:Record

Record :: struct {
	r_name: string,
	r_type:  any,
	r_data: any,
}

// example of a cluster with records in it

/*
{
	cluster_id: 12345 //this is technically a record
	player name: "Marshall" //this is a record
	player age: 25 //this is a record
	player height: "6'2" //this is a record
}
*/

//this will take in data and prepare it to be stored in a record
OST_PREP_RECORD_INFO :: proc(n:string,t:any,d:any) -> any {
	record.r_name = n
	record.r_type = t
	record.r_data = d
	return record
}

// todo
//need to create a proc that takes in the users input on which cluster they want to store the record in
//create a proc that checks if the cluster that the user wants to store the record in actually exists
// need to create a proc that passes all info of a record to a different proc that will then store the record into a cluster