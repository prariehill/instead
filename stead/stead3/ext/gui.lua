-- sdl-instead specific methods

local std = stead

local instead = std.obj { nam = '@instead' }

local iface = std '@iface'
local type = std.type

local dict = {}

iface.inv_delim = '\n'
iface.hinv_delim = ' | '
iface.ways_delim = ' | '

local function get_bool(o, nam)
	if type(o[nam]) == 'boolean' then
		return o[nam]
	end
	if type(o[nam]) == 'function' then
		return o:nam()
	end
	return nil
end

iface.notitle = false

instead.get_title = std.cacheable('title', function()
	if get_bool(iface, 'notitle') then
		return
	end
	return iface:fmt(std.titleof(stead.here()), false)
end)

iface.noways = false

instead.get_ways = std.cacheable('ways', function()
	if get_bool(iface, 'noways') then
		return
	end
	local str = iface:cmd("way");
	if str then
		str = std.string.gsub(str, '\n$','');
		str = std.string.gsub(str, '\\?['..std.delim ..']',
			{ [std.delim] = iface.ways_delim, [ '\\'..std.delim ] = std.delim });
		return iface:center(str);
	end
	return str
end)

iface.noinv = false

instead.get_inv = std.cacheable('inv', function(horiz)
	if get_bool(iface, 'noinv') then
		return
	end
	local str = iface:cmd("inv");
	if str then
		str = std.string.gsub(str, '\n$','');
		if not horiz then
			str = std.string.gsub(str, '\\?['.. std.delim ..']',
				{ [std.delim] = iface.inv_delim, ['\\'..std.delim] = std.delim });
		else
			str = std.string.gsub(str, '\\?['.. std.delim ..']',
				{ [std.delim] = iface.hinv_delim, ['\\'..std.delim] = std.delim });
		end
	end
	return str
end)

iface.nopic = false

instead.get_picture = std.cacheable('pic', function()
	if get_bool(iface, 'nopic') then
		return
	end
	local s = stead.call(std.here(), 'pic')
	if not s then
		s = stead.call(std.ref 'game', 'pic')
	end
	return s and std.tostr(s)
end)

local last_picture

function instead.get_fading()
	if not iface.fading or iface.fading == 0 then
		return false
	end
	if type(iface.fading) == 'function' then
		local n = iface:fading()
		if not n or n == 0 then return false end
		return true, n
	end

	return true, iface.fading
end

instead.fading = 4 -- default fading

function iface:fading()
	local pic = instead.get_picture()
	if std.me():moved() or std.cmd[1] == 'load' or pic ~= last_picture then
		last_picture = pic
		return instead.fading
	end
end

function instead.get_restart()
	return instead.__restart or false
end


function instead.get_menu()
	return instead.__menu
end

function instead.isEnableSave()
	local s = get_bool(instead, 'nosave')
	if instead.get_autosave() then
		return true
	end
	return not s
end

function instead.isEnableAutosave()
	return not get_bool(instead, 'noautosave')
end

function instead.autosave(slot)
	instead.__autosave = true
	instead.__autosave_slot = slot
end

function instead.get_autosave()
	return instead.__autosave or false, instead.__autosave_slot
end

function instead.menu(n)
	if n == nil then
		n = 'main'
	elseif type(n) ~= 'string' then
		n = 'toggle'
	end
	instead.__menu = n
end

function instead.restart(v)
	instead.__restart = (v == false) and false or true
end

function iface:title() -- hide title
	return
end

std.stat = std.class({
	__stat_type = true;
}, std.obj);

std.menu = std.class({
	__menu_type = true;
	new = function(self, v)
		if type(v) ~= 'table' then
			std.err ("Wrong argument to std.menu:"..std.tostr(v), 2)
		end
		v = std.obj(v)
		std.setmt(v, self)
		return v
	end;
	inv = function(s, ...)
		local r, v = std.call(s, 'act', ...)
		if r ~= nil then
			return r, v
		end
		return true, false -- menu mode
	end;
}, std.obj);

function iface:esc(str)
	str = str:gsub("\\?[\\<>]", { ['\\\\'] = '\\\\\\\\\\', ['>'] = iface:nb('>'), ['<'] = iface:nb('<') })
	return str
end

