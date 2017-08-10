
_G.net = _G.net or {}
local net = _G.net
net.NetType = net.NetType or {}
net.Name2ID = {}
net.NetC2S = {}
net.NetS2C = {}

--服务端标记
net.IsServer = true

--基础数据类型
net.DATA_TYPE = {
	["string"] = true, 
	["int8"] = true,
	["int16"] = true, 
	["int32"] = true, 
	["int64"] = true,
	["uint8"] = true, 
	["uint16"] = true, 
	["uint32"] = true, 
	["uint64"] = true,
	["float"] = true,
	["double"] = true,
	["number"] = true,
}
--基础类型的别名转换表
net.TYPE_NAME_TRANS = {
	["str"] = "string",
	["byte"] = "uint8",
	["int"] = "int32",
	["long"] = "int64",
	["uint"] = "uint32",
	["ulong"] = "uint64",
	["word"] = "uint8",
}

--导出转换
net.TYPE_EXPORT_LUA = {
	["string"] = "String", 
	["int8"] = "Int8", ["int16"] = "Int16", ["int32"] = "Int32", ["int64"] = "Int64",
	["uint8"] = "Uint8", ["uint16"] = "Uint16", ["uint32"] = "Uint32", ["uint64"] = "Uint64",
	["float"] = "Float", ["double"] = "Double", ["number"] = "Number",
}

--二进制流读写接口
function net.ReadBegin(str)
	if not net.ReadData then net.ReadData = {} end
	net.ReadData.Data = str
	net.ReadData.Pos = 1
	net.ReadData.Len = string.len(str)
end

function net.ReadEnd()
	net.ReadData = nil
end

--通用变长number
local function ReadNumberCore(data)
	local size, len = string.unpack("B", data.Data, data.Pos)
	data.Pos = len
	local negative = size & 0x1
	size = size >> 1
	if size == 1 then
		ret = string.unpack("B", data.Data, data.Pos)
	elseif size == 2 then
		ret = string.unpack("H", data.Data, data.Pos)
	elseif size == 3 then
		ret = string.byte(data.Data, len)
		ret = ret | (string.byte(data.Data, len+1) << 8)
		ret = ret | (string.byte(data.Data, len+2) << 16)
	else
		ret = string.unpack("I", data.Data, data.Pos)
	end
	data.Pos = len + size
	if negative ~= 0 then ret = -ret end
	return ret
end

local function ReadNumber(name, isarray)
	local data = net.ReadData
	if not data then return end
	local count = 1
	local len
	if isarray then
		if data.Pos + 1 > data.Len then return end
		count, len = string.unpack("B", data.Data, data.Pos)
		data.Pos = len
	end
	if not count then return end
	if data.Pos + count * 2 > data.Len then return end
	local size, ret
	if count == 1 then
		return ReadNumberCore(data)
	else
		ret = {}
		for i = 1, count do
			ret[i] = ReadNumberCore(data)
		end
		return ret
	end
end

local function ReadPtoNumber(name, _type, size, isarray)
	local data = net.ReadData
	if not data then return end
	local count = 1
	local len
	if isarray then
		if data.Pos + 1 > data.Len then return end
		count, len = string.unpack("B", data.Data, data.Pos)
		data.Pos = len
	end
	if not count then return end
	--data.Pos是从1开始的，所以要+1
	if data.Pos + count * size > data.Len + 1 then return end
	local ret
	if count == 1 then
		ret, len = string.unpack(_type, data.Data, data.Pos)
		data.Pos = len
	else
		ret = {}
		local val
		for i = 1, count do
			ret[i], len = string.unpack(_type, data.Data, data.Pos)
			data.Pos = len
		end
	end
	return ret
end

