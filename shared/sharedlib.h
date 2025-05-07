// sharedlib.h
#ifndef SHAREDLIB_H
#define SHAREDLIB_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

bool create_database(const char* name);

#ifdef __cplusplus
}
#endif

#endif // SHAREDLIB_H