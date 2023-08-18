set shell := ["bash", "-uc"]

# Release collection to the wanted version
_init project type repository *group:
    #!/usr/bin/env bash
    repository_type=$(curl -Lis https://{{repository}}/ | egrep -oi "<title>.*GitHub<\/title>|<title>.*GitLab<\/title>" | awk '{sub(/<\/title>/,"");print $NF}' || echo "unknown repo")

    # Set repo vars
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
        VAR_REPO_HOST="GLAB_HOST"
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
    eval "${CMD} auth status"

    # Get the email associated with repo or set it if missing
    if [[ $(yq "${YQ_SEARCH}" ${CONFIG_FILE}) == null ]]; then
      # Ask for email
      while true; do
        read -p "Give a email to associate to this repository :  "  email
        if echo $email | grep -q '^[a-zA-Z0-9.]*@[a-zA-Z0-9]*\.[a-zA-Z0-9]*$'; then
          printf "\e[1;34m[INFO]\e[m This email will be set in all projects that you will create in the git config.\n";
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
    
    # Define Project namespace if group was provides or by default take user
    if [[ "{{group}}" != "" ]]; then
      namespace="{{group}}"
    elif [ -n "$user" ]; then
      namespace="${user}"
    else
      printf "\e[1;31m[ERROR]\e[m It did not get a group or username to define as namespace.\n"
      exit 1
    fi

    project_to_create="${namespace}/{{project}}"
    project_path="$HOME/${project_to_create}"
    project_lowercase=$(echo ${project_to_create} | tr '[:upper:]' '[:lower:]')  

    # Give a description
    while true; do
    read -p "Give a description to your project :  " description 
    case $description in 
        "" ) echo "You need to give a description";;
        * ) echo "Ok, Let continue";
            break;;
    esac
    done

    # Display infos
    printf "git repository: \e[1;32m {{repository}} \e[m\n"
    printf "git repository type: \e[1;32m ${repository_type} \e[m\n"
    printf "project to create: \e[1;32m ${project_to_create} \e[m\n"
    printf "project type: \e[1;32m {{type}} \e[m\n"
    printf "project description: \e[1;32m ${description} \e[m\n"
    printf "project author: \e[1;32m ${email} \e[m\n"

    # Pause to verify information
    while true; do
    read -p "Do you want to proceed with information above? (yes/no) " yn
    case $yn in 
        yes ) printf "\e[1;32m[OK]\e[m it will proceed\n";
              break;;
        no ) echo exiting...;
             exit;;
        * ) printf "\e[1;31m[ERROR]\e[m invalid response\n";;
    esac
    done

    # Create project on repository
    number_of_projects_found=$( eval "${CMD} repo list | grep -iw "^${project_lowercase}"| wc -l" )

    if (( $number_of_projects_found > 0 )); then
        printf "\e[1;31m[ERROR]\e[m Project ${project_lowercase} already exist.\n"
        exit 1
    else
        printf "\e[1;34m[INFO]\e[m ${CMD} repo create --{{type}} ${project_to_create}\n"
        eval "${CMD} repo create --{{type}} ${project_to_create}"
        #Could be also with gh/glab repo clone 
        git clone https://{{repository}}/${project_lowercase}.git ${project_path}

        # Set user/email in git local otherwise the push are going to be with your global user.
        cd ${project_path}; git config --local --replace-all user.name ${user}; cd -
        cd ${project_path}; git config --local --replace-all user.email ${email}; cd -

        ansible-playbook ../../playbooks/tasks/createCollection.yml \
          -e namespace="${namespace}" \
          -e project="{{project}}" \
          -e email="${email}" \
          -e description="${description}" \
          -e repository="{{repository}}"
        
        cd ${project_path}; git add -A; git commit -m "Initialisation Project ${namespace}/{{project}}"; git push
        printf "\e[1;32m[OK]\e[m Project ${project_to_create} successfully created on {{repository}},\n"
        printf "     and present on localhost:${project_path} with git config user.name equal to ${user}.\n"
    fi
