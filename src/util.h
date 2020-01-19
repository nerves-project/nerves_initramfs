/*
 * Copyright 2019 Frank Hunleth
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef UTIL_H
#define UTIL_H

#include "uboot_env.h"

#define PROGRAM_NAME "nerves_initramfs"

#ifndef PROGRAM_VERSION
#define PROGRAM_VERSION unknown
#endif

#define xstr(s) str(s)
#define str(s) #s
#define PROGRAM_VERSION_STR xstr(PROGRAM_VERSION)

//#define DEBUG 1

// Logging functions
void info(const char *fmt, ...);
void fatal(const char *fmt, ...);

#define ERR_CLEANUP() do { rc = -1; goto cleanup; } while (0)
#define ERR_CLEANUP_MSG(MSG, ...) do { info(MSG, ## __VA_ARGS__); rc = -1; goto cleanup; } while (0)

#define OK_OR_CLEANUP(WORK) do { if ((WORK) < 0) ERR_CLEANUP(); } while (0)
#define OK_OR_CLEANUP_MSG(WORK, MSG, ...) do { if ((WORK) < 0) ERR_CLEANUP_MSG(MSG, ## __VA_ARGS__); } while (0)

#define ERR_RETURN(MSG, ...) do { info(MSG, ## __VA_ARGS__); return -1; } while (0)
#define OK_OR_RETURN(WORK) do { if ((WORK) < 0) return -1; } while (0)
#define OK_OR_RETURN_MSG(WORK, MSG, ...) do { if ((WORK) < 0) ERR_RETURN(MSG, ## __VA_ARGS__); } while (0)

#define OK_OR_FATAL(WORK, MSG, ...) do { if ((WORK) < 0) fatal(MSG, ## __VA_ARGS__); } while (0)
#define OK_OR_WARN(WORK, MSG, ...) do { if ((WORK) < 0) info(MSG, ## __VA_ARGS__); } while (0)

#ifdef DEBUG
#define debug warn
#define OK_OR_DEBUG(WORK, MSG, ...) do { if ((WORK) < 0) info(MSG, ## __VA_ARGS__); } while (0)
#define assert(CONDITION) do { if (!(CONDITION)) fatal("assert failed at %s:%d", __FILE__, __LINE__); } while (0)
#else
#define debug(MSG, ...)
#define OK_OR_DEBUG(WORK, MSG, ...) do { (void) (WORK); } while (0)
#define assert(CONDITION)
#endif

#ifdef __APPLE__
#include "compat.h"
#endif

// String functions
void trim_string_in_place(char *str);

// Globals
extern struct uboot_env working_uboot_env;

#endif // UTIL_H
