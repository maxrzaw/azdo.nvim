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
    local result = utils.get_pull_request_id_for_checked_out_ref()
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

return M
