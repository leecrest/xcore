--初始化包管理器
engine.path = uv.exepath()
engine.cwd = uv.cwd()

engine.__EnvMap = {}
engine.set = function (key, value)
	engine.__EnvMap[key] = value
end

engine.get = function (self, key)
	if key == nil or not engine.__EnvMap then return end
	return engine.__EnvMap[key]
end




--版本号
VERSION = "1.0.0"
VERSION_DEPS = "Lua5.3, libuv1.9.1"

--加载基础模块
dofile("base/utils.lua")
dofile("base/require.lua")
dofile("base/class.lua")
dofile("base/net/base.lua")
