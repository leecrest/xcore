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


int luv_req_check_continuation(lua_State* L, int index) {
	if (lua_isnoneornil(L, index)) return LUA_NOREF;
	luaL_checktype(L, index, LUA_TFUNCTION);
	lua_pushvalue(L, index);
	return luaL_ref(L, LUA_REGISTRYINDEX);
}

// Store a lua callback in a luv_req for the continuation.
// The uv_req_t is assumed to be at the top of the stack
luv_req_t* luv_req_setup(lua_State* L, int callback_ref) {
	luaL_checktype(L, -1, LUA_TUSERDATA);
	luv_req_t* data = (luv_req_t*)malloc(sizeof(luv_req_t));
	if (!data) luaL_error(L, "Problem allocating luv request");

	luaL_getmetatable(L, "uv_req");
	lua_setmetatable(L, -2);

	lua_pushvalue(L, -1);
	data->req_ref = luaL_ref(L, LUA_REGISTRYINDEX);
	data->callback_ref = callback_ref;
	data->data_ref = LUA_NOREF;
	data->data = NULL;

	return data;
}


void luv_req_fulfill(lua_State* L, luv_req_t* data, int nargs) {
	if (data->callback_ref == LUA_NOREF) {
		lua_pop(L, nargs);
	}
	else {
		lua_pushcfunction(L, luv_stackdump);
		if (nargs) {
			lua_insert(L, -1 - nargs);
		}
		lua_rawgeti(L, LUA_REGISTRYINDEX, data->callback_ref);
		if (nargs) {
			lua_insert(L, -1 - nargs);
		}

		lua_pcall(L, nargs, 0, -2 - nargs);
		lua_pop(L, 1);
	}
}

void luv_req_cleanup(lua_State* L, luv_req_t* data) {
	luaL_unref(L, LUA_REGISTRYINDEX, data->req_ref);
	luaL_unref(L, LUA_REGISTRYINDEX, data->callback_ref);
	luaL_unref(L, LUA_REGISTRYINDEX, data->data_ref);
	free(data->data);
	free(data);
}

uv_req_t* luv_req_check(lua_State* L, int index) {
	uv_req_t* req = (uv_req_t*)luaL_checkudata(L, index, "uv_req");
	if (req) {
		luaL_argcheck(L, (uv_req_t*)(req->data), index, "Expected uv_req_t");
	}
	return req;
}

int luv_req_tostring(lua_State* L) {
  uv_req_t* req = (uv_req_t*)luaL_checkudata(L, 1, "uv_req");
  if (req == NULL) return 0;
  switch (req->type) {
#define XX(uc, lc) case UV_##uc: lua_pushfstring(L, "uv_"#lc"_t: %p", req); break;
  UV_REQ_TYPE_MAP(XX)
#undef XX
    default: lua_pushfstring(L, "uv_req_t: %p", req); break;
  }
  return 1;
}

void luv_req_init(lua_State* L) {
  luaL_newmetatable (L, "uv_req");
  lua_pushcfunction(L, luv_req_tostring);
  lua_setfield(L, -2, "__tostring");
  lua_pop(L, 1);
}

// Metamethod to allow storing anything in the userdata's environment
int luv_req_cancel(lua_State* L) {
  uv_req_t* req = luv_req_check(L, 1);
  int ret = uv_cancel(req);
  if (ret < 0) return luv_error(L, ret);
  luv_req_cleanup(L, (luv_req_t*)(req->data));
  req->data = NULL;
  lua_pushinteger(L, ret);
  return 1;
}