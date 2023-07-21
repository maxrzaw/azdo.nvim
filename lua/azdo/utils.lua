local types = require("azdo.enums_and_types")
local Job = require("plenary.job")
local M = {}
local next = next

local settings = {
    projects = {
        "TestProject",
        "Platform",
        "Sandbox",
        "Area51",
        "Amrock Way",
        "Signing",
    },
    default_project = "TestProject",
    username = "",
}
M.settings = settings

local function table_contains(table, needle)
    local found = false
    for _, v in pairs(table) do
        if v == needle then
            found = true
        end
    end
    return found
end

--- Check to see if the current working tree is clean
---@return boolean
local function is_working_tree_clean()
    -- Check to see if there are any unstaged changes
    local output = nil
    Job:new({
        command = "git",
        args = { "status", "--porcelain" },
        cwd = vim.fn.getcwd(),
        on_exit = function(job, code, signal)
            output = job:result()
        end,
    }):sync()

    return next(output) == nil
end

local function get_current_branch()
    local output = nil
    Job:new({
        command = "git",
        args = { "branch", "--show-current" },
        cwd = vim.fn.getcwd(),
        on_exit = function(job, code, signal)
            output = job:result()
        end,
    }):sync()
    local ref = table.concat(output)

    return ref
end

local function get_current_ref()
    local output = nil
    Job:new({
        command = "git",
        args = { "symbolic-ref", "HEAD" },
        cwd = vim.fn.getcwd(),
        on_exit = function(job, code, signal)
            output = job:result()
        end,
    }):sync()
    local ref = table.concat(output)

    return ref
end

--- Vote on a Pull Request
---@param pull_request_id (integer) ID for the pull request
---@param vote (string) acceptable votes are: approve, approve-with-suggestions, reject, reset, wait-for-author
local function vote_on_pr(pull_request_id, vote)
    Job:new({
        command = "az",
        args = { "repos", "pr", "set-vote", "--id", pull_request_id, "--vote", vote },
        cwd = vim.fn.getcwd(),
    }):start()
end

local function set_pr_draft(pull_request_id, is_draft)
    Job:new({
        command = "az",
        args = { "repos", "pr", "update", "--id", pull_request_id, "--draft", is_draft },
        cwd = vim.fn.getcwd(),
    }):start()
end

local function set_pr_status(pull_request_id, status)
    Job:new({
        command = "az",
        args = { "repos", "pr", "update", "--id", pull_request_id, "--status", status },
        cwd = vim.fn.getcwd(),
    }):start()
end

local function abandon_pr(pull_request_id)
    set_pr_status(pull_request_id, "abandoned")
end

local function complete_pr(pull_request_id)
    set_pr_status(pull_request_id, "completeed")
end

local function activate_pr(pull_request_id)
    set_pr_status(pull_request_id, "active")
end

local function set_pr_title(pull_request_id, title)
    Job:new({
        command = "az",
        args = { "repos", "pr", "update", "--id", pull_request_id, "--title", title },
        cwd = vim.fn.getcwd(),
    }):start()
end

-- New description for the pull request.  Can include markdown.  Each
-- value sent to this arg will be a new line. For example:
-- "First Line" "Second Line"
local function set_pr_description(pull_request_id, description)
    local _args = { "repos", "pr", "update", "--id", pull_request_id, "--description" }
    for i, line in pairs(description) do
        table.insert(_args, line)
    end
    Job:new({
        command = "az",
        args = _args,
        cwd = vim.fn.getcwd(),
    }):start()
end

--- Calls git checkout, if the working tree is clean. Otherwise displays a message.
---@param pull_request (pull_request) lua table representing a pull request { sourceRefName: (string), pullRequestId: (int)}
function M.checkout_pr(pull_request)
    -- Check to see if there are any unstaged changes
    local working_tree_is_clean = is_working_tree_clean()

    local branch = string.gsub(pull_request.sourceRefName, "refs/heads/", "")

    if not working_tree_is_clean then
        vim.notify("Please clean working tree before checking out " .. branch, vim.log.levels.ERROR)
        return
    end

    Job:new({
        command = "az",
        args = { "repos", "pr", "checkout", "--id", pull_request.pullRequestId },
        cwd = vim.fn.getcwd(),
    }):start()
end

--- Prompt the user to select a pull request.
---@param pull_requests (pull_request[]) list of pull requests
---@param prompt (string) text to display to the user
---@param callback (fun(item: pull_request)) called if the user makes a selection
function M.prompt_user_with_prs(pull_requests, prompt, callback)
    vim.ui.select(pull_requests, {
        prompt = prompt,
        format_item = function(item)
            return "Title: "
                .. item.title
                .. " | Created by: "
                .. item.createdBy.displayName
                .. " | Repository: "
                .. item.repository.name
        end,
    }, function(item)
        if item then
            callback(item)
        end
    end)
end

--- Get pull requests
---@param opts (table) optional table of options
---@return (pull_request[]) a list of pull requests
function M.get_pull_requests(opts)
    -- local args = { "repos", "pr", "list", "--query", JMES_path_string_list_prs }
    local args = { "repos", "pr", "list" }
    local default_opts = { skip = 0, top = 100 }
    local options = vim.tbl_deep_extend("keep", opts, default_opts)

    -- if a valid option was passed in, add the status argument
    if type(options.status) == "string" then
        if table_contains(types.pull_request_statuses, options.status) then
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

    local result = nil
    Job:new({
        command = "az",
        args = args,
        cwd = vim.fn.getcwd(),
        on_exit = function(self, code, signal)
            local jobResult = self:result()
            local stringResult = table.concat(jobResult)
            local finalResult = vim.json.decode(stringResult)
            result = finalResult
        end,
        on_stderr = function(error, data)
            print("Standard Error:")
            print(error)
            print(data)
        end,
    }):sync()

    return result
