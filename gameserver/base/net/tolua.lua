
-------------------------------------------------------------------------------
--文件导出
-------------------------------------------------------------------------------
local log = require("base/log.lua")

--将协议格式转换成Lua格式的协议文件，用于服务端
function Export(isserver)
	local typeTrans = net.TYPE_EXPORT_LUA
	local function __Convert(name, isreader, args, showname)
		local argname, argtype, argnum, trans
		local list = {}
		local idx = 0
		local idxname
		for k, v in ipairs(args) do
			argname, argtype, argnum = v[1], v[2], v[3]
			trans = typeTrans[argtype]
			if showname then
				idxname = "\"" .. argname .. "\""
			else
				idxname = tostring(k)
			end
			if trans then
				idx = idx + 1
				if isreader then
					if argnum then
						list[idx] = string.format("data[%s]=net.Read%s(\"%s\", %s);", idxname, trans, argname, argnum)
					else
						list[idx] = string.format("data[%s]=net.Read%s(\"%s\");", idxname, trans, argname)
					end
				else
					list[idx] = string.format("net.Write%s(\"%s\", data[%d] or data[\"%s\"]);", trans, argname, k, argname)
				end
			else
				if isreader then
					if argnum then
						list[idx+1] = "local tmp = {};"
						list[idx+2] = string.format("local tmpsize = net.ReadUint16(\"%s\");", argname)
						list[idx+3] = string.format("for i=1,tmpsize do tmp[i]=net.NetType[\"%s\"].reader(\"%s\"); end;", argtype, argname)
						list[idx+4] = string.format("data[%s] = tmp;", idxname)
						idx = idx + 4
					else
						idx = idx + 1
						list[idx] = string.format("data[%s]=net.NetType['%s'].reader();", idxname, argtype)
					end
				else
					if argnum then
						list[idx+1] = string.format("local tmp = data[%d] or data[\"%s\"];", k, argname)
						list[idx+2] = string.format("net.WriteUint16(\"%s\", #tmp);", argname)
						list[idx+3] = string.format("for k,v in ipairs(tmp) do net.NetType[\"%s\"].writer(\"%s\",v); end;", argtype, argname)
						idx = idx + 3
					else
						idx = idx + 1
						list[idx] = string.format("data[%s]=net.NetType[\"%s\"].reader(\"%s\");", idxname, argtype, argname)
					end
				end
			end
		end
		local code
		if isreader then
			code = string.format("return function(argname) local data={}; %s return data; end", table.concat(list))
		else
			code = string.format("return function(argname, data) %s end", table.concat(list))
		end
		return load(code)()
	end
	--解析协议类型文件
	for name, info in pairs(net.NetType) do
		if type(info) == "table" then
			info.reader = __Convert(name, true, info.args, true)
			info.writer = __Convert(name, false, info.args)
		end
	end
	--解析协议定义文件
	if isserver then
		for _, info in pairs(net.NetC2S) do
			info.reader = __Convert(info.name, true, info.args)
		end
		for ptoid, info in pairs(net.NetS2C) do
			info.writer = __Convert(info.name, false, info.args)
			net[info.name] = function (vfds, ...)
				if not net.Name2ID[info.name] then
					log:Error("Protocol(%s) not supported!", info.name)
					return
				end
				local data = {...}
				--log:Debug("[Protocol]%s,vfd=%s,args=%s", info.name, vfds, Serialize(data))
				local func = net.NetS2C[ptoid]
				net.WriteBegin(ptoid)
				if #data > 0 then
					func.writer(info.name, data)
				end
				net.Send2Client(vfds)
			end
		end
	else
		for ptoid, info in pairs(net.NetC2S) do
			info.writer = __Convert(info.name, false, info.args)
			net[info.name] = function (vfd, ...)
				--log:Debug("[Protocol]%s", info.name, vfd, ...)
				if not net.Name2ID[info.name] then
					log:Error("Protocol(%s) not supported!", info.name)
					return
				end
				local func = net.NetC2S[ptoid]
				net.WriteBegin(iPtoID)
				local data = {...}
				if #data > 0 then
					func.writer(info.name, data)
				end
				net.Send2Server(vfd)
			end
		end
		for _, info in pairs(net.NetS2C) do
			info.reader = __Convert(info.name, true, info.args)
		end
	end
end
