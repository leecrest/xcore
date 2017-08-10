--网络协议监听器
--每10分钟打印一次数据
--数据格式：分上下行
--总流量、总协议数、总链接数
--按照单个协议的流量从大到小排列
--协议名称、次数、总流量、平均流量、单包最大值、单包最小值

local log = require("base/log.lua")
local timer = require("base/timer.lua")

--
function __init__(self)
	self.m_State = false
end

function __destroy__(self)
	self:TimerDump()
	timer:DelAll(self)
end

--接收协议包
function OnRecvProtocol(self, ptoid, ptoname, ptolen)
	if not self.m_State then return end
	if not self.m_UpData then
		self.m_UpData = {Count=0, Size=0, List={}}
	end
	self.m_UpData.Count = self.m_UpData.Count + 1
	self.m_UpData.Size = self.m_UpData.Size + ptolen
	local list = self.m_UpData.List[ptoid]
	if not list then
		list = {Name=ptoname, Count=1, Size=ptolen, Max=ptolen, Min=ptolen}
		self.m_UpData.List[ptoid] = list
	else
		list.Count = list.Count + 1
		list.Size = list.Size + ptolen
		if ptolen > list.Max then
			list.Max = ptolen
		elseif ptolen < list.Min then
			list.Min = ptolen
		end
	end
end

--发送协议包
function OnSendProtocol(self, ptoid, ptolen, count)
	if not self.m_State then return end
	local ptoHandle = (net.IsServer and net.NetS2C[ptoid] or net.NetC2S[ptoid])
	if not ptoHandle then return end
	count = count or 1
	if not self.m_DownData then
		self.m_DownData = {Count=0, Size=0, List={}}
	end
	self.m_DownData.Count = self.m_DownData.Count + count
	self.m_DownData.Size = self.m_DownData.Size + ptolen
	local list = self.m_DownData.List[ptoid]
	if not list then
		list = {Name=ptoHandle.name, Count=count, Size=ptolen, Max=ptolen, Min=ptolen}
		self.m_DownData.List[ptoid] = list
	else
		list.Count = list.Count + count
		list.Size = list.Size + ptolen
		if ptolen > list.Max then
			list.Max = ptolen
		elseif ptolen < list.Min then
			list.Min = ptolen
		end
	end
end

function Dump(self, Data)
	log:Log("netmonitor.txt", "TotalSize=%d, TotalCount=%d", Data.Size, Data.Count)
	local list = {}
	local idx = 0
	for k, v in pairs(Data.List) do
		idx = idx + 1
		list[idx] = v
	end
	table.sort(list, function(x, y) 
		if x.Size ~= y.Size then return x.Size > y.Size end
		return x.Count > y.Count
	end)
	for k, v in ipairs(list) do
		log:Log("netmonitor.txt", "%-25s%d\t%d\t%0.2f\t%d\t%d", v.Name, v.Count, v.Size, v.Size/v.Count, v.Max, v.Min)
	end
	Data.Count = 0
	Data.Size = 0
	Data.List = {}
end

function TimerDump(self)
	if self.m_UpData and self.m_UpData.Count > 0 then
		log:Log("netmonitor.txt", "==========[Upload]==========")
		self:Dump(self.m_UpData)
	end
	if self.m_DownData and self.m_DownData.Count > 0 then
		log:Log("netmonitor.txt", "==========[Download]==========")
		self:Dump(self.m_DownData)
		log:Log("netmonitor.txt", " ")
	end
end

--启动监听
function Init(self)
	self.m_State = true
	timer:AddTimer(self, 10*60*1000, 10*60*1000, "TimerDump")
end