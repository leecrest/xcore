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
#ifndef LUV_PIPE_H
#define LUV_PIPE_H
#include "luv.h"


int luv_pipe_new(lua_State* L);
int luv_pipe_open(lua_State* L);
int luv_pipe_bind(lua_State* L);
int luv_pipe_connect(lua_State* L);
int luv_pipe_getsockname(lua_State* L);
int luv_pipe_getpeername(lua_State* L);
int luv_pipe_pending_instances(lua_State* L);
int luv_pipe_pending_count(lua_State* L);
int luv_pipe_pending_type(lua_State* L);

#endif