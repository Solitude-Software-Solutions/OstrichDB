package commands

import "../data"
import "core:fmt"
import "core:os"
import "core:strings"

//Non Data Commands
HELP :: "HELP"
EXIT :: "EXIT"
LOGOUT :: "LOGOUT"

//Standard Data Commands -- Require a space before and after the prefix and atleast one argument
NEW :: "NEW" //used to create a new record, cluster, or collection
ERASE :: "ERASE" //used to delete a record, cluster, or collection
FETCH :: "FETCH" //used to get the data from a record, cluster, or collection
RENAME :: "RENAME" //used to change the name of a record, cluster, or collection
AND :: "AND" //used to specify that there is another record, cluster, or collection to be created
WITHIN :: "WITHIN" //used to specify where the record, cluster, or collection is going to be created

//Special Data Commands
OF_TYPE :: "OF_TYPE" //ONLY used to specify the type of data that is going to be stored in a record...see types below
ALL_OF :: "ALL_OF" //ONLY used with FETCH and ERASE.
TO :: "TO" //ONLY used with RENAME
//Target Arguments -- Require a data command to be used
COLLECTION :: "COLLECTION" //Targets a collection to be manupulated
CLUSTER :: "CLUSTER" //Targets a cluster to be manipulated
RECORD :: "RECORD" //Targets a record to be manipulated
ALL :: "ALL" //Targets all records, clusters, or collections that are specified

//Types -- Requires a special data commands as a prefix
STRING :: "STRING"
INT :: "INT"
FLOAT :: "FLOAT"
BOOL :: "BOOL"
//might add more...doubtful though

/*
EXAMPLE USAGES OF ALL COMMANDS AND ARGS:

NEW COLLECTION car companies //creates file "car_industry.ost"
NEW CLUSTER car companies WITHIN COLLECTION car companies  //creates cluster called "car_companies" within "car_industry.ost
NEW RECORD Ford OF_TYPE STRING WITHIN COLLECTION car companies //creates record called "Ford" within the "car_companies" cluster in "car_industry.ost
NEW RECORD Chevy AND Ferrarri OF_TYPE STRING WITHIN COLLECTION car companies //creates records called "Chevy" and "Ferrari" within the "car_companies" cluster in "car_industry.ost
ERASE RECORD Ford WITHIN COLLECTION car companies //deletes record "Ford" within the "car_companies" cluster in "car_industry.ost
FETCH ALL RECORD WITHIN COLLECTION NAMED car companies //would return all records within ANY cluster in "car_industry.ost
ERASE CLUSTER car companies WITHIN COLLECTION car companies //deletes cluster "car_companies" within "car_industry.ost
RENAME RECORD Chevy TO Chevrolet WITHIN COLLECTION car companies //renames record "Chevy" to "Chevrolet" within "car_companies" cluster in "car_industry.ost

*/

//used to creeate records and clusters and dbs depending on arg passed in
OST_CREATE_ :: proc(n: string) -> bool {
	result: bool
	switch (n) 
	{
	case "record":
		fmt.print("Creating record")
		//todo need to get what db and cluster the record is going to be in
		break

	case "cluster":
		fmt.print("Creating cluster")
		//todo need to get what db the cluster is going to be in
		break

	case "collection":
		fmt.print("Creating collection")
		//todo need to get what db the collection is going to be in
		break

	}
	return result
}


//EZ
OST_EXIT :: proc() {
	fmt.print("Exiting")
	fmt.print("Thank you for using OstrichDB")
	os.exit(0)
}
