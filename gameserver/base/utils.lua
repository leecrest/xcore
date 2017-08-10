
--------------------------------------------------------------------------------
--table扩展
--------------------------------------------------------------------------------
--列举出对象的所有方法
function table.funcs(self, all)
	local list = {}
	for k, v in pairs(self) do
		if type(v) == "function" then
			list[k] = v
		end
	end
	if all then
		for k, v in pairs(getmetatable(self) or {}) do
			if type(v) == "function" then
				list[k] = v
			end
		end
	end
	table.print(list)
end

function table.mergeto(self, tbl2)
    local new_table = {}
    for k,v in pairs(self) do new_table[k] = v end
    for k,v in pairs(tbl2) do new_table[k] = v end
    return new_table
end

function table.merge(self, tbl)
	self = self or {}
	for k, v in pairs(tbl) do
		self[k] =  v
	end
	return self
end

function table.keys(self)
    local keys = {}
	if self then
		local idx = 0
		for k, _ in pairs(self) do
			idx = idx + 1
			keys[idx] =k
		end
	end
    return keys
end

function table.values(self)
    local values = {}
	if self then
		local idx = 0
		for _, v in pairs(self) do
			idx = idx + 1
			values[idx] = v
		end
	end
    return values
end

function table.find(self, value)
    for k, v in pairs(self) do
        if v == value then return k end
    end
end

function table.ifind(self, value, start)
	for i = (start or 1), #self do
        if self[i] == value then return i end
    end
end

--浅拷贝
function table.copy(self, dst)
	local dst = dst or {}
	if type(self) ~= "table" then
		return dst
	end
	for k, v in pairs(self) do
		dst[k] = v
	end
	return dst
end

--设置一个Table为只读
function table.readonly(self)
	local mt = getmetatable(self) or {}
	mt.__newindex = function (self, k, v)
		error("attempt to update a read-only table",3)
	end
	setmetatable(self, mt)
	return self
end

--深拷贝
function table.deepcopy(self, quiet)
	if type(self) ~= "table" then
		return self
	end
	local cache = {}
	local function clone_table(t, level)
		if not level then
			level = 0
		end

		if level > 20 then
			if not quiet then
				error("table clone failed, "..
						"source table is too deep!")
			else
				return t
			end
		end

		local k, v
		local rel = {}
		for k, v in pairs(t) do
			--if k == "Name" then print(k, tostring(v)) end
			if type(v) == "table" then
				if cache[v] then
					rel[k] = cache[v]
				else
					rel[k] = clone_table(v, level+1)
					cache[v] = rel[k]
				end
			else
				rel[k] = v
			end
		end
		setmetatable(rel, getmetatable(t))
		return rel
	end
	return clone_table(self)
end

function table.print(t, tname, print_one_level)
	if type(t) ~= "table" then
		--err_info("deep_print error, parameter accept is not a table!")
		return
	end
	local _deep_count = 0
	local print_one_table
	local max_deep = deep or 10
	local printed_tables = {}
	local t_path = {}

	local function PrintValue(value)
		if not value then return "nil" end
		local str, value_type
		value_type = type(value)
		if value_type == "number" then
			str = string.format("[ %s ]n", value)
		elseif value_type == "string" then
			str = string.format("[ \"%s\" ]s", value)
		elseif value_type == "table" then
			str = string.format("[ 0x%s ]t", string.sub(tostring(value), 8))
		elseif value_type == "function" then
			str = string.format("[ 0x%s ]f", string.sub(tostring(value), 11))
		elseif value_type == "userdata" then
			str = string.format("[ 0x%s ]u", string.sub(tostring(value), 11))
		else
			str = string.format("[ S\"%s\" ]%s", tostring(value), type(value))
		end
		return str
	end

	tname = tname or "root_table"
	local function PrintTable(tb, tb_name, print_one_level)
		tb_name = tb_name or "table"			
		table.insert(t_path, tb_name)
		local tpath, i, tname = ""
		for i, pname in pairs(t_path) do
			tpath = tpath.."."..pname
		end
		printed_tables[tb] = tpath
		_deep_count = _deep_count + 1
		local k, v, str
		local tab = string.rep(" ", _deep_count*4)
		--print(string.format("%s  [ 0x%s ]t\n%s  {    ", tab, string.sub(tostring(tb), 8), tab))
		print(string.format("%s  {", tab))
		for k, v in pairs(tb) do
			if type(v) == "table" then
				if printed_tables[v] then
					str = string.format("%s    %s = [ %s ]t", tab, PrintValue(k), printed_tables[v])
					print(str)
				elseif not print_one_level then
					str = string.format("%s    %s = ", tab, PrintValue(k))
					print(str)
					PrintTable(v, tostring(k))
				else
					str = string.format("%s    %s = %s", tab, PrintValue(k), PrintValue(v))
					print(str)
				end
			else
				str = string.format("%s    %s = %s", tab, PrintValue(k), PrintValue(v))
				print(str)
			end
		end
		print(tab.."  }")
		table.remove(t_path)
		_deep_count = _deep_count - 1
	end	
	PrintTable(t, tname, print_one_level)
	printed_tables = nil
