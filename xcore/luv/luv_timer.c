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
#include "luv.h"

uv_timer_t* luv_timer_check(lua_State* L, int index) {
	uv_timer_t* handle = (uv_timer_t*)luaL_checkudata(L, index, "uv_timer");
	if (!handle) { return NULL; }
	luaL_argcheck(L, handle->type == UV_TIMER && handle->data, index, "Expected uv_timer_t");
	return handle;
}

int luv_timer_new(lua_State* L) {
	uv_timer_t* handle = (uv_timer_t*)lua_newuserdata(L, sizeof(uv_timer_t));
	int ret = uv_timer_init(luv_loop(L), handle);
	if (ret < 0) { 
		lua_pop(L, 1);
		return luv_error(L, ret);
	}
	handle->data = luv_handle_setup(L);
	return 1;
}

void luv_timer_cb(uv_timer_t* handle) {
	lua_State* L = luv_state(handle->loop);
	luv_callback_call(L, (luv_handle_t*)(handle->data), LUV_TIMEOUT, 0);
}

int luv_timer_start(lua_State* L) {
	uv_timer_t* handle = luv_timer_check(L, 1);
	if (!handle) { return 0; }
	uint64_t timeout = luaL_checkinteger(L, 2);
	uint64_t repeat = luaL_checkinteger(L, 3);
	luv_callback_check(L, (luv_handle_t*)(handle->data), LUV_TIMEOUT, 4);
	int ret = uv_timer_start(handle, luv_timer_cb, timeout, repeat);
	if (ret < 0) { return luv_error(L, ret); }
	lua_pushinteger(L, ret);
	return 1;
}

int luv_timer_stop(lua_State* L) {
	uv_timer_t* handle = luv_timer_check(L, 1);
	if (!handle) { return 0; }
	int ret = uv_timer_stop(handle);
	if (ret < 0) { return luv_error(L, ret); }
	lua_pushinteger(L, ret);
	return 1;
}

int luv_timer_again(lua_State* L) {
	uv_timer_t* handle = luv_timer_check(L, 1);
	if (!handle) { return 0; }
	int ret = uv_timer_again(handle);
	if (ret < 0) { return luv_error(L, ret); }
	lua_pushinteger(L, ret);
	return 1;
}

int luv_timer_set_repeat(lua_State* L) {
	uv_timer_t* handle = luv_timer_check(L, 1);
	if (!handle) { return 0; }
	uint64_t repeat = luaL_checkinteger(L, 2);
	uv_timer_set_repeat(handle, repeat);
	return 0;
}

int luv_timer_get_repeat(lua_State* L) {
	uv_timer_t* handle = luv_timer_check(L, 1);
	if (!handle) { return 0; }
	uint64_t repeat = uv_timer_get_repeat(handle);
	lua_pushinteger(L, repeat);
	return 1;
}
