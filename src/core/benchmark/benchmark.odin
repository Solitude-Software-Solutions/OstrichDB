package benchmark

//=========================================================//
// Author: Marshall A Burns aka @SchoolyB
//
// Copyright 2024 Marshall A Burns and Solitude Software Solutions LLC
// Licensed under Apache License 2.0 (see LICENSE file for details)
//=========================================================//


//MY GUIDELINES FOR THE BENCHMARKING OSTRICHDB PACKAGAGE
// All benchmarking types,procs,utils,etc will be located in this single file.
// The file will be split into sections.
// Procs will NOT take any user input, thus all data will be generated randomly.
// Cluster IDs will be randomly generated but NOT stored in the ./ids.ost file.
// Created collection files will NOT be in the ./collections dir but in the ./benchmark dir
// After the benchmark.main() proc runs the ./benchmark directory will be deleted.
//
// Benchmarking will evaluate the performance of the following operations:
// 1. Create 3 collections
// 2. 1 collection will have 10 clusters, another 100 cluster and the last 1000 clusters
// 3. The amount of records that each cluster of each file contains will be randomly generated between 10 and 1000
// 4. The datatype and value for each record will be randomized as well.
// 5. After all data is set, the next benchmark will be to fetch entire collections, then individual clusters, then individual records.
// 6. The final benchmark will be to delete all data from the collections.
