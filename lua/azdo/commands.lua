local utils = require("azdo.utils")

local M = {}

function M.prompt_user_to_checkout_a_pr()
    local pull_requests = utils.get_pull_requests({})
    utils.prompt_user_with_prs(pull_requests, "Select a PR to checkout", utils.checkout_pr)
end

function M.prompt_user_to_vote_on_a_pr()
    local pull_requests = utils.get_pull_requests({})
    utils.prompt_user_with_prs(pull_requests, "Select a PR to vote on", function(pull_request)
        utils.prompt_user_for_vote_on_pr(pull_request.pullRequestId, "Voting on " .. pull_request.title)
    end)
end

function M.prompt_user_to_vote_on_current_ref()
    local result = utils.get_pull_request_for_checked_out_ref()
    local pr = result.pr
    local ref = result.ref

    if pr then
        utils.prompt_user_for_vote_on_pr(pr.pullRequestId, "Voting on " .. ref)
    else
        vim.notify("Could not find a Pull Request for ref: " .. ref, vim.log.levels.INFO)
    end
end

--- Create Pull Request for current branch
---@param opts { target_branch?: string, delete_source_branch?: boolean }
function M.create_pull_request_for_current_branch(opts)
    local options = vim.tbl_extend("keep", opts, { target_branch = "main", delete_source_branch = true })

    utils.create_pull_request_for_current_branch(options)
end

function M.change_pull_request_description_for_current_branch()
    local result = utils.get_pull_request_for_checked_out_ref()
    local pr = result.pr
    local ref = result.ref

    if pr then
        utils.change_pull_request_description(pr)
    else
        vim.notify("Could not find a Pull Request for ref: " .. ref, vim.log.levels.INFO)
    end
end

function M.test()
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
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, {})

    -- Create the autocmds for saving
    vim.api.nvim_create_autocmd("BufWinLeave", {
        buffer = buf,
        desc = "AzDo Buffer Win leave command",
        callback = function()
            local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
            print("The lines are: " .. vim.inspect(lines))
            vim.api.nvim_buf_set_option(0, "modified", false)
        end,
    })
    vim.api.nvim_create_autocmd("BufWriteCmd", {
        buffer = buf,
        desc = "AzDo Buffer write command",
        callback = function()
            -- Do nothing here. I just want to enable :w
            -- The saving actually happens in the BufWinLeave autocmd
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

return M
