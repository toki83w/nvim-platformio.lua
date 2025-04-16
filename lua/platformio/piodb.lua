local M = {}

local utils = require("platformio.utils")

function M.piodb()
    local command = "pio run -t compiledb" .. utils.env_args()
    utils.ToggleTerminal(command, "float")
end

return M
