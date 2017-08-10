
--[[
以下为协议包格式，可自行重定义

协议数据包的格式：
+----------+----------+
| size(2)  |    body  |
+----------+----------+
1.size	：2byte，body的长度
2.body	：协议的二进制内容
]]

local log = require("base/log.lua")
local monitor = require("base/net/monitor.lua")

local PACKET_SIZE_MIN	= 2
local PACKET_SIZE_MAX	= 2 ^ (2 * 8)

--解包前的分析，从数据流中获取到一个完整的数据包
function net.UnpackHead(pkg)
	local len = string.len(pkg)
	if len < PACKET_SIZE_MIN then return end
	--解析包头数据
	local bodysize, bodystart = string.unpack("H", pkg)
	if bodystart + bodysize - 1 > len then
		return
	end
	return bodystart, bodystart+bodysize
end

--协议解包
function net.UnpackBody(vfd, str)
	local len = string.len(str)
	--解析协议头
	net.ReadBegin(str)
	local ptoID = net.ReadUint16()
	local ptoHandle = (net.IsServer and net.NetC2S[ptoID] or net.NetS2C[ptoID])
	if not ptoHandle then
		log:Error("protocol(%d) not supported", ptoID)
		return
	end
	if net.monitor then
		monitor:OnRecvProtocol(ptoID, ptoHandle.name, len)
	end
	local data = ptoHandle.reader()
	local func = net[ptoHandle.name]
	--log:Debug("[Protocol]%s,%s", ptoHandle.name, type(data)=="table" and table.tostring(data) or data)
	if not func then
		if net.DefaultHandle then
			return net.DefaultHandle(vfd, ptoHandle.name, table.unpack(data))
		end
		log:Error("Protocol(%s) no handler", ptoHandle.name)
		return
	end
	func(vfd, table.unpack(data))
end


--协议打包，暂时不加密
function net.Pack(vfds)
	assert(vfds, "vfds is nil!")
	if not net.WriteData then return end
	local data = net.WriteData
	if not data.Data or data.Len <= 0 then return end
	--协议包
	local out = string.pack("H", data.Pto)..table.concat(data.Data)
	net.WriteEnd()
	if type(vfds) == "table" then
		local pkg, pak
		local Result = {}
		local size = 0
		for _, vfd in ipairs(vfds) do
			pak = string.pack("H", string.len(pkg))..pkg
			size = size + string.len(pak)
			Result[vfd] = pak
		end
		if net.monitor then
			monitor:OnSendProtocol(data.Pto, size, #vfds)
		end
		return Result
	else
		local pak = string.pack("H", string.len(out))..out
		if net.monitor then
			monitor:OnSendProtocol(data.Pto, string.len(pak))
		end
		return pak
	end
end

--明文打包
function net.PackSimple()
	if not net.WriteData then return end
	local data = net.WriteData
	if not data.Data or data.Len <= 0 then return end
	--协议包
	local out = string.pack("H", data.Pto) .. table.concat(data.Data)
	net.WriteEnd()
	local pak = string.pack("H", string.len(out)) .. out
	if net.monitor then
		monitor:OnSendProtocol(data.Pto, string.len(pak))
	end
	return pak
end
