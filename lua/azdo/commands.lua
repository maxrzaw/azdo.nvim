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

--- Create Pull Request for current branch.
---
--- `target_branch`: defaults to "main"
--- `delete_source_branch`: defaults to true
--- `title`: Not required, but you will be prompted for a title if missing or empty
--- `description`: Not required, but you will be prompted for a description if missing
---@param opts { target_branch?: string, delete_source_branch?: boolean, title?: string, description?: string[]}
function M.create_pull_request_for_current_branch(opts)
    local options = vim.tbl_extend("keep", opts, { target_branch = "main", delete_source_branch = true })

    if options.title == nil or options.title == "" then
        options.title = vim.fn.input("Title: ")
    end

    if options.description ~= nil then
        utils.create_pull_request_for_current_branch(options)
    else
        utils.edit_description({}, function(lines)
            options.description = lines
            utils.create_pull_request_for_current_branch(options)
        end)
    end
end

function M.change_pull_request_description_for_current_branch()
    local result = utils.get_pull_request_for_checked_out_ref()
    local pr = result.pr
    local ref = result.ref

    if pr then
        local description_lines = {}
        if pr.description ~= vim.NIL then
            for s in pr.description:gmatch("([^\n]*)\n?") do
                table.insert(description_lines, s)
            end
            -- Removes a trailing newline. This will get rid of one trailing newline
            -- even if it was intended, but I haven't figured out a way around it.
            table.remove(description_lines)
        end

        utils.edit_description(description_lines, function(lines)
            utils.set_pr_description(pr.pullRequestId, lines)
            vim.notify("Pull Request " .. pr.pullRequestId .. " has been updated.")
        end)
    else
        vim.notify("Could not find a Pull Request for ref: " .. ref, vim.log.levels.INFO)
    end
end

function M.test()
    print("no testing function currently")
end

return M
