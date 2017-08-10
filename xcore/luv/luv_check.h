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
#ifndef LUV_CHECK_H
#define LUV_CHECK_H
#include "luv.h"

uv_check_t* luv_check_check(lua_State* L, int index);
int luv_check_new(lua_State* L);
void luv_check_cb(uv_check_t* handle);
int luv_check_start(lua_State* L);
int luv_check_stop(lua_State* L);

#endif