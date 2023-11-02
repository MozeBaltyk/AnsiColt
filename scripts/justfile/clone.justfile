set shell := ["bash", "-euc"]

# Clone a project from repository keeping directory structure for ansible.
_clone project repository:
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
    # Setup command to eval
    CMD="${VAR_REPO_HOST}={{repository}} ${CLI_REPO}"
    #printf "CMD: \e[1;32m ${CMD} \e[m\n"

    # Connect to repo before
    # eval "${CMD} auth status"

    # Get the email associated with repo or set it if missing
    if [[ $(yq "${YQ_SEARCH}" ${CONFIG_FILE}) == null ]]; then
      # Ask for email
      while true; do
        read -p "Give a email to associate to this repository :  "  email
        if echo $email | grep -q '^[a-zA-Z0-9.]*@[a-zA-Z0-9]*\.[a-zA-Z0-9]*$'; then
          printf "\e[1;34m[INFO]\e[m This email will be set in all projects git config.\n";
          break;
        else
          printf "\e[1;31m[ERROR]\e[m This does NOT look like an email.\n"
        fi
      done
      # Set the email in repo config
      eval "yq eval '"${YQ_SEARCH}" = \"${email}\"' -i ${CONFIG_FILE}"
    else
      email=$(yq "${YQ_SEARCH}" ${CONFIG_FILE})
    fi

    # Define your user
    user=$( eval "${CMD} auth status 2>&1" | awk '{for (I=1;I<NF;I++) if ($I == "as") print $(I+1)}' )
    printf "\e[1;34m[INFO]\e[m Connected to {{repository}} with ${user}\n"

    # Create project on repository
    number_of_projects_found=$( eval "${CMD} repo list | awk '{print $1}' | grep -iw "^.*/{{ project }}$" | wc -l" )

    if (( $number_of_projects_found == 0 )); then
        printf "\e[1;31m[ERROR]\e[m Project {{ project }} does not exist in your repository: {{repository}}.\n"
    elif (( $number_of_projects_found == 1 )); then
        project_found=$( eval "${CMD} repo list | grep -iw "^.*/{{ project }}"" )
        project_to_clone=$(echo ${project_found} | awk '{print $1;}')
        project_lowercase=$(echo ${project_to_clone} | tr '[:upper:]' '[:lower:]')
        printf "\e[1;32m[OK]\e[m Project ${project_to_clone} exist, Let\'s clone it... \n"

        # Try first with gh/glab CLI to keep protocol
        printf "\e[1;34m[INFO]\e[m ${CMD} repo clone ${project_lowercase} $HOME/${project_to_clone} -- --recursive\n"
        eval "${CMD} repo clone ${project_lowercase} $HOME/${project_to_clone} -- --recursive" || {
          # if failed, retry with git clone on https
          printf "\e[1;34m[INFO]\e[m Second trial with in https: git clone https://{{repository}}/${project_lowercase}.git $HOME/${project_to_clone}\n"
          git clone --recursive https://{{repository}}/${project_lowercase}.git $HOME/${project_to_clone}
        }

        # Set user/email in git local otherwise the push are going to be with your global user.
        cd $HOME/${project_to_clone}; git config --local --replace-all user.name ${user}; cd - 
        cd $HOME/${project_to_clone}; git config --local --replace-all user.email ${email}; cd - 

    elif (( $number_of_projects_found > 1 )); then
        project_found=$( eval "${CMD} repo list  | grep -iw "^.*/{{ project }}"" )
        printf "\e[1;31m[ERROR]\e[m There is several Project: {{ project }} which already exist in different namespace.\n"
        echo "${project_found}"
    fi