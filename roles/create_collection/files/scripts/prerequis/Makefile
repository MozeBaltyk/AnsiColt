ifneq ("$(wildcard /etc/redhat-release)","")
    PKG_MANAGER := yum
else ifneq ("$(wildcard /etc/debian_version)","")
    PKG_MANAGER := apt-get
endif

.PHONY: all
## everythings below
all: images arkade collections pythons bindeps

.PHONY: images
## Load images in files directories of each roles (since too big, those are in the .gitignore)
images:
	./load.sh

.PHONY: arkade
## Install admin kubernetes commands
arkade:
	./arkade.sh

.PHONY: collections
## Install ansible collection defined in ./deps/requirements.yml
collections:
	ansible-galaxy install -r ../../deps/requirements.yml

.PHONY: pythons
## Install pythons packages defined in ./deps/requirements.txt
pythons:
	python3 -m pip install -r ../../deps/requirements.txt

.PHONY: bindeps
## Install packages rpm/dep defined in ./deps/bindeps
bindeps:
        @echo "## Install Bindeps dependancies ##"
        @python3 -m pip install bindep
        @for i in $$( python3 -m bindep -bf ../../deps/bindeps.txt ); do echo "### $$i ###"; sudo $(PKG_MANAGER) install -y $$i; done

# keep it at the end of your Makefile
.DEFAULT_GOAL := show-help

# Inspired by <http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html>
.PHONY: show-help
show-help:
	@echo "$$(tput bold)Available rules:$$(tput sgr0)"
	@echo
	@sed -n -e "/^## / { \
                h; \
                s/.*//; \
                :doc" \
                -e "H; \
                n; \
                s/^## //; \
                t doc" \
                -e "s/:.*//; \
                G; \
                s/\\n## /---/; \
                s/\\n/ /g; \
                p; \
        }" ${MAKEFILE_LIST} \
        | LC_ALL='C' sort --ignore-case \
        | awk -F '---' \
                -v ncol=$$(tput cols) \
                -v indent=19 \
                -v col_on="$$(tput setaf 6)" \
                -v col_off="$$(tput sgr0)" \
        '{ \
                printf "%s%*s%s ", col_on, -indent, $$1, col_off; \
                n = split($$2, words, " "); \
                line_length = ncol - indent; \
                for (i = 1; i <= n; i++) { \
                        line_length -= length(words[i]) + 1; \
                        if (line_length <= 0) { \
                                line_length = ncol - indent - length(words[i]) - 1; \
                                printf "\n%*s ", -indent, " "; \
                        } \
                        printf "%s ", words[i]; \
                } \
                printf "\n"; \
        }' \
        | cat

