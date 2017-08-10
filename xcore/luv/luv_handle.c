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

uv_handle_t* lua_handle_check(lua_State* L, int index) {
	uv_handle_t* handle = (uv_handle_t*)lua_touserdata(L, index);
	if (!handle) {
		luaL_argerror(L, index, "Expected uv_handle userdata");
		return NULL;
	}
	lua_getfield(L, LUA_REGISTRYINDEX, "uv_handle");
	lua_getmetatable(L, index < 0 ? index - 1 : index);
	lua_rawget(L, -2);
	int isHandle = lua_toboolean(L, -1);
	lua_pop(L, 2);
	if (isHandle) { return handle; }
	luaL_argerror(L, index, "Expected uv_handle userdata");
	return NULL;
}

// Show the libuv type instead of generic "userdata"
int luv_handle_tostring(lua_State* L) {
  uv_handle_t* handle = lua_handle_check(L, 1);
  switch (handle->type) {
#define XX(uc, lc) case UV_##uc: lua_pushfstring(L, "uv_"#lc"_t: %p", handle); break;
  UV_HANDLE_TYPE_MAP(XX)
#undef XX
    default: lua_pushfstring(L, "uv_handle_t: %p", handle); break;
  }
  return 1;
}

int luv_handle_is_active(lua_State* L) {
  uv_handle_t* handle = lua_handle_check(L, 1);
  int ret = uv_is_active(handle);
  if (ret < 0) return luv_error(L, ret);
  lua_pushboolean(L, ret);
  return 1;
}

int luv_handle_is_closing(lua_State* L) {
  uv_handle_t* handle = lua_handle_check(L, 1);
  int ret = uv_is_closing(handle);
  if (ret < 0) return luv_error(L, ret);
  lua_pushboolean(L, ret);
  return 1;
}

void luv_handle_close_cb(uv_handle_t* handle) {
  lua_State* L = luv_state(handle->loop);
  luv_handle_t* data = (luv_handle_t*)(handle->data);
  if (!data) return;
  luv_callback_call(L, data, LUV_CLOSED, 0);
  luv_handle_cleanup(L, data);
  handle->data = NULL;
}

int luv_handle_close(lua_State* L) {
  uv_handle_t* handle = lua_handle_check(L, 1);
  if (uv_is_closing(handle)) {
    luaL_error(L, "handle %p is already closing", handle);
  }
  if (!lua_isnoneornil(L, 2)) {
    luv_callback_check(L, (luv_handle_t*)(handle->data), LUV_CLOSED, 2);
  }
  uv_close(handle, luv_handle_close_cb);
  return 0;
}

int luv_handle_ref(lua_State* L) {
  uv_handle_t* handle = lua_handle_check(L, 1);
  uv_ref(handle);
  return 0;
}

int luv_handle_unref(lua_State* L) {
  uv_handle_t* handle = lua_handle_check(L, 1);
  uv_unref(handle);
  return 0;
}

int luv_handle_has_ref(lua_State* L) {
  uv_handle_t* handle = lua_handle_check(L, 1);
  int ret = uv_has_ref(handle);
  if (ret < 0) return luv_error(L, ret);
  lua_pushboolean(L, ret);
  return 1;
}

int luv_handle_send_buffer_size(lua_State* L) {
  uv_handle_t* handle = lua_handle_check(L, 1);
  int value;
  int ret;
  if (lua_isnoneornil(L, 2)) {
    value = 0;
  }
  else {
    value = luaL_checkinteger(L, 2);
  }
  ret = uv_send_buffer_size(handle, &value);
  if (ret < 0) return luv_error(L, ret);
  lua_pushinteger(L, ret);
  return 1;
}

int luv_handle_recv_buffer_size(lua_State* L) {
  uv_handle_t* handle = lua_handle_check(L, 1);
  int value;
  int ret;
  if (lua_isnoneornil(L, 2)) {
    value = 0;
  }
  else {
    value = luaL_checkinteger(L, 2);
  }
  ret = uv_recv_buffer_size(handle, &value);
  if (ret < 0) return luv_error(L, ret);
  lua_pushinteger(L, ret);
  return 1;
}

int luv_handle_fileno(lua_State* L) {
  uv_handle_t* handle = lua_handle_check(L, 1);
  uv_os_fd_t fd;
  int ret = uv_fileno(handle, &fd);
  if (ret < 0) return luv_error(L, ret);
  lua_pushinteger(L, (LUA_INTEGER)fd);
  return 1;
}
