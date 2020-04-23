--;===========================================================
--; INITIALIZE DATA
--;===========================================================
--nClock = os.clock()
--print("Elapsed time: " .. os.clock() - nClock)
--SetGCPercent(-1)

main = {}

refresh()
math.randomseed(os.time())

--One-time load of the json routines
json = (loadfile 'external/script/dkjson.lua')()

--Data loading from config.json
local file = io.open("save/config.json","r")
config = json.decode(file:read("*all"))
file:close()

--Data loading from stats.json
file = io.open("save/stats.json","r")
stats = json.decode(file:read("*all"))
file:close()

--;===========================================================
--; COMMON FUNCTIONS
--;===========================================================
--add default commands
main.t_commands = {
	['$U'] = 0, ['$D'] = 0, ['$B'] = 0, ['$F'] = 0, ['a'] = 0, ['b'] = 0, ['c'] = 0, ['x'] = 0, ['y'] = 0, ['z'] = 0, ['s'] = 0, ['d'] = 0, ['w'] = 0, ['/s'] = 0, ['/d'] = 0, ['/w'] = 0}
function main.f_commandNew()
	local c = commandNew()
	for k, v in pairs(main.t_commands) do
		commandAdd(c, k, k)
	end
	return c
end
main.cmd = {main.f_commandNew(), main.f_commandNew(), main.f_commandNew(), main.f_commandNew()}

--add new commands
function main.f_commandAdd(cmd)
	if main.t_commands[cmd] ~= nil then
		return
	end
	for i = 1, #main.cmd do
		commandAdd(main.cmd[i], cmd, cmd)
	end
	main.t_commands[cmd] = 0
end

--makes the input detectable in the current frame
main.p1In = 1
main.p2In = 2
main.p3In = 3
main.p4In = 4
function main.f_cmdInput()
	commandInput(main.cmd[1], main.p1In)
	commandInput(main.cmd[2], main.p2In)
	commandInput(main.cmd[3], main.p3In)
	commandInput(main.cmd[4], main.p4In)
end

--returns value depending on button pressed (a = 1; a + start = 7 etc.)
function main.f_btnPalNo(cmd)
	local s = 0
	if commandGetState(cmd, '/s') then s = 6 end
	--if commandGetState(cmd, '/d') then s = 12 end
	--if commandGetState(cmd, '/w') then s = 18 end
	for i, k in pairs({'a','b','c','x','y','z'}) do
		if commandGetState(cmd, k) then return i + s end
	end
	return 0
end

--return bool based on command input
function main.input(p, b)
	for i = 1, #p do
		for j = 1, #b do
			if b[j] == 'pal' then
				if main.f_btnPalNo(main.cmd[p[i]]) > 0 then
					return true
				end
			elseif commandGetState(main.cmd[p[i]], b[j]) then
				return true
			end
		end
	end
	return false
end

--return table with key names
function main.f_extractKeys(str)
	local t = {}
	for i, c in ipairs(main.f_strsplit('%s*&%s*', str)) do --split string using "%s*&%s*" delimiter
		t[i] = c
	end
	return t
end

--check if a file or directory exists in this path
function main.f_exists(file)
	local ok, err, code = os.rename(file, file)
	if not ok then
		if code == 13 then
			--permission denied, but it exists
			return true
		end
	end
	return ok, err
end
--check if a directory exists in this path
function  main.f_isdir(path)
	-- "/" works on both Unix and Windows
	return main.f_exists(path .. '/')
end

main.debugLog = false
if main.f_isdir('debug') then
	main.debugLog = true
end

--check if file exists
function main.f_fileExists(file)
	if file == '' then
		return false
	end
	local f = io.open(file,'r')
	if f ~= nil then
		io.close(f)
		return true
	end
	return false
end

--prints "t" table content into "toFile" file
function main.f_printTable(t, toFile)
	local toFile = toFile or 'debug/table_print.txt'
	local txt = ''
	local print_t_cache = {}
	local function sub_print_t(t, indent)
		if print_t_cache[tostring(t)] then
			txt = txt .. indent .. '*' .. tostring(t) .. '\n'
		else
			print_t_cache[tostring(t)] = true
			if type(t) == 'table' then
				for pos, val in pairs(t) do
					if type(val) == 'table' then
						txt = txt .. indent .. '[' .. pos .. '] => ' .. tostring(t) .. ' {' .. '\n'
						sub_print_t(val, indent .. string.rep(' ', string.len(tostring(pos)) + 8))
						txt = txt .. indent .. string.rep(' ', string.len(tostring(pos)) + 6) .. '}' .. '\n'
					elseif type(val) == 'string' then
						txt = txt .. indent .. '[' .. pos .. '] => "' .. val .. '"' .. '\n'
					else
						txt = txt .. indent .. '[' .. pos .. '] => ' .. tostring(val) ..'\n'
					end
				end
			else
				txt = txt .. indent .. tostring(t) .. '\n'
			end
		end
	end
	if type(t) == 'table' then
		txt = txt .. tostring(t) .. ' {' .. '\n'
		sub_print_t(t, '  ')
		txt = txt .. '}' .. '\n'
	else
		sub_print_t(t, '  ')
	end
	local file = io.open(toFile,"w+")
	if file == nil then return end
	file:write(txt)
	file:close()
end

--prints "v" variable into "toFile" file
function main.f_printVar(v, toFile)
	local toFile = toFile or 'debug/var_print.txt'
	local file = io.open(toFile,"w+")
	file:write(v)
	file:close()
end

--split strings
function main.f_strsplit(delimiter, text)
	local list = {}
	local pos = 1
	if string.find('', delimiter, 1) then
		if string.len(text) == 0 then
			table.insert(list, text)
		else
			for i = 1, string.len(text) do
				table.insert(list, string.sub(text, i, i))
			end
		end
	else
		while true do
			local first, last = string.find(text, delimiter, pos)
			if first then
				table.insert(list, string.sub(text, pos, first - 1))
				pos = last + 1
			else
				table.insert(list, string.sub(text, pos))
				break
			end
		end
	end
	return list
end

require('external.script.screenpack')
main.IntLocalcoordValues()
main.CalculateLocalcoordValues()
main.IntLifebarScale()
main.SetScaleValues()

--fix for wrong x coordinate after flipping text/sprite (this should be fixed on source code level at some point)
function main.f_alignOffset(align)
	if align == -1 then
		return 1
	end
	return 0
end

main.font = {}
text = {}
--create text
function text:create(t)
	--default values
	if t.window == nil then t.window = {} end
	local o = {
		font = t.font or '',
		bank = t.bank or 0,
		align = t.align or 0,
		text = t.text or '',
		x = t.x or 0,
		y = t.y or 0,
		scaleX = t.scaleX or 1, 
		scaleY = t.scaleY or 1,
		r = t.r or 255,
		g = t.g or 255,
		b = t.b or 255,
		src = t.src or 255,
		dst = t.dst or 0,
		height = t.height or -1,
		window = {
			main.screenOverscan + (t.window[1] or 0), 
			t.window[2] or 0,
			main.screenOverscan + (t.window[3] or motif.info.localcoord[1]) - (t.window[1] or 0),
			(t.window[4] or motif.info.localcoord[2]) - (t.window[2] or 0)
		},
		defsc = t.defsc or false
	}
	o.ti = textImgNew()
	setmetatable(o, self) -- https://https://www.lua.org/manual/5.1/manual.html#2.8
	self.__index = self
	--font
	if o.font ~= '' then
		if main.font[o.font] == nil then
			main.font[o.font] = {}
		end
		local s = o.r .. o.g .. o.b .. o.src .. o.dst .. o.height
		if main.font[o.font][s] == nil then
			main.font[o.font][s] = fontNew(o.font)
		end
		--r, g, b, trans
		if o.r ~= 255 or o.g ~= 255 or o.b ~= 255 or o.src ~= 255 or o.dst ~= 0 then
			fontSetColor(main.font[o.font][s], o.r, o.g, o.b, o.src, o.dst)
		end
		--height (ttf)
		if o.height ~= -1 then
			fontSetHeight(main.font[o.font][s], t.height)
		end
		--font def
		if main.font[o.font].def == nil then
			main.font[o.font].def = fontGetDef(main.font[o.font][s])
		end
		textImgSetFont(o.ti, main.font[o.font][s])
	end
	textImgSetBank(o.ti, o.bank)
	textImgSetAlign(o.ti, o.align)
	textImgSetText(o.ti, o.text)
	if o.defsc then main.SetDefaultScale() end
	textImgSetPos(o.ti, o.x + main.f_alignOffset(o.align), o.y)
	textImgSetScale(o.ti, o.scaleX, o.scaleY)
	textImgSetWindow(o.ti, o.window[1], o.window[2], o.window[3], o.window[4])
	if o.defsc then main.SetScaleValues() end
	return o
end

--update text
function text:update(t)
	local fontChange = false
	local colorChange = false
	local heightChange = false
	for k, v in pairs(t) do
		if self[k] ~= v then
			if k == 'font' then
				fontChange = true
			elseif k == 'r' or k == 'g' or k == 'b' or k == 'src' or k == 'dst' then
				colorChange = true
			elseif k == 'height' then
				heightChange = true
			end
			self[k] = v
			ok = true
		end
	end
	if not ok then return end
	--font
	if fontChange or colorChange or heightChange then
		if main.font[self.font] == nil then
			main.font[self.font] = {}
		end
		local s = self.r .. self.g .. self.b .. self.src .. self.dst .. self.height
		if main.font[self.font][s] == nil then
			main.font[self.font][s] = fontNew(self.font)
		end
		--r, g, b, trans
		if colorChange then
			fontSetColor(main.font[self.font][s], self.r, self.g, self.b, self.src, self.dst)
		end
		--height (ttf)
		if heightChange then
			fontSetHeight(main.font[self.font][s], self.height)
		end
		--font def
		if main.font[self.font].def == nil then
			main.font[self.font].def = fontGetDef(main.font[self.font][s])
		end
		textImgSetFont(self.ti, main.font[self.font][s])
	end
	textImgSetBank(self.ti, self.bank)
	textImgSetAlign(self.ti, self.align)
	textImgSetText(self.ti, self.text)
	if self.defsc then main.SetDefaultScale() end
	textImgSetPos(self.ti, self.x + main.f_alignOffset(self.align), self.y)
	textImgSetScale(self.ti, self.scaleX, self.scaleY)
	textImgSetWindow(self.ti, self.window[1], self.window[2], self.window[3], self.window[4])
	if self.defsc then main.SetScaleValues() end
end

--draw text
function text:draw()
	textImgDraw(self.ti)
end

--animDraw at specified coordinates
function main.f_animPosDraw(a, x, y)
	animSetPos(a, x, y)
	animUpdate(a)
	animDraw(a)
end

--dynamically adjusts alpha blending each time called based on specified values
local alpha1cur = 0
local alpha2cur = 0
local alpha1add = true
local alpha2add = true
function main.f_boxcursorAlpha(r1min, r1max, r1step, r2min, r2max, r2step)
	if r1step == 0 then alpha1cur = r1max end
	if alpha1cur < r1max and alpha1add then
		alpha1cur = alpha1cur + r1step
		if alpha1cur >= r1max then
			alpha1add = false
		end
	elseif alpha1cur > r1min and not alpha1add then
		alpha1cur = alpha1cur - r1step
		if alpha1cur <= r1min then
			alpha1add = true
		end
	end
	if r2step == 0 then alpha2cur = r2max end
	if alpha2cur < r2max and alpha2add then
		alpha2cur = alpha2cur + r2step
		if alpha2cur >= r2max then
			alpha2add = false
		end
	elseif alpha2cur > r2min and not alpha2add then
		alpha2cur = alpha2cur - r2step
		if alpha2cur <= r2min then
			alpha2add = true
		end
	end
	return alpha1cur, alpha2cur
end

--generate anim from table
function main.f_animFromTable(t, sff, x, y, scaleX, scaleY, facing, infFrame, defsc)
	x = x or 0
	y = y or 0
	scaleX = scaleX or 1.0
	scaleY = scaleY or 1.0
	facing = facing or '0'
	infFrame = infFrame or 1
	local facing_sav = ''
	local anim = ''
	local length = 0
	for i = 1, #t do
		local t_anim = {}
		for j, c in ipairs(main.f_strsplit(',', t[i])) do --split using "," delimiter
			table.insert(t_anim, c)
		end
		if #t_anim > 1 then
			--required parameters
			t_anim[3] = tonumber(t_anim[3]) + x
			t_anim[4] = tonumber(t_anim[4]) + y
			if tonumber(t_anim[5]) == -1 then
				length = length + infFrame
			else
				length = length + tonumber(t_anim[5])
			end
			--optional parameters
			if t_anim[6] ~= nil and not t_anim[6]:match(facing) then --flip parameter not negated by repeated flipping
				if t_anim[6]:match('[Hh]') then t_anim[3] = t_anim[3] + 1 end --fix for wrong offset after flipping sprites
				if t_anim[6]:match('[Vv]') then t_anim[4] = t_anim[4] + 1 end --fix for wrong offset after flipping sprites
				t_anim[6] = facing .. t_anim[6]
			end
		end
		for j = 1, #t_anim do
			if j == 1 then
				anim = anim .. t_anim[j]
			else
				anim = anim .. ', ' .. t_anim[j]
			end
		end
		anim = anim .. '\n'
	end
	if defsc then main.SetDefaultScale() end
	local data = animNew(sff, anim)
	animSetScale(data, scaleX, scaleY)
	animUpdate(data)
	if defsc then main.SetScaleValues() end
	return data, length
end

--copy table content into new table
function main.f_copyTable(t)
	if t == nil then
		return nil
	end
	t = t or {}
	local t2 = {}
	for k, v in pairs(t) do
		if type(v) == "table" then
			t2[k] = main.f_copyTable(v)
		else
			t2[k] = v
		end
	end
	return t2
end

