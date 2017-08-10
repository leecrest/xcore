
local theme = {}
local useColors = false
local defaultTheme = 16

local stdout, stdin, stderr, width
local quote, quote2, dquote, dquote2, obracket, cbracket, obrace, cbrace, comma, equals, controls
local themes = {

  -- nice color theme using 16 ansi colors
	[16] = {
		property     = "0;37", -- white
		sep          = "1;30", -- bright-black
		braces       = "1;30", -- bright-black

		["nil"]      = "1;30", -- bright-black
		boolean      = "0;33", -- yellow
		number       = "1;33", -- bright-yellow
		string       = "0;32", -- green
		quotes       = "1;32", -- bright-green
		escape       = "1;32", -- bright-green
		["function"] = "0;35", -- purple
		thread       = "1;35", -- bright-purple

		table        = "1;34", -- bright blue
		userdata     = "1;36", -- bright cyan
		cdata        = "0;36", -- cyan

		err          = "1;31", -- bright red
		success      = "1;33;42", -- bright-yellow on green
		failure      = "1;33;41", -- bright-yellow on red
		highlight    = "1;36;44", -- bright-cyan on blue
	},

  -- nice color theme using ansi 256-mode colors
	[256] = {
		property     = "38;5;253",
		braces       = "38;5;247",
		sep          = "38;5;240",

		["nil"]      = "38;5;244",
		boolean      = "38;5;220", -- yellow-orange
		number       = "38;5;202", -- orange
		string       = "38;5;34",  -- darker green
		quotes       = "38;5;40",  -- green
		escape       = "38;5;46",  -- bright green
		["function"] = "38;5;129", -- purple
		thread       = "38;5;199", -- pink

		table        = "38;5;27",  -- blue
		userdata     = "38;5;39",  -- blue2
		cdata        = "38;5;69",  -- teal

		err          = "38;5;196", -- bright red
		success      = "38;5;120;48;5;22",  -- bright green on dark green
		failure      = "38;5;215;48;5;52",  -- bright red on dark red
		highlight    = "38;5;45;48;5;236",  -- bright teal on dark grey
	},

}

local special = {
	[7] = 'a',
	[8] = 'b',
	[9] = 't',
	[10] = 'n',
	[11] = 'v',
	[12] = 'f',
	[13] = 'r'
}


function loadColors(index)
	if index == nil then index = defaultTheme end

	-- Remove the old theme
	for key in pairs(theme) do
		theme[key] = nil
	end

	if index then
		local new = themes[index]
		if not new then
			error("Invalid theme index: " .. tostring(index)) 
		end
		-- Add the new theme
		for key in pairs(new) do
			theme[key] = new[key]
		end
		useColors = true
	else
		useColors = false
	end

	quote    = colorize('quotes', "'", 'string')
	quote2   = colorize('quotes', "'")
	dquote    = colorize('quotes', '"', 'string')
	dquote2   = colorize('quotes', '"')
	obrace   = colorize('braces', '{ ')
	cbrace   = colorize('braces', '}')
	obracket = colorize('property', '[')
	cbracket = colorize('property', ']')
	comma    = colorize('sep', ', ')
	equals   = colorize('sep', ' = ')

	controls = {}
	for i = 0, 31 do
		local c = special[i]
		if not c then
			if i < 10 then
				c = "00" .. tostring(i)
			else
				c = "0" .. tostring(i)
			end
		end
		controls[i] = colorize('escape', '\\' .. c, 'string')
	end
	controls[92] = colorize('escape', '\\\\', 'string')
	controls[34] = colorize('escape', '\\"', 'string')
	controls[39] = colorize('escape', "\\'", 'string')
end

function color(colorName)
	return '\27[' .. (theme[colorName] or '0') .. 'm'
end

function colorize(colorName, string, resetName)
	return useColors and
		(color(colorName) .. tostring(string) .. color(resetName)) or
		tostring(string)
end

function strip(str)
	return string.gsub(str, '\027%[[^m]*m', '')
end

function stringEscape(c)
	return controls[string.byte(c, 1)]
end

