
--日志级别
local LEVEL_DEBUG	= 1
local LEVEL_LOG		= 2
local LEVEL_INFO	= 3
local LEVEL_WARNING	= 4
local LEVEL_ERROR	= 5


function __init__(self)
	self.Files = {}
end

function __destroy__(self)
	for _, v in pairs(self.Files) do
		v:flush()
		v:close()
	end
	self.Files = {}
end

function Init(self, cfg)
	cfg = cfg or {}
	--日志路径
	self.Path = cfg.path or "./log/"
	local ret = uv.fs_stat(self.Path)
	if not ret then
		uv.fs_mkdir(self.Path, 777)
	end
	--日志级别
	self.Level = cfg.level or LEVEL_DEBUG
	self:Info("InitLog:path=%s,level=%s", self.Path, self.Level)
end

function Write2File(self, file, msg)
	file = file:gsub("\\", "/")
	local handle = self.Files[file]
	if not handle then
		handle = io.open(self.Path .. file, "a+")
		if not handle then
			local x = file:rfind("/")
			if not x then return end
			local dir = self.Path .. file:sub(1,x)
			if dir then
				uv.fs_mkdir(dir, 777)
			end
			handle = io.open(self.Path .. file, "a+")
		end
		self.Files[file] = handle
	end
	handle:write(msg .. "\n")
	handle:flush()
end

function Write(self, level, file, fmt, arg1, ...)
	if not fmt then return end
	local msg
	if arg1 ~= nil then
		if string.find(fmt, "%%") then
			msg = fmt:format(arg1, ...)
		else
			msg = table.concat({fmt, arg1, ...}, "\t")
		end
	else
		msg = fmt
	end
	msg = string.format("%s %s", os.date("%x %X"), msg)
	print(msg)
	if self.Level and level >= self.Level then
		self:Write2File(file, msg)
	end
end

function Debug (self, ...)
	self:Write(LEVEL_DEBUG, "debug.txt", ...)
end

function Info (self, ...)
	self:Write(LEVEL_INFO, "info.txt", ...)
end

function Warning (self, ...)
	self:Write(LEVEL_WARNING, "warning.txt", ...)
end

function Error (self, ...)
	self:Write(LEVEL_ERROR, "error.txt", ...)
end

function Log (self, file, ...)
	self:Write(LEVEL_LOG, file, ...)
end

