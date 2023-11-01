set shell := ["bash", "-uc"]

REPOSITORY    :=  env_var_or_default('REPOSITORY', "github.com") 
TYPE          :=  env_var_or_default('TYPE', "private")

# Lists all available commands in the justfile.
_help:
    @printf "NAME\n"
    @printf "     AnsiColt - kickstart Ansible Collection\n"
    @printf "\n"
    @printf "SYNOPSIS\n"
    @printf "     colt [vars=value] recipe [arguments]... \n"
    @printf "\n"
    @printf "DESCRIPTION\n"
    @printf "     \'colt\' allow you to trigger recipes which are describes below. The arguments need to follow the order as described below.\n"
    @printf "     Arguments without \'*\' in front are mandatory, the one without are not mandatory. Default variables can be redefined before the recipe.\n"
    @printf "\n"
    @just --list --unsorted
    @printf "\n"
    @printf "DEFAULT VARIABLES\n"
    @printf "     REPOSITORY = {{REPOSITORY}}\n"
    @printf "     TYPE = {{TYPE}}\n"
    @printf "\n"
    @printf "EXAMPLE\n"
    @printf "     colt REPOSITORY=gitlab.com TYPE=public init AweSome DreamTEAM\n"

# Precheck synthax
_precheck_collection NAME:
    #!/usr/bin/env bash
    if ! echo "{{NAME}}" | egrep -q "^[a-zA-Z][a-zA-Z0-9_]+$"; then 
        printf "\e[1;31m[ERROR]\e[m The name choosen for the project is incompatible with an Ansible collection.\n";
        printf "\e[1;34m[INFO]\e[m Respect this REGEX ^[a-zA-Z][a-zA-Z0-9_]+$ in the name of your Ansible Collection.\n";
        exit 1
    fi

_precheck_role NAME:
    #!/usr/bin/env bash
    if ! echo "{{NAME}}" | egrep -q "^[a-z][a-z0-9_]+$"; then
        printf "\e[1;31m[ERROR]\e[m The name choosen for the role is incompatible with Ansible collection.\n";
        printf "\e[1;34m[INFO]\e[m Respect this REGEX ^[a-z][a-z0-9_]+$ in the name of your role.\n";
        exit 1
    fi

# List all your configured repositories.
list:
    @just -f scripts/justfile/list.justfile _list

# Create a new ansible collection on repository.
init PROJECT *GROUP:
    @just _precheck_collection {{PROJECT}}
    @just -f scripts/justfile/init.justfile _init {{PROJECT}} {{TYPE}} {{REPOSITORY}} {{GROUP}}

# Create a new ansible role inside an existing collection.
role GROUP PROJECT ROLE:
    @just _precheck_role {{ROLE}}

    cd ~/{{GROUP}}/{{PROJECT}}; email=$(git config --local user.email); cd -; \
    ansible-playbook playbooks/tasks/createRole.yml \
    -e role="{{ROLE}}" \
    -e project="{{PROJECT}}" \
    -e namespace="{{GROUP}}" \
    -e email="${email}"

# Release collection on your repository to the given version in command or in galaxy.yml.
release PROJECT *VERSION:
    @just _precheck_collection {{PROJECT}}
    @just -f scripts/justfile/release.justfile _release {{PROJECT}} {{REPOSITORY}} {{VERSION}}

# Clone a project from repository keeping directory structure for ansible.
clone PROJECT:
    @just -f scripts/justfile/clone.justfile _clone {{PROJECT}} {{REPOSITORY}}

# Git clone all projects from your repository, or if argument provided only from specific group.
clone_all *GROUP:
    @just -f scripts/justfile/clone_all.justfile _clone_all {{REPOSITORY}} {{GROUP}}

# Install a ansible collection. (if PROJECT is an artifact .tar.gz install local)
install PROJECT *VERSION:
    #!/usr/bin/env bash
    if [[ {{PROJECT}} =~ .*.tar.gz ]]; then
      printf "Install artifact: {{PROJECT}}\n"
      ansible-galaxy collection install -U {{PROJECT}}
    else
      printf "Install {{PROJECT}} from {{REPOSITORY}}\n"
      just -f scripts/justfile/install.justfile _install {{PROJECT}} {{REPOSITORY}} {{VERSION}} 
    fi

# Create a new empty project on remote repository.
blank PROJECT *GROUP:
    @just -f scripts/justfile/blank.justfile _blank {{PROJECT}} {{TYPE}} {{REPOSITORY}} {{GROUP}}

# Create a new ansible collection on localhost (not on repository like function below).
local PROJECT NAMESPACE:  
    @just _precheck_collection {{PROJECT}}

    #!/usr/bin/env bash
    ansible-playbook playbooks/tasks/createCollection.yml -e namespace="{{NAMESPACE}}" -e project="{{PROJECT}}"

# Build collection locally.
build PROJECT NAMESPACE:
    @just _precheck_collection {{PROJECT}}
    
    #!/usr/bin/env bash
    ansible-galaxy collection build $HOME/{{NAMESPACE}}/{{PROJECT}} --output-path $HOME/{{NAMESPACE}}/{{PROJECT}}

# Test 
_test PROJECT ROLE *NAMESPACE:
    #!/usr/bin/env bash
    echo {{PROJECT}}
    echo {{ROLE}}
    echo {{NAMESPACE}}
    echo {{REPOSITORY}}
    echo {{TYPE}}
