--实现类

--序列化相关
function Serialize(data, temp)
    local tp = type(data)
    if tp == "string" then
        return "\""..data.."\""
    elseif tp ~= "table" then
        return tostring(data)
    end
	if type(data.ToString) == "function" and type(data.GetType) == "function" then
		return data:ToString(temp)
	end
    local tbl = {[1]="{"}
    local idx = 2
	local ks, vs
    for k, v in pairs(data) do
		vs = Serialize(v, temp)
		if vs then
            tp = type(k)
            if tp == "string" then
                ks = "[\""..k.."\"]"
            elseif tp == "number" then
                ks = "["..k.."]"
            else
                ks = tostring(k)
            end
            tbl[idx] = ks
            tbl[idx+1] = "="
            tbl[idx+2] = vs
            tbl[idx+3] = ","
            idx = idx + 4
		end
	end
    tbl[idx] = "}"
    return table.concat(tbl)
end

function UnSerialize(data)
    if type(data) ~= "string" then
		return data
	end
	local func = load("return "..data)
	if not func then return end
	data = func()
    if type(data) ~= "table" then
		return data
	end
	local cls, obj
	if data.__class__ then
	    cls = CLASS[data.__class__]
		if not cls then return end
	    obj = cls:New()
	    if data.__save__ then
		    obj:Load(data.__save__)
	    end
        return obj
	end
	for k, v in pairs(data) do
		if type(v) == "table" then
			if v.__class__ then
	            cls = CLASS[v.__class__]
                if cls then
	                obj = cls:New()
	                if v.__save__ then
						obj:Load(v.__save__)
	                end
                    data[k] = obj
                else
                    data[k] = nil
                end
			end
		end
	end
	return data
end



--获取一个class的父类
function Super(cls)
	return getmetatable(cls).__index
end

--判断一个class或者对象是否
function SubClassOf(a, b)
	local temp = a
	while  1 do
		local mt = getmetatable(temp)
		if mt then
			temp = mt.__index
			if temp == b then
				return true
			end
		else
			return false
		end
	end
end

--判断a是否是b的实例
function InstanceOf(obj, cls)
	if type(obj) ~= "table" then return false end
	if not obj.__ClassType then return false end
	return SubClassOf(obj, cls)
end


--继承类
function Inherit(cls, name)
	return _CLASS[cls]:Inherit(name)
end

CObject = {
	--用于区别是否是一个对象 or Class or 普通table
	__ClassType = "CObject"
}

