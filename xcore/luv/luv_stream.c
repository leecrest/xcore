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

uv_stream_t* luv_stream_check(lua_State* L, int index) {
	int isStream;
	uv_stream_t* handle = (uv_stream_t*)lua_touserdata(L, index);
	if (!handle) { goto fail; }
	lua_getfield(L, LUA_REGISTRYINDEX, "uv_stream");
	lua_getmetatable(L, index < 0 ? index - 1 : index);
	lua_rawget(L, -2);
	isStream = lua_toboolean(L, -1);
	lua_pop(L, 2);
	if (isStream) { return handle; }
	fail: luaL_argerror(L, index, "Expected uv_stream userdata");
	return NULL;
}

void luv_stream_shutdown_cb(uv_shutdown_t* req, int status) {
	lua_State* L = luv_state(req->handle->loop);
	luv_status(L, status);
	luv_req_t* data = (luv_req_t*)(req->data);
	luv_req_fulfill(L, data, 1);
	luv_req_cleanup(L, data);
	req->data = NULL;
}

int luv_stream_shutdown(lua_State* L) {
	uv_stream_t* handle = luv_stream_check(L, 1);
	int ref = luv_req_check_continuation(L, 2);
	uv_shutdown_t* req = (uv_shutdown_t*)lua_newuserdata(L, sizeof(uv_shutdown_t));
	int ret;
	req->data = luv_req_setup(L, ref);
	ret = uv_shutdown(req, handle, luv_stream_shutdown_cb);
	if (ret < 0) {
		lua_pop(L, 1);
		return luv_error(L, ret);
	}
	return 1;
}

void luv_stream_connection_cb(uv_stream_t* handle, int status) {
	lua_State* L = luv_state(handle->loop);
	luv_status(L, status);
	luv_callback_call(L, (luv_handle_t*)(handle->data), LUV_CONNECTION, 1);
}

int luv_stream_listen(lua_State* L) {
	uv_stream_t* handle = luv_stream_check(L, 1);
	int backlog = luaL_checkinteger(L, 2);
	luv_callback_check(L, (luv_handle_t*)(handle->data), LUV_CONNECTION, 3);
	int ret = uv_listen(handle, backlog, luv_stream_connection_cb);
	if (ret < 0) return luv_error(L, ret);
	lua_pushinteger(L, ret);
	return 1;
}

int luv_stream_accept(lua_State* L) {
	uv_stream_t* server = luv_stream_check(L, 1);
	uv_stream_t* client = luv_stream_check(L, 2);
	int ret = uv_accept(server, client);
	if (ret < 0) return luv_error(L, ret);
	lua_pushinteger(L, ret);
	return 1;
}

void luv_stream_alloc_cb(uv_handle_t* handle, size_t suggested_size, uv_buf_t* buf) {
	buf->base = (char*)malloc(suggested_size);
	assert(buf->base);
	buf->len = suggested_size;
}

void luv_stream_read_cb(uv_stream_t* handle, ssize_t nread, const uv_buf_t* buf) {
	lua_State* L = luv_state(handle->loop);
	int nargs;

	if (nread > 0) {
		lua_pushnil(L);
		lua_pushlstring(L, buf->base, nread);
		nargs = 2;
	}

	free(buf->base);
	if (nread == 0) return;

	if (nread == UV__EOF) {
		nargs = 0;
	}
	else if (nread < 0) {
		luv_status(L, nread);
		nargs = 1;
	}

	luv_callback_call(L, (luv_handle_t*)(handle->data), LUV_READ, nargs);
}

int luv_stream_read_start(lua_State* L) {
	uv_stream_t* handle = luv_stream_check(L, 1);
	int ret;
	luv_callback_check(L, (luv_handle_t*)(handle->data), LUV_READ, 2);
	ret = uv_read_start(handle, luv_stream_alloc_cb, luv_stream_read_cb);
	if (ret < 0) return luv_error(L, ret);
	lua_pushinteger(L, ret);
	return 1;
}

int luv_stream_read_stop(lua_State* L) {
	uv_stream_t* handle = luv_stream_check(L, 1);
	int ret = uv_read_stop(handle);
	if (ret < 0) return luv_error(L, ret);
	lua_pushinteger(L, ret);
	return 1;
}

void luv_stream_write_cb(uv_write_t* req, int status) {
	lua_State* L = luv_state(req->handle->loop);
	luv_status(L, status);
	luv_req_t* data = (luv_req_t*)(req->data);
	luv_req_fulfill(L, data, 1);
	luv_req_cleanup(L, data);
	req->data = NULL;
}

