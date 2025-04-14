local utils = require("platformio.utils")

local M = {}

local default_config = {
    lsp = "clangd",
    active_env = utils.default_env,
}

M.config = vim.deepcopy(default_config)

function M.setup(user_config)
    local valid_keys = {
        lsp = true,
    }
    for key, _ in pairs(user_config or {}) do
        if not valid_keys[key] then
            local error_message =
                string.format("Invalid configuration key: '%s'\n%s", key, debug.traceback("Stack trace:"))
            vim.api.nvim_err_writeln(error_message)
            return
        end
    end
    M.config = vim.tbl_deep_extend("force", default_config, user_config or {})

    local json_conf = utils.get_json_conf()
    if json_conf and json_conf.active_env then
        M.config.active_env = json_conf.active_env
    end
end

return M
