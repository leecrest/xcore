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
#ifndef LUV_STREAM_H
#define LUV_STREAM_H
#include "luv.h"

uv_stream_t* luv_stream_check(lua_State* L, int index);
void luv_stream_alloc_cb(uv_handle_t* handle, size_t suggested_size, uv_buf_t* buf);
void luv_stream_connection_cb(uv_stream_t* handle, int status);
uv_buf_t* luv_stream_prep_bufs(lua_State* L, int index, size_t *count);

int luv_stream_shutdown(lua_State* L);
int luv_stream_listen(lua_State* L);
int luv_stream_accept(lua_State* L);
int luv_stream_read_start(lua_State* L);
int luv_stream_read_stop(lua_State* L);
int luv_stream_write(lua_State* L);
int luv_stream_write2(lua_State* L);
int luv_stream_try_write(lua_State* L);
int luv_stream_is_readable(lua_State* L);
int luv_stream_is_writable(lua_State* L);
int luv_stream_set_blocking(lua_State* L);

#endif