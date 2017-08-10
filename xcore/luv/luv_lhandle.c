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

luv_handle_t* luv_handle_setup(lua_State* L) {
  luv_handle_t* data;
  const uv_handle_t* handle = (const uv_handle_t*)lua_touserdata(L, -1);
  luaL_checktype(L, -1, LUA_TUSERDATA);

  data = (luv_handle_t*)malloc(sizeof(luv_handle_t));
  if (!data) luaL_error(L, "Can't allocate luv handle");

  #define XX(uc, lc) case UV_##uc: \
    luaL_getmetatable(L, "uv_"#lc); \
    break;
  switch (handle->type) {
    UV_HANDLE_TYPE_MAP(XX)
    default:
      luaL_error(L, "Unknown handle type");
      return NULL;
  }
  #undef XX

  lua_setmetatable(L, -2);

  lua_pushvalue(L, -1);

  data->ref = luaL_ref(L, LUA_REGISTRYINDEX);
  data->callbacks[0] = LUA_NOREF;
  data->callbacks[1] = LUA_NOREF;
  return data;
}

void luv_callback_check(lua_State* L, luv_handle_t* data, luv_callback_id id, int index) {
  luaL_checktype(L, index, LUA_TFUNCTION);
  luaL_unref(L, LUA_REGISTRYINDEX, data->callbacks[id]);
  lua_pushvalue(L, index);
  data->callbacks[id] = luaL_ref(L, LUA_REGISTRYINDEX);
}

int traceback (lua_State *L) {
  if (!lua_isstring(L, 1))  /* 'message' not a string? */
    return 1;  /* keep it intact */
  lua_pushglobaltable(L);
  lua_getfield(L, -1, "debug");
  lua_remove(L, -2);
  if (!lua_istable(L, -1)) {
    lua_pop(L, 1);
    return 1;
  }
  lua_getfield(L, -1, "traceback");
  if (!lua_isfunction(L, -1)) {
    lua_pop(L, 2);
    return 1;
  }
  lua_pushvalue(L, 1);  /* pass error message */
  lua_pushinteger(L, 2);  /* skip this function and traceback */
  lua_call(L, 2, 1);  /* call debug.traceback */
  return 1;
}

void luv_callback_call(lua_State* L, luv_handle_t* data, luv_callback_id id, int nargs) {
	int ref = data->callbacks[id];
	luv_pcall(L, ref, nargs);
}

void luv_handle_cleanup(lua_State* L, luv_handle_t* data) {
  luaL_unref(L, LUA_REGISTRYINDEX, data->ref);
  luaL_unref(L, LUA_REGISTRYINDEX, data->callbacks[0]);
  luaL_unref(L, LUA_REGISTRYINDEX, data->callbacks[1]);
  free(data);
}

void luv_handle_find(lua_State* L, luv_handle_t* data) {
  lua_rawgeti(L, LUA_REGISTRYINDEX, data->ref);
}
