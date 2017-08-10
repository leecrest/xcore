--redis
local class = require("base/class")
local tcp = require("base/tcp")
local log = require("base/log")

-------------------------------------------------------------------------------
--CCRedis，封装redis客户端操作
-------------------------------------------------------------------------------
local TIMEOUT = 60*1000 --数据读写链接超时

CRedis = Inherit("CObject", "CRedis")

function CRedis:Create(config)
	config = config or {}
	self.m_Config = {}
	self.m_Config.port = config.port or 6379
	self.m_Config.ip = config.ip or "127.0.0.1"
	self.m_Config.db = config.db or 1
	self.m_Client = tcp.TcpClient:New(self.m_Config.port, self.m_Config.ip)
	self.m_LockList = {}	--指令锁，完全同样的指令同一时间将只执行一次
	self.m_SendList = {}	--指令发送队列
	self.m_Inited = false
end

function CRedis:Start()
	self.m_Client:AddEvents({
		connect = function(...)
			log:Info("connect to redis-server success!")
			self:Exec({"SELECT", self.m_Config.db}, function()
				self.m_Inited = true
				log:Info("[redis]select redis-db:%d", self.m_Config.db)
				if self.m_InitFuncs then
					for k, v in pairs(self.m_InitFuncs) do
						self:Send(v[1], k, v[2])
					end
					self.m_InitFuncs = nil
				end
				self:OnEvent("inited")
			end, true)
		end,
		recv = function(name, data)
			self:Recv(data.ret, data.data)
		end,
		close = function(...)
			log:Info("redis-server close!")
			self.m_Inited = false
			self:OnEvent("close")
		end,
		error = function(...)
			log:Error("redis-server error, reconnect")
			self.m_Inited = false
			self:OnEvent("error")
			if not self.m_Client:IsConnected() then
				log:Info("reconnect to redis-server")
				self.m_Client:ReStart()
			end
		end,
	})
	--设置处理粘包的函数
	self.m_Client:SetPackageParser(function(data)
		if not data or not data.meta then
			return
		end
		local maxpos = data.meta:len()
		if maxpos <= 0 then return end
		maxpos = maxpos + 1

		--每个完整的数据包分为3大部分：
		--标识：flag(+\-\:$\*)、头部(描述\整数\包体数量)、包体(空\数据)
		local pak = data.left
		if not pak then
			pak = {}
			data.left = pak
		end
		local line
		local curpos = 1
		local endpos
		if pak.flag == nil then
			pak.flag = data.meta:sub(1, 1)
			curpos = curpos + 1
		end
		if pak.head == nil then
			endpos = data.meta:find("\r\n", curpos)
			if not endpos then return end
			pak.head = data.meta:sub(curpos, endpos-1)
			curpos = endpos + 2
		end
		if pak.flag == "+" then
			--状态回复，格式：+OK\r\n
			data.pak = {ret=true, data=pak.head}
			data.left = nil
			data.meta = data.meta:sub(curpos)
			return true
		elseif pak.flag == "-" then
			--错误回复，格式：-ERRxxx\r\n
			data.pak = {ret=false, data=pak.head}
			data.left = nil
			data.meta = data.meta:sub(curpos)
			return true
		end
		pak.head = tonumber(pak.head)
		if pak.flag == ":" then
			--整数回复，格式：:1000\r\n
			data.pak = {ret=true, data=pak.head}
			data.left = nil
			data.meta = data.meta:sub(curpos)
			return true
		end
		if pak.flag == "$" then
			--批量回复，格式：$6\r\nfoobat\r\n
			if curpos + pak.head + 2 > maxpos then
				data.meta = data.meta:sub(curpos)
				return
			end
			data.pak = {ret=true, data=data.meta:sub(curpos, curpos+pak.head)}
			data.left = nil
			data.meta = data.meta:sub(curpos+pak.head+2)
			return true
		end
		if pak.flag == "*" then
			--多条批量回复，格式：*2\r\n$3\r\nfoo\r\n$3\r\nbar\r\n
			--数据长度 >= pak.head × 7
			if curpos + pak.head*7 > maxpos then
				data.meta = data.meta:sub(curpos)
				return
			end
			pak.body = pak.body or {}
			local full = true
			local size = 0
			local beginpos = curpos
			local idx = #pak.body
			for i = 1, pak.head do
				endpos = data.meta:find("\r\n", beginpos)
				if not endpos then 
					full = false
					break
				end
				size = tonumber(data.meta:sub(beginpos+1, endpos))
				endpos = endpos + 2
				if endpos + size + 2 > maxpos then
					full = false
					break
				end
				idx = idx + 1
				pak.body[idx] = data.meta:sub(endpos, endpos+size-1)
				curpos = endpos + size + 2
				beginpos = curpos
			end
			if not full then
				data.meta = data.meta:sub(curpos)
				return
			else
				data.pak = {ret=true, data=pak.body}
				data.left = nil
				data.meta = data.meta:sub(curpos)
				return true
			end
		end
	end)
	self.m_Client:Start()
	log:Info("start connect to redis-server %s:%s", self.m_Config.ip, self.m_Config.port)
