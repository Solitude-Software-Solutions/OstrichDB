package bindings

import "core:c"
import "core:strings"
import "base:runtime"
import "../core/nlp"
import "../../main"
import "../core/engine/operations"

@(export, link_name = "ostrichdb_init")
init :: proc "c" (username, password: cstring) {
    context = runtime.default_context()
    main.ostrichdb_init(cast(string)username, cast(string)password)
}

@(export, link_name = "ostrichdb_exit")
exit :: proc "c" () {
    context = runtime.default_context()
    main.ostrichdb_exit()
}

@(export, link_name = "ostrichdb_nlp_run")
nlp_run :: proc "c" () -> int {
    context = runtime.default_context()
    return nlp.runner() 
}

@(export, link_name = "ostrichdb_create_collection")
create_collection :: proc "c" (collectionName: cstring) {
    context = runtime.default_context()
    operations.handle_collection_creation(cast(string)collectionName)
}

@(export, link_name = "ostrichdb_create_cluster")
create_cluster :: proc "c" (collectionName, clusterName: cstring) {
    context = runtime.default_context()
    operations.handle_cluster_creation(cast(string)collectionName, cast(string)clusterName)
}

// I'm not sure how to call this from C with the map type yet
@(export, link_name = "ostrichdb_create_record")
create_record :: proc "c" (collectionName, clusterName, recordName: cstring, p_token: map[string]string) {
    context = runtime.default_context()
    operations.handle_record_creation(cast(string)collectionName, cast(string)clusterName, cast(string)recordName, p_token)
}

// Allocates, needs to be freed by user
@(export, link_name = "ostrichdb_fetch_collection")
fetch_collection :: proc "c" (collectionName: cstring) -> cstring {
    context = runtime.default_context()
    str := operations.handle_collection_fetch(cast(string)collectionName)
    return strings.clone_to_cstring(str)
}

@(export, link_name = "ostrichdb_fetch_cluster")
fetch_cluster :: proc "c" (collectionName, clusterName: cstring) -> cstring {
    context = runtime.default_context()
    str := operations.handle_cluster_fetch(cast(string)collectionName, cast(string)clusterName)
    return strings.clone_to_cstring(str)
}

@(export, link_name = "ostrichdb_fetch_record")
fetch_record :: proc "c" (collectionName, clusterName, recordName: cstring) {
    context = runtime.default_context()
    operations.handle_record_fetch(cast(string)collectionName, cast(string)clusterName, cast(string)recordName)
}
