set shell := ["bash", "-uc"]

# List all repository configured
_list:
    #!/usr/bin/env bash
 
    # List Github repo
    VAR_REPO_HOST="GH_HOST"
    CLI_REPO="gh"
    CONFIG_REPO="$HOME/.config/gh"
    CONFIG_FILE="${CONFIG_REPO}/hosts.yml"
    YQ_SEARCH=".\"{{repository}}\".email"
    # Setup command to eval
    CMD="${VAR_REPO_HOST}={{repository}} ${CLI_REPO}"
    ${CMD} auth status

    # List Gitlab repo
    VAR_REPO_HOST="GITLAB_HOST"
    CLI_REPO="glab"
    CONFIG_REPO="$HOME/.config/glab-cli"
    CONFIG_FILE="${CONFIG_REPO}/config.yml"
    YQ_SEARCH=".hosts.\"{{repository}}\".email"
    # Setup command to eval
    CMD="${VAR_REPO_HOST}={{repository}} ${CLI_REPO}"
    ${CMD} auth status   
