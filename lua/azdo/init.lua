local M = {}

local function addUserCommands()
    vim.api.nvim_create_user_command("AzDoCheckoutPullRequest", function()
        require("azdo.commands").prompt_user_to_checkout_a_pr()
    end, {})
    vim.api.nvim_create_user_command("AzDoVoteOnPullRequest", function()
        require("azdo.commands").prompt_user_to_vote_on_a_pr()
    end, {})
    vim.api.nvim_create_user_command("AzDoVoteOnCurrent", function()
        require("azdo.commands").prompt_user_to_vote_on_current_ref()
    end, {})
    vim.api.nvim_create_user_command("AzDoCreatePullRequestFromCurrent", function()
        require("azdo.commands").create_pull_request_for_current_branch({})
    end, {})
    vim.api.nvim_create_user_command("AzTest", function()
        require("azdo.utils").reload()
        require("azdo.commands").test()
    end, {})
    vim.api.nvim_create_user_command("AzReload", function()
        require("azdo.utils").reload()
    end, {})
end

M.setup = function(opts)
    addUserCommands()
end

return M
