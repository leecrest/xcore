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

uv_idle_t* luv_idle_check(lua_State* L, int index) {
  uv_idle_t* handle = (uv_idle_t*)luaL_checkudata(L, index, "uv_idle");
  if (handle) {
	  luaL_argcheck(L, handle->type == UV_IDLE && handle->data, index, "Expected uv_idle_t");
  }
  return handle;
}

int luv_idle_new(lua_State* L) {
  uv_idle_t* handle = (uv_idle_t*)lua_newuserdata(L, sizeof(uv_idle_t));
  int ret = uv_idle_init(luv_loop(L), handle);
  if (ret < 0) {
    lua_pop(L, 1);
    return luv_error(L, ret);
  }
  handle->data = luv_handle_setup(L);
  return 1;
}

void luv_idle_cb(uv_idle_t* handle) {
  lua_State* L = luv_state(handle->loop);
  luv_callback_call(L, (luv_handle_t*)(handle->data), LUV_IDLE, 0);
}

int luv_idle_start(lua_State* L) {
  uv_idle_t* handle = luv_idle_check(L, 1);
  int ret;
  luv_callback_check(L, (luv_handle_t*)(handle->data), LUV_IDLE, 2);
  ret = uv_idle_start(handle, luv_idle_cb);
  if (ret < 0) return luv_error(L, ret);
  lua_pushinteger(L, ret);
  return 1;
}

int luv_idle_stop(lua_State* L) {
  uv_idle_t* handle = luv_idle_check(L, 1);
  int ret = uv_idle_stop(handle);
  if (ret < 0) return luv_error(L, ret);
  lua_pushinteger(L, ret);
  return 1;
}

