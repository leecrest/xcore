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

uv_check_t* luv_check_check(lua_State* L, int index) {
	uv_check_t* handle = (uv_check_t*)luaL_checkudata(L, index, "uv_check");
	if (!handle) return NULL;
	luaL_argcheck(L, handle->type == UV_CHECK && handle->data, index, "Expected uv_check_t");
	return handle;
}

int luv_check_new(lua_State* L) {
	uv_check_t* handle = (uv_check_t*)lua_newuserdata(L, sizeof(uv_check_t));
	int ret = uv_check_init(luv_loop(L), handle);
	if (ret < 0) {
		lua_pop(L, 1);
		return luv_error(L, ret);
	}
	handle->data = luv_handle_setup(L);
	return 1;
}

void luv_check_cb(uv_check_t* handle) {
	lua_State* L = luv_state(handle->loop);
	luv_handle_t* data = (luv_handle_t*)(handle->data);
	luv_callback_call(L, data, LUV_CHECK, 0);
}

int luv_check_start(lua_State* L) {
	uv_check_t* handle = luv_check_check(L, 1);
	if (!handle) return 0;
	int ret;
	luv_callback_check(L, (luv_handle_t*)(handle->data), LUV_CHECK, 2);
	ret = uv_check_start(handle, luv_check_cb);
	if (ret < 0) return luv_error(L, ret);
	lua_pushinteger(L, ret);
	return 1;
}

int luv_check_stop(lua_State* L) {
	uv_check_t* handle = luv_check_check(L, 1);
	if (!handle) return 0;
	int ret = uv_check_stop(handle);
	if (ret < 0) return luv_error(L, ret);
	lua_pushinteger(L, ret);
	return 1;
}

