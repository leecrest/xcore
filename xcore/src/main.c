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
#include "lminiz.h"
#include "lengine.h"


lua_State* g_Lua;
void ExitEngine() {
	if (g_Lua == NULL) return;
	luaL_dostring(g_Lua, "lengine.stop()");
	uv_loop_close(luv_loop(g_Lua));
	lua_close(g_Lua);
	g_Lua = NULL;
}

int ExecFile(const char* file) {
	lua_pushcfunction(g_Lua, luv_stackdump);
	int iErrFunc = lua_gettop(g_Lua);
	int iRet = luaL_loadfile(g_Lua, file);
	if (iRet) {
		return iRet;
	}
	lua_pcall(g_Lua, 0, 0, iErrFunc);
	return 0;
}


#ifdef WIN32
#include <Windows.h>
BOOL CtrlHandler(DWORD fdwCtrlType)
{
	switch (fdwCtrlType)
	{
		// Handle the CTRL-C signal. 
	case CTRL_C_EVENT:
		//fprintf(stderr, ">>>>>>CTRL_C_EVENT<<<<<<\n");
		ExitEngine();
		return FALSE;

		// CTRL-CLOSE: confirm that the user wants to exit.
	case CTRL_CLOSE_EVENT:
		//fprintf(stderr, ">>>>>>CTRL_CLOSE_EVENT<<<<<<\n");
		ExitEngine();
		return FALSE;

		// Pass other signals to the next handler. 
	case CTRL_BREAK_EVENT:
		//fprintf(stderr, ">>>>>>CTRL_BREAK_EVENT<<<<<<\n");
		ExitEngine();
		return FALSE;

	case CTRL_LOGOFF_EVENT:
		//fprintf(stderr, ">>>>>>CTRL_LOGOFF_EVENT<<<<<<\n");
		ExitEngine();
		return FALSE;

	case CTRL_SHUTDOWN_EVENT:
		//fprintf(stderr, ">>>>>>CTRL_SHUTDOWN_EVENT<<<<<<\n");
		ExitEngine();
		return FALSE;

	default:
		//fprintf(stderr, ">>>>>>CtrlHandler<<<<<<\n");
		return FALSE;
	}
}
#endif


int main(int argc, char* argv[] ) {
	argv = uv_setup_args(argc, argv);

	// Lua虚拟机初始化
	g_Lua = luaL_newstate();
	if (g_Lua == NULL) {
		fprintf(stderr, "luaL_newstate has failed\n");
		return 1;
	}
	// 加载基础库
	luaL_openlibs(g_Lua);
	// 初始化uv库，建立lua和uv_loop的关联
	luv_init(g_Lua);

	// 加载内建库
	const luaL_Reg libs[] = {
		{ "uv", luaopen_luv },
		{ "miniz", luaopen_miniz },
		{ "engine",  luaopen_engine },
		{ NULL, NULL },
	};
	for (const luaL_Reg* lib = libs; lib->func; lib++) {
		luaL_requiref(g_Lua, lib->name, lib->func, 1);
		lua_pop(g_Lua, 1);
	}

	// 加载框架层脚本
	int iRet = ExecFile("base/preload.lua");
	if (iRet) { return iRet; }

	// 初始化包管理库
	if (argc > 1 && argv[1] != NULL) {
		// 将命令行参数填入engine.exeargs丿
		if (argc > 2 && argv[2] != NULL) {
			lua_getglobal(g_Lua, "engine");
			lua_pushstring(g_Lua, "exeargs");
			lua_newtable(g_Lua);
			for (int i = 1; i < argc; i++) {
				lua_pushinteger(g_Lua, i);
				lua_pushstring(g_Lua, argv[i+1]);
				lua_settable(g_Lua, -3);
			}
			lua_settable(g_Lua, -3);
			lua_pop(g_Lua, 1);
		}

		// 执行文件
		int iRet = ExecFile(argv[1]);
		if (iRet) { return iRet; }
	}
	else {
		// 进入repl
		luaL_dostring(g_Lua, "require('base/repl').run()");
	}

	// 处理Ctrl+C
#ifdef WIN32
	SetConsoleCtrlHandler((PHANDLER_ROUTINE)CtrlHandler, TRUE);
#endif

	uv_run(luv_loop(g_Lua), UV_RUN_DEFAULT);

	//引擎退出
	ExitEngine();
	return 1;
}