end

function table.tostring(tbl, deep)
	local max_deep = deep or 10
	local _deep_count = 0

	local function tab2str(tab)
		if tab == nil then
			return
		end

		assert(_deep_count < max_deep, "deep > max")
		_deep_count = _deep_count + 1

		local result = "{"
		for k,v in pairs(tab) do
			if type(k) == "number" then
				if type(v) == "table" then
					result = string.format( "%s[%d]=%s,", result, k, tab2str(v) )
				elseif type(v) == "number" then
					result = string.format( "%s[%d]=%s,", result, k, v )
				elseif type(v) == "string" then
					result = string.format( "%s[%d]=%q,", result, k, v )
				elseif type(v) == "boolean" then
					result = string.format( "%s[%d]=%s,", result, k, tostring(v) )
				else
					error("the type of value is a function or userdata")
				end
			else
				if type(v) == "table" then
					result = string.format( "%s['%s']=%s,", result, k, tab2str(v) )
				elseif type(v) == "number" then
					result = string.format( "%s['%s']=%s,", result, k, v )
				elseif type(v) == "string" then
					result = string.format( "%s['%s']=%q,", result, k, v )
				elseif type(v) == "boolean" then
					result = string.format( "%s['%s']=%s,", result, k, tostring(v) )
				else
					error("the type of value is a function or userdata")
				end
			end
		end
		result = result .. "}"
		_deep_count = _deep_count - 1
		return result
	end

	return tab2str(tbl)
end

function table.loadstring(str)
	local chunk = load("return "..(str or "{}"))
	if chunk then
		local rt = chunk()
		rt = (rt and type(rt) == "table") and rt or {}
		return rt
	else
		error("Invalid table string %s",str)
	end
end

function table.equal(a, b)
	if type(a) ~= "table" or type(b) ~= "table" then return end
	if a == b then return true end
	for k, v in pairs(a) do
		if not b[k] then return end
		if type(v) == "table" then
			if not table.equal(v, b[k]) then return end
		elseif b[k] ~= v then
			return
		end
	end
	for k, v in pairs(b) do
		if not a[k] then return end
		if type(v) == "table" then
			if not table.equal(v, a[k]) then return end
		elseif a[k] ~= v then
			return
		end
	end
	return true
end

function table.size(a)
	if not a then return 0 end
	local size = 0
	for k, _ in pairs(a) do
		size = size + 1
	end
	return size
end

function table.remove_value(t, v)
	if not t or not v then return end
	for i, j in pairs(t) do
		if j == v then
			t[i] = nil
		end
	end
end

function table.append(t, v)
	if not t or type(t) ~= "table" then return end
	t[#t+1] = v
end



--------------------------------------------------------------------------------
--string扩展
--------------------------------------------------------------------------------

function string.startwith(str, flag)
	return string.find(str, flag, 1, true) == 1
end

function string.split(str, sep, maxsplit)
	local size = string.len(str)
	if size == 0 then
		return {}
	end
	sep = sep or ' '
	maxsplit = maxsplit or 0
	local result = {}
	local pos = 1   
	local step = 0
	while true do   
		local from, to = string.find(str, sep, pos, true)
		step = step + 1
		if (maxsplit ~= 0 and step > maxsplit) or from == nil then
			if pos < size then
				table.insert(result, string.sub(str, pos))
			end
			break
		else
			table.insert(result, string.sub(str, pos, from-1))
			pos = to + 1
		end
	end     
	return result  
end

--删除空白前导空白字符或者指定字符集中的字符
function string.lstrip(str, chars)
	if chars then
		for k = 1, #str do
			local sub = string.sub(str, k, k)
			if not string.find(chars, sub, 1, true) then
				return string.sub(str, k)
			end
		end
	else
		return string.gsub(str, "^%s*", "")
	end
end

--删除空白后导空白字符或者指定字符集中的字符
function string.rstrip(str, chars)
	if chars then
		for k=#str,1 do
			local sub = string.sub(str,k,k)
			--
			if not string.find(chars, sub, 1, true) then
				return string.sub(str, 1, k)
			end
		end
	else
		return string.gsub(str, "%s*$", "")
	end
end

--删除空白前后空白字符或者指定字符集中的字符
function string.strip(str, chars)
	return string.rstrip(string.lstrip(str, chars), chars)
end

--判断一个字符串是否以$ends结尾
function string.endwith(str, flag)
	local i, j = string.rfind(str, flag)
	return (i and j == #str)
end

function string.rfind(str, flag)
	local ret = str:reverse():find(flag)
	if not ret then return end
	return #str - ret + 1
end
