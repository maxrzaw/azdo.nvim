local M = {}
M.GetPRs = require("azdo.commands").prs

M.test = function()
    vim.ui.select({ { name = "tabs", desc = "inferior" }, { name = "spaces", desc = "superior" } }, {
        prompt = "Select tabs or spaces",
        format_item = function(item)
            return "name: " .. item.name .. " desc: " .. item.desc
        end,
    }, function(choice)
        if choice then
            print("You are " .. choice.desc .. "!!")
        end
    end)
end

local function addUserCommands()
    vim.api.nvim_create_user_command("AzDOPullRequests", function()
        require("azdo.commands").prs({})
    end, {})
end

M.setup = function(opts)
    addUserCommands()
    vim.notify("Done setting up azdo.nvim")
end

return M
