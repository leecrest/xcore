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
#ifndef LUV_TIMER_H
#define LUV_TIMER_H
#include "luv.h"

int luv_timer_new(lua_State* L);
int luv_timer_start(lua_State* L);
int luv_timer_stop(lua_State* L);
int luv_timer_again(lua_State* L);
int luv_timer_set_repeat(lua_State* L);
int luv_timer_get_repeat(lua_State* L);

#endif