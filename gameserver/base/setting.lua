--配置管理
local log = require("base/log")

function Init(self, path, callback)
	log:Info("InitModule:setting, %s", path)
	self.m_Data = {}
	self.m_Callback = callback
	self:LoadSetting(path)
end

function LoadSetting(self, path)
	local req = uv.fs_scandir(path)
	if not req then
		return self:LoadFinish()
	end
	local function iter()
		return uv.fs_scandir_next(req)
    end
	for entry in iter do
		local fullName = path .. "/" .. entry.name
		if entry.type then
			local pos = string.rfind(entry.name, "%.")
			if not pos then return end
			local name = string.sub(entry.name, 1, pos-1)
			local ext = string.sub(entry.name, pos, #entry.name)
			if ext ~= ".lua" then return end
			local value = dofile(fullName)
			if type(value) == "table" then
				table.readonly(value)
			end
			self.m_Data[name] = value
		else
			self:LoadSetting(fullName)
		end
	end
	self:LoadFinish()
end

function LoadFinish(self)
	if not self.m_Callback then return end
	local func = self.m_Callback
	self.m_Callback = nil
	func()
end


--查询配置，File：文件名
--类似：Query("const", "sex")
function Query(self, file, ...)
	local result = self.m_Data[file]
	if not result then return end
	local ret = result
	for _, key in ipairs({...}) do
		ret = ret[key]
		if not ret then return end
	end
	return ret
end
