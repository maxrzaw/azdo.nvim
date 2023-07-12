---@class project
---@field id (string)
---@field name (string)
---@field state (string)
---@field url (string)
---@field visibility (string)

---@class repository
---@field defaultBranch (string)
---@field id (string)
---@field name (string)
---@field project (project)
---@field remoteUrl (string)
---@field sshUrl (string)
---@field url (string)
---@field webUrl (string)

---@class identity
---@field id (string)           : Identifier for this graph subject
---@field displayName (string)  : Non-unique display name
---@field uniqueName (string)   : Unique name for this graph subject
---@field url (string)          : Full route to this graph subject
---@field imageUrl (string)     :

---@class commitIdentity
---@field name (string)
---@field email (string)
---@field date (string)

---@class commit
---@field author (commitIdentity)
---@field committer (commitIdentity)
---@field commitId (string)
---@field comment (string)
---@field url (string)

---@class reviewer
---@field displayName (string)
---@field hasDeclined (string)
---@field id (string)
---@field isRequired (string)
---@field uniqueName (string)
---@field vote (integer)
---@field votedFor (reviewer[])

---@class pull_request
---@field artifactId (string)
---@field autoCompleteSetBy (identity)
---@field closedBy (identity)
---@field closedDate (string)
---@field codeReviewId (integer)
---@field commits (unknown)
---@field completionQueueTime (string)
---@field createdBy (identity)
---@field creationDate (string)
---@field description (string)
---@field isDraft (boolean)
---@field labels (unknown)
---@field lastMergeCommit (commit)
---@field lastMergeSourceCommit (commit)
---@field lastMergeTargetCommit (commit)
---@field mergeFailureMessage (string)
---@field mergeFailureType (string)
---@field mergeId (string)
---@field mergeOptions (unknown)
---@field mergeStatus (string)
---@field pullRequestId (integer)
---@field repository (repository)
---@field reviewers (reviewer[])
---@field sourceRefName (string)
---@field status (string)
---@field supportsIterations (boolean)
---@field targetRefName (string)
---@field title (string)
---@field url (string)
---@field workItemRefs (unknown)

local M = {}
M.JMES_path_string_list_prs =
    "[].{codeReviewId: codeReviewId, createdBy: createdBy.{displayName: displayName, uniqueName: uniqueName}, creationDate: creationDate, description: description, mergeStatus: mergeStatus, pullRequestId: pullRequestId, repository: repository.{name: name, project: project.{name: name}}, isDraft: isDraft, reviewers: reviewers.{displayName: displayName, hasDeclined: hasDeclined, isRequired: isRequired, vote: vote }, sourceRefName: sourceRefName, status: status, targetRefName: targetRefName, title: title, url: url }"

---@enum pull_request_statuses
M.pull_request_statuses = { "abandoned", "active", "all", "completed" }

---@enum vote_options
M.vote_options = { "approve", "approve-with-suggestions", "reject", "reset", "wait-for-author" }

return M
