set shell := ["bash", "-euc"]

# login to a repository
_login repository:
    #!/usr/bin/env bash
    repository_type=$(curl -Lis https://{{repository}}/ | egrep -oi "<title>.*GitHub<\/title>|<title>.*GitLab<\/title>" | awk '{sub(/<\/title>/,"");print $NF}' || echo "unknown repo")

    printf "\e[1;34m[INFO]\e[m repository type: ${repository_type}.\n"

    # Setup repo vars
    if [[ "$repository_type" == "GitHub" ]]; then
        REPO={{repository}}
        VAR_REPO_HOST="GH_HOST"
        CLI_REPO="gh"
        CONFIG_REPO="$HOME/.config/gh"
        CONFIG_FILE="${CONFIG_REPO}/hosts.yml"
        YQ_SEARCH=".\"{{repository}}\".user"
        #https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/scopes-for-oauth-apps#available-scopes
        OPTIONS="-s read:project,repo,write:packages,read:org,workflow"
        # Setup command to eval
        CMD="gh auth login -p ssh ${OPTIONS} -h {{repository}} -w"
        CMD_CHECK="gh auth status -h {{repository}}"
    elif [[ "$repository_type" == "GitLab" ]]; then
        REPO={{repository}}
        VAR_REPO_HOST="GITLAB_HOST"
        CLI_REPO="glab"
        CONFIG_REPO="$HOME/.config/glab-cli"
        CONFIG_FILE="${CONFIG_REPO}/config.yml"
        YQ_SEARCH=".hosts.\"{{repository}}\".user"
        # Setup command to eval
        CMD="NO_COLORS=1 NO_PROMPT=1 glab auth login -h {{repository}} "
        OPTIONS=""
    else
        printf "\e[1;31m[ERROR]\e[m unknown repository or not reachable.\n"
        exit 1
    fi

    # Setup command to eval
    printf "CMD: \e[1;32m ${CMD} \e[m\n"

    # Apply only to Github
    if [[ "$repository_type" == "GitHub" ]]; then
        # Get User
        printf "CMD USER: \e[1;32m yq \'${YQ_SEARCH}\' ${CONFIG_FILE} \e[m\n"
        REPO_USER=$(yq eval ${YQ_SEARCH} ${CONFIG_FILE})
        printf "Connexion USER: \e[1;32m ${REPO_USER}\e[m\n"

        # Get path of the private key
        while true; do
          read -p "Give path from the private to set in your .ssh/config :  "  privatekey_path
          if [ -f ${privatekey_path} ]; then
            printf "\e[1;34m[INFO]\e[m This ${privatekey_path} exists.\n";
            break;
          else
            printf "\e[1;31m[ERROR]\e[m This private key ${privatekey_path} does NOT exist.\n"
          fi
        done

        # Set .ssh/config
        if ! grep -q "Host ${REPO}" ~/.ssh/config; then
            printf "\e[1;34m[INFO]\e[m Adding SSH config for ${REPO}\n"
            {
                echo ""
                echo "Host ${REPO}"
                echo "  HostName ${REPO}"
                echo "  User ${REPO_USER}"
                echo "  IdentityFile ${privatekey_path}"
            } >> ~/.ssh/config
        else
            printf "\e[1;34m[INFO]\e[m SSH config for ${REPO} already exists\n"
        fi
    fi

    # Check auth
    eval "${CMD_CHECK}"
