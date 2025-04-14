-- ## Usage
--
--   require("lualine").setup({
--     sections = {
--       lualine_x = { "platformio" },
--     },
--   })
--

local config = require("platformio").config
local utils = require("platformio.utils")

local M = require("lualine.component"):extend()

function M:init(options)
    M.super.init(self, options)

    local color = { fg = "#fab387" }
    self.hl_icon = self:create_hl(color, "Pio_Icon")
end

function M:update_status()
    if not utils.cd_pioini(true) then
        return ""
    end

    local icon = ""
    local env = config.active_env == utils.default_env and "default" or config.active_env

    local hl_start = self:format_hl(self.hl_icon)
    local hl_end = self:get_default_hl()
    return string.format("%s%s %s%s", hl_start, icon, hl_end, env)
end

return M
