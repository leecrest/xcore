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

uv_async_t* luv_async_check(lua_State* L, int index) {
	uv_async_t* handle = (uv_async_t*)luaL_checkudata(L, index, "uv_async");
	if (!handle) return NULL;
	luaL_argcheck(L, handle->type == UV_ASYNC && handle->data, index, "Expected uv_async_t");
	return handle;
}

void luv_async_cb(uv_async_t* handle) {
	lua_State* L = luv_state(handle->loop);
	luv_callback_call(L, (luv_handle_t*)(handle->data), LUV_ASYNC, 0);
}

int luv_async_new(lua_State* L) {
	luaL_checktype(L, 1, LUA_TFUNCTION);
	uv_async_t* handle = (uv_async_t*)lua_newuserdata(L, sizeof(uv_async_t));
	int ret = uv_async_init(luv_loop(L), handle, luv_async_cb);
	if (ret < 0) {
		lua_pop(L, 1);
		return luv_error(L, ret);
	}
	handle->data = luv_handle_setup(L);
	luv_callback_check(L, (luv_handle_t*)(handle->data), LUV_ASYNC, 1);
	return 1;
}

int luv_async_send(lua_State* L) {
  uv_async_t* handle = luv_async_check(L, 1);
  if (!handle) return 0;
  int ret = uv_async_send(handle);
  if (ret < 0) return luv_error(L, ret);
  lua_pushinteger(L, ret);
  return 1;
}