--randomizes table content
function main.f_shuffleTable(t)
	local rand = math.random
	assert(t, "main.f_shuffleTable() expected a table, got nil")
	local iterations = #t
	local j
	for i = iterations, 2, -1 do
		j = rand(i)
		t[i], t[j] = t[j], t[i]
	end
end

--iterate over the table in order
-- basic usage, just sort by the keys:
--for k, v in main.f_sortKeys(t) do
--	print(k, v)
--end
-- this uses an custom sorting function ordering by score descending
--for k, v in main.f_sortKeys(t, function(t, a, b) return t[b] < t[a] end) do
--	print(k, v)
--end
function main.f_sortKeys(t, order)
	-- collect the keys
	local keys = {}
	for k in pairs(t) do table.insert(keys, k) end
	-- if order function given, sort it by passing the table and keys a, b,
	-- otherwise just sort the keys 
	if order then
		table.sort(keys, function(a, b) return order(t, a, b) end)
	else
		table.sort(keys)
	end
	-- return the iterator function
	local i = 0
	return function()
		i = i + 1
		if keys[i] then
			return keys[i], t[keys[i]]
		end
	end
end

--remove duplicated string pattern
function main.f_uniq(str, pattern, subpattern)
	local out = {}
	for s in str:gmatch(pattern) do
		local s2 = s:match(subpattern)
		if not main.f_contains(out, s2) then table.insert(out, s) end
	end
	return table.concat(out)
end

function main.f_contains(t, val)
	for k, v in pairs(t) do
		--if v == val then
		if v:match(val) then
			return true
		end
	end
	return false
end

--calculates text line length (in pixels) for main.f_textRender
function main.f_lineLength(startX, maxWidth, align, window, windowWrap)
	local w = maxWidth
	if #window > 0 and windowWrap then
		w = window[3]
	end
	if align == 1 then --left
		return w - startX
	elseif align == 0 then --center
		return math.floor(math.min(startX - (window[1] or 0), w - startX) * 2 + 0.5)
	else --right
		return startX - (window[1] or 0)
	end
end