end

--- Ask the user to vote on a pull_request
---@param pull_request_id (integer)
---@param prompt (string)
function M.prompt_user_for_vote_on_pr(pull_request_id, prompt)
    vim.ui.select(types.vote_options, {
        prompt = prompt,
    }, function(choice)
        vote_on_pr(pull_request_id, choice)
    end)
end

--- Gets a pull request for the current branch
---@return ({ref: (string), pr: pull_request|nil})
function M.get_pull_request_for_checked_out_ref()
    local ref = get_current_ref()
    local pr_to_checkout = nil
    local pull_requests = M.get_pull_requests({})
    for _, pr in ipairs(pull_requests) do
        if pr.sourceRefName == ref then
            pr_to_checkout = pr
            break
        end
    end

    return { ref = ref, pr = pr_to_checkout }
end

--- Push the current branch to the remote
local function push_current_branch_to_origin()
    -- git push -u origin HEAD
    Job:new({
        command = "git",
        args = { "push", "-u", "origin", "HEAD" },
        cwd = vim.fn.getcwd(),
    }):sync()
end

---Create a Pull Request
---@param title string
---@param target_branch string
---@param source_branch string
---@param delete_source_branch boolean
---@param description string[]
local function create_pull_request(title, target_branch, source_branch, delete_source_branch, description)
    local args = {
        "repos",
        "pr",
        "create",
        "--title",
        title,
        "-t",
        target_branch,
        "-s",
        source_branch,
        "--delete-source-branch",
        tostring(delete_source_branch),
        "-d",
    }

    -- insert each line at the end of the args table
    for _, line in pairs(description) do
        table.insert(args, line)
    end

    Job:new({
        command = "az",
        args = args,
        cwd = vim.fn.getcwd(),
        on_exit = function(job, code, signal)
            print(vim.inspect(job:result()))
            print("code " .. code)
            print("signal " .. signal)
        end,
        on_stderr = function(error, data)
            print("Standard Error:")
            print(error)
            print(data)
        end,
    }):start()
end

--- Create a Pull Request for the current branch.
---@param opts { target_branch: string, delete_source_branch: boolean }
function M.create_pull_request_for_current_branch(opts)
    -- make sure the current branch is pushed
    push_current_branch_to_origin()

    local title = vim.fn.input("Title: ")
    local target_branch = opts.target_branch
    local source_branch = get_current_branch()
    local delete_source_branch = opts.delete_source_branch
    local description = { "I have not implemented description yet :(" }

    create_pull_request(title, target_branch, source_branch, delete_source_branch, description)
end

local function test() end

---Changes the description of a pull request
---@param pr pull_request
function M.change_pull_request_description(pr)
    local buf = vim.g.azdo_bufnr
    if buf == nil then
        buf = vim.api.nvim_create_buf(false, false)
        vim.g.azdo_bufnr = buf
        vim.api.nvim_buf_set_option(buf, "buftype", "acwrite")
        vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
        vim.api.nvim_buf_set_name(buf, "AzDoPRDescription")
    end

    -- Clear the existing autocmds so we do not save multiple times
    vim.api.nvim_clear_autocmds({ buffer = buf })

    -- set the lines to the lines from the description
    local description_lines = {}
    if pr.description ~= vim.NIL then
        for s in pr.description:gmatch("([^\n]*)\n?") do
            table.insert(description_lines, s)
        end
        -- Removes a trailing newline. This will get rid of one trailing newline
        -- even if it was intended, but I haven't figured out a way around it.
        table.remove(description_lines)
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, description_lines)
    vim.api.nvim_buf_set_option(buf, "modified", false)

    vim.api.nvim_create_autocmd("BufWinEnter", {
        buffer = buf,
        desc = "AzDo set nohidden",
        callback = function()
            if vim.g.azdo_hidden == nil then
                vim.g.azdo_hidden = vim.api.nvim_get_option("hidden")
            end
            vim.api.nvim_set_option("hidden", false)
        end,
    })

    -- Create the autocmds for saving
    vim.api.nvim_create_autocmd("BufWinLeave", {
        buffer = buf,
        desc = "AzDo Buffer Win leave command",
        callback = function()
            if not vim.api.nvim_buf_get_option(0, "modified") then
                local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
                set_pr_description(pr.pullRequestId, lines)
                vim.notify("Pull Request " .. pr.pullRequestId .. " has been updated.")
            end

            -- Restore the previous setting for hidden
            vim.api.nvim_set_option("hidden", vim.g.azdo_hidden)
        end,
    })
    vim.api.nvim_create_autocmd("BufWriteCmd", {
        buffer = buf,
        desc = "AzDo Buffer write command",
        callback = function()
            -- All we are really doing here is marking that it is safe to
            -- update the PR
            vim.api.nvim_buf_set_option(0, "modified", false)
        end,
    })

    -- Open the window
    local width = 100
    local height = math.min(120, 60)
    local ui = vim.api.nvim_list_uis()[1]
    local opts = {
        relative = "editor",
        width = width,
        height = height,
        col = (ui.width / 2) - (width / 2),
        row = (ui.height / 2) - (height / 2),
        anchor = "NW",
        style = "minimal",
        border = "rounded",
        title = "Azure DevOps Pull Request Description",
        title_pos = "center",
    }
    vim.api.nvim_open_win(buf, true, opts)
end

function M.reload()
    -- unload all the files
    package.loaded["azdo"] = nil
    package.loaded["azdo.commands"] = nil
    package.loaded["azdo.utils"] = nil

    -- call setup again
    require("azdo").setup({})
end

return M