uv_buf_t* luv_stream_prep_bufs(lua_State* L, int index, size_t *count) {
	*count = lua_rawlen(L, index);
	uv_buf_t *bufs = (uv_buf_t*)malloc(sizeof(uv_buf_t) * *count);
	for (size_t i = 0; i < *count; ++i) {
		lua_rawgeti(L, index, i + 1);
		bufs[i].base = (char*) luaL_checklstring(L, -1, &(bufs[i].len));
		lua_pop(L, 1);
	}
	return bufs;
}

int luv_stream_write(lua_State* L) {
	uv_stream_t* handle = luv_stream_check(L, 1);
	int ref = luv_req_check_continuation(L, 3);
	uv_write_t* req = (uv_write_t*)lua_newuserdata(L, sizeof(uv_write_t));
	req->data = luv_req_setup(L, ref);
	int ret;
	if (lua_istable(L, 2)) {
		size_t count;
		uv_buf_t *bufs = luv_stream_prep_bufs(L, 2, &count);
		ret = uv_write(req, handle, bufs, count, luv_stream_write_cb);
		free(bufs);
	}
	else if (lua_isstring(L, 2)) {
		uv_buf_t buf;
		buf.base = (char*) luaL_checklstring(L, 2, &buf.len);
		ret = uv_write(req, handle, &buf, 1, luv_stream_write_cb);
	}
	else {
		return luaL_argerror(L, 2, "data must be string or table of strings");
	}
	if (ret < 0) {
		lua_pop(L, 1);
		return luv_error(L, ret);
	}
	lua_pushvalue(L, 2);
	((luv_req_t*)req->data)->data_ref = luaL_ref(L, LUA_REGISTRYINDEX);
	return 1;
}

int luv_stream_write2(lua_State* L) {
	uv_stream_t* handle = luv_stream_check(L, 1);
	uv_write_t* req;
	int ret, ref;
	uv_stream_t* send_handle;
	send_handle = luv_stream_check(L, 3);
	ref = luv_req_check_continuation(L, 4);
	req = (uv_write_t*)lua_newuserdata(L, sizeof(uv_write_t));
	req->data = luv_req_setup(L, ref);
	if (lua_istable(L, 2)) {
		size_t count;
		uv_buf_t *bufs = luv_stream_prep_bufs(L, 2, &count);
		ret = uv_write2(req, handle, bufs, count, send_handle, luv_stream_write_cb);
		free(bufs);
	}
	else if (lua_isstring(L, 2)) {
		uv_buf_t buf;
		buf.base = (char*) luaL_checklstring(L, 2, &buf.len);
		ret = uv_write2(req, handle, &buf, 1, send_handle, luv_stream_write_cb);
	}
	else {
		return luaL_argerror(L, 2, "data must be string or table of strings");
	}
	if (ret < 0) {
		lua_pop(L, 1);
		return luv_error(L, ret);
	}
	lua_pushvalue(L, 2);
	((luv_req_t*)req->data)->data_ref = luaL_ref(L, LUA_REGISTRYINDEX);
	return 1;
}

int luv_stream_try_write(lua_State* L) {
	uv_stream_t* handle = luv_stream_check(L, 1);
	int ret;
	if (lua_istable(L, 2)) {
		size_t count;
		uv_buf_t *bufs = luv_stream_prep_bufs(L, 2, &count);
		ret = uv_try_write(handle, bufs, count);
		free(bufs);
	}
	else if (lua_isstring(L, 2)) {
		uv_buf_t buf;
		buf.base = (char*) luaL_checklstring(L, 2, &buf.len);
		ret = uv_try_write(handle, &buf, 1);
	}
	else {
		return luaL_argerror(L, 2, "data must be string or table of strings");
	}
	if (ret < 0) return luv_error(L, ret);
	lua_pushinteger(L, ret);
	return 1;
}

int luv_stream_is_readable(lua_State* L) {
	uv_stream_t* handle = luv_stream_check(L, 1);
	lua_pushboolean(L, uv_is_readable(handle));
	return 1;
}

int luv_stream_is_writable(lua_State* L) {
	uv_stream_t* handle = luv_stream_check(L, 1);
	lua_pushboolean(L, uv_is_writable(handle));
	return 1;
}

int luv_stream_set_blocking(lua_State* L) {
	uv_stream_t* handle = luv_stream_check(L, 1);
	int blocking, ret;
	luaL_checktype(L, 2, LUA_TBOOLEAN);
	blocking = lua_toboolean(L, 2);
	ret = uv_stream_set_blocking(handle, blocking);
	if (ret < 0) return luv_error(L, ret);
	lua_pushinteger(L, ret);
	return 1;
}

