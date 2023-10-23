
set shell := ["bash", "-uc"]

# Lists all available commands in the justfile.
_help:
    @just --list --unsorted


# Not working anymore for GitLab:
# repository_type=$(curl -Lis https://{{repository}}/ | awk '/<title>.*GitHub<\/title>/ || /<title>.*GitLab<\/title>/ {sub(/<\/title>/,"");print $NF}' || echo "unknown")

# Setup repository commands and vars
_setup_repo_cmd repository:
    #!/usr/bin/env bash
    repository_type=$(curl -Lis https://{{repository}}/ | egrep -oi "<title>.*GitHub<\/title>|<title>.*GitLab<\/title>" | awk '{sub(/<\/title>/,"");print $NF}' || echo "unknown repo")
    
    printf "\e[1;33m[INFO]\e[m repository type: ${repository_type}.\n"

    # Setup repo vars
    if [[ "$repository_type" == "GitHub" ]]; then 
        VAR_REPO_HOST="GH_HOST"
        CLI_REPO="gh"
        CONFIG_REPO="$HOME/.config/gh"
        # Setup command to eval
        CMD="${VAR_REPO_HOST}={{repository}} ${CLI_REPO}"
        #https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/scopes-for-oauth-apps#available-scopes
        OPTIONS="-s read:project,repo,write:packages,read:org,workflow"
    elif [[ "$repository_type" == "GitLab" ]]; then
        VAR_REPO_HOST="GITLAB_HOST"
        CLI_REPO="glab"
        CONFIG_REPO="$HOME/.config/glab-cli"
        # Setup command to eval
        CMD="NO_COLORS=1 NO_PROMPT=1 ${VAR_REPO_HOST}={{repository}} ${CLI_REPO}"
        OPTIONS=""
    else
        printf "\e[1;31m[ERROR]\e[m unknown repository.\n"
        exit
    fi
    # Setup command to eval
    export CMD="${VAR_REPO_HOST}={{repository}} ${CLI_REPO}"
    printf "CMD: \e[1;32m ${CMD} \e[m\n"

# TEST
_test repository='github.com': (_setup_repo_cmd repository)
    #!/usr/bin/env bash
    printf "git repository: \e[1;32m {{ repository }} \e[m\n"
    printf "CMD: \e[1;32m ${CMD} \e[m\n"