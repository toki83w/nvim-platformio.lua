local utils = require("platformio.utils")
local M = {}

function M.piomon(args_table)
    if not utils.pio_install_check() then
        return
    end

    if not utils.cd_pioini() then
        return
    end

    local command
    if args_table[1] == "" then
        command = "pio device monitor" .. utils.env_args()
    else
        local baud_rate = args_table[1]
        command = string.format("pio device monitor -b %s%s", baud_rate, utils.env_args())
    end
    utils.ToggleTerminal(command, "horizontal", nil, 44)
end

return M
