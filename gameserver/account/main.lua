
require("base/timer.lua")
require("base/log.lua")
require("base/server.lua")
require("base/setting.lua")
require("base/tcp.lua")

require("account/login.lua")

local server = require("base/server.lua")
server:Init(100)
server:Run()