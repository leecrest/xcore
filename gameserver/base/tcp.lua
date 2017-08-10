
-------------------------------------------------------------------------------
--TCP服务器
-------------------------------------------------------------------------------
local cls = require("base/class")

CTcpServer = cls.CObject:Inherit("CTcpServer")

function CTcpServer:Create(port, ip)
	self.m_Sock = uv.tcp_new()
	self.m_IP = ip or "127.0.0.1"
	self.m_Port = port
	self.m_Sock:bind(self.m_IP, self.m_Port)
	self.m_ClientVfd = 0
	self.m_ClientVfd2Obj = {}
	self.m_ClientObj2Vfd = {}
	self.m_ClientKey = {}
end

function CTcpServer:GetAddressString()
	return string.format("%s:%s", self.m_IP, self.m_Port)
end

function CTcpServer:Start()
	self.m_Sock:listen(128, function(err)
		self:Accept()
	end)
end

function CTcpServer:Stop()
	for _, v in pairs(self.m_ClientVfd2Obj) do
		v:close()
	end
	self.m_Sock:close()
	self.m_ClientVfd2Obj = nil
	self.m_ClientObj2Vfd = nil
	self.m_ClientKey = nil
end

function CTcpServer:Accept()
	local client = uv.tcp_new()
	self.m_ClientVfd = self.m_ClientVfd + 1
	local vfd = self.m_ClientVfd
	self.m_ClientObj2Vfd[client] = vfd
	self.m_ClientVfd2Obj[vfd] = client
	self.m_Sock:accept(client)
	self:SendKey(vfd, client)
	self:OnEvent("accept", vfd)
	
	client:read_start(function(err, data)
		if err then
			return self:OnClientLost(client)
		end
		if data then
			self:Recv(vfd, data)
		else
			self:OnClientLost(client)
		end
	end)
	return client
end

--设置包体分析函数
--函数声明：bool func({meta=, pak=})
--返回值：true/false，表示是否继续解析
--meta为源数据字符串，pak为解析完成的完整数据
--pak的格式由各玩法自行定义，一般是一个table
function CTcpServer:SetPackageParser(func)
	if not func then return end
	if type(func) ~= "function" then return end
	self.m_PackageParser = func
end

function CTcpServer:Recv(vfd, str)
	--对接收到的数据进行解密
	data = self:Decode(vfd, str)
	if not self.m_PackageParser then
		self:OnEvent("recv", vfd, data)
		return
	end
	--将数据合并入数据源中
	local pkg
	if not self.m_CacheData then
		pkg = {meta=data}
		self.m_CacheData = {[vfd] = pkg}
	else
		pkg = self.m_CacheData[vfd]
		if not pkg then
			pkg = {meta=data}
			self.m_CacheData[vfd] = pkg
		else
			pkg.meta = pkg.meta .. data
		end
	end
	--循环解析
	local flag, pak
	while true do
		pkg.pak = nil
		flag = self.m_PackageParser(pkg)
		pak = pkg.pak
		pkg.pak = nil
		if pak then
			self:OnEvent("recv", vfd, pak)
		end
		if not flag then break end
	end
end

function CTcpServer:Send(vfd, data)
	local client = self.m_ClientVfd2Obj[vfd]
	if not client then return end
	--data = self:Encode(vfd, data)
	client:write(data)
end

--准备解密key
function CTcpServer:SendKey(vfd, client)
	local key = os.time()
	self.m_ClientKey[vfd] = key
	local data = string.pack("BI", 4, key)
	client:write(data)
end

--数据加密
function CTcpServer:Encode(vfd, data)
	local key = self.m_ClientKey[vfd]
	if not key then return data end
	local len = string.len(data)
	local str = {}
	local src, dst
	for i = 1, len do
		src = string.byte(data, i)
		dst = (src ~ key) & 0xff
		key = key + (src & 0x03)
		str[i] = string.char(dst)
	end
	self.m_ClientKey[vfd] = key
	return table.concat(str)
end

