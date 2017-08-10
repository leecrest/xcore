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


const luaL_Reg luv_functions[] = {
	// loop.c
	{ "close", luv_loop_close },
	{ "run", luv_loop_run },
	{ "alive", luv_loop_alive },
	{ "stop", luv_loop_stop },
	{ "backend_fd", luv_loop_backend_fd },
	{ "backend_timeout", luv_loop_backend_timeout },
	{ "now", luv_loop_now },
	{ "update_time", luv_loop_update_time },
	{ "walk", luv_loop_walk },

	// req.c
	{ "req_cancel", luv_req_cancel },

	// handle.c
	{ "handle_is_active", luv_handle_is_active },
	{ "handle_is_closing", luv_handle_is_closing },
	{ "handle_close", luv_handle_close },
	{ "handle_ref", luv_handle_ref },
	{ "handle_unref", luv_handle_unref },
	{ "handle_has_ref", luv_handle_has_ref },
	{ "handle_send_buffer_size", luv_handle_send_buffer_size },
	{ "handle_recv_buffer_size", luv_handle_recv_buffer_size },
	{ "handle_fileno", luv_handle_fileno },

	// timer.c
	{ "timer_new", luv_timer_new },
	{ "timer_start", luv_timer_start },
	{ "timer_stop", luv_timer_stop },
	{ "timer_again", luv_timer_again },
	{ "timer_set_repeat", luv_timer_set_repeat },
	{ "timer_get_repeat", luv_timer_get_repeat },

	// prepare.c
	{ "prepare_new", luv_prepare_new },
	{ "prepare_start", luv_prepare_start },
	{ "prepare_stop", luv_prepare_stop },

	// check.c
	{ "check_new", luv_check_new },
	{ "check_start", luv_check_start },
	{ "check_stop", luv_check_stop },

	// idle.c
	{ "idle_new", luv_idle_new },
	{ "idle_start", luv_idle_start },
	{ "idle_stop", luv_idle_stop },

	// async.c
	{ "async_new", luv_async_new },
	{ "async_send", luv_async_send },

	// poll.c
	{ "poll_new", luv_poll_new },
	{ "poll_start", luv_poll_start },
	{ "poll_stop", luv_poll_stop },

	// signal.c
	{ "signal_new", luv_signal_new },
	{ "signal_start", luv_signal_start },
	{ "signal_stop", luv_signal_stop },

	// process.c
	{ "process_disable_stdio_inheritance", luv_process_disable_stdio_inheritance },
	{ "process_spawn", luv_process_spawn },
	{ "process_kill", luv_process_kill },
	{ "kill", luv_kill },

	// stream.c
	{ "stream_shutdown", luv_stream_shutdown },
	{ "stream_listen", luv_stream_listen },
	{ "stream_accept", luv_stream_accept },
	{ "stream_read_start", luv_stream_read_start },
	{ "stream_read_stop", luv_stream_read_stop },
	{ "stream_write", luv_stream_write },
	{ "stream_write2", luv_stream_write2 },
	{ "stream_try_write", luv_stream_try_write },
	{ "stream_is_readable", luv_stream_is_readable },
	{ "stream_is_writable", luv_stream_is_writable },
	{ "stream_set_blocking", luv_stream_set_blocking },

	// tcp.c
	{ "tcp_new", luv_tcp_new },
	{ "tcp_open", luv_tcp_open },
	{ "tcp_nodelay", luv_tcp_nodelay },
	{ "tcp_keepalive", luv_tcp_keepalive },
	{ "tcp_simultaneous_accepts", luv_tcp_simultaneous_accepts },
	{ "tcp_bind", luv_tcp_bind },
	{ "tcp_getpeername", luv_tcp_getpeername },
	{ "tcp_getsockname", luv_tcp_getsockname },
	{ "tcp_connect", luv_tcp_connect },
	{ "tcp_write_queue_size", luv_tcp_write_queue_size },

	// pipe.c
	{ "pipe_new", luv_pipe_new },
	{ "pipe_open", luv_pipe_open },
	{ "pipe_bind", luv_pipe_bind },
	{ "pipe_connect", luv_pipe_connect },
	{ "pipe_getsockname", luv_pipe_getsockname },
	{ "pipe_getpeername", luv_pipe_getpeername },
	{ "pipe_pending_instances", luv_pipe_pending_instances },
	{ "pipe_pending_count", luv_pipe_pending_count },
	{ "pipe_pending_type", luv_pipe_pending_type },

	// tty.c
	{ "tty_new", luv_tty_new },
	{ "tty_set_mode", luv_tty_set_mode },
	{ "tty_reset_mode", luv_tty_reset_mode },
	{ "tty_get_winsize", luv_tty_get_winsize },

	// udp.c
	{ "udp_new", luv_udp_new },
	{ "udp_open", luv_udp_open },
	{ "udp_bind", luv_udp_bind },
	{ "udp_bindgetsockname", luv_udp_getsockname },
	{ "udp_set_membership", luv_udp_set_membership },
	{ "udp_set_multicast_loop", luv_udp_set_multicast_loop },
	{ "udp_set_multicast_ttl", luv_udp_set_multicast_ttl },
	{ "udp_set_multicast_interface", luv_udp_set_multicast_interface },
	{ "udp_set_broadcast", luv_udp_set_broadcast },
	{ "udp_set_ttl", luv_udp_set_ttl },
	{ "udp_send", luv_udp_send },
	{ "udp_try_send", luv_udp_try_send },
	{ "udp_recv_start", luv_udp_recv_start },
	{ "udp_recv_stop", luv_udp_recv_stop },

	// fs_event.c
	{ "fs_event_new", luv_fs_event_new },
	{ "fs_event_start", luv_fs_event_start },
	{ "fs_event_stop", luv_fs_event_stop },
	{ "fs_event_getpath", luv_fs_event_getpath },

	// fs_poll.c
	{ "fs_poll_new", luv_fs_poll_new },
	{ "fs_poll_start", luv_fs_poll_start },
	{ "fs_poll_stop", luv_fs_poll_stop },
	{ "fs_poll_getpath", luv_fs_poll_getpath },

	// fs.c
	{ "fs_close", luv_fs_close },
	{ "fs_open", luv_fs_open },
	{ "fs_read", luv_fs_read },
	{ "fs_unlink", luv_fs_unlink },
	{ "fs_write", luv_fs_write },
	{ "fs_mkdir", luv_fs_mkdir },
	{ "fs_mkdtemp", luv_fs_mkdtemp },
	{ "fs_rmdir", luv_fs_rmdir },
	{ "fs_scandir", luv_fs_scandir },
	{ "fs_scandir_next", luv_fs_scandir_next },
	{ "fs_stat", luv_fs_stat },
	{ "fs_fstat", luv_fs_fstat },
	{ "fs_lstat", luv_fs_lstat },
	{ "fs_rename", luv_fs_rename },
	{ "fs_fsync", luv_fs_fsync },
	{ "fs_fdatasync", luv_fs_fdatasync },
	{ "fs_ftruncate", luv_fs_ftruncate },
	{ "fs_sendfile", luv_fs_sendfile },
	{ "fs_access", luv_fs_access },
	{ "fs_chmod", luv_fs_chmod },
	{ "fs_fchmod", luv_fs_fchmod },
	{ "fs_utime", luv_fs_utime },
	{ "fs_futime", luv_fs_futime },
	{ "fs_link", luv_fs_link },
	{ "fs_symlink", luv_fs_symlink },
	{ "fs_readlink", luv_fs_readlink },
	{ "fs_chown", luv_fs_chown },
	{ "fs_fchown", luv_fs_fchown },

	// dns.c
	{ "getaddrinfo", luv_getaddrinfo },
	{ "getnameinfo", luv_getnameinfo },

	// misc.c
	{ "chdir", luv_chdir },
	{ "cpu", luv_cpu_info },
	{ "cwd", luv_cwd },
	{ "exepath", luv_exepath },
	{ "get_process_title", luv_get_process_title },
	{ "set_process_title", luv_set_process_title },
	{ "get_total_memory", luv_get_total_memory },
	{ "getpid", luv_getpid },
#ifndef _WIN32
	{ "getuid", luv_getuid },
	{ "setuid", luv_setuid },
	{ "getgid", luv_getgid },
	{ "setgid", luv_setgid },
#endif
	{ "getrusage", luv_getrusage },
	{ "guess_handle", luv_guess_handle },
	{ "hrtime", luv_hrtime },
	{ "interface_addresses", luv_interface_addresses },
	{ "loadavg", luv_loadavg },
	{ "resident_set_memory", luv_resident_set_memory },
	{ "uptime", luv_uptime },
	{ "version", luv_version },
	{ "version_string", luv_version_string },

	{ "stackdump", luv_stackdump },
	{ NULL, NULL }
};

