package types


OST_Command :: struct {
	a_token: string, //action token e.g. NEW, ERASE, FETCH, RENAME
	t_token: string, //object token the type of "object" that the action is preformed on e.g. RECORD, CLUSTER, COLLECTION
	o_token: [dynamic]string, //target token the specific name of a record, cluster, or collection e.g. Ford, car_companies, car_industry.ost
	m_token: map[string]string, //modifier token //map that contains the modifier token and the value e.g. OF_TYPE, WITHIN, AND, TO
	s_token: map[string]string, //scope token //map that contains the scope token and the value e.g. WITHIN
}