--当字符串长度小于255时，用1字节表示长度
--当字符串长度超出255时，第1字节填0，后2字节表示长度
--并且字符串长度=实际长度+1
local function ReadPtoString(name, isarray)
	local data = net.ReadData
	if not data then return end
	local count = 1
	local len
	if isarray then
		if data.Pos + 1 > data.Len then return end
		count, len = string.unpack("B", data.Data, data.Pos)
		data.Pos = len
	end
	if not count then return end
	if data.Pos + count * 2 > data.Len then return end
	local size, ret
	if count == 1 then
		size, len = string.unpack("B", data.Data, data.Pos)
		if size <= 0 then
			size, len = string.unpack("H", data.Data, len)
		end
		size = size - 1
		ret = string.sub(data.Data, len, size+len-1)
		data.Pos = len + size
	else
		ret = {}
		for i = 1, count do
			if data.Pos + 1 > data.Len then return end
			size, len = string.unpack("B", data.Data, data.Pos)
			if size <= 0 then
				size, len = string.unpack("H", data.Data, len)
			end
			size = size - 1
			ret[i] = string.sub(data.Data, len, size+len-1)
			data.Pos = size + len
		end
	end
	return ret
end

function net.ReadByte(name, isarray)	return ReadPtoNumber(name, "B", 1, isarray) end
function net.ReadUint8(name, isarray)	return ReadPtoNumber(name, "B", 1, isarray) end
function net.ReadUint16(name, isarray)	return ReadPtoNumber(name, "H", 2, isarray) end
function net.ReadUint32(name, isarray)	return ReadPtoNumber(name, "I", 4, isarray) end
function net.ReadUint64(name, isarray)	return ReadPtoNumber(name, "J", 8, isarray) end
function net.ReadInt8(name, isarray)	return ReadPtoNumber(name, "b", 1, isarray) end
function net.ReadInt16(name, isarray)	return ReadPtoNumber(name, "h", 2, isarray) end
function net.ReadInt32(name, isarray)	return ReadPtoNumber(name, "i", 4, isarray) end
function net.ReadInt64(name, isarray)	return ReadPtoNumber(name, "j", 8, isarray) end
function net.ReadFloat(name, isarray)	return ReadPtoNumber(name, "f", 4, isarray) end
function net.ReadDouble(name, isarray)	return ReadPtoNumber(name, "d", 8, isarray) end
function net.ReadString(name, isarray)	return ReadPtoString(name, isarray) end
function net.ReadNumber(name, isarray)	return ReadNumber(name, isarray) end

function net.WriteBegin(ptoid)
	if not net.WriteData then net.WriteData = {} end
	net.WriteData.Pto = ptoid
	net.WriteData.Data = {}
	net.WriteData.Len = 0
	net.WriteData.Pos = 0
end

function net.WriteEnd()
	net.WriteData = nil
end

local function WritePtoNumber(name, _type, size, value)
	local data = net.WriteData
	if type(value) == "table" then
		local len = #value
		assert(len <= 255, "array is toooooooooooooo large!")
		data.Pos = data.Pos + 1
		data.Data[data.Pos] = string.pack("B", len)
		data.Len = data.Len + 1
		for _, v in ipairs(value) do
			data.Pos = data.Pos + 1
			data.Data[data.Pos] = string.pack(_type, v)
			data.Len = data.Len + size
		end
	else
		--assert(value and type(value) == "number")
		data.Pos = data.Pos + 1
		data.Data[data.Pos] = string.pack(_type, value)
		data.Len = data.Len + size
	end
end

local function WriteNumberCore(data, value)
	local flag = 0
	if value < 0 then
		flag = 1
		value = -value
	end
	local size = 0
	if value <= 0xff then
		flag = (1 << 1) | flag
		data.Data[data.Pos+1] = string.pack("B", flag)
		data.Data[data.Pos+2] = string.pack("B", value)
		data.Pos = data.Pos + 2
		size = 2
	elseif value < 0xffff then
		data.Data[data.Pos+1] = string.pack("B", flag)
		data.Data[data.Pos+2] = string.pack("H", value)
		data.Pos = data.Pos + 2
		size = 3
	elseif value < 0xffffff then
		data.Data[data.Pos+1] = string.pack("B", flag)
		data.Data[data.Pos+2] = string.pack("B", (value & 0xff))
		data.Data[data.Pos+3] = string.pack("B", (value >> 8) & 0xff)
		data.Data[data.Pos+4] = string.pack("B", (value >> 16) & 0xff)
		data.Pos = data.Pos + 4
		size = 4
	else
		data.Data[data.Pos+1] = string.pack("B", flag)
		data.Data[data.Pos+2] = string.pack("I", value)
		data.Pos = data.Pos + 2
		size = 5
	end
	data.Len = data.Len + size
