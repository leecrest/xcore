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

uv_signal_t* luv_signal_check(lua_State* L, int index) {
	uv_signal_t* handle = (uv_signal_t*)luaL_checkudata(L, index, "uv_signal");
	if (handle) {
		luaL_argcheck(L, handle->type == UV_SIGNAL && handle->data, index, "Expected uv_signal_t");
	}
	return handle;
}

int luv_signal_new(lua_State* L) {
	uv_signal_t* handle = (uv_signal_t*)lua_newuserdata(L, sizeof(uv_signal_t));
	int ret = uv_signal_init(luv_loop(L), handle);
	if (ret < 0) {
		lua_pop(L, 1);
		return luv_error(L, ret);
	}
	handle->data = luv_handle_setup(L);
	return 1;
}

void luv_signal_cb(uv_signal_t* handle, int signum) {
	lua_State* L = luv_state(handle->loop);
	luv_handle_t* data = (luv_handle_t*)(handle->data);
	lua_pushstring(L, luv_sig_num_to_string(signum));
	luv_callback_call(L, data, LUV_SIGNAL, 1);
}

int luv_signal_start(lua_State* L) {
	uv_signal_t* handle = luv_signal_check(L, 1);
	int signum, ret;
	if (lua_isnumber(L, 2)) {
		signum = lua_tointeger(L, 2);
	}
	else if (lua_isstring(L, 2)) {
		signum = luv_sig_string_to_num(luaL_checkstring(L, 2));
		luaL_argcheck(L, signum, 2, "Invalid Signal name");
	}
	else {
		return luaL_argerror(L, 2, "Missing Signal name");
	}

	if (!lua_isnoneornil(L, 3)) {
		luv_callback_check(L, (luv_handle_t*)(handle->data), LUV_SIGNAL, 3);
	}
	ret = uv_signal_start(handle, luv_signal_cb, signum);
	if (ret < 0) return luv_error(L, ret);
	lua_pushinteger(L, ret);
	return 1;
}

int luv_signal_stop(lua_State* L) {
	uv_signal_t* handle = luv_signal_check(L, 1);
	int ret = uv_signal_stop(handle);
	if (ret < 0) return luv_error(L, ret);
	lua_pushinteger(L, ret);
	return 1;
}
