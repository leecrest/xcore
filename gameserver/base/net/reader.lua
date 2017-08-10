
--格式检查
local function CheckType(NetType)
	--类型文件可以嵌套，但是不能出现环，也不能嵌套自身
	if not next(NetType) then return end
	local custom = {}
	for name, info in pairs(NetType) do
		for _, v in ipairs(info.args) do
			assert(v[2] ~= name, "协议文件 "..v[2].." 出现嵌套环")
			assert(net.DATA_TYPE[v[2]] or NetType[v[2]], "数据类型 "..v[2].." 不支持")
			if NetType[v[2]] then
				if not custom[name] then custom[name] = {} end
				custom[name][v[2]] = true
			end
		end
	end
	--检查环
	local chain = {}
	local function __CheckNode(root, name)
		assert(not chain[name], "数据类型 "..root.." 出现嵌套环")
		chain[name] = true
		for subname, _ in pairs(custom[name] or {}) do
			__CheckNode(root, subname)
		end
	end
	for name, _ in pairs(custom) do
		chain = {}
		__CheckNode(name, name)
	end
end

--读取类型定义
local function ReadType(name, args)
	local keys = {}
	for _, v in ipairs(args) do
		assert(type(v) == "table" and #v >= 2 and type(v[1]) == "string", "协议文件 "..name.." 格式错误")
		assert(not keys[v[1]], "协议文件 "..name.." 出现重复字段")
		keys[v[1]] = true
		if type(v[2]) == "string" then
			if net.TYPE_NAME_TRANS[v[2]] then
				v[2] = net.TYPE_NAME_TRANS[v[2]]
			end
			if not net.DATA_TYPE[v[2]] then
				assert(v[2] ~= name, "协议文件 "..name.." 出现嵌套环")
			end
		elseif type(v[2]) == "table" then
			--出现嵌套
			assert(#v[2] > 0, "协议文件 "..name.." 嵌套格式错误")
			local subname = string.format("%s_%s", name, v[1])
			ReadType(subname, {name=subname, args=v[2]}, NetType)
			v[2] = subname
		else
			assert(nil, "协议文件 "..name.." 出现不支持的数据类型："..tostring(v[2]))
		end
	end
	net.NetType[name] = {name = name, args = args}
end

--读取协议定义
local function ReadPto(id, name, args)
	local keys = {}
	for _, v in ipairs(args) do
		assert(type(v) == "table" and #v >= 2 and type(v[1]) == "string", "协议文件 "..name.." 格式错误")
		assert(not keys[v[1]], "协议文件 "..name.." 出现重复字段")
		keys[v[1]] = true
		if type(v[2]) == "string" then
			if net.TYPE_NAME_TRANS[v[2]] then
				v[2] = net.TYPE_NAME_TRANS[v[2]]
			end
			if not net.DATA_TYPE[v[2]] then
				assert(v[2] ~= name, "协议文件 "..name.." 出现嵌套环")
				assert(not string.startwith(v[2], "c2s"), "协议文件 "..name.." 不允许嵌套"..v[2])
				assert(not string.startwith(v[2], "s2c"), "协议文件 "..name.." 不允许嵌套"..v[2])
			end
		elseif type(v[2]) == "table" then
			--出现嵌套
			assert(#v[2] > 0, "协议文件 "..name.." 嵌套格式错误")
			local subname = string.format("%s_%s", name, v[1])
			ReadType(subname, {name=subname, args=v[2]}, net.NetType)
			v[2] = subname
		else
			assert(nil, "协议文件 "..name.." 出现不支持的数据类型："..tostring(v[2]))
		end
	end
	net.Name2ID[name] = id
	if string.sub(name, 1, 2) == "c_" then
		net.NetS2C[id] = {name = name, args = args}
	else
		net.NetC2S[id] = {name = name, args = args}
	end
end


--网络协议初始化
function Init(cfg)
	cfg = cfg or {}
	net.IsServer = cfg.isserver
	
	--直接读取协议集中文件
	local path = string.format("%s/allpto.lua", cfg.path or "protocol")
	local types, ptos = dofile(path)
	assert(type(types) == "table" and type(ptos) == "table", string.format("协议文件 %s 格式错误", path))
	for _, v in ipairs(types) do
		ReadType(v[1], v[2])
	end
	for k, v in ipairs(ptos) do
		ReadPto(k, v[1], v[2])
	end

	--检查协议格式，是否出现异常
	CheckType(net.NetType)
end
