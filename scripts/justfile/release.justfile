set shell := ["bash", "-uc"]

# Release collection to the wanted version
_release project repository *version:
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

    # Check if project exist and set path
    number_of_projects_found=$( eval "${CMD} repo list | awk '{print $1}' | grep -iw "^.*/{{ project }}$" | wc -l" )

    if (( $number_of_projects_found == 0 )); then
        printf "\e[1;31m[ERROR]\e[m Project {{ project }} does not exist in your repository: {{repository}}.\n"
        exit 1        
    elif (( $number_of_projects_found > 1 )); then
        project_found=$(eval "${CMD} repo list  | grep -iw "^.*/{{ project }}"")
        printf "\e[1;31m[ERROR]\e[m There is several Project: {{ project }} which already exist in different namespace.\n"
        echo "${project_found}"
        exit 1
    elif (( $number_of_projects_found == 1 )); then
        project_found=$(eval "${CMD} repo list | grep -iw "^.*/{{ project }}"")
        project_to_release=$(echo ${project_found} | awk '{print $1;}')
        project_path="$HOME/${project_to_release}"
        project_lowercase=$(echo ${project_to_install} | tr '[:upper:]' '[:lower:]')
        printf "\e[1;32m[OK]\e[m Project ${project_to_release} exist, Let\'s release it... \n"
    fi

    # Check if path exist
    if [ -d ${project_path} ]; then 
      printf "\e[1;32m[OK]\e[m ${project_to_release} is in the expected directory ${project_path} \n"
    else
      printf "\e[1;31m[ERROR]\e[m Project path: ${project_path} is not present. First clone this project! \n"
      exit 1
    fi 

    # Check that version is coherent
    version_galaxy=$([ -f ${project_path}/galaxy.yml ] && awk -F":" '/version/ {print $2}' ${project_path}/galaxy.yml|tr -d ' ' || echo "Null")
    version_changelog=$([ -f ${project_path}/CHANGELOG.md ] && grep "##.*([0-9].*)" ${project_path}/CHANGELOG.md|head -1|awk '{print $2}'|tr -d ' ' || echo "Null")
    version_latest=$( eval "$CMD release list -R ${project_to_release} | awk '/^v/||/^V/ {sub(/v/,\"\");sub(/V/,\"\"); print \$1}' | head -1" )

    # By default take version from galaxy.yml 
    if [[ "{{version}}" != "" ]]; then
      version_requested="{{version}}"
    else
      version_requested="${version_galaxy}"
    fi

    printf "\e[1;34m[INFO]\e[m Version in galaxy.yml:   ${version_galaxy}    \n"
    printf "\e[1;34m[INFO]\e[m Version in CHANGELOG.md: ${version_changelog} \n"
    printf "\e[1;34m[INFO]\e[m Version latest in repo:  ${version_latest}    \n"
    printf "\e[1;34m[INFO]\e[m Version you requested:   ${version_requested} \n"

    ## Check that version requested is coherent with galaxy.yml and CHANGELOG.md
    if [[ ! -z ${version_galaxy} ]] && [[ ${version_latest} > ${version_galaxy} ]]; then
      printf "\e[1;31m[ERROR]\e[m Stop! Version in galaxy.yml  is lower than latest version found on repository..."
      exit 1
    elif [[ ! -z ${version_changelog} ]] && [[ ${version_latest} > ${version_changelog} ]]; then
      printf "\e[1;31m[ERROR]\e[m Stop! Version in CHANGELOG.md is lower than latest version found on repository..."
      exit 1
    elif [[ "${version_requested}" != "" ]] && [[ ${version_latest} > ${version_requested} ]]; then
      printf "\e[1;31m[ERROR]\e[m Stop! Version you requested to release is lower than latest version found on repository..."
      exit 1
    elif [[ "${version_requested}" != "" ]] && [[ ${version_latest} = ${version_requested} ]]; then
      printf "\e[1;31m[ERROR]\e[m Stop! Version you requested to release already exist on repository..."
      exit 1   
    else
      printf "\e[1;32m[OK]\e[m Version {{ version }} verified.\n"
    fi

    # Update galaxy.yml if it was not done
    if [[ "${version_requested}" != "" ]] && [[ ${version_requested} != ${version_galaxy} ]]; then
      printf "\e[1;34m[INFO]\e[m You did not completed the galaxy.yml with the version that you requested. Doing it for you.\n"
      sed -i "s/^version.*$/version: ${version_requested}/g" ${project_path}/galaxy.yml
      cd ${project_path}; git add galaxy.yml && git commit -m "update release version in galaxy" && git push
      printf "\e[1;32m[OK]\e[m File galaxy.yml updated with the version: ${version_requested}\n"
    fi

    # Update CHANGELOG.md if it was not done
    if [[ "${version_requested}" != "" ]] && [[ ${version_requested} != ${version_changelog} ]]; then
      printf "\e[1;34m[INFO]\e[m You did not completed the CHANGELOG.md with the version that you requested. Doing it for you.\n"
      printf "# CHANGELOG.md\n\n## ${version_requested} ($(date '+%Y-%m-%d'))" > ${project_path}/CHANGELOG.md
      
      # Notes for the CHANGELOG.md 
      read -p "Give somes notes for the CHANGELOG.md:  " note 
      printf "\n\n ${note} \n\n\n" >> ${project_path}/CHANGELOG.md

      # Display CHANGELOG.md
      cat ${project_path}/CHANGELOG.md
      
      # Pause to verify CHANGELOG.md
      while true; do
      read -p "# Do you want to git push CHANGELOG.md as it is above and proceed with release? (yes/no) " yn
      case $yn in 
        yes ) printf "\e[1;32m[OK]\e[m Let\'s push...\n\n";
              break;;
        no )  printf "\e[1;34m[INFO]\e[m Reset CHANGELOG.md\n"
              printf "# CHANGELOG.md\n" > ${project_path}/CHANGELOG.md
              printf "\e[1;34m[INFO]\e[m Complete the CHANGELOG.md and then relaunch same command.\n"
              echo exiting...;
              exit;;
        * )   printf "\e[1;31m[ERROR]\e[m invalid response\n";;
      esac
      done

      cd ${project_path}; git add CHANGELOG.md && git commit -m "update release version in CHANGELOG" && git push 
      printf "\e[1;32m[OK]\e[m File galaxy.yml updated with the version: ${version_requested}\n"
    fi

    # Releasing
    printf "\e[1;34m[INFO]\e[m Start Releasing version: v${version_requested}.\n"
    git tag -a v${version_requested} -m "$(cat changelog.md)"
    git push origin v${version_requested}
    cd ${project_path}; eval "${CMD} release create v${version_requested} -F CHANGELOG.md"
