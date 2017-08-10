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
static char g_ErrMsgBuff[1024] = {"\0"};

void luv_stackdump_impl(lua_State*L, int iLevel) {
	lua_Debug stDebug;
	int iRet = lua_getstack(L, iLevel, &stDebug);
	if (1 != iRet) {
		return;
	}
	lua_getinfo(L, "nfSlu", &stDebug);
	lua_pop(L, 1);
	int pos = strlen(g_ErrMsgBuff);
	if (stDebug.what[0] == 'C') {
		if (stDebug.name) {
			sprintf(g_ErrMsgBuff + pos, "%4d[C] : in %s\n", iLevel, stDebug.name);
		}
		else {
			sprintf(g_ErrMsgBuff + pos, "%4d[C] :\n", iLevel);
		}
	}
	else {
		if (stDebug.name) {
			sprintf(g_ErrMsgBuff + pos, "%4d %s:%d in %s\n", iLevel, stDebug.short_src, stDebug.currentline, stDebug.name);
		}
		else {
			sprintf(g_ErrMsgBuff + pos, "%4d %s:%d\n", iLevel, stDebug.short_src, stDebug.currentline);
		}
	}
	pos = strlen(g_ErrMsgBuff);

	int iIndex = 1;
	int iType;
	const char* sName = NULL;
	const char* sType = NULL;
	while ((sName = lua_getlocal(L, &stDebug, iIndex++)) != NULL) {
		if (strcmp(sName, "_ENV") == 0 || strcmp(sName, "_G") == 0) {
			continue;
		}
		iType = lua_type(L, -1);
		if (iType == LUA_TNIL) {
			continue;
		}
		sType = lua_typename(L, iType);
		switch (iType) {
		case LUA_TBOOLEAN:
			sprintf(g_ErrMsgBuff + strlen(g_ErrMsgBuff), "\t%s = <%s> %s\n", sName, sType, lua_toboolean(L, -1) ? "true" : "false");
			break;
		case LUA_TLIGHTUSERDATA:
		case LUA_TUSERDATA:
		case LUA_TTHREAD:
		case LUA_TFUNCTION:
		case LUA_TTABLE:
			sprintf(g_ErrMsgBuff + strlen(g_ErrMsgBuff), "\t%s = <%s> 0x%8p\n", sName, sType, lua_topointer(L, -1));
			break;
		default:
			sprintf(g_ErrMsgBuff + strlen(g_ErrMsgBuff), "\t%s = <%s> %s\n", sName, sType, lua_tostring(L, -1));
			break;
		}
		lua_pop(L, 1);
	}
	iIndex = 1;
	while ((sName = lua_getupvalue(L, -1, iIndex++)) != NULL) {
		if (strcmp(sName, "_ENV") == 0 || strcmp(sName, "_G") == 0) {
			continue;
		}
		iType = lua_type(L, -1);
		if (iType == LUA_TNIL) {
			continue;
		}
		sType = lua_typename(L, iType);
		switch (iType) {
		case LUA_TBOOLEAN:
			sprintf(g_ErrMsgBuff + strlen(g_ErrMsgBuff), "\t%s = <%s> %s\n", sName, sType, lua_toboolean(L, -1) ? "true" : "false");
			break;
		case LUA_TLIGHTUSERDATA:
		case LUA_TUSERDATA:
		case LUA_TTHREAD:
		case LUA_TFUNCTION:
		case LUA_TTABLE:
			sprintf(g_ErrMsgBuff + strlen(g_ErrMsgBuff), "\t%s = <%s> 0x%8p\n", sName, sType, lua_topointer(L, -1));
			break;
		default:
			sprintf(g_ErrMsgBuff + strlen(g_ErrMsgBuff), "\t%s = <%s> %s\n", sName, sType, lua_tostring(L, -1));
			break;
		}
		lua_pop(L, 1);
	}
	luv_stackdump_impl(L, iLevel + 1);
}

const char LUV_STACKDUMP_STR[] = "\n===========[luv_stackdump]==============\n";
int luv_stackdump(lua_State *L) {
	g_ErrMsgBuff[0] = '\0';
	strcpy(g_ErrMsgBuff, LUV_STACKDUMP_STR);
	int iTop = lua_gettop(L);
	if (iTop > 0) {
		sprintf(g_ErrMsgBuff + strlen(g_ErrMsgBuff), "%s\n", lua_tostring(L, -1));
	}
	luv_stackdump_impl(L, 1);
	fprintf(stdout, "%s\n", g_ErrMsgBuff);
	//lua_getglobal(L, "debug.excepthook");
	lua_pushstring(L, g_ErrMsgBuff);
	return 1;
}

int luv_error(lua_State* L, int status) {
	const char* sErrName = uv_err_name(status);
	const char* sErrStr = uv_strerror(status);
	lua_pushnil(L);
	lua_pushfstring(L, "[luv_error]%s: %s", sErrName, sErrStr);
	lua_pushstring(L, sErrName);

	g_ErrMsgBuff[0] = '\0';
	strcpy(g_ErrMsgBuff, LUV_STACKDUMP_STR);
	sprintf(g_ErrMsgBuff + strlen(g_ErrMsgBuff), "%s:%s\n", sErrName, sErrStr);
	luv_stackdump_impl(L, 1);
	fprintf(stdout, "%s\n", g_ErrMsgBuff);
	return 3;
}

void luv_status(lua_State* L, int status) {
	//fprintf(stdout, "[luv_status]%s\n", status);
	if (status < 0) {
		// For now log errors to stderr in case they aren't asserted or checked for.
		//fprintf(stdout, "[luv_status]%s: %s\n", uv_err_name(status), uv_strerror(status));
		lua_pushstring(L, uv_err_name(status));
	}
	else {
		lua_pushnil(L);
	}
}

void luv_pcall(lua_State* L, int ref, int nargs) {
	if (ref == LUA_NOREF) {
		lua_pop(L, nargs);
		return;
	}
	// Get the traceback function in case of error
	lua_pushcfunction(L, luv_stackdump);
	// And insert it before the args if there are any.
	if (nargs) {
		lua_insert(L, -1 - nargs);
	}
	// Get the callback
	lua_rawgeti(L, LUA_REGISTRYINDEX, ref);
	// And insert it before the args if there are any.
	if (nargs) {
		lua_insert(L, -1 - nargs);
	}

	lua_pcall(L, nargs, 0, -2 - nargs);
	lua_pop(L, 1);
}