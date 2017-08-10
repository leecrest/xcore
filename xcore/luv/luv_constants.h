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

#ifndef LUV_CONSTANTS_H
#define LUV_CONSTANTS_H
#include "luv.h"

int luv_constants(lua_State* L);
int luv_af_string_to_num(const char* string);
const char* luv_af_num_to_string(const int num);
int luv_ai_string_to_num(const char* string);
const char* luv_ai_num_to_string(const int num);
int luv_sock_string_to_num(const char* string);
const char* luv_sock_num_to_string(const int num);
int luv_sig_string_to_num(const char* string);
const char* luv_sig_num_to_string(const int num);

#endif