function dump(value)
	if not value then return "nil" end
	local seen = {}
	local output = {}
	local offset = 0
	local stack = {}

	local function recalcOffset(index)
		for i = index + 1, #output do
			local m = string.match(output[i], "\n([^\n]*)$")
			if m then
				offset = #(strip(m))
			else
				offset = offset + #(strip(output[i]))
			end
		end
	end

	local function write(text, length)
		if not length then length = #(strip(text)) end
		-- Create room for data by opening parent blocks
		-- Start at the root and go down.
		local i = 1
		while offset + length > width and stack[i] do
			local entry = stack[i]
			if not entry.opened then
				entry.opened = true
				table.insert(output, entry.index + 1, "\n" .. string.rep("  ", i))
				-- Recalculate the offset
				recalcOffset(entry.index)
				-- Bump the index of all deeper entries
				for j = i + 1, #stack do
					stack[j].index = stack[j].index + 1
				end
			end
			i = i + 1
		end
		output[#output + 1] = text
		offset = offset + length
		if offset > width then
			dump(stack)
		end
	end

	local function indent()
		stack[#stack + 1] = {
			index = #output,
			opened = false,
		}
	end

	local function unindent()
		stack[#stack] = nil
	end

	local function process(value)
		local typ = type(value)
		if typ == 'string' then
			if string.match(value, "'") and not string.match(value, '"') then
				write(dquote .. string.gsub(value, '[%c\\]', stringEscape) .. dquote2)
			else
				write(quote .. string.gsub(value, "[%c\\']", stringEscape) .. quote2)
			end
		elseif typ == 'table' and not seen[value] then

			seen[value] = true
			write(obrace)
			-- Count the number of keys so we know when to stop adding commas
			local total = 0
			local keylist = {}
			for k, v in pairs(value) do
				keylist[total+1] = k
				total = total + 1 
			end
			table.sort(keylist)
			local v
			local i = 1
			for _, k in ipairs(keylist) do
				v = value[k]
				indent()
				if k == i then
					-- if the key matches the index, don't show it.
					-- This is how lists print without keys
					process(v)
				else
					if type(k) == "string" and string.find(k,"^[%a_][%a%d_]*$") then
						write(colorize("property", k) .. equals)
					else
						write(obracket)
						process(k)
						write(cbracket .. equals)
					end
					if type(v) == "table" then
						process(v)
					else
						indent()
						process(v)
						unindent()
					end
				end
				if i < total then
					write(comma)
				else
					write(" ")
				end
				i = i + 1
				unindent()
			end
			write(cbrace)
		else
			write(colorize(typ, tostring(value)))
		end
	end

	process(value)
	return table.concat(output, "")
end


function bind(fn, ...)
	local args = {...}
	if #args == 0 then return fn end
	return function ()
		return fn(table.unpack(args))
	end
end

function noop(err)
	if err then print("Unhandled callback error", err) end
end

function adapt(c, fn, ...)
	local nargs = select('#', ...)
	local args = {...}
	-- No continuation defaults to noop callback
	if not c then c = noop end
	local t = type(c)
	if t == 'function' then
		args[nargs + 1] = c
		return fn(table.unpack(args))
	elseif t ~= 'thread' then
		error("Illegal continuation type " .. t)
	end
	local err, data, waiting
	args[nargs + 1] = function (err, ...)
		if waiting then
			if err then
				assert(coroutine.resume(c, nil, err))
			else
				assert(coroutine.resume(c, ...))
			end
		else
			error, data = err, {...}
			c = nil
		end
	end
	fn(table.unpack(args))
	if c then
		waiting = true
		return coroutine.yield(c)
	elseif err then
		return nil, err
	else
		return table.unpack(data)
	end
end

function run(greeting)
	greeting = greeting or string.format("Welcome to the xcore %s repl!\ndeps:%s", VERSION, VERSION_DEPS)
	if uv.guess_handle(0) == 'tty' then
		stdin = assert(uv.tty_new(0, true))
	else
		stdin = uv.pipe_new(false)
		uv.pipe_open(stdin, 0)
	end
	if uv.guess_handle(1) == 'tty' then
		stdout = assert(uv.tty_new(1, false))
		width = uv.tty_get_winsize(stdout)
	else
		stdout = uv.pipe_new(false)
		uv.pipe_open(stdout, 1)
		width = 80
	end
	loadColors()

	if uv.guess_handle(2) == 'tty' then
		stderr = assert(uv.tty_new(2, false))
	else
		stderr = uv.pipe_new(false)
		uv.pipe_open(stderr, 2)
	end

	local Print = function(...)
		uv.stream_write(stdout, table.concat({...}, "\t") .. "\n")
	end

	if greeting then Print(color("quotes") .. greeting .. color()) end

	local c = color

	local function gatherResults(success, ...)
		local n = select('#', ...)
		return success, { n = n, ... }
	end

	local function printResults(results)
		local ret = {}
		for i = 1, results.n do
			ret[i] = dump(results[i])
		end
		Print(table.concat(ret, '\t'))
	end

	local buffer = ''

	local function evaluateLine(line)
		if line == "<3\n" then
			Print("I " .. c("Bred") .. "♥" .. c() .. " you too!")
			return '>'
		end
		local chunk  = buffer .. line
		local f, err = load('return ' .. chunk, 'REPL') -- first we prefix return
		if not f then
			f, err = load(chunk, 'REPL') -- try again without return
		end

		if f then
			buffer = ''
			local success, results = gatherResults(xpcall(f, debug.traceback))
			if success then
				-- successful call
				if results.n > 0 then
					printResults(results)
				end
			else
				-- error
				Print(results[1])
			end
		else
			if err:match "'<eof>'$" then
				-- Lua expects some more input; stow it away for next time
				buffer = chunk .. '\n'
				return '>>'
			else
				Print(err)
				buffer = ''
			end
		end
		return '>'
	end

	local function displayPrompt(prompt)
		uv.stream_write(stdout, prompt .. ' ')
	end

	displayPrompt('>')

	uv.stream_read_start(stdin, function (err, line)
		assert(not err, err)
		if line then
			local prompt = evaluateLine(line)
			displayPrompt(prompt)
		else
			uv.close(stdin)
		end
	end)
end
