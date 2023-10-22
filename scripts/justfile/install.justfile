set shell := ["bash", "-uc"]

# Install an ansible collection
_install project repository *version:
    #!/usr/bin/env bash    
    repository_type=$(curl -Lis https://{{repository}}/ | egrep -oi "<title>.*GitHub<\/title>|<title>.*GitLab<\/title>" | awk '{sub(/<\/title>/,"");print $NF}' || echo "unknown repo")
    
    printf "\e[1;34m[INFO]\e[m repository type: ${repository_type}.\n"

    # Setup repo vars
    if [[ "$repository_type" == "GitHub" ]]; then 
        VAR_REPO_HOST="GH_HOST"
        CLI_REPO="gh"
        CONFIG_REPO="$HOME/.config/gh"
        CONFIG_FILE="${CONFIG_REPO}/hosts.yml"
        YQ_SEARCH=".\"{{repository}}\".email"
        # Setup command to eval
        CMD="${VAR_REPO_HOST}={{repository}} ${CLI_REPO}"
        #https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/scopes-for-oauth-apps#available-scopes
        OPTIONS="-s read:project,repo,write:packages,read:org,workflow"
    elif [[ "$repository_type" == "GitLab" ]]; then
        VAR_REPO_HOST="GITLAB_HOST"
        CLI_REPO="glab"
        CONFIG_REPO="$HOME/.config/glab-cli"
        CONFIG_FILE="${CONFIG_REPO}/config.yml"
        YQ_SEARCH=".hosts.\"{{repository}}\".email"
        # Setup command to eval
        CMD="${VAR_REPO_HOST}={{repository}} ${CLI_REPO}"
        OPTIONS=""
    else
        printf "\e[1;31m[ERROR]\e[m unknown repository or not reachable.\n"
        exit 1
    fi

    # Connect to repo before
    # eval "${CMD} auth status"
        
    # Create project on repository
    number_of_projects_found=$( eval "${CMD} repo list | grep -iw "^.*/{{ project }}"| wc -l" )

    if (( $number_of_projects_found == 0 )); then
        printf "\e[1;31m[ERROR]\e[m Project {{ project }} does not exist in your repository: {{repository}}.\n"
        exit 1
    elif (( $number_of_projects_found == 1 )); then
        project_found=$( eval "${CMD} repo list | grep -iw "^.*/{{ project }}"" )
        project_to_install=$(echo ${project_found} | awk '{print $1;}')
        project_lowercase=$(echo ${project_to_install} | tr '[:upper:]' '[:lower:]')
        printf "\e[1;32m[OK]\e[m Project ${project_to_install} exist, Let\'s install it... \n"

        if [[ "{{version}}" != "" ]]; then
            printf "\e[1;34m[INFO]\e[m # ansible-galaxy collection install git+https://{{repository}}/${project_lowercase}.git,v{{version}}\n"
            ansible-galaxy collection install git+https://{{repository}}/${project_lowercase}.git,v{{version}}
        else
            printf "\e[1;34m[INFO]\e[m # ansible-galaxy collection install git+https://{{repository}}/${project_lowercase}.git\n"
            ansible-galaxy collection install -U git+https://{{repository}}/${project_lowercase}.git
        fi
    elif (( $number_of_projects_found > 1 )); then
        project_found=$( eval "${CMD} repo list  | grep -iw "^.*/{{ project }}"" )
        printf "\e[1;31m[ERROR]\e[m There is several Project: {{ project }} which already exist in different namespace.\n"
        echo "${project_found}"
        exit 1
    fi