
--[[
服务器配置：
{
	id : ,	--服务器编号，唯一标识
	path : "./",			--工作路径
	net : {"127.0.0.1", 12345},	--前端链接socket
	log : {path:"log/xxx", level=},	--日志
	rpc : {port:},	--rpc端口
	db : {ip:, port:}, --数据库服务器
}
每个进程最多只允许存在一个服务器实例
]]

local log = require("base/log")
local setting = require("base/setting")
local redis = require("base/redis")
local tcp = require("base/tcp")

function Init(self, id)
	--工作目录
	uv.chdir("./")
	--日志
	log:Init("log")
	--配置中心
	setting:Init("setting", function()
		self:InitStart(id)
	end)
end

function InitStart(self, id)
	local config = setting:Query("server", id)
	self.m_ServerID = config.ID
	self.m_Name = config.Name
	self.m_Platform = config.Platform
	self.m_Version = config.Version
	engine.set("serverid", self.m_ServerID)
	engine.set("servername", self.m_Name)
	engine.set("serverplatform", self.m_Platform)
	engine.set("serverversion", self.m_Version)

	--网络
	if config.Net then
		net.Init({isserver=true, tocsharp=false, monitor=true})
		self.m_NetNode = tcp.CTcpServer:New(config.Net.port, config.Net.ip)
		self.m_NetNode:AddEvents({
			accept = function(name, vfd)
				print("new client:", vfd)
				self.m_NetNode:OnEvent("netaccept", vfd)
			end,
			recv = function(name, vfd, data)
				net.UnpackBody(vfd, data)
			end,
			close = function(name, vfd)
				print("close client:", vfd)
				self.m_NetNode:OnEvent("netclose", vfd)
			end,
		})
		self.m_NetNode:SetPackageParser(function(data)
			if not data or not data.meta then return end
			local start, stop = net.UnpackHead(data.meta)
			if not start then return end
			data.pak = data.meta:sub(start, stop)
			data.meta = data.meta:sub(stop)
			return true
		end)
	end
	--RPC，暂时用socket
	if config.Rpc then
		self.m_RpcNode = tcp.CTcpServer:New(config.Rpc.port, config.Rpc.ip)
		self.m_RpcNode:AddEvents({
			accept = function(name,vfd)
				self.m_RpcNode:OnEvent("rpcaccept", vfd)
			end,
			recv = function(name, vfd, data)
				self.m_RpcNode:OnEvent("rpcrecv", vfd, data)
			end,
			close = function(name, vfd)
				self.m_RpcNode:OnEvent("rpcclose", vfd)
			end,
		})
	end
	--redis
	if config.Redis then
		self.m_RedisNode = redis.CRedis:New(config.Redis)
	end
	self.m_InitFlag = true
end

function GetNetNode(self)
	return self.m_NetNode
end

function GetRpcNode(self)
	return self.m_RpcNode
end

function GetRedis(self)
	return self.m_RedisNode
end

--服务器启动
function Run(self)
	if self.m_RpcNode then
		self.m_RpcNode:Start()
		log:Info("rpc listen at %s", self.m_RpcNode:GetAddressString())
	end
	if self.m_NetNode then
		self.m_NetNode:Start()
		log:Info("net listen at %s", self.m_NetNode:GetAddressString())
	end
	if self.m_RedisNode then
		self.m_RedisNode:Start()
	end
	engine.start()
end

function Stop(self)
	if self.m_NetNode then
		self.m_NetNode:Stop()
	end
	if self.m_RpcNode then
		self.m_RpcNode:Stop()
	end
	if self.m_RedisNode then
		self.m_RedisNode:Stop()
	end
end

function Send2Net(self, vfds)
	if not vfds then return end
	local t = type(vfds)
	if t == "table" then
		if not next(t) then return end
	elseif t ~= "number" then
		return
	end
	local list = net.Pack(vfds)
	if not list then return end
	if t == "table" then
		for vfd, data in pairs(list) do
			self.m_NetNode:Send(vfd, data)
		end
	else
		self.m_NetNode:Send(vfds, list)
	end
end

function Send2Rpc(self, vfd)
	if not vfd then return end
	local data = net.PackSimple()
	if not data then return end
	self.m_RpcNode:Send(vfd, data)
end

--主动断开链接
function NetClose(self, vfd)
	self.m_NetNode:CloseClient(vfd)
end

function RpcClose(self, vfd)
	self.m_RpcNode:CloseClient(vfd)
end


net.Send2Client = function(vfds)
	require("base/server"):Send2Net(vfds)
end

net.Send2Rpc = function(vfd)
	require("base/server"):Send2Rpc(vfd)
end
