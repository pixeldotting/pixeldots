-- Executes the Hyprland Lua config against a strict mock of the documented `hl` API.
local confdir = assert(arg[1], "usage: harness.lua <confdir>")
package.path = confdir .. "/?.lua;" .. package.path

local calls, errors = {}, {}
local function rec(name) return function(...) calls[#calls+1] = {name, ...}; return {name = name} end end

local function ns(prefix, names)
  local t = {}
  for _, n in ipairs(names) do t[n] = rec(prefix .. "." .. n) end
  return setmetatable(t, {__index = function(_, k) error("UNKNOWN API: hl." .. prefix .. "." .. tostring(k), 2) end})
end

local top = {}
for _, n in ipairs{"env","monitor","config","curve","animation","bind","on","exec_cmd","gesture","window_rule","layer_rule","workspace_rule","device","timer","permission","define_submap"} do
  top[n] = function(...) calls[#calls+1] = {n, ...}; return setmetatable({}, {__index=function() return function() end end}) end
end
top.dsp = setmetatable({
  exec_cmd = rec("dsp.exec_cmd"), focus = rec("dsp.focus"), layout = rec("dsp.layout"),
  submap = rec("dsp.submap"), global = rec("dsp.global"), pass = rec("dsp.pass"),
  exit = rec("dsp.exit"), dpms = rec("dsp.dpms"),
  window = ns("dsp.window", {"close","kill","fullscreen","fullscreen_state","float","pin","center","move","resize","drag","pseudo","swap","cycle_next"}),
  workspace = ns("dsp.workspace", {"toggle_special","rename","move"}),
  group = ns("dsp.group", {"toggle","next","prev","active"}),
  cursor = ns("dsp.cursor", {"move_to_corner","move"}),
}, {__index = function(_, k) error("UNKNOWN API: hl.dsp." .. tostring(k), 2) end})
hl = setmetatable(top, {__index = function(_, k) error("UNKNOWN API: hl." .. tostring(k), 2) end})

local startHooks = {}
local origOn = top.on
top.on = function(ev, fn) calls[#calls+1] = {"on", ev}; if ev == "hyprland.start" then startHooks[#startHooks+1] = fn end end

local function run(label)
  calls = {}
  local ok, err = pcall(dofile, confdir .. "/hyprland.lua")
  for _, f in ipairs(startHooks) do local ok2, e2 = pcall(f); if not ok2 then ok, err = false, e2 end end
  startHooks = {}
  local counts = {}
  for _, c in ipairs(calls) do counts[c[1]] = (counts[c[1]] or 0) + 1 end
  local names = {}
  for k in pairs(counts) do names[#names+1] = k end
  table.sort(names)
  local parts = {}
  for _, k in ipairs(names) do parts[#parts+1] = k .. "=" .. counts[k] end
  print(label .. ": " .. (ok and "OK" or ("FAIL -> " .. tostring(err))))
  print("  calls: " .. table.concat(parts, " "))
  return ok
end

-- also dump all exec_cmd strings and bind keys for eyeballing
local function dump()
  for _, c in ipairs(calls) do
    if c[1] == "exec_cmd" then print("  exec_cmd(" .. tostring(c[2]) .. ")") end
  end
end

local ok1 = run("fallback colours (no colors.lua)")
-- now with a generated colors.lua (simulated matugen output)
local f = assert(io.open(confdir .. "/colors.lua", "w"))
f:write('return { primary="aabbcc", on_primary="112233", primary_container="334455", secondary="ccbbaa", tertiary="ddeeff", error="ff0000", surface="101010", surface_container="202020", on_surface="eeeeee", outline="888888", outline_variant="444444", shadow="000000" }\n')
f:close()
for k in pairs(package.loaded) do if k == "colors" or k:match("^modules%.") or k == "user" then package.loaded[k] = nil end end
local ok2 = run("generated colours")
dump()
os.remove(confdir .. "/colors.lua")
os.exit((ok1 and ok2) and 0 or 1)
