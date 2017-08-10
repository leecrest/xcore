--定时器

--增加定时器
function AddTimer(self, obj, delay, interval, func, ...)
	if not delay or not interval or not func then return end
	if delay < 0 or interval < 0 then return end
	obj = obj or self
	local args = {...}
	local t = type(func)
	if t ~= "function" and t ~= "string" then return end
	local timer = uv.timer_new()
	if t == "function" then
		uv.timer_start(timer, delay, interval, function()
			local callback = obj.__Timer[timer]
			if interval == 0 then
				obj.__Timer[timer] = nil
				uv.timer_stop(timer)
			end
			callback(table.unpack(args))
		end)
		if not obj.__Timer then
			obj.__Timer = {}
		end
		obj.__Timer[timer] = func
	elseif t == "string" then
		uv.timer_start(timer, delay, interval, function()
			local callback = obj.__Timer[timer]
			if interval == 0 then
				obj.__Timer[timer] = nil
				uv.timer_stop(timer)
			end
			obj[callback](obj, table.unpack(args))
		end)
		if not obj.__Timer then
			obj.__Timer = {}
		end
		obj.__Timer[timer] = func
	end
	return timer
end

--删除指定对象的指定 定时器
function DelTimer(self, obj, timer)
	obj = obj or self
	if not obj.__Timer then return end
	if not obj.__Timer[timer] then return end
	obj.__Timer[timer] = nil
	uv.timer_stop(timer)
end

function DelTimerByName(self, obj, func)
	if not func then return end
	obj = obj or self
	if not obj.__Timer then return end
	local list = {}
	for k, v in pairs(obj.__Timer) do
		if v == func then
			list[k] = 1
		end
	end
	for k, _ in pairs(list) do
		obj.__Timer[k] = nil
		uv.timer_stop(k)
	end
end

--删除指定对象的所有定时器
function DelAll(self, obj)
	obj = obj or self
	if not obj.__Timer then return end
	local list = obj.__Timer
	obj.__Timer = {}
	for k, _ in pairs(list) do
		uv.timer_stop(k)
	end
end

function HasTimer(self, obj, func)
	if not func then return end
	obj = obj or self
	if not obj.__Timer then return end
	for _, v in pairs(obj.__Timer) do
		if v == func then
			return true
		end
	end
end


function SetTimeOut(self, sec, func, ...)
	return self:AddTimer(nil, sec, 0, func, ...)
end

function SetInterval(self, sec, interval, func, ...)
	return self:AddTimer(nil, sec, interval, func, ...)
end