const luaL_Reg luv_handle_methods[] = {
	// handle.c
	{ "is_active", luv_handle_is_active },
	{ "is_closing", luv_handle_is_closing },
	{ "close", luv_handle_close },
	{ "ref", luv_handle_ref },
	{ "unref", luv_handle_unref },
	{ "has_ref", luv_handle_has_ref },
	{ "send_buffer_size", luv_handle_send_buffer_size },
	{ "recv_buffer_size", luv_handle_recv_buffer_size },
	{ "fileno", luv_handle_fileno },
	{ NULL, NULL }
};

const luaL_Reg luv_async_methods[] = {
	{ "send", luv_async_send },
	{ NULL, NULL }
};

const luaL_Reg luv_check_methods[] = {
	{ "start", luv_check_start },
	{ "stop", luv_check_stop },
	{ NULL, NULL }
};

const luaL_Reg luv_fs_event_methods[] = {
	{ "start", luv_fs_event_start },
	{ "stop", luv_fs_event_stop },
	{ "getpath", luv_fs_event_getpath },
	{ NULL, NULL }
};

const luaL_Reg luv_fs_poll_methods[] = {
	{ "start", luv_fs_poll_start },
	{ "stop", luv_fs_poll_stop },
	{ "getpath", luv_fs_poll_getpath },
	{ NULL, NULL }
};