--draw string letter by letter + wrap lines. Returns true after finishing rendering last letter.
function main.f_textRender(data, str, counter, x, y, font_def, delay, length)
	local delay = delay or 0
	local length = length or 0
	str = tostring(str)
	local text = ''
	if length <= 0 then --auto wrapping disabled
		text = str:gsub('\\n', '\n')
	else --add \n before the word that exceeds amount of free pixels in the line
		local tmp = ''
		local pxLeft = length
		local tmp_px = 0
		local s = data.r .. data.g .. data.b .. data.src .. data.dst .. data.height
		local space = (font_def[' '] or fontGetTextWidth(main.font[data.font][s], ' ')) * data.scaleX
		for i = 1, string.len(str) do
			local symbol = string.sub(str, i, i)
			if font_def[symbol] == nil then --store symbol length in global table for faster counting
				font_def[symbol] = fontGetTextWidth(main.font[data.font][s], symbol)
			end
			local px = font_def[symbol] * data.scaleX
			if pxLeft + space - px >= 0 then
				if symbol:match('%s') then
					text = text .. tmp .. symbol
					tmp = ''
					tmp_px = 0
				else
					tmp = tmp .. symbol
					tmp_px = tmp_px + px
				end
				pxLeft = pxLeft - px
			else --character in this word is outside the pixel range
				text = text .. '\n'
				tmp = tmp .. symbol
				tmp_px = tmp_px + px
				pxLeft = length - tmp_px
				tmp_px = 0
			end
		end
		text = text .. tmp
	end
	--store each string ending with \n in new table row
	local subEnd = math.floor(#text - (#text - counter / delay))
	local t = {}
	for line in text:gmatch('([^\r\n]*)[\r\n]?') do
		table.insert(t, line)
	end
	--render
	local ret = false
	local lengthCnt = 0
	for i = 1, #t do
		if subEnd < #str then
			local length = #t[i]
			if i > 1 and i <= #t then
				length = length + 1
			end
			lengthCnt = lengthCnt + length
			if subEnd < lengthCnt then
				t[i] = t[i]:sub(0, subEnd - lengthCnt)
			end
		elseif i == #t then
			ret = true
		end
		data:update({
			text = t[i],
			x =    x,
			y =    y + math.floor(font_def.Size[2] * data.scaleY + font_def.Spacing[2] * data.scaleY + 0.5) * (i - 1),
		})
		data:draw()
	end
	return ret
end

--Convert DEF string to table
function main.f_extractText(txt, var1, var2, var3, var4)
	local t = {var1 or '', var2 or '', var3 or '', var4 or ''}
	local tmp = ''
	--replace %s, %i with variables
	local cnt = 0
	tmp = txt:gsub('(%%[is])', function(m1)
		cnt = cnt + 1
		if t[cnt] ~= nil then
			return t[cnt]
		end
	end)
	--store each line in different row
	t = {}
	tmp = tmp:gsub('\n', '\\n')
	for i, c in ipairs(main.f_strsplit('\\n', tmp)) do --split string using "\n" delimiter
		t[i] = c
	end
	if #t == 0 then
		t[1] = tmp
	end
	return t
end

--ensure that correct data type is set
function main.f_dataType(arg)
	arg = arg:gsub('^%s*(.-)%s*$', '%1')
	if tonumber(arg) then
		arg = tonumber(arg)
	elseif arg == 'true' then
		arg = true
	elseif arg == 'false' then
		arg = false
	else
		arg = tostring(arg)
	end
	return arg
end

--merge 2 tables into 1 overwriting values
function main.f_tableMerge(t1, t2)
	for k, v in pairs(t2) do
		if type(v) == "table" then
			if type(t1[k] or false) == "table" then
				main.f_tableMerge(t1[k] or {}, t2[k] or {})
			else
				t1[k] = v
			end
		elseif type(t1[k] or false) == "table" then
			t1[k][1] = v
		else
			t1[k] = v
		end
	end
	return t1
end

--return table with reversed keys
function main.f_reversedTable(t)
	local reversedTable = {}
	local itemCount = #t
	for k, v in ipairs(t) do
		reversedTable[itemCount + 1 - k] = v
	end
	return reversedTable
end

--return table with proper order and without rows disabled in screenpack
function main.f_cleanTable(t, t_sort)
	local t_clean = {}
	local t_added = {}
	--first we add all entries existing in screenpack file in correct order
	for i = 1, #t_sort do
		for j = 1, #t do
			if t_sort[i] == t[j].itemname and t[j].displayname ~= '' then
				table.insert(t_clean, t[j])
				t_added[t[j].itemname] = 1
				break
			end
		end
	end
	--then we add remaining default entries if not existing yet and not disabled (by default or via screenpack)
	for i = 1, #t do
		if t_added[t[i].itemname] == nil and t[i].displayname ~= '' then
			table.insert(t_clean, t[i])
		end
	end
	return t_clean
end

--odd value rounding
function main.f_oddRounding(v)
	if v % 2 ~= 0 then
		return 1
	else
		return 0
	end
end

--count occurrences of a substring
function main.f_countSubstring(s1, s2)
    return select(2, s1:gsub(s2, ""))
end

--warning display
function main.f_warning(t, info, background, font_info, title, coords, col, alpha, defaultscale)
	if defaultscale == nil then defaultscale = motif.defaultWarning end
	font_info = font_info or motif.warning_info
	title = title or main.txt_warningTitle
	coords = coords or motif.warning_info.boxbg_coords
	col = col or motif.warning_info.boxbg_col
	alpha = alpha or motif.warning_info.boxbg_alpha
	main.f_cmdInput()
	esc(false) --reset ESC
	while true do
		if main.input({1, 2}, {'pal'}) or esc() then
			sndPlay(motif.files.snd_data, info.cursor_move_snd[1], info.cursor_move_snd[2])
			break
		end
		--draw clearcolor
		clearColor(background.bgclearcolor[1], background.bgclearcolor[2], background.bgclearcolor[3])
		--draw layerno = 0 backgrounds
		bgDraw(background.bg, false)
		--draw layerno = 1 backgrounds
		bgDraw(background.bg, true)
		--draw menu box
		fillRect(coords[1], coords[2], coords[3] - coords[1] + 1, coords[4] - coords[2] + 1, col[1], col[2], col[3], alpha[1], alpha[2], false)
		--draw title
		title:draw()
		--draw text
		for i = 1, #t do
			main.txt_warning:update({
				font =   font_info.text_font[1],
				bank =   font_info.text_font[2],
				align =  font_info.text_font[3],
				text =   t[i],
				x =      font_info.text_pos[1],
				y =      font_info.text_pos[2] + math.floor(main.font[font_info.text_font[1]].def.Size[2] * font_info.text_font_scale[2] + main.font[font_info.text_font[1]].def.Spacing[2] * font_info.text_font_scale[2] + 0.5) * (i - 1),
				scaleX = font_info.text_font_scale[1],
				scaleY = font_info.text_font_scale[2],
				r =      font_info.text_font[4],
				g =      font_info.text_font[5],
				b =      font_info.text_font[6],
				src =    font_info.text_font[7],
				dst =    font_info.text_font[8],
				height = font_info.text_font_height,
				defsc =  defaultscale
			})
			main.txt_warning:draw()
		end
		--end loop
		main.f_cmdInput()
		refresh()
	end
end

--input display
function main.f_input(t, info, background, category, controllerNo, keyBreak)
	--main.f_cmdInput()
	category = category or 'string'
	controllerNo = controllerNo or 0
	keyBreak = keyBreak or ''
	if category == 'string' then
		table.insert(t, '')
	end
	local input = ''
	local btnReleased = 0
	resetKey()
	while true do
		if esc() then
			input = ''
			break
		end
		if category == 'keyboard' then
			input = getKey()
			if input ~= '' then
				break
			end
		elseif category == 'gamepad' then
			if getJoystickPresent(controllerNo) == false then
				break
			end
			if getKey() == keyBreak then
				input = keyBreak
				break
			end
			local tmp = getKey()
			if tonumber(tmp) == nil then --button released
				if btnReleased == 0 then
					btnReleased = 1
				elseif btnReleased == 2 then
					break
				end
			elseif btnReleased == 1 then --button pressed after releasing button once
				input = tmp
				btnReleased = 2
			end
		else --string
			if getKey() == 'RETURN' then
				break
			elseif getKey() == 'BACKSPACE' then
				input = input:match('^(.-).?$')
			else
				input = input .. getKeyText()
			end
			t[#t] = input
			resetKey()
		end
		--draw clearcolor
		clearColor(background.bgclearcolor[1], background.bgclearcolor[2], background.bgclearcolor[3])
		--draw layerno = 0 backgrounds
		bgDraw(background.bg, false)
		--draw layerno = 1 backgrounds
		bgDraw(background.bg, true)
		--draw menu box
		fillRect(
			motif.infobox.boxbg_coords[1],
			motif.infobox.boxbg_coords[2],
			motif.infobox.boxbg_coords[3] - motif.infobox.boxbg_coords[1] + 1,
			motif.infobox.boxbg_coords[4] - motif.infobox.boxbg_coords[2] + 1,
			motif.infobox.boxbg_col[1],
			motif.infobox.boxbg_col[2],
			motif.infobox.boxbg_col[3],
			motif.infobox.boxbg_alpha[1],
			motif.infobox.boxbg_alpha[2],
			false
		)
		--draw text
		for i = 1, #t do
			main.txt_input:update({
				text = t[i],
				y =    motif.infobox.text_pos[2] + math.floor(main.font[motif.infobox.text_font[1]].def.Size[2] * motif.infobox.text_font_scale[2] + main.font[motif.infobox.text_font[1]].def.Spacing[2] * motif.infobox.text_font_scale[2] + 0.5) * (i - 1),
			})
			main.txt_input:draw()
		end
		--end loop
		main.f_cmdInput()
		refresh()
	end
	main.f_cmdInput()
	return input
end

--refresh screen every 0.02 during initial loading
main.nextRefresh = os.clock() + 0.02
function main.loadingRefresh(txt)
	if os.clock() >= main.nextRefresh then
		if txt ~= nil then
			txt:draw()
		end
		refresh()
		main.nextRefresh = os.clock() + 0.02
	end
end

--;===========================================================
--; COMMAND LINE QUICK VS
--;===========================================================
main.flags = getCommandLineFlags()
if main.flags['-p1'] ~= nil and main.flags['-p2'] ~= nil then
	--load lifebar
	local def = config.Motif
	if main.flags['-r'] ~= nil then
		local case = main.flags['-r']:lower()
		if case:match('^data[/\\]') and main.f_fileExists(main.flags['-r']) then
			def = main.flags['-r']
		elseif case:match('%.def$') and main.f_fileExists('data/' .. main.flags['-r']) then
			def = 'data/' .. main.flags['-r']
		elseif main.f_fileExists('data/' .. main.flags['-r'] .. '/system.def') then
			def = 'data/' .. main.flags['-r'] .. '/system.def'
		end
	end
	local fileDir = def:match('^(.-)[^/\\]+$')
	local file = io.open(def,"r")
	local s = file:read("*all")
	file:close()
	local lifebar = s:match('fight%s*=%s*(.-%.def)%s*')
	if main.f_fileExists(lifebar) then
		loadLifebar(lifebar)
	elseif main.f_fileExists(fileDir .. lifebar) then
		loadLifebar(fileDir .. lifebar)
	elseif main.f_fileExists('data/' .. lifebar) then
		loadLifebar('data/' .. lifebar)
	else
		loadLifebar('data/fight.def')
	end
	refresh()
	--set settings
	setAutoguard(1, config.AutoGuard)
	setAutoguard(2, config.AutoGuard)
	setPowerShare(1, config.TeamPowerShare)
	setPowerShare(2, config.TeamPowerShare)
	setLifeAdjustment(config.TeamLifeAdjustment)
	setLoseKO(config.SimulLoseKO, config.TagLoseKO)
	setLifeMul(config.LifeMul / 100)
	setGameSpeed(config.GameSpeed / 100)
	setSingleVsTeamLife(config.SingleVsTeamLife / 100)
	setTurnsRecoveryRate(config.TurnsRecoveryBase / 100, config.TurnsRecoveryBonus / 100)
	--add chars
	local p1NumChars = 0
	local p2NumChars = 0
	local p1TeamMode = 0
	local p2TeamMode = 0
	local roundTime = config.RoundTime
	local t = {}
	for k, v in pairs(main.flags) do
		if k:match('^-p[0-9]+$') then
			local num = tonumber(k:match('^-p([0-9]+)'))
			local player = 1
			if num % 2 == 0 then --even value
				player = 2
				p2NumChars = p2NumChars + 1
			else
				p1NumChars = p1NumChars + 1
			end
			local pal = 1
			if main.flags['-p' .. num .. '.pal'] ~= nil then
				pal = tonumber(main.flags['-p' .. num .. '.pal'])
			end
			local ai = 0
			if main.flags['-p' .. num .. '.ai'] ~= nil then
				ai = tonumber(main.flags['-p' .. num .. '.ai'])
			end
			table.insert(t, {character = v, player = player, num = num, pal = pal, ai = ai, override = {}})
			if main.flags['-p' .. num .. '.power'] ~= nil then
				t[#t].override['power'] = tonumber(main.flags['-p' .. num .. '.power'])
			end
			if main.flags['-p' .. num .. '.life'] ~= nil then
				t[#t].override['life'] = tonumber(main.flags['-p' .. num .. '.life'])
			end
			if main.flags['-p' .. num .. '.lifeMax'] ~= nil then
				t[#t].override['lifeMax'] = tonumber(main.flags['-p' .. num .. '.lifeMax'])
			end
			if main.flags['-p' .. num .. '.lifeRatio'] ~= nil then
				t[#t].override['lifeRatio'] = tonumber(main.flags['-p' .. num .. '.lifeRatio'])
			end
			if main.flags['-p' .. num .. '.attackRatio'] ~= nil then
				t[#t].override['attackRatio'] = tonumber(main.flags['-p' .. num .. '.attackRatio'])
			end
			refresh()
		elseif k:match('^-tmode1$') then
			p1TeamMode = tonumber(v)
		elseif k:match('^-tmode2$') then
			p2TeamMode = tonumber(v)
		elseif k:match('^-time$') then
			roundTime = tonumber(v)
		elseif k:match('^-rounds$') then
			setMatchWins(tonumber(v))
		elseif k:match('^-draws$') then
			setMatchMaxDrawGames(tonumber(v))
		end
	end
	if p1TeamMode == 0 and p1NumChars > 1 then
		p1TeamMode = 1
	end
	if p2TeamMode == 0 and p2NumChars > 1 then
		p2TeamMode = 1
	end
	local frames = getFramesPerCount()
	local p1FramesMul = 1
	local p2FramesMul = 1
	if p1TeamMode == 3 then
		p1FramesMul = p1NumChars
	end
	if p2TeamMode == 3 then
		p2FramesMul = p2NumChars
	end
	frames = frames * math.max(p1FramesMul, p2FramesMul)
	setFramesPerCount(frames)
	setRoundTime(math.max(-1, roundTime * frames))
	--add stage
	local stage = 'stages/stage0.def'
	if main.flags['-s'] ~= nil then
		if main.f_fileExists(main.flags['-s']) then
			stage = main.flags['-s']
		elseif main.f_fileExists('stages/' .. main.flags['-s'] .. '.def') then
			stage = 'stages/' .. main.flags['-s'] .. '.def'
		end
	end
	addStage(stage)
	--load data
	loadDebugFont('f-6x9.fnt')
	setDebugScript('external/script/debug.lua')
	selectStart()
	setMatchNo(1)
	setStage(0)
	selectStage(0)
	setTeamMode(1, p1TeamMode, p1NumChars)
	setTeamMode(2, p2TeamMode, p2NumChars)
	if main.debugLog then main.f_printTable(t, 'debug/t_quickvs.txt') end
	--iterate over the table in -p order ascending
	for k, v in main.f_sortKeys(t, function(t, a, b) return t[b].num > t[a].num end) do
		addChar(v.character)
		selectChar(v.player, v.num - 1, v.pal)
		setCom(v.num, v.ai)
		overrideCharData(v.num, v.override)
	end
	loadStart()
	local winner, t_gameStats = game()
	if main.flags['-log'] ~= nil then
		main.f_printTable(t_gameStats, main.flags['-log'])
	end
	--exit ikemen
	return
end

--;===========================================================
--; LOAD DATA
--;===========================================================
motif = require('external.script.motif')

setMotifDir(motif.fileDir)
setPortrait(motif.select_info.p1_face_spr[1], motif.select_info.p1_face_spr[2], 1) --Big portrait
setPortrait(motif.select_info.portrait_spr[1], motif.select_info.portrait_spr[2], 2) --Small portrait
setPortrait(motif.vs_screen.p1_spr[1], motif.vs_screen.p1_spr[2], 3) --Versus portrait
setPortrait(motif.select_info.stage_portrait_spr[1], motif.select_info.stage_portrait_spr[2], 4) --Stage portrait

main.txt_warning = text:create({})
main.txt_warningTitle = text:create({
	font =   motif.warning_info.title_font[1],
	bank =   motif.warning_info.title_font[2],
	align =  motif.warning_info.title_font[3],
	text =   motif.warning_info.title,
	x =      motif.warning_info.title_pos[1],
	y =      motif.warning_info.title_pos[2],
	scaleX = motif.warning_info.title_font_scale[1],
	scaleY = motif.warning_info.title_font_scale[2],
	r =      motif.warning_info.title_font[4],
	g =      motif.warning_info.title_font[5],
	b =      motif.warning_info.title_font[6],
	src =    motif.warning_info.title_font[7],
	dst =    motif.warning_info.title_font[8],
	height = motif.warning_info.title_font_height,
	defsc =  motif.defaultWarning
})
main.txt_input = text:create({
	font =   motif.infobox.text_font[1],
	bank =   motif.infobox.text_font[2],
	align =  motif.infobox.text_font[3],
	text =   '',
	x =      motif.infobox.text_pos[1],
	y =      0,
	scaleX = motif.infobox.text_font_scale[1],
	scaleY = motif.infobox.text_font_scale[2],
	r =      motif.infobox.text_font[4],
	g =      motif.infobox.text_font[5],
	b =      motif.infobox.text_font[6],
	src =    motif.infobox.text_font[7],
	dst =    motif.infobox.text_font[8],
	height = motif.infobox.text_font_height,
	defsc =  motif.defaultInfobox
})
local txt_loading = text:create({
	font =   motif.title_info.loading_font[1],
	bank =   motif.title_info.loading_font[2],
	align =  motif.title_info.loading_font[3],
	text =   motif.title_info.loading_text,
	x =      motif.title_info.loading_offset[1],
	y =      motif.title_info.loading_offset[2],
	scaleX = motif.title_info.loading_font_scale[1],
	scaleY = motif.title_info.loading_font_scale[2],
	r =      motif.title_info.loading_font[4],
	g =      motif.title_info.loading_font[5],
	b =      motif.title_info.loading_font[6],
	src =    motif.title_info.loading_font[7],
	dst =    motif.title_info.loading_font[8],
	height = motif.title_info.loading_font_height,
	defsc =  motif.defaultLoading
})
txt_loading:draw()
refresh()

--add characters and stages using select.def
function main.f_charParam(t, c)
	if c:match('music[alv]?[li]?[tfc]?[et]?o?r?y?%s*=') then --music / musicalt / musiclife / musicvictory
		local bgmvolume, bgmloopstart, bgmloopend = 100, 0, 0
		c = c:gsub('%s+([0-9%s]+)$', function(m1)
			for i, c in ipairs(main.f_strsplit('%s+', m1)) do --split using whitespace delimiter
				if i == 1 then
					bgmvolume = tonumber(c)
				elseif i == 2 then
					bgmloopstart = tonumber(c)
				elseif i == 3 then
					bgmloopend = tonumber(c)
				else
					break
				end
			end
			return ''
		end)
		c = c:gsub('\\', '/')
		local bgtype, bgmusic = c:match('^(music[a-z]*)%s*=%s*(.-)%s*$')
		if t[bgtype] == nil then t[bgtype] = {} end
		table.insert(t[bgtype], {bgmusic = bgmusic, bgmvolume = bgmvolume, bgmloopstart = bgmloopstart, bgmloopend = bgmloopend})
	elseif c:match('lifebar%s*=') then --lifebar
		if t.lifebar == nil then
			t.lifebar = c:match('=%s*(.-)%s*$')
		end
	elseif c:match('[0-9]+%s*=%s*[^%s]') then --num = string (unused)
		local var1, var2 = c:match('([0-9]+)%s*=%s*(.+)%s*$')
		t[tonumber(var1)] = var2
	elseif c:match('%.[Dd][Ee][Ff]') then --stage
		c = c:gsub('\\', '/')
		if t.stage == nil then
			t.stage = {}
		end
		table.insert(t.stage, c)
	else --param = value
		local param, value = c:match('^(.-)%s*=%s*(.-)$')
		if param ~= nil and value ~= nil and param ~= '' and value ~= '' then
			t[param] = tonumber(value)
			if t[param] == nil then
				t[param] = value
			end
		end
	end
end

function main.f_addChar(line, row, playable, slot)
	local slot = slot or false
	local valid = false
	local tmp = ''
	main.t_selChars[row] = {}
	--parse 'rivals' param and get rid of it if exists
	for num, str in line:gmatch('([0-9]+)%s*=%s*{([^%}]-)}') do
		num = tonumber(num)
		if main.t_selChars[row].rivals == nil then
			main.t_selChars[row].rivals = {}
		end
		for i, c in ipairs(main.f_strsplit(',', str)) do --split using "," delimiter
			c = c:match('^%s*(.-)%s*$')
			if i == 1 then
				c = c:gsub('\\', '/')
				c = tostring(c)
				main.t_selChars[row].rivals[num] = {char = c}
			else
				main.f_charParam(main.t_selChars[row].rivals[num], c)
			end
		end
		line = line:gsub(',%s*' .. num .. '%s*=%s*{([^%}]-)}', '')
	end
	--parse rest of the line
	for i, c in ipairs(main.f_strsplit(',', line)) do --split using "," delimiter
		c = c:match('^%s*(.-)%s*$')
		if i == 1 then
			c = c:gsub('\\', '/')
			c = tostring(c)
			addChar(c)
			tmp = getCharName(row - 1)
			if tmp == '' then
				playable = false
				break
			end
			main.t_charDef[c:lower()] = row - 1
			main.t_selChars[row].char = c
			if tmp == 'Random' then
				playable = false
				break
			end
			valid = true
			main.t_selChars[row].playable = playable
			main.t_selChars[row].displayname = tmp
			main.t_selChars[row].def = getCharFileName(row - 1)
			main.t_selChars[row].dir = main.t_selChars[row].def:gsub('[^/]+%.def$', '')
			main.t_selChars[row].pal, main.t_selChars[row].pal_defaults, main.t_selChars[row].pal_keymap = getCharPalettes(row - 1)
			if playable then
				tmp = getCharIntro(row - 1)
				if tmp ~= '' then
					main.t_selChars[row].intro = main.t_selChars[row].dir .. tmp:gsub('\\', '/')
				end
				tmp = getCharEnding(row - 1)
				if tmp ~= '' then
					main.t_selChars[row].ending = main.t_selChars[row].dir .. tmp:gsub('\\', '/')
				end
				main.t_selChars[row].order = 1
			end
		else
			main.f_charParam(main.t_selChars[row], c)
		end
	end
	if main.t_selChars[row].hidden == nil then
		main.t_selChars[row].hidden = 0
	end
	if main.t_selChars[row].char ~= nil then
		main.t_selChars[row].char_ref = main.t_charDef[main.t_selChars[row].char:lower()]
	end
	if playable then
		--order param
		if main.t_orderChars[main.t_selChars[row].order] == nil then
			main.t_orderChars[main.t_selChars[row].order] = {}
		end
		table.insert(main.t_orderChars[main.t_selChars[row].order], row - 1)
		--ordersurvival param
		local num = 1
		if main.t_selChars[row].ordersurvival ~= nil then
			num = main.t_selChars[row].ordersurvival
		end
		if main.t_orderSurvival[num] == nil then
			main.t_orderSurvival[num] = {}
		end
		table.insert(main.t_orderSurvival[num], row - 1)
	end
	--slots
	if not slot then
		table.insert(main.t_selGrid, {['chars'] = {row}, ['slot'] = 1})
	else
		table.insert(main.t_selGrid[#main.t_selGrid].chars, row)
	end
	for _, v in ipairs({'next', 'previous', 'select'}) do
		if main.t_selChars[row][v] ~= nil then
			main.t_selChars[row][v] = main.t_selChars[row][v]:gsub('/(.)%s*+', '/%1,') --convert '+' to ',' for button holding
			main.f_commandAdd(main.t_selChars[row][v])
			if main.t_selGrid[#main.t_selGrid][v] == nil then
				main.t_selGrid[#main.t_selGrid][v] = {}
			end
			if main.t_selGrid[#main.t_selGrid][v][main.t_selChars[row][v]] == nil then
				main.t_selGrid[#main.t_selGrid][v][main.t_selChars[row][v]] = {}
			end
			table.insert(main.t_selGrid[#main.t_selGrid][v][main.t_selChars[row][v]], #main.t_selGrid[#main.t_selGrid].chars)
		end
	end
	main.loadingRefresh(txt_loading)
	return valid
end

function main.f_addStage(file)
	file = file:gsub('\\', '/')
	--if not main.f_fileExists(file) or file:match('^stages/$') then
	--	return #main.t_selStages
	--end
	addStage(file)
	local stageNo = #main.t_selStages + 1
	local tmp = getStageName(stageNo)
	--if tmp == '' then
	--	return stageNo
	--end
	main.t_stageDef[file:lower()] = stageNo
	main.t_selStages[stageNo] = {name = tmp, stage = file}
	local t_bgmusic, attachedChar = getStageInfo(stageNo)
	for k = 1, #t_bgmusic do
		if t_bgmusic[k].bgmusic ~= '' then
			if k == 1 then
				tmp = 'music'
			elseif k == 2 then
				tmp = 'musicalt'
			elseif k == 3 then
				tmp = 'musiclife'
			else
				tmp = 'musicvictory'
			end
			main.t_selStages[stageNo][tmp] = {[1] = {bgmusic = t_bgmusic[k].bgmusic:gsub('\\', '/'), bgmvolume = t_bgmusic[k].bgmvolume, bgmloopstart = t_bgmusic[k].bgmloopstart, bgmloopend = t_bgmusic[k].bgmloopend}}
		end
	end
	if attachedChar ~= '' then
		main.t_selStages[stageNo].attachedChar = {}
		main.t_selStages[stageNo].attachedChar.def, main.t_selStages[stageNo].attachedChar.displayname, main.t_selStages[stageNo].attachedChar.sprite, main.t_selStages[stageNo].attachedChar.sound = getAttachedCharInfo(attachedChar)
		main.t_selStages[stageNo].attachedChar.dir = main.t_selStages[stageNo].attachedChar.def:gsub('[^/]+%.def$', '')
	end
	return stageNo
end

main.t_includeStage = {{}, {}} --includestage = 1, includestage = -1
main.t_orderChars = {}
main.t_orderStages = {}
main.t_orderSurvival = {}
main.t_stageDef = {['random'] = 0}
main.t_charDef = {}
local t_addExluded = {}
local chars = 0
local stages = 0
local tmp = ''
local section = 0
local row = 0
local slot = false
local file = io.open(motif.files.select,"r")
local content = file:read("*all")
file:close()
content = content:gsub('([^\r\n;]*)%s*;[^\r\n]*', '%1')
content = content:gsub('\n%s*\n', '\n')
for line in content:gmatch('[^\r\n]+') do
--for line in io.lines("data/select.def") do
	local lineCase = line:lower()
	if lineCase:match('^%s*%[%s*characters%s*%]') then
		main.t_selChars = {}
		main.t_selGrid = {}
		row = 0
		section = 1
	elseif lineCase:match('^%s*%[%s*extrastages%s*%]') then
		main.t_selStages = {}
		row = 0
		section = 2
	elseif lineCase:match('^%s*%[%s*options%s*%]') then
		main.t_selOptions = {
			arcadestart = {wins = 0, offset = 0},
			arcadeend = {wins = 0, offset = 0},
			teamstart = {wins = 0, offset = 0},
			teamend = {wins = 0, offset = 0},
			survivalstart = {wins = 0, offset = 0},
			survivalend = {wins = 0, offset = 0},
			ratiostart = {wins = 0, offset = 0},
			ratioend = {wins = 0, offset = 0},
		}
		row = 0
		section = 3
	elseif section == 1 then --[Characters]
		if lineCase:match(',%s*exclude%s*=%s*1') then --character should be added after all slots are filled
			table.insert(t_addExluded, line)
		elseif lineCase:match('^%s*slot%s*=%s*{%s*$') then --start of the 'multiple chars in one slot' assignment
			table.insert(main.t_selGrid, {['chars'] = {}, ['slot'] = 1})
			slot = true
		elseif slot and lineCase:match('^%s*}%s*$') then --end of 'multiple chars in one slot' assignment
			slot = false
		else
			chars = chars + 1
			main.f_addChar(line, chars, true, slot)
		end
	elseif section == 2 then --[ExtraStages]
		for i, c in ipairs(main.f_strsplit(',', line)) do --split using "," delimiter
			c = c:gsub('^%s*(.-)%s*$', '%1')
			if i == 1 then
				row = main.f_addStage(c)
				table.insert(main.t_includeStage[1], row)
				table.insert(main.t_includeStage[2], row)
			elseif c:match('music[alv]?[li]?[tfc]?[et]?o?r?y?%s*=') then --music / musicalt / musiclife / musicvictory
				local bgmvolume, bgmloopstart, bgmloopend = 100, 0, 0
				c = c:gsub('%s+([0-9%s]+)$', function(m1)
					for i, c in ipairs(main.f_strsplit('%s+', m1)) do --split using whitespace delimiter
						if i == 1 then
							bgmvolume = tonumber(c)
						elseif i == 2 then
							bgmloopstart = tonumber(c)
						elseif i == 3 then
							bgmloopend = tonumber(c)
						else
							break
						end
					end
					return ''
				end)
				c = c:gsub('\\', '/')
				local bgtype, bgmusic = c:match('^(music[a-z]*)%s*=%s*(.-)%s*$')
				if main.t_selStages[row][bgtype] == nil then main.t_selStages[row][bgtype] = {} end
				table.insert(main.t_selStages[row][bgtype], {bgmusic = bgmusic, bgmvolume = bgmvolume, bgmloopstart = bgmloopstart, bgmloopend = bgmloopend})
			else
				local param, value = c:match('^(.-)%s*=%s*(.-)$')
				if param ~= nil and value ~= nil and param ~= '' and value ~= '' then
					main.t_selStages[row][param] = tonumber(value)
					if param:match('order') then
						if main.t_orderStages[main.t_selStages[row].order] == nil then
							main.t_orderStages[main.t_selStages[row].order] = {}
						end
						table.insert(main.t_orderStages[main.t_selStages[row].order], row)
					end
				end
			end
		end
	elseif section == 3 then --[Options]
		if lineCase:match('%.maxmatches%s*=') then
			local rowName, line = lineCase:match('^%s*(.-)%.maxmatches%s*=%s*(.+)')
			rowName = rowName:gsub('%.', '_')
			main.t_selOptions[rowName .. 'maxmatches'] = {}
			for i, c in ipairs(main.f_strsplit(',', line:gsub('%s*(.-)%s*', '%1'))) do --split using "," delimiter
				main.t_selOptions[rowName .. 'maxmatches'][i] = tonumber(c)
			end
		elseif lineCase:match('%.ratiomatches%s*=') then
			local rowName, line = lineCase:match('^%s*(.-)%.ratiomatches%s*=%s*(.+)')
			rowName = rowName:gsub('%.', '_')
			main.t_selOptions[rowName .. 'ratiomatches'] = {}
			for i, c in ipairs(main.f_strsplit(',', line:gsub('%s*(.-)%s*', '%1'))) do --split using "," delimiter
				local rmin, rmax, order = c:match('^%s*([0-9]+)-?([0-9]*)%s*:%s*([0-9]+)%s*$')
				rmin = tonumber(rmin)
				rmax = tonumber(rmax) or rmin
				order = tonumber(order)
				if rmin == nil or order == nil or rmin < 1 or rmin > 4 or rmax < 1 or rmax > 4 or rmin > rmax then
					main.f_warning(main.f_extractText(motif.warning_info.text_ratio), motif.title_info, motif.titlebgdef)
					main.t_selOptions[rowName .. 'ratiomatches'] = nil
					break
				end
				if rmax == '' then
					rmax = rmin
				end
				table.insert(main.t_selOptions[rowName .. 'ratiomatches'], {['rmin'] = rmin, ['rmax'] = rmax, ['order'] = order})
			end
		elseif lineCase:match('%.airamp%.') then
			local rowName, rowName2, wins, offset = lineCase:match('^%s*(.-)%.airamp%.(.-)%s*=%s*([0-9]+)%s*,%s*([0-9-]+)')
			main.t_selOptions[rowName .. rowName2] = {wins = tonumber(wins), offset = tonumber(offset)}
		end
	end
end

--add default maxmatches / ratiomatches values if config is missing in select.def
if main.t_selOptions.arcademaxmatches == nil then main.t_selOptions.arcademaxmatches = {6, 1, 1, 0, 0, 0, 0, 0, 0, 0} end
if main.t_selOptions.teammaxmatches == nil then main.t_selOptions.teammaxmatches = {4, 1, 1, 0, 0, 0, 0, 0, 0, 0} end
if main.t_selOptions.timeattackmaxmatches == nil then main.t_selOptions.timeattackmaxmatches = {6, 1, 1, 0, 0, 0, 0, 0, 0, 0} end
if main.t_selOptions.survivalmaxmatches == nil then main.t_selOptions.survivalmaxmatches = {-1, 0, 0, 0, 0, 0, 0, 0, 0, 0} end
if main.t_selOptions.arcaderatiomatches == nil then
	main.t_selOptions.arcaderatiomatches = {
		{['rmin'] = 1, ['rmax'] = 3, ['order'] = 1},
		{['rmin'] = 3, ['rmax'] = 3, ['order'] = 1},
		{['rmin'] = 2, ['rmax'] = 2, ['order'] = 1},
		{['rmin'] = 2, ['rmax'] = 2, ['order'] = 1},
		{['rmin'] = 1, ['rmax'] = 1, ['order'] = 2},
		{['rmin'] = 3, ['rmax'] = 3, ['order'] = 1},
		{['rmin'] = 1, ['rmax'] = 2, ['order'] = 3}
	}
end

--add excluded characters once all slots are filled
for i = #main.t_selGrid, (motif.select_info.rows + motif.select_info.rows_scrolling) * motif.select_info.columns - 1 do
	chars = chars + 1
	main.t_selChars[chars] = {}
	table.insert(main.t_selGrid, {['chars'] = {}, ['slot'] = 1})
	addChar('dummyChar')
end
for i = 1, #t_addExluded do
	chars = chars + 1
	main.f_addChar(t_addExluded[i], chars, true)
end

--add Training by stupa if not included in select.def
if main.t_charDef.training == nil and main.f_fileExists('chars/training/training.def') then
	chars = chars + 1
	main.f_addChar('training, exclude = 1', chars, false)
end

--add remaining character parameters
main.t_bossChars = {}
main.t_bonusChars = {}
main.t_randomChars = {}
--for each character loaded
for i = 1, #main.t_selChars do
	--change character 'rivals' param char and stage string file paths to reference values
	if main.t_selChars[i].rivals ~= nil then
		for j = 1, #main.t_selChars[i].rivals do
			--add 'rivals' param character if needed or reference existing one
			if main.t_selChars[i].rivals[j].char ~= nil then
				if main.t_charDef[main.t_selChars[i].rivals[j].char:lower()] == nil then --new char
					chars = chars + 1
					if main.f_addChar(main.t_selChars[i].rivals[j].char .. ', exclude = 1', chars, false) then
						main.t_selChars[i].rivals[j].char_ref = chars - 1
					else
						main.f_warning(main.f_extractText(main.t_selChars[i].rivals[j].char .. motif.warning_info.text_rivals), motif.title_info, motif.titlebgdef)
						main.t_selChars[i].rivals[j].char = nil
					end
				else --already added
					main.t_selChars[i].rivals[j].char_ref = main.t_charDef[main.t_selChars[i].rivals[j].char:lower()]
				end
			end
			--add 'rivals' param stages if needed or reference existing ones
			if main.t_selChars[i].rivals[j].stage ~= nil then
				for k = 1, #main.t_selChars[i].rivals[j].stage do
					if main.t_stageDef[main.t_selChars[i].rivals[j].stage[k]:lower()] == nil then
						main.t_selChars[i].rivals[j].stage[k] = main.f_addStage(main.t_selChars[i].rivals[j].stage[k])
					else --already added
						main.t_selChars[i].rivals[j].stage[k] = main.t_stageDef[main.t_selChars[i].rivals[j].stage[k]:lower()]
					end
				end
			end
		end
	end
	--character stage param
	if main.t_selChars[i].stage ~= nil then
		for j = 1, #main.t_selChars[i].stage do
			--add 'stage' param stages if needed or reference existing ones
			if main.t_stageDef[main.t_selChars[i].stage[j]:lower()] == nil then
				main.t_selChars[i].stage[j] = main.f_addStage(main.t_selChars[i].stage[j])
				if main.t_selChars[i].includestage == nil or main.t_selChars[i].includestage == 1 then --stage available all the time
					table.insert(main.t_includeStage[1], main.t_selChars[i].stage[j])
					table.insert(main.t_includeStage[2], main.t_selChars[i].stage[j])
				elseif main.t_selChars[i].includestage == -1 then --excluded stage that can be still manually selected
					table.insert(main.t_includeStage[2], main.t_selChars[i].stage[j])
				end
			else --already added
				main.t_selChars[i].stage[j] = main.t_stageDef[main.t_selChars[i].stage[j]:lower()]
			end
		end
	end
	--if character's name has been stored
	if main.t_selChars[i].displayname ~= nil then
		--generate table for boss rush mode
		if main.t_selChars[i].boss ~= nil and main.t_selChars[i].boss == 1 then
			table.insert(main.t_bossChars, i - 1)
		end
		--generate table for bonus games mode
		if main.t_selChars[i].bonus ~= nil and main.t_selChars[i].bonus == 1 then
			table.insert(main.t_bonusChars, i - 1)
		end
		--generate table with characters allowed to be random selected
		if main.t_selChars[i].playable and (main.t_selChars[i].hidden == nil or main.t_selChars[i].hidden <= 1) and (main.t_selChars[i].exclude == nil or main.t_selChars[i].exclude == 0) then
			table.insert(main.t_randomChars, i - 1)
		end
	end
end

--Save debug tables
if main.debugLog then
	main.f_printTable(main.t_selChars, "debug/t_selChars.txt")
	main.f_printTable(main.t_selStages, "debug/t_selStages.txt")
	main.f_printTable(main.t_selOptions, "debug/t_selOptions.txt")
	main.f_printTable(main.t_orderChars, "debug/t_orderChars.txt")
	main.f_printTable(main.t_orderStages, "debug/t_orderStages.txt")
	main.f_printTable(main.t_orderSurvival, "debug/t_orderSurvival.txt")
	main.f_printTable(main.t_randomChars, "debug/t_randomChars.txt")
	main.f_printTable(main.t_bossChars, "debug/t_bossChars.txt")
	main.f_printTable(main.t_bonusChars, "debug/t_bonusChars.txt")
	main.f_printTable(main.t_stageDef, "debug/t_stageDef.txt")
	main.f_printTable(main.t_charDef, "debug/t_charDef.txt")
	main.f_printTable(main.t_includeStage, "debug/t_includeStage.txt")
	main.f_printTable(main.t_selGrid, "debug/t_selGrid.txt")
	main.f_printTable(config, "debug/config.txt")
end

--Debug stuff
loadDebugFont(motif.files.debug_font)
setDebugScript(motif.files.debug_script)

--Assign Lifebar
txt_loading:draw()
refresh()
loadLifebar(motif.files.fight)
main.loadingRefresh(txt_loading)

--print warning if training character is missing
if main.t_charDef.training == nil then
	main.f_warning(main.f_extractText(motif.warning_info.text_training), motif.title_info, motif.titlebgdef)
	os.exit()
end

--print warning if no characters can be randomly chosen
if #main.t_randomChars == 0 then
	main.f_warning(main.f_extractText(motif.warning_info.text_chars), motif.title_info, motif.titlebgdef)
	os.exit()
end

--print warning if no stages have been added
if #main.t_includeStage[1] == 0 then
	main.f_warning(main.f_extractText(motif.warning_info.text_stages), motif.title_info, motif.titlebgdef)
	os.exit()
end

--print warning if at least 1 match is not possible with the current maxmatches settings
for k, v in pairs(main.t_selOptions) do
	local mode = k:match('^(.+)maxmatches$')
	if mode ~= nil then
		local orderOK = false
		for i = 1, #main.t_selOptions[k] do
			if mode == 'survival' and (main.t_selOptions[k][i] > 0 or main.t_selOptions[k][i] == -1) and main.t_orderSurvival[i] ~= nil and #main.t_orderSurvival[i] > 0 then
				orderOK = true
				break
			elseif main.t_selOptions[k][i] > 0 and main.t_orderChars[i] ~= nil and #main.t_orderChars[i] > 0 then
				orderOK = true
				break
			end
		end
		if not orderOK then
			main.f_warning(main.f_extractText(motif.warning_info.text_order), motif.title_info, motif.titlebgdef)
			os.exit()
		end
	end
end

--Load additional scripts
randomtest = require('external.script.randomtest')
options = require('external.script.options')
start = require('external.script.start')
storyboard = require('external.script.storyboard')

--;===========================================================
--; MENUS
--;===========================================================
local txt_titleFooter1 = text:create({
	font =   motif.title_info.footer1_font[1],
	bank =   motif.title_info.footer1_font[2],
	align =  motif.title_info.footer1_font[3],
	text =   motif.title_info.footer1_text,
	x =      motif.title_info.footer1_offset[1],
	y =      motif.title_info.footer1_offset[2],
	scaleX = motif.title_info.footer1_font_scale[1],
	scaleY = motif.title_info.footer1_font_scale[2],
	r =      motif.title_info.footer1_font[4],
	g =      motif.title_info.footer1_font[5],
	b =      motif.title_info.footer1_font[6],
	src =    motif.title_info.footer1_font[7],
	dst =    motif.title_info.footer1_font[8],
	height = motif.title_info.footer1_font_height,
	defsc =  motif.defaultFooter
})
local txt_titleFooter2 = text:create({
	font =   motif.title_info.footer2_font[1],
	bank =   motif.title_info.footer2_font[2],
	align =  motif.title_info.footer2_font[3],
	text =   motif.title_info.footer2_text,
	x =      motif.title_info.footer2_offset[1],
	y =      motif.title_info.footer2_offset[2],
	scaleX = motif.title_info.footer2_font_scale[1],
	scaleY = motif.title_info.footer2_font_scale[2],
	r =      motif.title_info.footer2_font[4],
	g =      motif.title_info.footer2_font[5],
	b =      motif.title_info.footer2_font[6],
	src =    motif.title_info.footer2_font[7],
	dst =    motif.title_info.footer2_font[8],
	height = motif.title_info.footer2_font_height,
	defsc =  motif.defaultFooter
})
local txt_titleFooter3 = text:create({
	font =   motif.title_info.footer3_font[1],
	bank =   motif.title_info.footer3_font[2],
	align =  motif.title_info.footer3_font[3],
	text =   motif.title_info.footer3_text,
	x =      motif.title_info.footer3_offset[1],
	y =      motif.title_info.footer3_offset[2],
	scaleX = motif.title_info.footer3_font_scale[1],
	scaleY = motif.title_info.footer3_font_scale[2],
	r =      motif.title_info.footer3_font[4],
	g =      motif.title_info.footer3_font[5],
	b =      motif.title_info.footer3_font[6],
	src =    motif.title_info.footer3_font[7],
	dst =    motif.title_info.footer3_font[8],
	height = motif.title_info.footer3_font_height,
	defsc =  motif.defaultFooter
})
local txt_infoboxTitle = text:create({
	font =   motif.infobox.title_font[1],
	bank =   motif.infobox.title_font[2],
	align =  motif.infobox.title_font[3],
	text =   motif.infobox.title,
	x =      motif.infobox.title_pos[1],
	y =      motif.infobox.title_pos[2],
	scaleX = motif.infobox.title_font_scale[1],
	scaleY = motif.infobox.title_font_scale[2],
	r =      motif.infobox.title_font[4],
	g =      motif.infobox.title_font[5],
	b =      motif.infobox.title_font[6],
	src =    motif.infobox.title_font[7],
	dst =    motif.infobox.title_font[8],
	height = motif.infobox.title_font_height,
	defsc =  motif.defaultInfobox
})

main.txt_mainSelect = text:create({
	font =   motif.select_info.title_font[1],
	bank =   motif.select_info.title_font[2],
	align =  motif.select_info.title_font[3],
	text =   '',
	x =      motif.select_info.title_offset[1],
	y =      motif.select_info.title_offset[2],
	scaleX = motif.select_info.title_font_scale[1],
	scaleY = motif.select_info.title_font_scale[2],
	r =      motif.select_info.title_font[4],
	g =      motif.select_info.title_font[5],
	b =      motif.select_info.title_font[6],
	src =    motif.select_info.title_font[7],
	dst =    motif.select_info.title_font[8],
	height = motif.select_info.title_font_height,
})

main.reconnect = false
main.serverhost = false
main.t_itemname = {
	--ARCADE / TEAM ARCADE
	['arcade'] = function(cursorPosY, moveTxt, item, t)
		if main.playerInput ~= 1 then
			remapInput(1, main.playerInput)
			remapInput(main.playerInput, 1)
		end
		main.p2In = 1 --P1 controls P2 side of the select screen
		main.resetScore = true --score is set to lose count after loosing a match
		main.versusScreen = true --versus screen enabled
		main.victoryScreen = true --victory screen enabled
		main.t_charparam.stage = true
		main.t_charparam.music = true
		main.t_charparam.ai = true
		main.t_charparam.rounds = true
		main.t_charparam.time = true
		main.t_charparam.onlyme = true
		main.t_charparam.rivals = true
		main.t_lifebar.p1score = true
		main.t_lifebar.p2ai = true
		main.resultsTable = motif.win_screen
		main.credits = config.Credits - 1 --amount of continues
		if t[item].itemname == 'arcade' then
			main.p1TeamMenu = {mode = 0, chars = 1} --predefined P1 team mode as Single, 1 Character
			main.p2TeamMenu = {mode = 0, chars = 1} --predefined P2 team mode as Single, 1 Character
			main.txt_mainSelect:update({text = motif.select_info.title_text_arcade}) --message displayed on top of select screen
		else --teamarcade
			main.txt_mainSelect:update({text = motif.select_info.title_text_teamarcade})
		end
		sndPlay(motif.files.snd_data, motif.title_info.cursor_done_snd[1], motif.title_info.cursor_done_snd[2])
		main.f_menuFade('title_info', 'fadeout', cursorPosY, moveTxt, item, t)
		setGameMode('arcade')
		start.f_selectArcade()
	end,
	--TIME ATTACK
	['timeattack'] = function(cursorPosY, moveTxt, item, t)
		if main.playerInput ~= 1 then
			remapInput(1, main.playerInput)
			remapInput(main.playerInput, 1)
		end
		main.p2In = 1
		if main.roundTime == -1 then
			main.roundTime = 99
		end
		main.resetScore = true
		main.quickContinue = true
		main.versusScreen = true
		main.t_charparam.stage = true
		main.t_charparam.music = true
		main.t_charparam.ai = true
		main.t_charparam.rounds = true
		main.t_charparam.time = true
		main.t_charparam.onlyme = true
		main.t_lifebar.timer = true
		main.t_lifebar.p2ai = true
		main.resultsTable = motif.time_attack_results_screen
		main.credits = config.Credits - 1
		main.txt_mainSelect:update({text = motif.select_info.title_text_timeattack})
		sndPlay(motif.files.snd_data, motif.title_info.cursor_done_snd[1], motif.title_info.cursor_done_snd[2])
		main.f_menuFade('title_info', 'fadeout', cursorPosY, moveTxt, item, t)
		setGameMode('timeattack')
		start.f_selectArcade()
	end,
	--TIME CHALLENGE
	['timechallenge'] = function(cursorPosY, moveTxt, item, t)
		if main.playerInput ~= 1 then
			remapInput(1, main.playerInput)
			remapInput(main.playerInput, 1)
		end
		main.p2In = 1
		main.matchWins = {1, 0, 0}
		if main.roundTime == -1 then
			main.roundTime = 99
		end
		main.stageMenu = true
		main.p2Faces = true
		main.p2SelectMenu = true
		main.versusScreen = true
		--uses default main.t_charparam assignment
		main.t_lifebar.timer = true
		main.t_lifebar.p2ai = true
		main.resultsTable = motif.time_challenge_results_screen
		main.p1TeamMenu = {mode = 0, chars = 1}
		main.p2TeamMenu = {mode = 0, chars = 1}
		main.txt_mainSelect:update({text = motif.select_info.title_text_timechallenge})
		sndPlay(motif.files.snd_data, motif.title_info.cursor_done_snd[1], motif.title_info.cursor_done_snd[2])
		main.f_menuFade('title_info', 'fadeout', cursorPosY, moveTxt, item, t)
		setGameMode('timechallenge')
		start.f_selectSimple()
	end,
	--SCORE CHALLENGE
	['scorechallenge'] = function(cursorPosY, moveTxt, item, t)
		if main.playerInput ~= 1 then
			remapInput(1, main.playerInput)
			remapInput(main.playerInput, 1)
		end
		main.p2In = 1
		main.matchWins = {1, 0, 0}
		main.stageMenu = true
		main.p2Faces = true
		main.p2SelectMenu = true
		main.versusScreen = true
		--uses default main.t_charparam assignment
		main.t_lifebar.p1score = true
		main.t_lifebar.p2ai = true
		main.resultsTable = motif.score_challenge_results_screen
		main.p1TeamMenu = {mode = 0, chars = 1}
		main.p2TeamMenu = {mode = 0, chars = 1}
		main.txt_mainSelect:update({text = motif.select_info.title_text_scorechallenge})
		sndPlay(motif.files.snd_data, motif.title_info.cursor_done_snd[1], motif.title_info.cursor_done_snd[2])
		main.f_menuFade('title_info', 'fadeout', cursorPosY, moveTxt, item, t)
		setGameMode('scorechallenge')
		start.f_selectSimple()
	end,
	--VS MODE / TEAM VERSUS
	['versus'] = function(cursorPosY, moveTxt, item, t)
		setHomeTeam(1) --P1 side considered the home team
		main.p2In = 2 --P2 controls P2 side of the select screen
		main.stageMenu = true --stage selection enabled
		main.p2Faces = true --additional window with P2 select screen small portraits (faces) enabled
		main.p2SelectMenu = true
		main.versusScreen = true
		main.victoryScreen = true
		--uses default main.t_charparam assignment
		main.t_lifebar.p1score = true
		main.t_lifebar.p2score = true
		if t[item].itemname == 'versus' then
			main.p1TeamMenu = {mode = 0, chars = 1} --predefined P1 team mode as Single, 1 Character
			main.p2TeamMenu = {mode = 0, chars = 1} --predefined P2 team mode as Single, 1 Character
			main.txt_mainSelect:update({text = motif.select_info.title_text_versus})
		else --teamversus
			main.txt_mainSelect:update({text = motif.select_info.title_text_teamversus})
		end
		sndPlay(motif.files.snd_data, motif.title_info.cursor_done_snd[1], motif.title_info.cursor_done_snd[2])
		main.f_menuFade('title_info', 'fadeout', cursorPosY, moveTxt, item, t)
		setGameMode('versus')
		start.f_selectSimple()
	end,
	--TEAM CO-OP
	['teamcoop'] = function(cursorPosY, moveTxt, item, t)
		main.p2In = 2
		main.coop = true --P2 fighting on P1 side enabled
		main.p2Faces = true
		main.p2SelectMenu = true
		main.resetScore = true
		main.versusScreen = true
		main.victoryScreen = true
		main.t_charparam.stage = true
		main.t_charparam.music = true
		main.t_charparam.ai = true
		main.t_charparam.rounds = true
		main.t_charparam.time = true
		main.t_charparam.onlyme = true
		main.t_charparam.rivals = true
		main.t_lifebar.p1score = true
		main.t_lifebar.p2ai = true
		main.resultsTable = motif.win_screen
		main.credits = config.Credits - 1
		main.txt_mainSelect:update({text = motif.select_info.title_text_teamcoop})
		sndPlay(motif.files.snd_data, motif.title_info.cursor_done_snd[1], motif.title_info.cursor_done_snd[2])
		main.f_menuFade('title_info', 'fadeout', cursorPosY, moveTxt, item, t)
		setGameMode('teamcoop')
		start.f_selectArcade()
	end,
	--SURVIVAL
	['survival'] = function(cursorPosY, moveTxt, item, t)
		if main.playerInput ~= 1 then
			remapInput(1, main.playerInput)
			remapInput(main.playerInput, 1)
		end
		main.p2In = 1
		main.matchWins = {1, 0, 0}
		main.versusScreen = true
		main.t_charparam.stage = true
		main.t_charparam.music = true
		main.t_charparam.ai = true
		main.t_charparam.time = true
		main.t_charparam.onlyme = true
		main.t_lifebar.match = true
		main.t_lifebar.p2ai = true
		main.resultsTable = motif.survival_results_screen
		main.txt_mainSelect:update({text = motif.select_info.title_text_survival})
		sndPlay(motif.files.snd_data, motif.title_info.cursor_done_snd[1], motif.title_info.cursor_done_snd[2])
		main.f_menuFade('title_info', 'fadeout', cursorPosY, moveTxt, item, t)
		setGameMode('survival')
		start.f_selectArranged()
	end,
	--SURVIVAL CO-OP
	['survivalcoop'] = function(cursorPosY, moveTxt, item, t)
		main.p2In = 2
		main.matchWins = {1, 0, 0}
		main.coop = true
		main.p2Faces = true
		main.p2SelectMenu = true
		main.versusScreen = true
		main.t_charparam.stage = true
		main.t_charparam.music = true
		main.t_charparam.ai = true
		main.t_charparam.time = true
		main.t_charparam.onlyme = true
		main.t_lifebar.match = true
		main.t_lifebar.p2ai = true
		main.resultsTable = motif.survival_results_screen
		main.txt_mainSelect:update({text = motif.select_info.title_text_survivalcoop})
		sndPlay(motif.files.snd_data, motif.title_info.cursor_done_snd[1], motif.title_info.cursor_done_snd[2])
		main.f_menuFade('title_info', 'fadeout', cursorPosY, moveTxt, item, t)
		setGameMode('survivalcoop')
		start.f_selectArranged()
	end,
	--TRAINING
	['training'] = function(cursorPosY, moveTxt, item, t)
		if main.playerInput ~= 1 then
			remapInput(1, main.playerInput)
			remapInput(main.playerInput, 1)
		end
		main.p2In = 2
		main.stageMenu = true
		main.p2SelectMenu = true
		main.roundTime = -1
		--uses default main.t_charparam assignment
		main.t_lifebar.p1score = true
		main.p2TeamMenu = {mode = 0, chars = 1} --predefined P2 team mode as Single, 1 Character
		main.p2Char = {main.t_charDef.training} --predefined P2 character as Training by stupa
		main.txt_mainSelect:update({text = motif.select_info.title_text_training})
		sndPlay(motif.files.snd_data, motif.title_info.cursor_done_snd[1], motif.title_info.cursor_done_snd[2])
		main.f_menuFade('title_info', 'fadeout', cursorPosY, moveTxt, item, t)
		setGameMode('training')
		start.f_selectSimple()
	end,
	--WATCH
	['watch'] = function(cursorPosY, moveTxt, item, t)
		if main.playerInput ~= 1 then
			remapInput(1, main.playerInput)
			remapInput(main.playerInput, 1)
		end
		main.p2In = 1
		main.aiFight = true --AI = config.Difficulty for all characters enabled
		main.stageMenu = true
		main.p2Faces = true
		main.p2SelectMenu = true
		main.versusScreen = true
		--uses default main.t_charparam assignment
		main.t_lifebar.p1ai = true
		main.t_lifebar.p2ai = true
		main.txt_mainSelect:update({text = motif.select_info.title_text_watch})
		sndPlay(motif.files.snd_data, motif.title_info.cursor_done_snd[1], motif.title_info.cursor_done_snd[2])
		main.f_menuFade('title_info', 'fadeout', cursorPosY, moveTxt, item, t)
		setGameMode('watch')
		start.f_selectSimple()
	end,
	--OPTIONS
	['options'] = function(cursorPosY, moveTxt, item, t)
		sndPlay(motif.files.snd_data, motif.title_info.cursor_done_snd[1], motif.title_info.cursor_done_snd[2])
		main.f_menuFade('title_info', 'fadeout', cursorPosY, moveTxt, item, t)
		options.menu.loop()
	end,
	--FREE BATTLE
	['freebattle'] = function(cursorPosY, moveTxt, item, t)
		if main.playerInput ~= 1 then
			remapInput(1, main.playerInput)
			remapInput(main.playerInput, 1)
		end
		main.p2In = 1
		main.stageMenu = true
		main.p2Faces = true
		main.p2SelectMenu = true
		main.versusScreen = true
		--uses default main.t_charparam assignment
		main.t_lifebar.p1score = true
		main.t_lifebar.p2ai = true
		main.txt_mainSelect:update({text = motif.select_info.title_text_freebattle})
		sndPlay(motif.files.snd_data, motif.title_info.cursor_done_snd[1], motif.title_info.cursor_done_snd[2])
		main.f_menuFade('title_info', 'fadeout', cursorPosY, moveTxt, item, t)
		setGameMode('freebattle')
		start.f_selectSimple()
	end,
	--VS 100 KUMITE
	['vs100kumite'] = function(cursorPosY, moveTxt, item, t)
		if main.playerInput ~= 1 then
			remapInput(1, main.playerInput)
			remapInput(main.playerInput, 1)
		end
		main.p2In = 1
		main.matchWins = {1, 0, 0}
		main.versusScreen = true
		main.t_charparam.stage = true
		main.t_charparam.music = true
		main.t_charparam.ai = true
		main.t_charparam.time = true
		main.t_charparam.onlyme = true
		main.t_lifebar.match = true
		main.t_lifebar.p2ai = true
		main.resultsTable = motif.vs100_kumite_results_screen
		main.txt_mainSelect:update({text = motif.select_info.title_text_vs100kumite})
		sndPlay(motif.files.snd_data, motif.title_info.cursor_done_snd[1], motif.title_info.cursor_done_snd[2])
		main.f_menuFade('title_info', 'fadeout', cursorPosY, moveTxt, item, t)
		setGameMode('vs100kumite')
		start.f_selectArranged()
	end,
	--BOSS RUSH
	['bossrush'] = function(cursorPosY, moveTxt, item, t)
		if main.playerInput ~= 1 then
			remapInput(1, main.playerInput)
			remapInput(main.playerInput, 1)
		end
		main.p2In = 1
		main.versusScreen = true
		main.t_charparam.stage = true
		main.t_charparam.music = true
		main.t_charparam.ai = true
		main.t_charparam.time = true
		main.t_charparam.onlyme = true
		main.t_lifebar.match = true
		main.t_lifebar.p2ai = true
		main.resultsTable = motif.boss_rush_results_screen
		main.txt_mainSelect:update({text = motif.select_info.title_text_bossrush})
		sndPlay(motif.files.snd_data, motif.title_info.cursor_done_snd[1], motif.title_info.cursor_done_snd[2])
		main.f_menuFade('title_info', 'fadeout', cursorPosY, moveTxt, item, t)
		setGameMode('bossrush')
		start.f_selectArranged()
	end,
	--REPLAY
	['replay'] = function(cursorPosY, moveTxt, item, t)
		if main.f_fileExists('save/replays/netplay.replay') then
			sndPlay(motif.files.snd_data, motif.title_info.cursor_done_snd[1], motif.title_info.cursor_done_snd[2])
			enterReplay('save/replays/netplay.replay')
			synchronize()
			math.randomseed(sszRandom())
			--main.menu.submenu.server.loop()
			local f = main.f_checkSubmenu(main.menu.submenu.server, 2)
			if f ~= '' then
				main.f_default()
				main.t_itemname[f](cursorPosY, moveTxt, item, t)
				--resetRemapInput()
			end
			exitNetPlay()
			exitReplay()
		end
	end,
	--DEMO
	['randomtest'] = function(cursorPosY, moveTxt, item, t)
		sndPlay(motif.files.snd_data, motif.title_info.cursor_done_snd[1], motif.title_info.cursor_done_snd[2])
		main.f_menuFade('title_info', 'fadeout', cursorPosY, moveTxt, item, t)
		clearColor(motif.titlebgdef.bgclearcolor[1], motif.titlebgdef.bgclearcolor[2], motif.titlebgdef.bgclearcolor[3])
		setGameMode('randomtest')
		randomtest.run()
		main.f_bgReset(motif.titlebgdef.bg)
		main.f_playBGM(true, motif.music.title_bgm, motif.music.title_bgm_loop, motif.music.title_bgm_volume, motif.music.title_bgm_loopstart, motif.music.title_bgm_loopend)
	end,
	--TOURNAMENT ROUND OF 32
	['tournament32'] = function(cursorPosY, moveTxt, item, t)
		main.versusScreen = true
		main.t_charparam.stage = true
		main.t_charparam.music = true
		main.t_charparam.ai = true
		main.t_charparam.rounds = true
		main.t_charparam.time = true
		main.t_charparam.onlyme = true
		main.txt_mainSelect:update({text = motif.select_info.title_text_tournament32})
		sndPlay(motif.files.snd_data, motif.title_info.cursor_done_snd[1], motif.title_info.cursor_done_snd[2])
		main.f_menuFade('title_info', 'fadeout', cursorPosY, moveTxt, item, t)
		setGameMode('tournament')
		start.f_selectTournament(32)
	end,
	--TOURNAMENT ROUND OF 16
	['tournament16'] = function(cursorPosY, moveTxt, item, t)
		main.versusScreen = true
		main.t_charparam.stage = true
		main.t_charparam.music = true
		main.t_charparam.ai = true
		main.t_charparam.rounds = true
		main.t_charparam.time = true
		main.t_charparam.onlyme = true
		main.txt_mainSelect:update({text = motif.select_info.title_text_tournament16})
		sndPlay(motif.files.snd_data, motif.title_info.cursor_done_snd[1], motif.title_info.cursor_done_snd[2])
		main.f_menuFade('title_info', 'fadeout', cursorPosY, moveTxt, item, t)
		setGameMode('tournament')
		start.f_selectTournament(16)
	end,
	--TOURNAMENT QUARTERFINALS
	['tournament8'] = function(cursorPosY, moveTxt, item, t)
		main.versusScreen = true
		main.t_charparam.stage = true
		main.t_charparam.music = true
		main.t_charparam.ai = true
		main.t_charparam.rounds = true
		main.t_charparam.time = true
		main.t_charparam.onlyme = true
		main.txt_mainSelect:update({text = motif.select_info.title_text_tournament8})
		sndPlay(motif.files.snd_data, motif.title_info.cursor_done_snd[1], motif.title_info.cursor_done_snd[2])
		main.f_menuFade('title_info', 'fadeout', cursorPosY, moveTxt, item, t)
		setGameMode('tournament')
		start.f_selectTournament(8)
	end,
	--HOST
	['serverhost'] = function(cursorPosY, moveTxt, item, t)
		main.serverhost = true
		main.f_connect("", main.f_extractText(motif.title_info.connecting_host_text, getListenPort()))
		local f = main.f_checkSubmenu(main.menu.submenu.server, 2)
		if f ~= '' then
			main.f_default()
			main.t_itemname[f](cursorPosY, moveTxt, item, t)
			--resetRemapInput()
		end
		exitNetPlay()
		exitReplay()
		--save replay with a new name
		local file = io.open("save/replays/netplay.replay", "r")
		local tpmFile = file:read("*all")
		io.close(file)
		file = io.open("save/replays/" .. os.date("%Y-%m(%b)-%d %I-%M%p-%Ss") .. ".replay", "w+")
		file:write(tpmFile)
		io.close(file)
	end,
	--NEW ADDRESS
	['joinadd'] = function(cursorPosY, moveTxt, item, t)
		sndPlay(motif.files.snd_data, motif.title_info.cursor_move_snd[1], motif.title_info.cursor_move_snd[2])
		local name = main.f_input(main.f_extractText(motif.title_info.input_ip_name_text), motif.title_info, motif.titlebgdef, 'string')
		if name ~= '' then
			sndPlay(motif.files.snd_data, motif.title_info.cursor_move_snd[1], motif.title_info.cursor_move_snd[2])
			local address = main.f_input(main.f_extractText(motif.title_info.input_ip_address_text), motif.title_info, motif.titlebgdef, 'string')
			if address:match('^[0-9%.]+$') then
				sndPlay(motif.files.snd_data, motif.title_info.cursor_done_snd[1], motif.title_info.cursor_done_snd[2])
				config.IP[name] = address
				table.insert(t, #t, {data = text:create({}), itemname = 'ip_' .. name, displayname = name})
				local file = io.open("save/config.json","w+")
				file:write(json.encode(config, {indent = true}))
				file:close()
			else
				sndPlay(motif.files.snd_data, motif.title_info.cancel_snd[1], motif.title_info.cancel_snd[2])
			end
		else
			sndPlay(motif.files.snd_data, motif.title_info.cancel_snd[1], motif.title_info.cancel_snd[2])
		end
	end,
	--ONLINE VERSUS
	['netplayversus'] = function(cursorPosY, moveTxt, item, t)
		setHomeTeam(1)
		main.p2In = 2
		main.stageMenu = true
		main.p2Faces = true
		main.p2SelectMenu = true
		main.versusScreen = true
		main.victoryScreen = true
		--uses default main.t_charparam assignment
		main.t_lifebar.p1score = true
		main.t_lifebar.p2score = true
		main.txt_mainSelect:update({text = motif.select_info.title_text_netplayversus})
		sndPlay(motif.files.snd_data, motif.title_info.cursor_done_snd[1], motif.title_info.cursor_done_snd[2])
		main.f_menuFade('title_info', 'fadeout', cursorPosY, moveTxt, item, t)
		setGameMode('netplayversus')
		start.f_selectSimple()
	end,
	--ONLINE CO-OP
	['netplayteamcoop'] = function(cursorPosY, moveTxt, item, t)
		main.p2In = 2
		main.coop = true
		main.p2Faces = true
		main.p2SelectMenu = true
		main.resetScore = true
		main.versusScreen = true
		main.victoryScreen = true
		main.t_charparam.stage = true
		main.t_charparam.music = true
		main.t_charparam.ai = true
		main.t_charparam.rounds = true
		main.t_charparam.time = true
		main.t_charparam.onlyme = true
		main.t_charparam.rivals = true
		main.t_lifebar.p1score = true
		main.t_lifebar.p2ai = true
		main.resultsTable = motif.win_screen
		main.credits = config.Credits - 1
		main.txt_mainSelect:update({text = motif.select_info.title_text_netplayteamcoop})
		sndPlay(motif.files.snd_data, motif.title_info.cursor_done_snd[1], motif.title_info.cursor_done_snd[2])
		main.f_menuFade('title_info', 'fadeout', cursorPosY, moveTxt, item, t)
		setGameMode('netplayteamcoop')
		start.f_selectArcade()
	end,
	--ONLINE SURVIVAL
	['netplaysurvivalcoop'] = function(cursorPosY, moveTxt, item, t)
		main.p2In = 2
		main.matchWins = {1, 0, 0}
		main.coop = true
		main.p2Faces = true
		main.p2SelectMenu = true
		main.versusScreen = true
		main.t_charparam.stage = true
		main.t_charparam.music = true
		main.t_charparam.ai = true
		main.t_charparam.time = true
		main.t_charparam.onlyme = true
		main.t_lifebar.match = true
		main.t_lifebar.p2ai = true
		main.resultsTable = motif.survival_results_screen
		main.txt_mainSelect:update({text = motif.select_info.title_text_netplaysurvivalcoop})
		sndPlay(motif.files.snd_data, motif.title_info.cursor_done_snd[1], motif.title_info.cursor_done_snd[2])
		main.f_menuFade('title_info', 'fadeout', cursorPosY, moveTxt, item, t)
		setGameMode('netplaysurvivalcoop')
		start.f_selectArranged()
	end,
	--BONUS CHAR
	['bonus'] = function(cursorPosY, moveTxt, item, t)
		if main.playerInput ~= 1 then
			remapInput(1, main.playerInput)
			remapInput(main.playerInput, 1)
		end
		main.p2In = 1
		main.p2SelectMenu = true
		main.t_charparam.stage = true
		main.t_charparam.music = true
		main.t_charparam.ai = true
		main.t_charparam.rounds = true
		main.t_charparam.time = true
		main.t_charparam.onlyme = true
		main.p1TeamMenu = {mode = 0, chars = 1}
		main.p2TeamMenu = {mode = 0, chars = 1}
		main.p2Char = {main.t_bonusChars[item]}
		main.txt_mainSelect:update({text = getCharName(main.t_bonusChars[item])})
		sndPlay(motif.files.snd_data, motif.title_info.cursor_done_snd[1], motif.title_info.cursor_done_snd[2])
		main.f_menuFade('title_info', 'fadeout', cursorPosY, moveTxt, item, t)
		setGameMode('bonus')
		start.f_selectSimple()
	end,
	--CONNECT
	['connect'] = function(cursorPosY, moveTxt, item, t)
		main.serverhost = false
		main.f_connect(config.IP[t[item].displayname], main.f_extractText(motif.title_info.connecting_join_text, t[item].displayname, config.IP[t[item].displayname]))
		local f = main.f_checkSubmenu(main.menu.submenu.server, 2)
		if f ~= '' then
			main.f_default()
			main.t_itemname[f](cursorPosY, moveTxt, item, t)
			--resetRemapInput()
		end
		exitNetPlay()
		exitReplay()
	end,
}
main.t_itemname.teamarcade = main.t_itemname.arcade
main.t_itemname.teamversus = main.t_itemname.versus
if main.debugLog then main.f_printTable(main.t_itemname, 'debug/t_mainItemname.txt') end

function main.f_deleteIP(item, t)
	if t[item].itemname:match('^ip_') then
		sndPlay(motif.files.snd_data, motif.title_info.cancel_snd[1], motif.title_info.cancel_snd[2])
		resetKey()
		config.IP[t[item].itemname:gsub('^ip_', '')] = nil
		local file = io.open("save/config.json","w+")
		file:write(json.encode(config, {indent = true}))
		file:close()
		for i = 1, #t do
			if t[i].itemname == t[item].itemname then
				table.remove(t, i)
				break
			end
		end
	end
end

--open submenu
function main.f_checkSubmenu(t, minimum)
	local minimum = minimum or 0
	if t == nil then return '' end
	local cnt = 0
	local f = ''
	local skip = false
	for k, v in ipairs(t.items) do
		if v.itemname:match('^bonus_') or v.itemname == 'joinadd' then
			skip = true
			break
		elseif v.itemname ~= 'back' then
			f = v.itemname
			cnt = cnt + 1
		end
	end
	if cnt >= minimum or skip then
		sndPlay(motif.files.snd_data, motif.title_info.cursor_done_snd[1], motif.title_info.cursor_done_snd[2])
		t.loop()
		f = ''
	end
	return f
end

function main.createMenu(tbl, bool_bgreset, bool_storyboard, bool_demo, bool_escsnd, bool_f1, bool_del)
	return function()
		--main.f_cmdInput()
		local cursorPosY = 1
		local moveTxt = 0
		local item = 1
		local t = tbl.items
		if bool_storyboard then
			if motif.files.logo_storyboard ~= '' then
				storyboard.f_storyboard(motif.files.logo_storyboard)
			end
			if motif.files.intro_storyboard ~= '' then
				storyboard.f_storyboard(motif.files.intro_storyboard)
			end
		end
		if bool_bgreset then
			main.f_bgReset(motif.titlebgdef.bg)
			main.f_playBGM(true, motif.music.title_bgm, motif.music.title_bgm_loop, motif.music.title_bgm_volume, motif.music.title_bgm_loopstart, motif.music.title_bgm_loopend)
		end
		while true do
			main.f_menuCommonDraw(cursorPosY, moveTxt, item, t)
			if bool_demo then
				main.f_demo(cursorPosY, moveTxt, item, t)
			end
			cursorPosY, moveTxt, item = main.f_menuCommonCalc(cursorPosY, moveTxt, item, t)
			if esc() then
				if bool_escsnd then
					sndPlay(motif.files.snd_data, motif.title_info.cancel_snd[1], motif.title_info.cancel_snd[2])
				end
				break
			elseif bool_f1 and getKey() == 'F1' then
				main.f_warning(
					main.f_extractText(motif.infobox.text),
					motif.title_info,
					motif.titlebgdef,
					motif.infobox,
					txt_infoboxTitle,
					motif.infobox.boxbg_coords,
					motif.infobox.boxbg_col,
					motif.infobox.boxbg_alpha,
					motif.defaultInfobox
				)
			elseif bool_del and getKey() == 'DELETE' then
				main.f_deleteIP(item, t)
			else
				main.playerInput = 0
				if main.input({1}, main.f_extractKeys(motif.title_info.menu_key_accept)) then
					main.playerInput = 1
				elseif main.input({2}, main.f_extractKeys(motif.title_info.menu_key_accept)) then
					main.playerInput = 2
				end
				if main.playerInput > 0 then
					demoFrameCounter = 0
					local f = main.f_checkSubmenu(tbl.submenu[t[item].itemname], 2)
					if f == '' then
						if t[item].itemname:match('^bonus_') then
							f = 'bonus'
						elseif t[item].itemname:match('^ip_') then
							f = 'connect'
						else
							f = t[item].itemname
						end
					end
					if f == 'back' then
						sndPlay(motif.files.snd_data, motif.title_info.cancel_snd[1], motif.title_info.cancel_snd[2])
						break
					elseif f == 'exit' then
						break
					elseif main.t_itemname[f] ~= nil then
						main.f_default()
						main.t_itemname[f](cursorPosY, moveTxt, item, t)
						main.f_default()
					end
				end
			end
		end
	end
end

--dynamically generates all main screen menus and submenus using itemname data stored in main.t_sort table
main.menu = {['submenu'] = {}, ['items'] = {}}
main.menu.loop = main.createMenu(main.menu, true, true, true, false, true, false)
local t_menuWindow = {
	0,
	math.max(0, motif.title_info.menu_pos[2] - motif.title_info.menu_window_margins_y[1]),
	motif.info.localcoord[1],
	math.min(motif.info.localcoord[2], motif.title_info.menu_pos[2] + (motif.title_info.menu_window_visibleitems - 1) * motif.title_info.menu_item_spacing[2] + motif.title_info.menu_window_margins_y[2])
}
local t_pos = {} --for storing current main.menu table position
local t_skipGroup = {}
local lastNum = 0
for i = 1, #main.t_sort.title_info do
	for j, c in ipairs(main.f_strsplit('_', main.t_sort.title_info[i])) do --split using "_" delimiter
		--exceptions for expanding the menu table
		if motif.title_info['menu_itemname_' .. main.t_sort.title_info[i]] == '' and c ~= 'server' then --items and groups without displayname are skipped
			t_skipGroup[c] = true
			break
		elseif t_skipGroup[c] then --named item but inside a group without displayname
			break
		elseif c == 'bossrush' and #main.t_bossChars == 0 then --skip boss rush mode if there are no characters with boss param set to 1
			break
		elseif c == 'bonusgames' and #main.t_bonusChars == 0 then --skip bonus mode if there are no characters with bonus param set to 1
			t_skipGroup[c] = true
			break
		end
		--appending the menu table
		if j == 1 then --first string after menu.itemname (either reserved one or custom submenu assignment)
			if main.menu.submenu[c] == nil then
				main.menu.submenu[c] = {['submenu'] = {}, ['items'] = {}}
				main.menu.submenu[c].loop = main.createMenu(main.menu.submenu[c], false, false, false, true, true, c == 'serverjoin')
				if not main.t_sort.title_info[i]:match(c .. '_') then
					table.insert(main.menu.items, {data = text:create({window = t_menuWindow}), itemname = c, displayname = motif.title_info['menu_itemname_' .. main.t_sort.title_info[i]]})
				end
			end
			t_pos = main.menu.submenu[c]
		else --following strings
			if t_pos.submenu[c] == nil then
				t_pos.submenu[c] = {['submenu'] = {}, ['items'] = {}}
				t_pos.submenu[c].loop = main.createMenu(t_pos.submenu[c], false, false, false, true, true, c == 'serverjoin')
				table.insert(t_pos.items, {data = text:create({window = t_menuWindow}), itemname = c, displayname = motif.title_info['menu_itemname_' .. main.t_sort.title_info[i]]})
			end
			if j > lastNum then
				t_pos = t_pos.submenu[c]
			end
		end
		lastNum = j
		--add bonus character names to bonusgames submenu
		if main.t_sort.title_info[i]:match('_bonusgames_back$') and c == 'bonusgames' then --j == main.f_countSubstring(main.t_sort.title_info[i], '_') then
			for k = 1, #main.t_bonusChars do
				local name = getCharName(main.t_bonusChars[k])
				table.insert(t_pos.items, {data = text:create({window = t_menuWindow}), itemname = 'bonus_' .. name:gsub('%s+', '_'), displayname = name:upper()})
			end
		end
		--add IP addresses for serverjoin submenu
		if main.t_sort.title_info[i]:match('_serverjoin_back$') and c == 'serverjoin' then --j == main.f_countSubstring(main.t_sort.title_info[i], '_') then
			for k, v in pairs(config.IP) do
				table.insert(t_pos.items, {data = text:create({window = t_menuWindow}), itemname = 'ip_' .. k, displayname = k})
			end
		end
	end
end
if main.debugLog then main.f_printTable(main.menu, 'debug/t_mainMenu.txt') end

local demoFrameCounter = 0
local introWaitCycles = 0
function main.f_default()
	main.matchWins = {main.roundsNumSingle, main.roundsNumTeam, main.maxDrawGames}
	main.roundTime = config.RoundTime --default round time
	main.p1Char = nil --no predefined P1 character (assigned via table: {X, Y, (...)})
	main.p2Char = nil --no predefined P2 character (assigned via table: {X, Y, (...)})
	main.p1TeamMenu = nil --no predefined P1 team mode (assigned via table: {mode = X, chars = Y})
	main.p2TeamMenu = nil --no predefined P2 team mode (assigned via table: {mode = X, chars = Y})
	main.aiFight = false --AI = config.Difficulty for all characters disabled
	main.stageMenu = false --stage selection disabled
	main.p2Faces = false --additional window with P2 select screen small portraits (faces) disabled
	main.coop = false --P2 fighting on P1 side disabled
	main.p2SelectMenu = false --P2 character selection disabled
	main.resetScore = false --score is not set to lose count after loosing a match
	main.quickContinue = false --continue without char selection enforcement disabled 
	main.versusScreen = false --versus screen disabled
	main.victoryScreen = false --victory screen disabled
	main.resultsTable = nil --no results table reference
	main.f_resetCharparam()
	main.f_resetLifebar()
	main.p1In = 1 --P1 controls P1 side of the select screen
	main.p2In = 2 --P2 controls P2 side of the select screen
	demoFrameCounter = 0
	setAutoLevel(false) --generate autolevel.txt in game dir
	setHomeTeam(2) --P2 side considered the home team: http://mugenguild.com/forum/topics/ishometeam-triggers-169132.0.html
	setConsecutiveWins(1, 0)
	setConsecutiveWins(2, 0)
	setGameMode('')
	setAutoguard(1, config.AutoGuard)
	setAutoguard(2, config.AutoGuard)
	setPowerShare(1, config.TeamPowerShare)
	setPowerShare(2, config.TeamPowerShare)
	setLifeAdjustment(config.TeamLifeAdjustment)
	setLoseKO(config.SimulLoseKO, config.TagLoseKO)
	setDemoTime(motif.demo_mode.fight_endtime)
	setLifeMul(config.LifeMul / 100)
	setGameSpeed(config.GameSpeed / 100)
	setSingleVsTeamLife(config.SingleVsTeamLife / 100)
	setTurnsRecoveryRate(config.TurnsRecoveryBase / 100, config.TurnsRecoveryBonus / 100)
	setFramesPerCount(main.framesPerCount)
	setRoundTime(math.max(-1, main.roundTime * main.framesPerCount))
	resetRemapInput()
end

function main.f_resetCharparam()
	main.t_charparam = {
		stage = false,
		music = false,
		ai = false,
		vsscreen = true,
		winscreen = true,
		rounds = false,
		time = false,
		lifebar = true,
		onlyme = false,
		rivals = false,
	}
end

function main.f_resetLifebar()
	main.t_lifebar = {
		timer = false,
		p1score = false,
		p2score = false,
		match = false,
		p1ai = false,
		p2ai = false,
		mode = true,
		bars = true,
		lifebar = true,
	}
	setLifeBarElements(main.t_lifebar)
end

function main.f_demo(cursorPosY, moveTxt, item, t, fadeType)
	if motif.demo_mode.enabled == 0 then
		return
	end
	demoFrameCounter = demoFrameCounter + 1
	if demoFrameCounter < motif.demo_mode.title_waittime then
		return
	end
	main.f_default()
	main.f_menuFade('demo_mode', 'fadeout', cursorPosY, moveTxt, item, t)
	clearColor(motif.titlebgdef.bgclearcolor[1], motif.titlebgdef.bgclearcolor[2], motif.titlebgdef.bgclearcolor[3])
	if motif.demo_mode.fight_playbgm == 1 or motif.demo_mode.fight_stopbgm == 1 then
		setAllowBGM(true)
	else
		setAllowBGM(false)
	end
	if motif.demo_mode.fight_bars_display == 1 then
		setLifeBarElements({['bars'] = true})
	else
		setLifeBarElements({['bars'] = false})
	end
	if motif.demo_mode.debuginfo == 0 and config.DebugKeys then
		setAllowDebugKeys(false)
	end
	setGameMode('demo')
	randomtest.run()
	setAllowBGM(true)
	setAllowDebugKeys(config.DebugKeys)
	refresh()
	--intro
	if introWaitCycles >= motif.demo_mode.intro_waitcycles then
		if motif.files.intro_storyboard ~= '' then
			storyboard.f_storyboard(motif.files.intro_storyboard)
		end
		introWaitCycles = 0
	else
		introWaitCycles = introWaitCycles + 1
	end
	main.f_bgReset(motif.titlebgdef.bg)
	--start title BGM only if it has been interrupted
	if motif.demo_mode.fight_stopbgm == 1 or motif.demo_mode.fight_playbgm == 1 or (introWaitCycles == 0 and motif.files.intro_storyboard ~= '') then
		main.f_playBGM(true, motif.music.title_bgm, motif.music.title_bgm_loop, motif.music.title_bgm_volume, motif.music.title_bgm_loopstart, motif.music.title_bgm_loopend)
	end
	main.f_menuFade('demo_mode', 'fadein', cursorPosY, moveTxt, item, t)
end

function main.f_menuCommonCalc(cursorPosY, moveTxt, item, t)
	if main.input({1, 2}, main.f_extractKeys(motif.title_info.menu_key_previous)) then
		sndPlay(motif.files.snd_data, motif.title_info.cursor_move_snd[1], motif.title_info.cursor_move_snd[2])
		item = item - 1
		demoFrameCounter = 0
		introWaitCycles = 0
	elseif main.input({1, 2}, main.f_extractKeys(motif.title_info.menu_key_next)) then
		sndPlay(motif.files.snd_data, motif.title_info.cursor_move_snd[1], motif.title_info.cursor_move_snd[2])
		item = item + 1
		demoFrameCounter = 0
		introWaitCycles = 0
	end
	--cursor position calculation
	if item < 1 then
		item = #t
		if #t > motif.title_info.menu_window_visibleitems then
			cursorPosY = motif.title_info.menu_window_visibleitems
		else
			cursorPosY = #t
		end
	elseif item > #t then
		item = 1
		cursorPosY = 1
	elseif main.input({1, 2}, main.f_extractKeys(motif.title_info.menu_key_previous)) and cursorPosY > 1 then
		cursorPosY = cursorPosY - 1
	elseif main.input({1, 2}, main.f_extractKeys(motif.title_info.menu_key_next)) and cursorPosY < motif.title_info.menu_window_visibleitems then
		cursorPosY = cursorPosY + 1
	end
	if cursorPosY == motif.title_info.menu_window_visibleitems then
		moveTxt = (item - motif.title_info.menu_window_visibleitems) * motif.title_info.menu_item_spacing[2]
	elseif cursorPosY == 1 then
		moveTxt = (item - 1) * motif.title_info.menu_item_spacing[2]
	end
	return cursorPosY, moveTxt, item
end

function main.f_menuCommonDraw(cursorPosY, moveTxt, item, t, fadeType, fadeData)
	fadeType = fadeType or 'fadein'
	fadeData = fadeData or 'title_info'
	--draw clearcolor
	clearColor(motif.titlebgdef.bgclearcolor[1], motif.titlebgdef.bgclearcolor[2], motif.titlebgdef.bgclearcolor[3])
	--draw layerno = 0 backgrounds
	bgDraw(motif.titlebgdef.bg, false)
	--draw menu items
	local items_shown = item + motif.title_info.menu_window_visibleitems - cursorPosY
	if motif.title_info.menu_window_visibleitems > 1 and items_shown < #t then
		items_shown = items_shown + 1
	end
	if items_shown > #t then
		items_shown = #t
	end
	for i = 1, items_shown do
		if i > item - cursorPosY then
			if i == item then
				t[i].data:update({
					font =   motif.title_info.menu_item_active_font[1],
					bank =   motif.title_info.menu_item_active_font[2],
					align =  motif.title_info.menu_item_active_font[3],
					text =   t[i].displayname,
					x =      motif.title_info.menu_pos[1],
					y =      motif.title_info.menu_pos[2] + (i - 1) * motif.title_info.menu_item_spacing[2] - moveTxt,
					scaleX = motif.title_info.menu_item_active_font_scale[1],
					scaleY = motif.title_info.menu_item_active_font_scale[2],
					r =      motif.title_info.menu_item_active_font[4],
					g =      motif.title_info.menu_item_active_font[5],
					b =      motif.title_info.menu_item_active_font[6],
					src =    motif.title_info.menu_item_active_font[7],
					dst =    motif.title_info.menu_item_active_font[8],
					height = motif.title_info.menu_item_active_font_height,
				})
				t[i].data:draw()
			else
				t[i].data:update({
					font =   motif.title_info.menu_item_font[1],
					bank =   motif.title_info.menu_item_font[2],
					align =  motif.title_info.menu_item_font[3],
					text =   t[i].displayname,
					x =      motif.title_info.menu_pos[1],
					y =      motif.title_info.menu_pos[2] + (i - 1) * motif.title_info.menu_item_spacing[2] - moveTxt,
					scaleX = motif.title_info.menu_item_font_scale[1],
					scaleY = motif.title_info.menu_item_font_scale[2],
					r =      motif.title_info.menu_item_font[4],
					g =      motif.title_info.menu_item_font[5],
					b =      motif.title_info.menu_item_font[6],
					src =    motif.title_info.menu_item_font[7],
					dst =    motif.title_info.menu_item_font[8],
					height = motif.title_info.menu_item_font_height,
				})
				t[i].data:draw()
			end
		end
	end
	--draw menu cursor
	if motif.title_info.menu_boxcursor_visible == 1 and not main.fadeActive then
		local src, dst = main.f_boxcursorAlpha(
			motif.title_info.menu_boxcursor_alpharange[1],
			motif.title_info.menu_boxcursor_alpharange[2],
			motif.title_info.menu_boxcursor_alpharange[3],
			motif.title_info.menu_boxcursor_alpharange[4],
			motif.title_info.menu_boxcursor_alpharange[5],
			motif.title_info.menu_boxcursor_alpharange[6]
		)
		fillRect(
			motif.title_info.menu_pos[1] + motif.title_info.menu_boxcursor_coords[1],
			motif.title_info.menu_pos[2] + motif.title_info.menu_boxcursor_coords[2] + (cursorPosY - 1) * motif.title_info.menu_item_spacing[2],
			motif.title_info.menu_boxcursor_coords[3] - motif.title_info.menu_boxcursor_coords[1] + 1,
			motif.title_info.menu_boxcursor_coords[4] - motif.title_info.menu_boxcursor_coords[2] + 1 + main.f_oddRounding(motif.title_info.menu_boxcursor_coords[2]),
			motif.title_info.menu_boxcursor_col[1],
			motif.title_info.menu_boxcursor_col[2],
			motif.title_info.menu_boxcursor_col[3],
			src,
			dst,
			motif.defaultLocalcoord --for some reason can't be false on winmugen screenpack, no idea why
		)
	end
	--draw layerno = 1 backgrounds
	bgDraw(motif.titlebgdef.bg, true)
	--footer draw
	if motif.title_info.footer_boxbg_visible == 1 then
		fillRect(
			motif.title_info.footer_boxbg_coords[1],
			motif.title_info.footer_boxbg_coords[2],
			motif.title_info.footer_boxbg_coords[3] - motif.title_info.footer_boxbg_coords[1] + 1,
			motif.title_info.footer_boxbg_coords[4] - motif.title_info.footer_boxbg_coords[2] + 1,
			motif.title_info.footer_boxbg_col[1],
			motif.title_info.footer_boxbg_col[2],
			motif.title_info.footer_boxbg_col[3],
			motif.title_info.footer_boxbg_alpha[1],
			motif.title_info.footer_boxbg_alpha[2],
			motif.defaultLocalcoord
		)
	end
	txt_titleFooter1:draw()
	txt_titleFooter2:draw()
	txt_titleFooter3:draw()
	--draw fadein / fadeout
	main.fadeActive = fadeScreen(
		fadeType,
		main.fadeStart,
		motif[fadeData][fadeType .. '_time'],
		motif[fadeData][fadeType .. '_col'][1],
		motif[fadeData][fadeType .. '_col'][2],
		motif[fadeData][fadeType .. '_col'][3]
	)
	--frame transition
	if main.fadeActive then
		commandBufReset(main.cmd[1])
		commandBufReset(main.cmd[2])
	elseif fadeType == 'fadeout' then
		commandBufReset(main.cmd[1])
		commandBufReset(main.cmd[2])
		return --skip last frame rendering
	else
		main.f_cmdInput()
	end
	refresh()
end

main.fadeActive = false
function main.f_menuFade(screen, fadeType, cursorPosY, moveTxt, item, t)
	main.fadeStart = getFrameCount()
	while true do
		if screen == 'title_info' then
			main.f_menuCommonDraw(cursorPosY, moveTxt, item, t, fadeType)
		elseif screen == 'option_info' then
			options.f_menuCommonDraw(cursorPosY, moveTxt, item, t, fadeType)
		elseif screen == 'demo_mode' then
			main.f_menuCommonDraw(cursorPosY, moveTxt, item, t, fadeType, 'demo_mode')
		end
		if not main.fadeActive then
			break
		end
	end
end

function main.f_bgReset(data)
	alpha1cur = 0
	alpha2cur = 0
	alpha1add = true
	alpha2add = true
	bgReset(data)
	main.fadeStart = getFrameCount()
end

function main.f_playBGM(interrupt, bgm, bgmLoop, bgmVolume, bgmLoopstart, bgmLoopend)
	local bgm = bgm or ''
	local bgmLoop = bgmLoop or 1
	local bgmVolume = bgmVolume or 100
	local bgmLoopstart = bgmLoopstart or 0
	local bgmLoopend = bgmLoopend or 0
	if interrupt or bgm ~= '' then
		playBGM(bgm, true, bgmLoop, bgmVolume, bgmLoopstart, bgmLoopend)
	end
end

local txt_connecting = text:create({
	font =   motif.title_info.connecting_font[1],
	bank =   motif.title_info.connecting_font[2],
	align =  motif.title_info.connecting_font[3],
	text =   '',
	x =      motif.title_info.connecting_offset[1],
	y =      motif.title_info.connecting_offset[2],
	scaleX = motif.title_info.connecting_font_scale[1],
	scaleY = motif.title_info.connecting_font_scale[2],
	r =      motif.title_info.connecting_font[4],
	g =      motif.title_info.connecting_font[5],
	b =      motif.title_info.connecting_font[6],
	src =    motif.title_info.connecting_font[7],
	dst =    motif.title_info.connecting_font[8],
	height = motif.title_info.connecting_font_height,
	defsc =  motif.defaultConnecting
})

function main.f_connect(server, t)
	local cancel = false
	enterNetPlay(server)
	while not connected() do
		if esc() then
			sndPlay(motif.files.snd_data, motif.title_info.cancel_snd[1], motif.title_info.cancel_snd[2])
			cancel = true
			break
		end
		--draw clearcolor
		clearColor(motif.titlebgdef.bgclearcolor[1], motif.titlebgdef.bgclearcolor[2], motif.titlebgdef.bgclearcolor[3])
		--draw layerno = 0 backgrounds
		bgDraw(motif.titlebgdef.bg, false)
		--draw layerno = 1 backgrounds
		bgDraw(motif.titlebgdef.bg, true)
		--draw menu box
		fillRect(
			motif.title_info.connecting_boxbg_coords[1],
			motif.title_info.connecting_boxbg_coords[2],
			motif.title_info.connecting_boxbg_coords[3] - motif.title_info.connecting_boxbg_coords[1] + 1,
			motif.title_info.connecting_boxbg_coords[4] - motif.title_info.connecting_boxbg_coords[2] + 1,
			motif.title_info.connecting_boxbg_col[1],
			motif.title_info.connecting_boxbg_col[2],
			motif.title_info.connecting_boxbg_col[3],
			motif.title_info.connecting_boxbg_alpha[1],
			motif.title_info.connecting_boxbg_alpha[2],
			false
		)
		--draw text
		for i = 1, #t do
			txt_connecting:update({text = t[i]})
			txt_connecting:draw()
		end
		--end loop
		refresh()
	end
	main.f_cmdInput()
	if not cancel then
		synchronize()
		math.randomseed(sszRandom())
	end
end

--;===========================================================
--; INITIALIZE LOOPS
--;===========================================================
--SetGCPercent(100)
main.menu.loop()

-- Debug Info
--if main.debugLog then main.f_printTable(main, "debug/t_main.txt") end
