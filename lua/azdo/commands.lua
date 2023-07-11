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
    local pull_request_id = result.pull_request_id
    local ref = result.ref_name

    if pull_request_id < 0 then
        vim.notify("Could not find a Pull Request for ref: " .. ref, vim.log.levels.INFO)
        return
    end

    utils.prompt_user_for_vote_on_pr(pull_request_id, "Voting on " .. ref)
end

return M