const luaL_Reg luv_idle_methods[] = {
	{ "start", luv_idle_start },
	{ "stop", luv_idle_stop },
	{ NULL, NULL }
};

const luaL_Reg luv_stream_methods[] = {
	{ "shutdown", luv_stream_shutdown },
	{ "listen", luv_stream_listen },
	{ "accept", luv_stream_accept },
	{ "read_start", luv_stream_read_start },
	{ "read_stop", luv_stream_read_stop },
	{ "write", luv_stream_write },
	{ "write2", luv_stream_write2 },
	{ "try_write", luv_stream_try_write },
	{ "is_readable", luv_stream_is_readable },
	{ "is_writable", luv_stream_is_writable },
	{ "set_blocking", luv_stream_set_blocking },
	{ NULL, NULL }
};

const luaL_Reg luv_pipe_methods[] = {
	{ "open", luv_pipe_open },
	{ "bind", luv_pipe_bind },
	{ "connect", luv_pipe_connect },
	{ "getsockname", luv_pipe_getsockname },
	{ "getpeername", luv_pipe_getpeername },
	{ "pending_instances", luv_pipe_pending_instances },
	{ "pending_count", luv_pipe_pending_count },
	{ "pending_type", luv_pipe_pending_type },
	{ NULL, NULL }
};

const luaL_Reg luv_poll_methods[] = {
	{ "start", luv_poll_start },
	{ "stop", luv_poll_stop },
	{ NULL, NULL }
};

const luaL_Reg luv_prepare_methods[] = {
	{ "start", luv_prepare_start },
	{ "stop", luv_prepare_stop },
	{ NULL, NULL }
};

const luaL_Reg luv_process_methods[] = {
	{ "kill", luv_process_kill },
	{ NULL, NULL }
};

const luaL_Reg luv_tcp_methods[] = {
	{ "open", luv_tcp_open },
	{ "nodelay", luv_tcp_nodelay },
	{ "keepalive", luv_tcp_keepalive },
	{ "simultaneous_accepts", luv_tcp_simultaneous_accepts },
	{ "bind", luv_tcp_bind },
	{ "getpeername", luv_tcp_getpeername },
	{ "getsockname", luv_tcp_getsockname },
	{ "connect", luv_tcp_connect },
	{ "write_queue_size", luv_tcp_write_queue_size },
	{ NULL, NULL }
};

const luaL_Reg luv_timer_methods[] = {
	{ "start", luv_timer_start },
	{ "stop", luv_timer_stop },
	{ "again", luv_timer_again },
	{ "set_repeat", luv_timer_set_repeat },
	{ "get_repeat", luv_timer_get_repeat },
	{ NULL, NULL }
};

