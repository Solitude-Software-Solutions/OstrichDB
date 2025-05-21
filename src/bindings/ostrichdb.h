#ifndef OSTRICHDB_H
#define OSTRICHDB_H

void ostrichdb_init(char *username, char *password);
void ostrichdb_exit();
void ostrichdb_create_collection(char *collectionName);
void ostrichdb_create_cluster(char *collectionName, char *clusterName);

// TODO
// void ostrichdb_create_record(char *collectionName, char *clusterName);

char *ostrichdb_fetch_collection(char *collectionName);
char *ostrichdb_fetch_cluster(char *collectionName, char *clusterName);

// TODO
// char *ostrichdb_fetch_record(char *collectionName, char *clusterName, char *recordName);

#endif
