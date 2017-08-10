/*
 *  Copyright 2014 The Luvit Authors. All Rights Reserved.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

#ifndef LUV_MISC_H
#define LUV_MISC_H
#include "luv.h"

int luv_guess_handle(lua_State* L);
int luv_version(lua_State* L);
int luv_version_string(lua_State* L);
int luv_get_process_title(lua_State* L);
int luv_set_process_title(lua_State* L);
int luv_resident_set_memory(lua_State* L);
int luv_uptime(lua_State* L);
void luv_push_timeval_table(lua_State* L, const uv_timeval_t* t);
int luv_getrusage(lua_State* L);
int luv_cpu_info(lua_State* L);
int luv_interface_addresses(lua_State* L);
int luv_loadavg(lua_State* L);
int luv_exepath(lua_State* L);
int luv_cwd(lua_State* L);
int luv_chdir(lua_State* L);
int luv_get_total_memory(lua_State* L);
int luv_hrtime(lua_State* L);
int luv_getpid(lua_State* L);

#ifndef _WIN32
int luv_getuid(lua_State* L);
int luv_getgid(lua_State* L);
int luv_setuid(lua_State* L);
int luv_setgid(lua_State* L);
#endif

#endif