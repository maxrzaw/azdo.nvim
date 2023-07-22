# azdo.nvim

Experimenting with the azure-devops-cli-extension and Neovim.

This plugin requires that you have the azure cli with the azure devops extension.

## Features Currently Supported:

- Creating a Pull Request from your current branch
- Modifying the description of the Pull Request for your current branch
- Checking out and switching to the branch for a Pull Request in your current git repository
- Voting on Pull Requests for your current repo

## TODO:

- Complete/Abandon/SetAutoComplete Pull Requests
- Switch to using the REST API rather than wrapping azure devops cli-extension

## Possible Features using the REST API:

Switching to the REST API will be a lot of work. I am mostly concerned with how to handle authentication. Maybe we can store a token in an environment variable
- Reviewers
- Comments (will this require showing diffs?)
- Work Items
