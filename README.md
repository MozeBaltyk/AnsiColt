<h1 style="text-align: center;"><code> AnsiColt </code></h1>

For everytime I want to quickly start a new ansible collection.


[![Releases](https://img.shields.io/github/release/MozeBaltyk/AnsiColt)](https://github.com/MozeBaltyk/AnsiColt/releases)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-green.svg)](https://opensource.org/licenses/apache-2-0/)

## What's for ?

AnsiColt allow you with few commands to start developping an Ansible Collection on Github or Gitlab.     
It meant to be installed on WSL or any Linux developping server.

What it does on your computer ?   
- It will install AnsiColt as classic ansible collection in your $HOME/.ansible/collections directory.
- Add an alias in $HOME/.config/aliases to use the AnsiColt collection.
- It will install Arkade, just, gh and glab.

Why not use repository templates from Github ? Currently, I see four good reasons:   
- Here, I can variabilize templates that I push 
- This collection can be available in the Ansible-Galaxy Portal
- Handle projects in Github and Gitlab, private or public, but also local.
- Handle several project's workflow (local, remote, blank).

Why do I need it, there is an Ansible-galaxy command for this ? yes, but it does not:
- Initialize a project in your Github, then init your collection, and push it on Github.
- Fullfill a maximum of values in the galaxy.yml and other meta data in roles.
- Bring a structure to handles dependencies of your collection and scripts to resolv them.
- It also add somes extras customs scripts, linter, .gitignore and other tricks...
- By default set your project with a License Apache-2.0 (to come later a menu with diverse type of license)
- When cloning or creating projects, some good pratices are applied, like git config user in each project directory.    
  Which avoid to push later on with the global email which can be different for each repositories. 

Yes, You got it... It's an Ansible Collection to create an Ansible Collection, make sense! 


# Getting started 🚀 

## Prerequisites

Linux Host debian or RHEL (can be a VM or your WSL).

- [✅ curl](#curl-) 

the installer script will install: 
- arkade
- just
- gh / glab-cli
- ansible-core
- this collection and alias...

## Basic installation

- Install AnsiColt
```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/MozeBaltyk/AnsiColt/main/scripts/install.sh)" 
```

## Use it to create and build new projects:

By default, *github.com* is configured as default repository and project are *private*.

Those value can be adapted on the run:
- redefine env var with `export REPOSITORY=gitlab.example.com` in your terminal or inside ` ~/.config/aliases/AnsiColt`
- inside the command `colt REPOSITORY=gitlab.example.com install AnsiColt`

Manual below was autogenerated with : `colt`   

<!-- Autogenerated -->
```
NAME
     AnsiColt - kickstart Ansible Collection

SYNOPSIS
     colt [vars=value] recipe [arguments]... 

DESCRIPTION
     'colt' allow you to trigger recipes which are describes below. The arguments need to follow the order as described below.
     Arguments without '*' in front are mandatory, the one without are not mandatory. Default variables can be redefined before the recipe.

Available recipes:
    list                         # List all your configured repositories.
    init PROJECT *GROUP          # Create a new ansible collection on repository.
    role GROUP PROJECT ROLE      # Create a new ansible role inside an existing collection.
    release PROJECT *VERSION     # Release collection on your repository to the given version in command or in galaxy.yml.
    clone PROJECT                # Clone a project from repository keeping directory structure for ansible.
    clone_all *GROUP             # Git clone all projects from your repository, or if argument provided only from specific group.
    install PROJECT *VERSION     # Install a ansible collection. (if PROJECT is an artifact .tar.gz install local)
    blank PROJECT *GROUP         # Create a new empty project on remote repository.
    local PROJECT NAMESPACE      # Create a new ansible collection on localhost (not on repository like function below).
    build PROJECT NAMESPACE      # Build collection locally.
    test PROJECT ROLE *NAMESPACE # Test

DEFAULT VARIABLES
     REPOSITORY = github.com
     TYPE = private

EXAMPLE
     colt REPOSITORY=gitlab.com TYPE=public init AweSome DreamTEAM
```
<!-- END -->


Workflow with a remote repository :

- `colt init`       start a new Ansible collection - private project on remote repository (by default Github).

- `colt role`       to create new roles in your project.

- `colt release`    release your project to version given in command or found in galaxy.yml.

- `colt clone`      reimport the project in the right directory to stay compliant with colt.

- `colt clone_all`  reimport all projects from remote repository keeping directory structure.

- `colt install`    install collection from your remote repository in your current homedir.


Workflow on local computer:

- `colt local`   start a new Ansible collection project on your local computer (no git).

- `colt role`    to create new roles in your project.

- `colt build`   build an ansible collection to get an artificat which can be exported to Ansible-galaxy.

- `colt install` install collection artifact in your current homedir.

Extras:

- `colt blank`   start a blank project on remote repository.


## Verify

Check if AnsiColt is available:
```sh
ansible-galaxy collection list
```

Your new aliases:
```sh
cat ~/.config/aliases/*
```

# Documentation

Ansible collection templates were design following Redhat documentation:
- https://docs.ansible.com/ansible/latest/dev_guide/developing_collections.html
- https://docs.ansible.com/ansible/latest/user_guide/collections_using.html
- https://www.ansible.com/blog/hands-on-with-ansible-collections

Using Ansible Collections: 
- https://docs.ansible.com/ansible/latest/collections_guide/collections_using_playbooks.html#simplifying-module-names-with-the-collections-keyword

Linter:
- https://yamllint.readthedocs.io/en/stable/

Pre-commit:
- https://pre-commit.com/
- https://maikel.tiny-host.nl/ansible-linting-pre-commit/


# Special thanks 📢

* Alex Ellis, for its [Arkade project](https://github.com/alexellis/arkade). I cannot live without anymore.
* Casey Rodarmor, for the command runner [Justfile](https://github.com/casey/just). 
* Deniz, an anonymous celibrity in his country. 😸

# Roadmaps

Some ideas:
- Give LICENCE choice during the creation of the collection
- Possibility to improve this collection with plugins
- Github workflow to Autogenerate README / Documentation
- Github workflow to publish in Galaxy


#### \# AnsiColt stand for Ansible [ColtExpress](https://en.wikipedia.org/wiki/Colt_Express)


       o x o x o x o . . .
       o      _____            _______________ ___=====__T___
     .][__n_n_|DD[  ====_____  |    |.\/.|   | |   |_|     |_
     (________|__|_[_________]_|____|_/\_|___|_|___________|_|
    _/oo OOOOO oo`  ooo   ooo   o^o       o^o   o^o     o^o 
