-- Shared values. Return a table; other modules do `local V = require("modules.variables")`.
local V = {}

V.mod         = "SUPER"
V.terminal    = "kitty"
V.browser     = "firefox"
V.fileManager = "thunar"
V.shell       = "qs -c material"

--- Command string that calls a Quickshell IPC function.
---   V.ipc("drawers", "toggle", "launcher") -> `qs -c material ipc call drawers toggle launcher`
function V.ipc(target, fn, ...)
    local parts = { V.shell, "ipc", "call", target, fn, ... }
    return table.concat(parts, " ")
end

--- Dispatcher that runs a Quickshell IPC call.
function V.qs(target, fn, ...)
    return hl.dsp.exec_cmd(V.ipc(target, fn, ...))
end

return V
