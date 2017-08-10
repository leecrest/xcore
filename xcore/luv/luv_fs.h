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
#ifndef LUV_FS_H
#define LUV_FS_H
#include "luv.h"

void luv_push_timespec_table(lua_State* L, const uv_timespec_t* t);
void luv_push_stats_table(lua_State* L, const uv_stat_t* s);
int luv_fs_check_flags(lua_State* L, int index);
int luv_fs_check_amode(lua_State* L, int index);
int push_fs_result(lua_State* L, uv_fs_t* req);
void luv_fs_cb(uv_fs_t* req);
int luv_fs_close(lua_State* L);
int luv_fs_open(lua_State* L);
int luv_fs_read(lua_State* L);
int luv_fs_unlink(lua_State* L);
int luv_fs_write(lua_State* L);
int luv_fs_mkdir(lua_State* L);
int luv_fs_mkdtemp(lua_State* L);
int luv_fs_rmdir(lua_State* L);
int luv_fs_scandir(lua_State* L);
int luv_fs_scandir_next(lua_State* L);
int luv_fs_stat(lua_State* L);
int luv_fs_fstat(lua_State* L);
int luv_fs_lstat(lua_State* L);
int luv_fs_rename(lua_State* L);
int luv_fs_fsync(lua_State* L);
int luv_fs_fdatasync(lua_State* L);
int luv_fs_ftruncate(lua_State* L);
int luv_fs_sendfile(lua_State* L);
int luv_fs_access(lua_State* L);
int luv_fs_chmod(lua_State* L);
int luv_fs_fchmod(lua_State* L);
int luv_fs_utime(lua_State* L);
int luv_fs_futime(lua_State* L);
int luv_fs_link(lua_State* L);
int luv_fs_symlink(lua_State* L);
int luv_fs_readlink(lua_State* L);
int luv_fs_chown(lua_State* L);
int luv_fs_fchown(lua_State* L);

#endif