function iface:xref(str, o, ...)
	if type(str) ~= 'string' then
		std.err ("Wrong parameter to iface:xref: "..std.tostr(str), 2)
	end
	if not std.is_obj(o) or std.is_obj(o, 'stat') then
		return str
	end
	local a = { ... }
	local args = ''
	for i = 1, #a do
		if type(a[i]) ~= 'string' and type(a[i]) ~= 'number' then
			std.err ("Wrong argument to iface:xref: "..std.tostr(a[i]), 2)
		end
		args = args .. ' '..std.dump(a[i])
	end
	local xref = std.string.format("%s%s", std.deref_str(o), args)
	-- std.string.format("%s%s", iface:esc(std.deref_str(o)), iface:esc(args))

	table.insert(dict, xref)
	xref = std.tostr(#dict)

	if std.cmd[1] == 'way' then
		return std.string.format("<a:go %s>", xref)..str.."</a>"
	elseif o:type 'menu' or std.is_system(o) then
		return std.string.format("<a:act %s>", xref)..str.."</a>"
	elseif std.cmd[1] == 'inv' then
		return std.string.format("<a:%s>", xref)..str.."</a>"
	end
	return std.string.format("<a:obj/act %s>", xref)..str.."</a>"
end

function iface:em(str)
	if type(str) == 'string' then
		return '<i>'..str..'</i>'
	end
end

function iface:center(str)
	if type(str) == 'string' then
		return '<c>'..str..'</c>'
	end
end

function iface:just(str)
	if type(str) == 'string' then
		return '<j>'..str..'</j>'
	end
end

function iface:left(str)
	if type(str) == 'string' then
		return '<l>'..str..'</l>'
	end
end

function iface:right(str)
	if type(str) == 'string' then
		return '<r>'..str..'</r>'
	end
end

function iface:bold(str)
	if type(str) == 'string' then
		return '<b>'..str..'</b>'
	end
end

function iface:top(str)
	if type(str) == 'string' then
		return '<t>'..str..'</t>'
	end
end

function iface:bottom(str)
	if type(str) == 'string' then
		return '<d>'..str..'</d>'
	end
end

function iface:middle(str)
	if type(str) == 'string' then
		return '<m>'..str..'</m>'
	end
end

function iface:nb(str)
	if type(str) == 'string' then
		return "<w:"..str:gsub("\\", "\\\\\\\\"):gsub(">","\\>"):gsub("%^","\\^")..">";
	end
end

function iface:anchor()
	return '<a:#>'
end

function iface:img(str)
	if str then
		return "<g:"..std.tostr(str)..">"
	end
end;

function iface:imgl(str)
	if str then
		return "<g:"..std.tostr(str).."\\|left>"
	end
end;

function iface:imgr(str)
	if str then
		return "<g:"..std.tostr(str).."\\|right>"
	end
end

function iface:under(str)
	if type(str) == 'string' then
		return "<u>"..str.."</u>"
	end
end;

function iface:st(str)
	if type(str) == 'string' then
		return "<s>"..str.."</s>"
	end
end

function iface:tab(str, al)
	if type(str) == 'number' then
		str = std.tostr(str)
	end
	if type(str) ~= 'string' then
		return
	end
	if al == 'right' then
		str = str .. ",right"
	elseif al == 'center' then
		str = str .. ",center"
	end
	return '<x:'..str..'>'
end

function iface:y(str, al)
	if stead.tonum(str) then
		str = stead.tostr(str)
	end
	if stead.type(str) ~= 'string' then
		return nil;
	end
	if al == 'middle' then
		str = str .. ",middle"
	elseif al == 'top' then
		str = str .. ",top"
	end
	return '<y:'..str..'>'
end;

function iface:input(event, ...)
	local input = std.ref '@input'
	if type(input) ~= 'table' then
		return
	end
	if event == 'kbd' then
		if type(input.key) == 'function' then
			return input:key(...); -- pressed, event
		end
	elseif event == 'mouse' then
		if type(input.click) == 'function' then
			return input:click(...); -- pressed, x, y, mb
		end
	elseif event == 'finger' then
		if type(input.finger) == 'function' then
			return input:finger(...); -- pressed, x, y, finger
		end
	elseif event == 'event' then
		if type(input.event) == 'function' then
			return input:event(...);
		end
	end
	return
end

local iface_cmd = iface.cmd -- save old

function iface:cmd(inp)
	local a = std.split(inp)
	if a[1] == 'act' or a[1] == 'use' or a[1] == 'go' then
		if a[1] == 'use' then
			local use = std.split(a[2], ',')
			for i = 1, 2 do
				local u = std.tonum(use[i])
				if u then
					use[i] = dict[u]
				end
			end
			a[2] = std.join(use, ',')
		elseif std.tonum(a[2]) then
			a[2] = dict[std.tonum(a[2])]
		end
		inp = std.join(a)
	end
	return iface_cmd(self, inp)
end

std.obj { -- input object
	nam = '@input';
};

-- some aliases
menu = std.menu
stat = std.stat
txt = iface

std.mod_init(function()
	std.rawset(_G, 'instead', instead)
	require "ext/sandbox"
end)
std.mod_step(function(state)
	if state then
		dict = {}
	end
end)
std.mod_done(function()
	last_picture = nil
end)

std.mod_save(function()
	instead.__autosave = nil
	instead.__autosave_slot = nil
end)

if DEBUG then
	require 'dbg'
end