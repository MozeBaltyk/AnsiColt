set shell := ["bash", "-uc"]

# Clone a project from repository keeping directory structure for ansible.
_clone_all repository group='NULL':
    #!/usr/bin/env bash    
    repository_type=$(curl -Lis https://{{repository}}/ | egrep -oi "<title>.*GitHub<\/title>|<title>.*GitLab<\/title>" | awk '{sub(/<\/title>/,"");print $NF}' || echo "unknown repo")
    
    printf "\e[1;34m[INFO]\e[m repository type: ${repository_type}.\n"

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
        VAR_REPO_HOST="GLAB_HOST"
        CLI_REPO="glab"
        CONFIG_REPO="$HOME/.config/glab-cli"
        # Setup command to eval
        CMD="${VAR_REPO_HOST}={{repository}} ${CLI_REPO}"
    else
        printf "\e[1;31m[ERROR]\e[m unknown repository.\n"
        exit 1
    fi

    # Connect to repo before
    eval "${CMD} auth status"

    # Define your user
    user=$( eval "${CMD} auth status 2>&1" | awk '{for (I=1;I<NF;I++) if ($I == "as") print $(I+1)}' )
    printf "\e[1;34m[INFO]\e[m Connected to {{repository}} with ${user}\n"

    # Create project on repository
    number_of_projects_found=$( eval "${CMD} repo list | wc -l" )

    if (( $number_of_projects_found == 0 )); then
        printf "\e[1;31m[ERROR]\e[m There is no project in your repository: {{repository}}.\n"
    elif (( $number_of_projects_found >= 1 )) && [[ "{{group}}" == "NULL" ]]; then
        project_found=$( eval "${CMD} repo list" | awk '{print $1;}')
        for project_to_clone in ${project_found}; do
            printf "\e[1;32m[OK]\e[m Project ${project_to_clone} exist, Let\'s clone it... \n"
            project_lowercase=$(echo ${project_to_clone} | tr '[:upper:]' '[:lower:]')
            printf "\e[1;34m[INFO]\e[m # git clone https://{{repository}}/${project_lowercase}.git $HOME/${project_to_clone}\n"
            #Could be also done with gh/glab repo clone 
            git clone https://{{repository}}/${project_lowercase}.git $HOME/${project_to_clone}

            # Your Connexion user is set as git local user.name otherwise the push are going to be with your global user.
            cd $HOME/${project_to_clone}; git config --local user.name ${user}

        done
    elif (( $number_of_projects_found >= 1 )) && [[ "{{group}}" != "NULL" ]]; then
        # Here we filter on specific group or user
        project_found=$( eval "${CMD} repo list" | awk '{print $1;}' | grep -wi "{{group}}")
        for project_to_clone in ${project_found}; do
            printf "\e[1;32m[OK]\e[m Project ${project_to_clone} exist, Let\'s clone it... \n"
            project_lowercase=$(echo ${project_to_clone} | tr '[:upper:]' '[:lower:]')
            printf "\e[1;34m[INFO]\e[m # git clone https://{{repository}}/${project_lowercase}.git $HOME/${project_to_clone}\n"
            #Could be also done with gh/glab repo clone 
            git clone https://{{repository}}/${project_lowercase}.git $HOME/${project_to_clone}

            # Your Connexion user is set as git local user.name otherwise the push are going to be with your global user.
            cd $HOME/${project_to_clone}; git config --local user.name ${user}

        done
    fi