end

--func格式：func(ret, data)
function CRedis:Exec(cmds, func, ignore)
	func = func or 0
	local msg = string.format("*%d\r\n", #cmds)
	local key
	for _, v in ipairs(cmds) do
		key = tostring(v)
		msg = msg .. string.format("$%d\r\n%s\r\n", string.len(key), key)
	end
	if (not ignore) and (not self.m_Inited) then
		if not self.m_InitFuncs then
			self.m_InitFuncs = {[msg] = {cmds[1], func}}
		else
			self.m_InitFuncs[msg] = {cmds[1], func}
		end
		return
	end
	self:Send(cmds[1], msg, func)
end

function CRedis:Send(cmd, msg, func)
	local lock = self.m_LockList[msg]
	if lock then
		if type(func) == "function" then
			lock.funcs[#lock.funcs+1] = func
		end
		return
	end
	lock = {cmd=cmd, time=os.time()}
	if type(func) == "function" then
		lock.funcs = {func}
	end
	self.m_LockList[msg] = lock
	self.m_SendList[#self.m_SendList+1] = msg
	self.m_Client:Send(msg)
	log:Debug("[redis]SendCmd:%s,%s", cmd, msg:gsub("\r\n","-"))
	if lock.funcs and not self:HasTimer("TimeOut") then
		self:AddTimer(TIMEOUT, 3000, "TimeOut")
	end
end

function CRedis:Recv(ret, data)
	local cmd = table.remove(self.m_SendList, 1)
	if not cmd then return end
	local info = self.m_LockList[cmd]
	if not info or not info.funcs then return end
	log:Debug("[redis]Recv:%s, ret=%s, data=%s", info.cmd, ret, data)
	self.m_LockList[cmd] = nil
	if table.size(self.m_LockList) == 0 and self:HasTimer("TimeOut") then
		self:DelTimer("TimeOut")
	end
	if not ret then
		log:Error("[redis][%s]recv error:%s", info.cmd, data)
	end
	if ret and info.cmd == "HGETALL" then
		local tbl = {}
		for i = 1, #data, 2 do
			tbl[data[i]] = data[i+1]
		end
		data = tbl
	end
	for _, func in ipairs(info.funcs) do
		if type(func) == "function" then
			func(ret, data)
		end
	end
end

--查询数据
function CRedis:Get(key, func)
	assert(key and func)
	return self:Exec({"GET",key}, func)
end

function CRedis:GetCo(co, key)
	assert(co and key)
	local data
	local NeedYield = true
	local Yielded = false
	local func = function(...)
		NeedYield = false
		data = {...}
		if Yielded then
			coroutine.resume(co)
		end
	end
	self:Get(key, func)
	if NeedYield then
		Yielded = true
		coroutine.yield(co)
	end
	return table.unpack(data)
end

--查询超时
function CRedis:TimeOut()
	local over = true
	local now = os.time()
	local List = {}
	for k, v in pairs(self.m_LockList) do
		if now - v.time >= TIMEOUT then
			self.m_LockList[k] = nil
			List[k] = v.funcs
		else
			over = false
		end
	end
	if over then
		self:DelTimer("TimeOut")
	end
	for k, v in pairs(List) do
		for _, func in ipairs(v) do
			func()
		end
	end
end

--得到查询结果
function CRedis:OnGet(key, data)
	local list = self.m_QueryList[key]
	if not list then return end
	self.m_QueryList[key] = nil
	if table.size(self.m_QueryList) == 0 then
		self:DelTimer("QueryTimeOut")
	end
	if list.FuncList then
		for _, func in ipairs(list.FuncList) do
			func(key, data)
		end
	end
end

--设置数据
function CRedis:Set(key, data)
	assert(key)
	return self:Exec({"SET",key,data})
end

function CRedis:HGetAll(name, func)
	return self:Exec({"HGETALL", name}, func)
end

function CRedis:HGet(name, key, func)
	assert(name and key and func)
	return self:Exec({"HGET", name, key}, func)
end

function CRedis:HSet(name, key, data)
	assert(name and key)
	return self:Exec({"HSET", name, key, data})
end
