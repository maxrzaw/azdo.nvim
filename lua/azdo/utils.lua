local Job = require("plenary.job")
local M = {}
local next = next

local JMES_path_string_list_prs =
    "[].{codeReviewId: codeReviewId, createdBy: createdBy.{displayName: displayName, uniqueName: uniqueName}, creationDate: creationDate, description: description, mergeStatus: mergeStatus, pullRequestId: pullRequestId, repository: repository.{name: name, project: project.{name: name}}, isDraft: isDraft, reviewers: reviewers.{displayName: displayName, hasDeclined: hasDeclined, isRequired: isRequired, vote: vote }, sourceRefName: sourceRefName, status: status, targetRefName: targetRefName, title: title, url: url }"

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

local pull_request_statuses = { "abandoned", "active", "all", "completed" }
local vote_options = { "approve", "approve-with-suggestions", "reject", "reset", "wait-for-author" }

local function table_contains(table, needle)
    local found = false
    for _, v in pairs(table) do
        if v == needle then
            found = true
        end
    end
    return found
end

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

local function vote_on_pr(pull_request_id, vote)
    Job:new({
        command = "az",
        args = { "repos", "pr", "set-vote", "--id", pull_request_id, "--vote", vote },
        cwd = vim.fn.getcwd(),
    }):start()
end

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
        args = { "repos", "pr", "checkout", "--id", pull_request.codeReviewId },
        cwd = vim.fn.getcwd(),
    }):start()
end

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
    }, callback)
end

function M.get_pull_requests(opts)
    local args = { "repos", "pr", "list", "--query", JMES_path_string_list_prs }
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

function M.prompt_user_for_vote_on_pr(pull_request_id, prompt)
    vim.ui.select(vote_options, {
        prompt = prompt,
    }, function(choice)
        vote_on_pr(pull_request_id, choice)
    end)
end

function M.get_pull_request_id_for_checked_out_ref()
    local ref = get_current_ref()
    local pull_requests = M.get_pull_requests({})
    for _, pr in ipairs(pull_requests) do
        if pr.sourceRefName == ref then
            return { ref_name = ref, pull_request_id = pr.pullRequestId }
        end
    end

    return -1
end

return M
