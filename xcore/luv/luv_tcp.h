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
#ifndef LUV_TCP_H
#define LUV_TCP_H
#include "luv.h"

void luv_tcp_connect_cb(uv_connect_t* req, int status);
void parse_sockaddr(lua_State* L, struct sockaddr_storage* address, int addrlen);

int luv_tcp_new(lua_State* L);
int luv_tcp_open(lua_State* L);
int luv_tcp_nodelay(lua_State* L);
int luv_tcp_keepalive(lua_State* L);
int luv_tcp_simultaneous_accepts(lua_State* L);
int luv_tcp_bind(lua_State* L);
int luv_tcp_getsockname(lua_State* L);
int luv_tcp_getpeername(lua_State* L);
int luv_tcp_write_queue_size(lua_State* L);
int luv_tcp_connect(lua_State* L);

#endif