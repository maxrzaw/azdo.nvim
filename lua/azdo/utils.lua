local Job = require("plenary.job")
local M = {}
local next = next

M.JMESPathString_list_prs =
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

M.pull_request_statuses = { "abandoned", "active", "all", "completed" }

M.settings = settings

function M.table_contains(table, needle)
    local found = false
    for _, v in pairs(table) do
        if v == needle then
            found = true
        end
    end
    return found
end

function M.checkoutPR(pr)
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

    local branch = string.gsub(pr.sourceRefName, "refs/heads/", "")

    if next(output) ~= nil then
        vim.notify("Please clean working tree before checking out " .. branch, vim.log.levels.ERROR)
        return
    end

    Job:new({
        command = "az",
        args = { "repos", "pr", "checkout", "--id", pr.codeReviewId },
        cwd = vim.fn.getcwd(),
    }):start()
end

function M.promptUserToSelectPR(prs)
    vim.ui.select(prs, {
        prompt = "Select a PR to view",
        format_item = function(item)
            return "Title: "
                .. item.title
                .. " | Created by: "
                .. item.createdBy.displayName
                .. " | Repository: "
                .. item.repository.name
        end,
    }, function(choice)
        if choice then
            M.checkoutPR(choice)
        end
    end)
end

return M
