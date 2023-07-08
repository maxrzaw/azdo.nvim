local M = {}

M.JMESPathString_list_prs =
    "[].{codeReviewId: codeReviewId, createdBy: createdBy.{displayName: displayName, uniqueName: uniqueName}, creationDate: creationDate, description: description, mergeStatus: mergeStatus, pullRequestId: pullRequestId, repository: repository.{name: name, project: project.{name: name}}, isDraft: isDraft, reviewers: reviewers.{displayName: displayName, hasDeclined: hasDeclined, isRequired: isRequired, vote: vote }, sourceRefName: sourceRefName, status: status, targetRefName: targetRefName, title: title, url: url }"

local settings = {
    org = "https://dev.azure.com/amrock/",
    projects = {
        "Platform",
        "Sandbox",
        "Area51",
        "Amrock Way",
        "Signing",
    },
    default_project = "Platform",
    username = "maxzawisa@amrock.com",
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

return M
