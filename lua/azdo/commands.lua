local Job = require("plenary.job")
local utils = require("utils")
local settings = utils.settings
local pull_request_statuses = require("utils").pull_request_statuses
local table_contains = require("utils").table_contains
local M = {}

local function getPullRequests(opts)
    local args = { "repos", "pr", "list", "--query", utils.JMESPathString_list_prs }
    local default_opts = { skip = 0, top = 100 }
    local options = vim.tbl_deep_extend("keep", opts, default_opts)

    -- if a valid option was passed in, add the status argument
    if type(options.status) == "string" then
        if table_contains(pull_request_statuses, options.status) then
            table.insert(args, "--status")
            table.insert(args, options.status)
        end
    end

    -- if the repo is set, include repo flag
    if options.repository then
        table.insert(args, "--repository")
        table.insert(args, options.repository)
    end

    -- if the reviewer flag is set, use the default user as username
    if options.reviewer then
        table.insert(args, "--reviewer")
        table.insert(args, opts.username or settings.username)
    end

    Job:new({
        command = "az",
        args = args,
        cwd = vim.fn.getcwd(),
        on_exit = function(self, code, signal)
            print("Result:")
            local result = self:result()
            print(vim.inspect(result))
        end,
        on_stderr = function(error, data)
            print("Standard Error:")
            print(error)
            print(data)
        end,
    }):start()
end

M.prs = getPullRequests

return M
