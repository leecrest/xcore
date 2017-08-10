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
#ifndef LUV_LOOP_H
#define LUV_LOOP_H
#include "luv.h"

int luv_loop_close(lua_State* L);
int luv_loop_run(lua_State* L);
int luv_loop_alive(lua_State* L);
int luv_loop_stop(lua_State* L);
int luv_loop_backend_fd(lua_State* L);
int luv_loop_backend_timeout(lua_State* L);
int luv_loop_now(lua_State* L);
int luv_loop_update_time(lua_State* L);
int luv_loop_walk(lua_State* L);

#endif