const luaL_Reg luv_tty_methods[] = {
	{ "set_mode", luv_tty_set_mode },
	{ "get_winsize", luv_tty_get_winsize },
	{ NULL, NULL }
};

const luaL_Reg luv_udp_methods[] = {
	{ "open", luv_udp_open },
	{ "bind", luv_udp_bind },
	{ "bindgetsockname", luv_udp_getsockname },
	{ "set_membership", luv_udp_set_membership },
	{ "set_multicast_loop", luv_udp_set_multicast_loop },
	{ "set_multicast_ttl", luv_udp_set_multicast_ttl },
	{ "set_multicast_interface", luv_udp_set_multicast_interface },
	{ "set_broadcast", luv_udp_set_broadcast },
	{ "set_ttl", luv_udp_set_ttl },
	{ "send", luv_udp_send },
	{ "try_send", luv_udp_try_send },
	{ "recv_start", luv_udp_recv_start },
	{ "recv_stop", luv_udp_recv_stop },
	{ NULL, NULL }
};

const luaL_Reg luv_signal_methods[] = {
	{ "start", luv_signal_start },
	{ "stop", luv_signal_stop },
	{ NULL, NULL }
};

void luv_handle_init(lua_State* L) {

	lua_newtable(L);
#define XX(uc, lc)                             \
    luaL_newmetatable (L, "uv_"#lc);           \
    lua_pushcfunction(L, luv_handle_tostring); \
    lua_setfield(L, -2, "__tostring");         \
    luaL_newlib(L, luv_##lc##_methods);        \
    luaL_setfuncs(L, luv_handle_methods, 0);   \
    lua_setfield(L, -2, "__index");            \
    lua_pushboolean(L, 1);                     \
    lua_rawset(L, -3);

	UV_HANDLE_TYPE_MAP(XX)
#undef XX
	lua_setfield(L, LUA_REGISTRYINDEX, "uv_handle");

	lua_newtable(L);

	luaL_getmetatable(L, "uv_pipe");
	lua_getfield(L, -1, "__index");
	luaL_setfuncs(L, luv_stream_methods, 0);
	lua_pop(L, 1);
	lua_pushboolean(L, 1);
	lua_rawset(L, -3);

	luaL_getmetatable(L, "uv_tcp");
	lua_getfield(L, -1, "__index");
	luaL_setfuncs(L, luv_stream_methods, 0);
	lua_pop(L, 1);
	lua_pushboolean(L, 1);
	lua_rawset(L, -3);

	luaL_getmetatable(L, "uv_tty");
	lua_getfield(L, -1, "__index");
	luaL_setfuncs(L, luv_stream_methods, 0);
	lua_pop(L, 1);
	lua_pushboolean(L, 1);
	lua_rawset(L, -3);

	lua_setfield(L, LUA_REGISTRYINDEX, "uv_stream");
}

lua_State* luv_state(uv_loop_t* loop) {
	return (lua_State*)(loop->data);
}

// TODO: find out if storing this somehow in an upvalue is faster
uv_loop_t* luv_loop(lua_State* L) {
	uv_loop_t* loop;
	lua_pushstring(L, "uv_loop");
	lua_rawget(L, LUA_REGISTRYINDEX);
	loop = (uv_loop_t*)lua_touserdata(L, -1);
	lua_pop(L, 1);
	return loop;
}

LUALIB_API int luaopen_luv (lua_State *L) {
	lua_setglobal(L, "uv");
	luaL_newlib(L, luv_functions);

	luv_constants(L);
	lua_setfield(L, -2, "constants");

	return 1;
}

int luv_init(lua_State* L) {
	uv_loop_t* loop;
	int ret;

	loop = (uv_loop_t*)lua_newuserdata(L, sizeof(*loop));
	ret = uv_loop_init(loop);
	if (ret < 0) {
		return luaL_error(L, "%s: %s\n", uv_err_name(ret), uv_strerror(ret));
	}
	lua_pushstring(L, "uv_loop");
	lua_insert(L, -2);
	lua_rawset(L, LUA_REGISTRYINDEX);
	loop->data = L;
	luv_req_init(L);
	luv_handle_init(L);
	
	return 1;
}
