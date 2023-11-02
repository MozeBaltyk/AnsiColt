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
        CMD="NO_COLORS=1 NO_PROMPT=1 ${VAR_REPO_HOST}={{repository}} ${CLI_REPO}"
        OPTIONS=""
    else
        printf "\e[1;31m[ERROR]\e[m unknown repository or not reachable.\n"
        exit 1
    fi

    # Connect to repo before
    # eval "${CMD} auth status"
        
    # Install the project 
    number_of_projects_found=$( eval "${CMD} repo list | awk '{print \$1}' | grep -iw "^.*/{{ project }}$" | wc -l" )

    if (( $number_of_projects_found == 0 )); then
        printf "\e[1;31m[ERROR]\e[m Project {{ project }} does not exist in your repository: {{repository}}.\n"
        exit 1
    elif (( $number_of_projects_found > 1 )); then
        project_found=$( eval "${CMD} repo list | awk '{print \$1}' | grep -iw "^.*/{{ project }}$"" )
        printf "\e[1;31m[ERROR]\e[m There is several Project: {{ project }} which already exist in different namespace.\n"
        echo "${project_found}"
        exit 1
    elif (( $number_of_projects_found == 1 )); then
        # Project found contain "[group|user]/project" 
        project_found=$( eval "${CMD} repo list | awk '{print \$1}' | grep -iw "^.*/{{ project }}$"" )
        project_lowercase=$(echo ${project_found} | tr '[:upper:]' '[:lower:]')
        
        #Ansible Namespace can be the repo group/user or can be directly in the project name. ex: ansible.posix
        # may should I use URL/galaxy.yml
        project_group=$(echo ${project_found} | awk -F'/' '{print $1}')
        project_name=$(echo ${project_found} | awk -F'/' '{print $2}')
        ansible_namespace=$( [[ {{ project }} = *[[:punct:]]* ]] && echo {{ project }} | awk -F"." '{print $1}' || echo ${project_group} )
        ansible_namespace_lowercase=$(echo ${ansible_namespace} | tr '[:upper:]' '[:lower:]')
        collection_name=$( [[ {{ project }} = *[[:punct:]]* ]] && echo {{ project }} | awk -F"." '{print $2}' || echo ${project_name} )
        collection_name_lowercase=$(echo ${collection_name} | tr '[:upper:]' '[:lower:]')

        printf "\e[1;32m[OK]\e[m Project ${project_found} for the collection ${ansible_namespace_lowercase}.${collection_name_lowercase} exist, Let\'s install it... \n"

        if [[ "{{version}}" != "" ]]; then
            printf "\e[1;34m[INFO]\e[m # ansible-galaxy collection install git+https://{{repository}}/${project_lowercase}.git,v{{version}}\n"
            ansible-galaxy collection install git+https://{{repository}}/${project_lowercase}.git,v{{version}}
        else
            printf "\e[1;34m[INFO]\e[m # ansible-galaxy collection install git+https://{{repository}}/${project_lowercase}.git\n"
            ansible-galaxy collection install -U git+https://{{repository}}/${project_lowercase}.git
        fi
    fi

    # Install dependencies

    ## Get the path of this collection:
    user_collection_path=$(ansible-galaxy collection list ${ansible_namespace_lowercase}.${collection_name_lowercase} | awk '/^#/ {print $2}')
    collection_path="${user_collection_path}/${ansible_namespace_lowercase}/${collection_name_lowercase}"