function CObject:Inherit(clsName, o)	
	o = o or {}
	o.mt = { __index = o}
	assert(clsName, "must have clsName")
	o.__ClassType = clsName
	o.__InheritMap = {}  -- 继承列表
	if self.__InheritMap then
		for k, v in ipairs(self.__InheritMap) do
			o.__InheritMap[k] = v
		end
	end
	o.__InheritMap[#o.__InheritMap+1] = self:GetType()
	setmetatable(o, {__index = self})
	return o
end

function CObject:IsSubObj(objtype)
	local map = self:GetTypeMap()
	if not map then return false end
	return table.ifind(map, objtype) and true or false
end

function CObject:GetTypeMap()
	local clsSelf = getmetatable(self)
	return clsSelf and clsSelf.__index.__InheritMap
end

function CObject:New(...)
	local o = {
		--以下必不可少，是属性和算子的基础
		__TempAttr = {},
		__SaveAttr = {},
		__SaveAttrFlag = {},
		__CounterID = 0,
		__CounterMap = {},
		__CounterSubMap = {},
		__CounterGroupMap = {},
		__CounterDisableMap = {},
	}
	setmetatable(o, self.mt)
	if o.Create then
		o:Create(...)
	end
	return o
end

function CObject:Create()
end

function CObject:IsClass()
	return true
end

function CObject:Destroy()
end

function CObject:GetType()
	return self.__ClassType
end

function CObject:ToString()
	local SaveData = self:GetSaveData()
	return string.format("{__class__=\"%s\",__save__=%s}", self:GetType(), Serialize(SaveData))
end

function CObject:Load(data)
	self.__SaveAttr = data
	self.__SaveAttrFlag = {}
end

-------------------------------------------------------------------------------
--节点定义
-------------------------------------------------------------------------------
function CObject:SetOwner(obj)
end

--查询父节点
function CObject:GetParent()
	
end

--查询子节点
function CObject:GetChild()

end




-------------------------------------------------------------------------------
--属性定制
-------------------------------------------------------------------------------
function CObject:GetSaveData()
	return self.__SaveAttr
end

--检查是否需要存盘
function CObject:CheckSave()
	return next(self.__SaveAttrFlag) and true or false
end

function CObject:ClearSave()
	self.__SaveAttrFlag = {}
end

--注册临时属性
function CObject:RegTempAttr(key)
	if not self.__TempAttr then
		self.__TempAttr = {}
	end
	self["Get"..key] = function (self)
		local val = self.__TempAttr[key]
		if val then return val end
		local name = "__Counter_"..key
		if not self[name] then return end
		val = self[name](self)
		self["Set"..key](self, val)
		return val
	end
	self["Set"..key] = function (self, value, noclean)
		self.__TempAttr[key] = value
		self:OnEvent("AttrChange", {Name=key})
		if NoClean then return end
		if not self.__AttrRelation then return end
		local list = self.__AttrRelation[key]
		if not list then return end
		for k, _ in pairs(list) do
			self.__TempAttr[k] = nil
			self:OnEvent("AttrChange", {Name=k})
		end
	end
end

--注册存盘属性
function CObject:RegSaveAttr(key)
	if not self.__SaveAttr then
		self.__SaveAttr = {}
	end
	if not self.__SaveAttrFlag then
		self.__SaveAttrFlag = {}
	end
	self["Get"..key] = function (self)
		local val = self.__SaveAttr[key]
		if val then return val end
		local name = "__Counter_"..key
		if not self[name] then return end
		val = self[name](self)
		self["Set"..key](self, val)
		return val
	end
	self["Set"..key] = function (self, value, noclean)
		self.__SaveAttr[key] = value
		self.__SaveAttrFlag[key] = true
		self:OnEvent("AttrChange", {Name=key})
		if noclean then return end
		if not self.__AttrRelation then return end
		local list = self.__AttrRelation[key]
		if not list then return end
		for k, _ in pairs(list) do
			self.__SaveAttr[k] = nil
			self:OnEvent("AttrChange", {Name=k})
		end
	end
end

--批量设置属性
function CObject:SetAttrs(tbl)
	if not tbl then return end
	local func
	for k, v in pairs(tbl) do
		func = self["Set" .. k]
		if func then
			func(self, v)
		end
	end
end

--根据配置初始化属性
function CObject:InitAttribute(config)
	--存盘属性
	if config.Save then
		for k, v in pairs(config.Save) do
			self:RegSaveAttr(k, v.InitValue)
			if v.Formula then
				local Func, Err = load(v.Formula)()
				assert(Func, "存盘属性公式加载错误:"..tostring(k).."="..tostring(v.Formula))
				self["__Counter_"..k] = Func
			end
		end
	end
	
	--临时属性
	if config.Temp then
		for k, v in pairs(config.Temp) do
			self:RegTempAttr(k, v.InitValue)
			if v.Formula then
				local Func, Err = load(v.Formula)()
				assert(Func, "临时属性公式加载错误:"..tostring(k).."="..tostring(v.Formula))
				self["__Counter_"..k] = Func
			end
		end
	end
	
	--属性关联
	self.__AttrRelation = config.Relation
	
	--属性算子
	if config.Counter then
		self:InitCounter(config.Counter)
	end
end


-------------------------------------------------------------------------------
--属性算子
-------------------------------------------------------------------------------
--[[初始化算子
config格式：
{
	["AddMaxHp"] = {
		["Name"] = "AddMaxHp",
		["Desc"]="最大生命增加",
		["Formula"] = "return function(self,Args) return self:GetMaxHpDelta()+Args[1] end",
		["Pri"] = 1, --优先级
		["Attr"] = "MaxHpDelta", --关联的属性
	},
}
]]
function CObject:InitCounter(config)
	if not config then return end
	self.__CounterInfo = config
	for Name, Info in pairs(self.__CounterInfo) do
		local Func, Err = load(Info.Formula)()
		assert(Func, "属性算子公式加载错误:"..tostring(Name).."="..tostring(Info.Formula))
		self["__Counter_"..Name] = Func
	end
	self.__CounterID = 0
	self.__CounterMap = {}
	self.__CounterSubMap = {}
	self.__CounterGroupMap = {}
	self.__CounterDisableMap = {}
end

function CObject:AllocCounterID()
	self.__CounterID = (self.__CounterID or 0) + 1
	return self.__CounterID
end

function CObject:DelCounter(counter, noclean)
	if not self.__CounterInfo then return end
	local info = self.__CounterInfo[counter.Name]
	assert(info, "cannot found counter info:"..tostring(counter.Name))
	local id = counter.ID
	local attr = info.Attr
	local BaseVar = self["Get"..attr](self)
	self["Set"..attr](self, BaseVar - counter.Change, noclean)
	self.__CounterMap[id] = nil
	self.__CounterSubMap[attr][id] = nil
end

function CObject:RunCounters(Name, List, NoClean)
	if not self.__CounterInfo then return end
	local Var = self["Get"..Name](self)
	for _, Counter in ipairs(List) do
		Var = Var + Counter.Change
		self.__CounterMap[Counter.Id] = Counter
		self.__CounterSubMap[Name] = self.__CounterSubMap[Name] or {}
		self.__CounterSubMap[Name][Counter.Id] = Counter
	end
	self["Set"..Name](self, Var, NoClean)
end

function CObject:FlushCounter(Name, CounterPri, CounterList)
	if not self.__CounterInfo then return end
	local IntVal,FracVal = math.modf(CounterPri)
	local Index = #CounterList
	for CounterId, Counter in pairs(self.__CounterSubMap[Name] or {}) do
		if (FracVal == 0 and Counter.Pri > CounterPri) or
			(FracVal > 0 and Counter.Pri >= CounterPri) then
			self:DelCounter(Counter, true)
			Counter.Change = 0
			Index = Index + 1
			CounterList[Index] = Counter
		end
	end
	table.sort(CounterList, function (x, y) return x.Pri < y.Pri end)
	local CacheList = {}
	local CurPri = CounterPri
	IntVal,FracVal = math.modf(CurPri)
	local BaseVar = self["Get"..Name](self)
	Index = 0
	for _, Counter in ipairs(CounterList) do
		if Counter.Pri ~= CurPri or FracVal > 0 then
			self:RunCounters(Name, CacheList, true)
			CacheList = {}
			Index = 0
			CurPri = Counter.Pri
			IntVal,FracVal = math.modf(CurPri)
			BaseVar = self["Get"..Name](self)
		end
		Counter.Change = self["__Counter_"..Counter.Name](self, Counter.Var) - BaseVar
		Index = Index + 1
		CacheList[Index] = Counter
	end
	self:RunCounters(Name, CacheList)
	self:OnEvent("CounterChange", {Name=Name})
end

function CObject:ClearCounter()
	if not self.__CounterInfo then return end
	for _, counter in pairs(self.__CounterMap) do
		self:DelCounter(counter)
	end
	self.__CounterMap = {}
	self.__CounterSubMap = {}
	return true
end

function CObject:AddCounter(name, ...)
	if not self.__CounterInfo then return end
	local info = self.__CounterInfo[name]
	assert(info, "cannot found counter info:"..tostring(name))
	local id = self:AllocCounterID()
	local counter = {Id = id, Name = name, Var = {...}, Change = 0, Pri = info.Pri,}
	self:FlushCounter(info.Attr, counter.Pri, {counter})
	return id
end

function CObject:DelCounter(id)
	if not self.__CounterInfo then return end
	local counter = self.__CounterMap[id]
	if not counter then return end
	local info = self.__CounterInfo[counter.Name]
	assert(info, "cannot found counter info:"..tostring(counter.Name))
	self:DelCounter(counter)
	self:FlushCounter(info.Attr, counter.Pri, {})
	return true
end

function CObject:AddCounterGroup(name, list)
	if not self.__CounterInfo then return end
	if self.__CounterDisableMap[name] then
		self.__CounterDisableMap[name] = list
		return true
	end
	self:DelCounterGroup(name)
	local CounterList = {}
	for k, v in ipairs(list) do
		CounterList[k] = self:AddCounter(table.unpack(v))
	end
	self.__CounterGroupMap[name] = CounterList
	return true
end

function CObject:DelCounterGroup(name, notCleanDisable)
	if not self.__CounterInfo then return end
	if not notCleanDisable and self.__CounterDisableMap[name] then
		self.__CounterDisableMap[name] = nil
		return
	end
	if not self.__CounterGroupMap[name] then return end
	for _, id in pairs(self.__CounterGroupMap[name]) do
		self:DelCounter(id)
	end
	self.__CounterGroupMap[name] = nil
	return true
end

function CObject:DisableCounterByGroups(names)
	if not self.__CounterInfo then return end
	local Counter
	local Index
	for _, v in ipairs(names) do
		local CounterList = self.__CounterGroupMap[v]
		local DisableCounters = self.__CounterDisableMap[v] or {}
		Index = #DisableCounters
		if CounterList then
			for _, Id in ipairs(CounterList) do
				Counter = self.__CounterMap[Id]
				Index = Index + 1
				DisableCounters[Index] = {Counter.Name,table.unpack(Counter.Var)}
			end
		end
		self.__CounterDisableMap[v] = DisableCounters
		self:DelCounterGroup(v, true)
	end
end

function CObject:EnableCounterByGroups(names)
	if not self.__CounterInfo then return end
	local InfoList
	for _, GroupName in ipairs(names) do
		if self.__CounterDisableMap[GroupName] then
			InfoList = {}
			for k, CountInfo in ipairs(self.__CounterDisableMap[GroupName]) do
				InfoList[k] = CountInfo
			end
			self.__CounterDisableMap[GroupName] = nil
			self:AddCounterGroup(GroupName, InfoList)
		end
	end
end

function CObject:EnableAllDisableCounter()
	if not self.__CounterInfo then return end
	local names = {}
	local Index = 0
	for GroupName, _ in pairs(self.__CounterDisableMap) do
		Index = Index + 1
		names[Index] = GroupName
	end
	if Index == 0 then return end
	self:EnableCounterByGroups(names)
end

function CObject:GetCounterDesc(id)
	if not self.__CounterInfo then return end
	local counter = self.__CounterMap[id]
	if not counter then return end
	if not counter.Desc then
		local info = self.__CounterInfo[counter.Name]
		assert(info, "cannot found counter info:"..tostring(counter.Name))
		counter.Desc = string.format(info.Desc, table.unpack(counter.Var))
	end
	return counter.Desc
end

function CObject:GetCounterGroupDesc(GroupName)
	if not self.__CounterInfo then return end
	if not self.__CounterGroupMap[GroupName] then return end
	local DescList = {}
	for Idx, CounterId in pairs(self.__CounterGroupMap[GroupName]) do
		DescList[Idx] = self:GetCounterDesc(CounterId)
	end
	return DescList
end


-------------------------------------------------------------------------------
--事件机制
-------------------------------------------------------------------------------
function CObject:OnceEvent(name, callback)
	return self:AddEvent(name, callback, true)
end

function CObject:AddEvent(name, callback, onceflag)
	local events = rawget(self, "__Events")
	if not events then
		events = {}
		rawset(self, "__Events", events)
	end
	local list = rawget(events, name)
	if not list then
		list = {}
		rawset(events, name, list)
	end
	if list[callback] then return end
	local idx = #list + 1
	list[callback] = 1
	list[idx] = {callback = callback, flag = onceflag}
end

function CObject:AddEvents(events)
	for k, v in pairs(events) do
		if type(v) == "table" then
			self:AddEvent(k, v.callback, v.onceflag)
		else
			self:AddEvent(k, v)
		end
	end
end

function CObject:DelEvent(name, callback)
	local events = rawget(self, "__Events")
	if not events then return end
	local list = rawget(events, name)
	if not list then return end
	local idx = list[callback]
	if not idx then return end
	list[callback] = nil
	table.remove(list[idx])
end

function CObject:DelAllEvent(name)
	local events = rawget(self, "__Events")
	if not events then return end
	if name then
		local list = rawget(events, name)
		if not list then return end
		rawset(events, name, nil)
	else
		rawset(self, "__Events", nil)
	end
end

function CObject:OnEvent(name, ...)
	self:NextTick("DispatchEvent", name, ...)
end

function CObject:DispatchEvent(name, ...)
	local events = rawget(self, "__Events")
	if not events then return end
	local list = rawget(events, name)
	if not list then return end
	local info
	for i = #list, 1, -1 do
		info = list[i]
		if info.flag then
			table.remove(list, i)
			list[info.callback] = nil
		end
		if type(info.callback) == "function" then
			info.callback(name, ...)
		elseif self[info.callback] then
			self[info.callback](self, name, ...)
		end
	end
end


-------------------------------------------------------------------------------
--定时器
-------------------------------------------------------------------------------
local timer = require("base/timer")
function CObject:AddTimer(delay, interval, func, ...)
	if not func or not self[func] then return end
	return timer:AddTimer(self, delay, interval, func, ...)
end

function CObject:DelTimer(func)
	return timer:DelTimerByName(self, func)
end

function CObject:HasTimer(func)
	return timer:HasTimer(self, func)
end

function CObject:DelTimerAll()
	return timer:DelAll(self)
end

function CObject:NextTick(func, ...)
	if not func or not self[func] then return end
	return timer:AddTimer(self, 0, 0, func, ...)
end