--数据解密
function CTcpServer:Decode(vfd, data)
	local key = self.m_ClientKey[vfd]
	if not key then return data end
	local len = string.len(data)
	local str = {}
	local src
	for i = 1, len do
		src = string.byte(data, i)
		src = (src ~ key) & 0xff
		key = key + (src & 0x03)
		str[i] = string.char(src)
	end
	self.m_ClientKey[vfd] = key
	return table.concat(str)
end


function CTcpServer:OnClientLost(client)
	local vfd = self.m_ClientObj2Vfd[client]
	if vfd then
		self.m_ClientObj2Vfd[client] = nil
		self.m_ClientVfd2Obj[vfd] = nil
		self.m_ClientKey[vfd] = nil
	end
	client:close()
	self:OnEvent("close", vfd)
end

function CTcpServer:CloseClient(vfd)
	local client = self.m_ClientVfd2Obj[vfd]
	if client then
		self.m_ClientVfd2Obj[vfd] = nil
		self.m_ClientObj2Vfd[client] = nil
		self.m_ClientKey[vfd] = nil
		client:close()
	end
	self:OnEvent("close", vfd)
end

function CTcpServer:Client2Vfd(client)
	return self.m_ClientObj2Vfd[client] or 0
end

function CTcpServer:Vfd2Client(vfd)
	return self.m_ClientVfd2Obj[vfd]
end




-------------------------------------------------------------------------------
--客户端
-------------------------------------------------------------------------------
CTcpClient = cls.CObject:Inherit("CTcpClient")

function CTcpClient:Create(port, ip)
	self.m_Sock = uv.tcp_new()
	self.m_IP = ip or "127.0.0.1"
	self.m_Port = port
	self.m_Connected = false
end

function CTcpClient:GetAddressString()
	return string.format("%s:%s", self.m_IP, self.m_Port)
end

function CTcpClient:Start(port, ip)
	if port then self.m_Port = port end
	if ip then self.m_IP = ip end
	self.m_Sock:connect(self.m_IP, self.m_Port, function(err)
		if err then
			return self:Error()
		end
		self:Connected()
		self.m_Sock:read_start(function(err, data)
			if err then
				return self:Error()
			end
			if data then
				self:Recv(data)
			else
				self:Close()
			end
		end)
	end)
end

function CTcpClient:Stop()
	self.m_Sock:close()
	self:Close()
end

function CTcpClient:ReStart()
	if self.m_Sock then
		self.m_Sock:close()
	end
	self.m_Sock = uv.tcp_new()
	self.m_Connected = false
	self:Start()
end

function CTcpClient:Connected()
	self.m_Connected = true
	self:OnEvent("connect")
end

function CTcpClient:Error()
	self.m_Connected = false
	--self.m_Sock:close()
	self:OnEvent("error")
end

function CTcpClient:Close()
	self.m_Connected = false
	--self.m_Sock:close()
	self:OnEvent("close")
end

--设置包体分析函数
--函数声明：bool func({meta=, pak=, left=})
--返回值：true/false，表示是否继续解析
--meta为源数据字符串，pak为解析完成的完整数据，left为解析未完成的数据
--pak和left的格式由各玩法自行定义，一般是一个table
function CTcpClient:SetPackageParser(func)
	if not func then return end
	if type(func) ~= "function" then return end
	self.m_PackageParser = func
end

function CTcpClient:Recv(data)
	if not self.m_PackageParser then
		self:OnEvent("recv", data)
		return
	end
	--将数据合并入数据源中
	if not self.m_CacheData then
		self.m_CacheData = {meta=data}
	else
		self.m_CacheData.meta = self.m_CacheData.meta .. data
	end
	--循环解析
	local pkg = self.m_CacheData
	local flag, pak
	while true do
		pkg.pak = nil
		flag = self.m_PackageParser(self.m_CacheData)
		pak = pkg.pak
		pkg.pak = nil
		if pak then
			self:OnEvent("recv", pak)
		end
		if not flag then break end
	end
end

function CTcpClient:Send(data)
	if not self.m_Connected then return end
	self.m_Sock:write(data)
end

function CTcpClient:IsConnected()
	return self.m_Connected
end
