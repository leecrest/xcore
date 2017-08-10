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
#ifndef LUV_H
#define LUV_H
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include "uv.h"

#include <string.h>
#include <stdlib.h>
#include <assert.h>

#if defined(_WIN32)
# include <fcntl.h>
# include <sys/types.h>
# include <sys/stat.h>
# ifndef __MINGW32__
#   define S_ISREG(x)  (((x) & _S_IFMT) == _S_IFREG)
#   define S_ISDIR(x)  (((x) & _S_IFMT) == _S_IFDIR)
#   define S_ISFIFO(x) (((x) & _S_IFMT) == _S_IFIFO)
#   define S_ISCHR(x)  (((x) & _S_IFMT) == _S_IFCHR)
#   define S_ISBLK(x)  0
# endif
# define S_ISLNK(x)  (((x) & S_IFLNK) == S_IFLNK)
# define S_ISSOCK(x) 0
#else
# include <unistd.h>
#include <errno.h>
#endif

#ifndef PATH_MAX
#define PATH_MAX (8096)
#endif

#ifndef MAX_TITLE_LENGTH
#define MAX_TITLE_LENGTH (8192)
#endif

#if LUA_VERSION_NUM < 502
# define lua_rawlen lua_objlen
/* lua_...uservalue: Something very different, but it should get the job done */
# define lua_getuservalue lua_getfenv
# define lua_setuservalue lua_setfenv
# define luaL_newlib(L,l) (lua_newtable(L), luaL_register(L,NULL,l))
# define luaL_setfuncs(L,l,n) (assert(n==0), luaL_register(L,NULL,l))
# define lua_resume(L,F,n) lua_resume(L,n)
# define lua_pushglobaltable(L) lua_pushvalue(L, LUA_GLOBALSINDEX)
#endif

// There is a 1-1 relation between a lua_State and a uv_loop_t
// These helpers will give you one if you have the other
// These are exposed for extensions built with luv
// This allows luv to be used in multithreaded applications.
lua_State* luv_state(uv_loop_t* loop);
// All libuv callbacks will lua_call directly from this root-per-thread state
uv_loop_t* luv_loop(lua_State* L);

// This is the main hook to load the library.
// This can be called multiple times in a process as long
// as you use a different lua_State and thread for each.
LUALIB_API int luaopen_luv (lua_State *L);
int luv_init(lua_State* L);


#include "luv_util.h"
#include "luv_lhandle.h"
#include "luv_loop.h"
#include "luv_req.h"
#include "luv_handle.h"
#include "luv_timer.h"
#include "luv_prepare.h"
#include "luv_check.h"
#include "luv_idle.h"
#include "luv_async.h"
#include "luv_poll.h"
#include "luv_signal.h"
#include "luv_process.h"
#include "luv_stream.h"
#include "luv_tcp.h"
#include "luv_pipe.h"
#include "luv_tty.h"
#include "luv_udp.h"
#include "luv_fs_event.h"
#include "luv_fs_poll.h"
#include "luv_fs.h"
// #include "luv_work.h"
#include "luv_dns.h"
// #include "luv_thread.h"
#include "luv_misc.h"
#include "luv_constants.h"

#endif
