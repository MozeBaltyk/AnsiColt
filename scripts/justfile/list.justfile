set shell := ["bash", "-uc"]

# List all repository configured
_list:
    #!/usr/bin/env bash
 
    printf "\e[1;34m[INFO]\e[m Here, all your configured repositories:\n"

    printf "\n# List Github repo"
    gh auth status || :

    printf "\n# List Gitlab repo"
    glab auth status || :
