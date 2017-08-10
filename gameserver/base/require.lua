--[[
替换系统require函数，实现自定义require，并支持热更新

各模块文件编写规范如下：
1、__init__：首次加载完成后调用
2、__start__：所有模块加载完毕后依次调用
3、__destory__：模块销毁前调用
4、__update__：模块再次加载完毕后调用，热更新
]]

local RealRequire = _ENV.require
_ENV._MODULE = _ENV._MODULE or {}	--记录所有模块的数据
_ENV._CLASS = _ENV._CLASS or {}		--记录所有类的结构

--加载模块文件
local function _LoadModel(name, func, env)
	local _ENV = env
	func()
end

--加载文件
local function LoadFile(name, flag, env)
	--优先尝试加载本地文件
	local func, err1 = loadfile(name, flag, env)
	if func and not err1 then
		return func, name, err1
	end
	if not string.find(err1, "cannot") then
		assert(nil, err1)
		return
	end
	
	--增加.lua后尝试加载本地文件
	local err2
	local name2 = name:gsub("\\", "/") .. ".lua"
	func, err2 = loadfile(name2, flag, env)
	if func and not err2 then
		return func, name2, err2
	end

	if err2 then
		assert(nil, err2)
	elseif err1 then
		assert(nil, err1)
	end
end

--执行模块的初始化__init__
local function _CallInit(name, Module)
	-- 注册所有的 Class 到 CLASS 里去，依赖 Class:GetType() 属性，注意：只遍历 1 层
	for _, v in pairs(Module) do
		if type(v) == "table" and rawget(v,"__ClassType") then
			local ClassType = v:GetType()
			assert(not _CLASS[ClassType], "class repeat:"..ClassType)
			_CLASS[ClassType] = v
		end
	end
	if Module.__init__ then
		Module:__init__()
	end
end

--执行模块的销毁__destroy__
local function _CallDestroy(Module)
	if Module.__destroy__ then
		Module:__destroy__()
	end	
	local metatable = getmetatable(Module)
	if metatable["__newindex"] then
		metatable["__newindex"] = nil
	end
end

--模块热更新时执行__update__
local function _CallUpdate(Module)
	if Module.__update__ then
		Module:__update__()
	end
end

local function _ReplaceTable(Dest, Src)
	local function RealFun(Dest, Src, Depth)
		Depth = Depth or 0
		assert(type(Dest)=="table" and type(Src)=="table", "error data type")
		if Depth>=20 then
			error("too long Depth to replace")
			return
		end
		for k, v in pairs(Dest) do
			if type(v) == "table" then
				-- 不对__index做deep替换
				if type(Src[k]) == "table" and k ~="__index" then
					RealFun(v, Src[k], Depth+1)
				else
					Dest[k] = Src[k]
				end
			else
				Dest[k] = Src[k]
			end
		end
		--把新增的数据或者方法引用进来
		for k,v in pairs(Src) do
			--注意一定要使用rawget，否则在以下情况更新会失败.
			--父类A实现了test函数，子类A1未实现，然后在线添加A1.test的实现并更新。
			--这时候Dest[k]实际上访问了metatable中父类的实现，所以不为nil，于是更新失败
			if rawget(Dest, k) == nil then
				Dest[k] = v
			end
		end
		setmetatable(Dest, getmetatable(Src))
	end
	RealFun(Dest, Src)
end


function require(name, reload)
	assert(name, "Missing name to require")
	--内建库仍然使用原生require
	if package.preload[name] or package.loaded[name] then
		return RealRequire(name)
	end

	local Old = _MODULE[name]
	if Old and not reload then
		return Old
	end

	--加载模块文件
	local New = {}
	_ENV.__init__ = nil
	_ENV.__start__ = nil
	_ENV.__update__ = nil
	_ENV.__destroy__ = nil
	setmetatable(New, {__index=_ENV})
	local func, name2, err = LoadFile(name, "bt", New)
	if not func then
		return func, err
	end
	if name2 and name2 ~= name then
		Old = _MODULE[name2]
		if Old and not reload then return Old end
		name = name2
	end
	_LoadModel(name, func, New)
	--首次加载
	if not Old then
		_MODULE[name] = New
		_CallInit(name, New)
		return New
	end
	
	--热更新
	_CallDestroy(Old)
	
	--更新以后的模块, 里面的table的reference将不再有效，需要还原.
	local TmpNewClass = {}
	-- 类与类名匹配,后面把新类重新指向旧类
	for k, v in pairs(New) do
		if type(v) == "table" and rawget(v,"__ClassType") then
			TmpNewClass[v] = k
		end
	end
	--还原table(copy by value)
	for k,v in pairs(Old) do
		local TmpNewData = New[k]
		New[k] = v
		if TmpNewData then
			if type(v) == "table" and type(TmpNewData) == "table" then
				--如果是一个class则需要全部更新,其他则可能只是一些数据，不需要更新
				if v.__ClassType then
					local mt = getmetatable(v)
					if rawget(v,"__ClassType") then
						-- 是class要更新其mt
						local old_mt = v.mt
						local index = old_mt.__index
						_ReplaceTable(v, TmpNewData)
						v.mt = old_mt
						old_mt.__index = index
					end
				end
				local mt = getmetatable(TmpNewData)
				if mt then setmetatable(v, mt) end
			--函数段必须用新的
			elseif type(v) == "function" then
				New[k] = TmpNewData
			end
		end
	end

	for k,v in pairs(New) do
		-- 更新继承关系，使用原型继承类
		if type(v) == "table" and rawget(v,"__ClassType") then
			local ParentMt = getmetatable(v)
			if ParentMt and ParentMt.__index then
				if TmpNewClass[ParentMt.__index] and Old[TmpNewClass[ParentMt.__index]] then
					ParentMt.__index = Old[TmpNewClass[ParentMt.__index]]
				end
			end
		end
	end
	_MODULE[name] = New
	_CallInit(name, New)
	_CallUpdate(New)
	return New
end
_ENV.require = require

--启动所有脚本
engine.start = function ()
	--注意:**先复制一份Module表，因为调用__start__的时候有可能改变这个table。
	local _copy = {}
	for k, v in pairs(_MODULE) do
		_copy[k] = v
	end
	for _, obj in pairs(_copy) do
		if obj.__start__ then
			obj:__start__()
		end
	end
end

--结束所有脚本
engine.stop = function ()
	local _copy = {}
	for k, v in pairs(_MODULE) do
		_copy[k] = v
	end
	for _, obj in pairs(_copy) do
		if obj.__destroy__ then
			obj:__destroy__()
		end
	end
end