end

local function WriteNumber(name, value)
	local data = net.WriteData
	local size, negative, len, _type
	if type(value) == "table" then
		len = #value
		assert(len <= 255, "array is toooooooooooooo large!")
		data.Pos = data.Pos + 1
		data.Data[data.Pos] = string.pack("B", len)
		data.Len = data.Len + 1
		for _, v in ipairs(value) do
			WriteNumberCore(data, v)
		end
	else
		WriteNumberCore(data, value)
	end
end

local function WritePtoString(name, value)
	local data = net.WriteData
	local size
	if type(value) == "table" then
		local len = #value
		assert(len <= 255, "array is toooooooooooooo large!")
		data.Pos = data.Pos + 1
		data.Data[data.Pos] = string.pack("B", len)
		data.Len = data.Len + 1
		for _, v in ipairs(value) do
			size = string.len(v) + 1
			if size <= 0xff then
				data.Data[data.Pos+1] = string.pack("B", size)
				data.Data[data.Pos+2] = v
				data.Pos = data.Pos + 2
				data.Len = data.Len + size + 1
			else
				data.Data[data.Pos+1] = string.pack("B", 0)
				data.Data[data.Pos+2] = string.pack("H", size)
				data.Data[data.Pos+3] = v
				data.Pos = data.Pos + 3
				data.Len = data.Len + size + 3
			end
		end
	else
		size = string.len(value) + 1
		if size <= 0xff then
			data.Data[data.Pos+1] = string.pack("B", size)
			data.Data[data.Pos+2] = v
			data.Pos = data.Pos + 2
			data.Len = data.Len + size + 1
		else
			data.Data[data.Pos+1] = string.pack("B", 0)
			data.Data[data.Pos+2] = string.pack("H", size)
			data.Data[data.Pos+3] = v
			data.Pos = data.Pos + 3
			data.Len = data.Len + size + 3
		end
	end
end

function net.WriteByte(name, value)		return WritePtoNumber(name, "B", 1, value) end
function net.WriteUint8(name, value)	return WritePtoNumber(name, "B", 1, value) end
function net.WriteUint16(name, value)	return WritePtoNumber(name, "H", 2, value) end
function net.WriteUint32(name, value)	return WritePtoNumber(name, "I", 4, value) end
function net.WriteUint64(name, value)	return WritePtoNumber(name, "J", 8, value) end
function net.WriteInt8(name, value)		return WritePtoNumber(name, "b", 1, value) end
function net.WriteInt16(name, value)	return WritePtoNumber(name, "h", 2, value) end
function net.WriteInt32(name, value)	return WritePtoNumber(name, "i", 4, value) end
function net.WriteInt64(name, value)	return WritePtoNumber(name, "j", 8, value) end
function net.WriteFloat(name, value)	return WritePtoNumber(name, "f", 4, value) end
function net.WriteDouble(name, value)	return WritePtoNumber(name, "d", 8, value) end
function net.WriteString(name, value)	return WritePtoString(name, value) end
function net.WriteNumber(name, value)	return WriteNumber(name, value) end

--设置默认的协议处理函数
function net.SetDefaultHandle(func)
	assert(func and type(func) == "function")
	net.DefaultHandle = func
end

--服务端专用，将当前打包的协议发送给指定客户端
function net.Send2Client(vfds)
	assert(nil, "请重写此函数 net.Send2Client")
end

--客户端专用，将当前打包的协议发送给指定服务端
function net.Send2Server(vfd)

end

--网络协议初始化
function net.Init(cfg)
	cfg = cfg or {}
	net.IsServer = cfg.isserver
	
	--加载协议文件
	local log = require("base/log.lua")
	local reader = require("base/net/reader.lua")
	reader.Init(cfg)

	--导出客户端协议文件
	if cfg.tocsharp and net.IsServer then
		require("base/net/tocsharp.lua").Export(net)
	end

	--导出服务端协议文件
	require("base/net/tolua.lua").Export(cfg.isserver)
	
	--加载解包函数
	require("base/net/pack.lua")
	
	if cfg.monitor then
		net.monitor = true
		require("base/net/monitor.lua"):Init()
	end
end
