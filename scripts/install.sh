#!/usr/bin/bash
#
# For the README.md
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/MozeBaltyk/AnsiColt/main/scripts/install.sh)"
#

aliases='
alias colt="just -f $HOME/.ansible/collections/ansible_collections/mozebaltyk/ansicolt/justfile"
'

find_home_profile(){
  if [[ "$SHELL" == *"/zsh" ]]; then
    HOME_PROFILE="$HOME/.zshrc"
  elif [[ "$SHELL" == *"/bash" ]]; then
    HOME_PROFILE="$HOME/.bashrc"
  fi
}

# The [ -t 1 ] check only works when the function is not called from
# a subshell (like in `$(...)` or `(...)`, so this hack redefines the
# function at the top level to always return false when stdout is not
# a tty.
if [ -t 1 ]; then
  is_tty() {
    true
  }
else
  is_tty() {
    false
  }
fi

# Source: https://gist.github.com/XVilka/8346728
supports_truecolor() {
  case "$COLORTERM" in
  truecolor|24bit) return 0 ;;
  esac

  case "$TERM" in
  iterm           |\
  tmux-truecolor  |\
  linux-truecolor |\
  xterm-truecolor |\
  screen-truecolor) return 0 ;;
  esac

  return 1
}

supports_hyperlinks() {
  # $FORCE_HYPERLINK must be set and be non-zero (this acts as a logic bypass)
  if [ -n "$FORCE_HYPERLINK" ]; then
    [ "$FORCE_HYPERLINK" != 0 ]
    return $?
  fi

  # If stdout is not a tty, it doesn't support hyperlinks
  is_tty || return 1

  # DomTerm terminal emulator (domterm.org)
  if [ -n "$DOMTERM" ]; then
    return 0
  fi

  # VTE-based terminals above v0.50 (Gnome Terminal, Guake, ROXTerm, etc)
  if [ -n "$VTE_VERSION" ]; then
    [ $VTE_VERSION -ge 5000 ]
    return $?
  fi

  # If $TERM_PROGRAM is set, these terminals support hyperlinks
  case "$TERM_PROGRAM" in
  Hyper|iTerm.app|terminology|WezTerm) return 0 ;;
  esac

  # kitty supports hyperlinks
  if [ "$TERM" = xterm-kitty ]; then
    return 0
  fi

  # Windows Terminal also supports hyperlinks
  if [ -n "$WT_SESSION" ]; then
    return 0
  fi

  return 1
}

fmt_link() {
  # $1: text, $2: url, $3: fallback mode
  if supports_hyperlinks; then
    printf '\033]8;;%s\033\\%s\033]8;;\033\\\n' "$2" "$1"
    return
  fi

  case "$3" in
  --text) printf '%s\n' "$1" ;;
  --url|*) fmt_underline "$2" ;;
  esac
}

fmt_underline() {
  is_tty && printf '\033[4m%s\033[24m\n' "$*" || printf '%s\n' "$*"
}

# shellcheck disable=SC2016 # backtick in single-quote
fmt_code() {
  is_tty && printf '`\033[2m%s\033[22m`\n' "$*" || printf '`%s`\n' "$*"
}

fmt_error() {
  printf '%sError: %s%s\n' "${FMT_BOLD}${FMT_RED}" "$*" "$FMT_RESET" >&2
}

setup_color() {
  # Only use colors if connected to a terminal
  if ! is_tty; then
    FMT_RAINBOW=""
    FMT_RED=""
    FMT_GREEN=""
    FMT_YELLOW=""
    FMT_BLUE=""
    FMT_BOLD=""
    FMT_RESET=""
    return
  fi

  if supports_truecolor; then
    FMT_RAINBOW="
      $(printf '\033[38;2;255;0;0m')
      $(printf '\033[38;2;255;97;0m')
      $(printf '\033[38;2;247;255;0m')
      $(printf '\033[38;2;0;255;30m')
      $(printf '\033[38;2;77;0;255m')
      $(printf '\033[38;2;168;0;255m')
      $(printf '\033[38;2;245;0;172m')
      $(printf '\033[38;2;0;255;30m')
    "
  else
    FMT_RAINBOW="
      $(printf '\033[38;5;196m')
      $(printf '\033[38;5;202m')
      $(printf '\033[38;5;226m')
      $(printf '\033[38;5;082m')
      $(printf '\033[38;5;021m')
      $(printf '\033[38;5;093m')
      $(printf '\033[38;5;163m')
      $(printf '\033[38;5;082m')
    "
  fi

  FMT_RED=$(printf '\033[31m')
  FMT_GREEN=$(printf '\033[32m')
  FMT_YELLOW=$(printf '\033[33m')
  FMT_BLUE=$(printf '\033[34m')
  FMT_BOLD=$(printf '\033[1m')
  FMT_RESET=$(printf '\033[0m')
}


# Install Arkade
install_arkade() {
  LATEST_VERSION_URL="https://api.github.com/repos/alexellis/arkade/releases/latest"
  LATEST_VERSION=$(curl -s "${LATEST_VERSION_URL}" | grep '"tag_name":' | cut -d'"' -f4)
  DOWNLOAD_URL="https://github.com/alexellis/arkade/releases/download"
  if [[ ! -f /usr/local/bin/arkade ]]; then
      printf "\e[1;33m[CHANGE]\e[m arkade is not found. Installing...\n"
      curl -LO "${DOWNLOAD_URL}"/"${LATEST_VERSION}"/arkade > /dev/null 2>&1
      chmod +x arkade && sudo mv arkade /usr/local/bin/
      CURRENT_VERSION=$(arkade version | grep 'Version:' | awk '{ print $2 }')
      printf "\e[1;32m[OK]\e[m arkade $CURRENT_VERSION has been installed.\n"
  else
      CURRENT_VERSION=$(arkade version | grep 'Version:' | awk '{ print $2 }')
      printf "\e[1;34m[INFO]\e[m arkade is already installed.\n"
      printf "\e[1;34m[INFO]\e[m Checking for updates...\n"
      if [[ "$CURRENT_VERSION" != "$LATEST_VERSION" ]]; then
          printf "\e[1;33m[CHANGE]\e[m New version of arkade found, current: $CURRENT_VERSION. Updating...\n"
          curl -LO "${DOWNLOAD_URL}"/"${LATEST_VERSION}"/arkade > /dev/null 2>&1
          chmod +x arkade && sudo mv arkade /usr/local/bin/
          printf "\e[1;32m[OK]\e[m arkade has been updated to version $CURRENT_VERSION.\n"
      else
          CURRENT_VERSION=$(arkade version | grep 'Version:' | awk '{ print $2 }')
          printf "\e[1;34m[INFO]\e[m arkade $CURRENT_VERSION is up-to-date.\n"
      fi
  fi

  find_home_profile

  if ! grep -qF "export PATH=\$PATH:\$HOME/.arkade/bin" "$HOME_PROFILE"; then
      printf "\e[1;33m[CHANGE]\e[m Appending arkade bin path to $HOME_PROFILE...\n"
      echo "export PATH=\$PATH:\$HOME/.arkade/bin" >> "$HOME_PROFILE"
  else
      printf "\e[1;34m[INFO]\e[m ~/.arkade/bin path is already present in $HOME_PROFILE.\n"
  fi
}

# Install Just
install_just() {
  if command -v just >/dev/null 2>&1; then
      printf "\e[1;34m[INFO]\e[m just is already installed.\n"
  else
      if [ -f ~/.arkade/bin/just ]; then
          printf "\e[1;33m[CHANGE]\e[m just is not found. Installing...\n"
          arkade get just
      else
          printf "\e[1;31m[ERROR]\e[m arkade is not installed. Please install arkade first.\n"
      fi
  fi
}


# Install ansible-core
install_ansible() {
  if command -v ansible >/dev/null 2>&1; then
      printf "\e[1;34m[INFO]\e[m ansible is already installed.\n"
  else
      printf "\e[1;33m[CHANGE]\e[m ansible is not found. Installing ansible-core package...\n"
      if [ -f /etc/redhat-release ] ; then
        sudo dnf install -y ansible-core
      elif [ -f /etc/debian_version ] ; then
        sudo apt install -y ansible-core
      fi
  fi
}

# Install glab-cli
install_glab(){
    if [[ ! -f /usr/local/bin/glab ]]; then
        printf "\e[1;33m[CHANGE]\e[m glab is not found. Installing...\n"
        LATEST_VERSION_URL="https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/releases"
        LATEST_VERSION=$(curl -s "${LATEST_VERSION_URL}" | jq -r '.[0].tag_name' | sed 's/^v//')
        URL="https://gitlab.com/gitlab-org/cli/-/releases"
        DOWNLOAD_URL="${URL}"/v"${LATEST_VERSION}"/downloads/glab_"${LATEST_VERSION}"_Linux_x86_64.tar.gz
        curl -LO "${DOWNLOAD_URL}" >/dev/null 2>&1
        tar xzf glab_"${LATEST_VERSION}"_Linux_x86_64.tar.gz
        sudo mv bin/glab /usr/local/bin/
        rm -rf bin glab_"${LATEST_VERSION}"_Linux_x86_64.tar.gz
        printf "\e[1;32m[OK]\e[m glab has been installed.\n"
    else
        printf "\e[1;34m[INFO]\e[m glab is already installed.\n"
        printf "\e[1;34m[INFO]\e[m Checking for updates...\n"
        CURRENT_VERSION=$(glab version | awk '{ print $3 }')
        LATEST_VERSION_URL="https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/releases"
        LATEST_VERSION=$(curl -s "${LATEST_VERSION_URL}" | jq -r '.[0].tag_name' | sed 's/^v//')
        if [[ "$CURRENT_VERSION" != "$LATEST_VERSION" ]]; then
            printf "\e[1;33m[CHANGE]\e[m New version of glab found. Updating...\n"
            URL="https://gitlab.com/gitlab-org/cli/-/releases"
            DOWNLOAD_URL="${URL}"/v"${LATEST_VERSION}"/downloads/glab_"${LATEST_VERSION}"_Linux_x86_64.tar.gz
            curl -LO "${DOWNLOAD_URL}" >/dev/null 2>&1
            tar xzf glab_"${LATEST_VERSION}"_Linux_x86_64.tar.gz
            sudo mv bin/glab /usr/local/bin/
            rm -rf bin glab_"${LATEST_VERSION}"_Linux_x86_64.tar.gz
            printf "\e[1;32m[OK]\e[m glab has been updated to version v${LATEST_VERSION}.\n"
        else
            printf "\e[1;34m[INFO]\e[m glab is up-to-date.\n"
        fi
    fi

    find_home_profile

    if ! grep -qF "export PATH=\$PATH:\$HOME/.glab/bin" "$HOME_PROFILE"; then
        printf "\e[1;33m[CHANGE]\e[m Appending glab bin path to $HOME_PROFILE...\n"
        echo "export PATH=\$PATH:\$HOME/.glab/bin" >> "$HOME_PROFILE"
    else
        printf "\e[1;34m[INFO]\e[m ~/.glab/bin path is already present in $HOME_PROFILE.\n"
    fi
}


install_gh(){
  if command -v gh >/dev/null 2>&1; then
      printf "\e[1;34m[INFO]\e[m github-cli is already installed.\n"
  else
      printf "\e[1;33m[CHANGE]\e[m github-cli is not found. Installing gh package...\n"
      if [ -f /etc/redhat-release ] ; then
        sudo dnf install -y 'dnf-command(config-manager)'
        sudo dnf config-manager -y --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
        sudo dnf install -y gh
      elif [ -f /etc/debian_version ] ; then
        type -p curl >/dev/null || (sudo apt update && sudo apt install curl -y)
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
        && sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
        && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
        && sudo apt update \
        && sudo apt install gh -y
      fi
  fi
}

# Install AnsiColt Collection
install_ansicolt() {
  printf "\e[1;33m[CHANGE]\e[m Installing ansiColt...\n"
  ansible-galaxy collection install git+https://github.com/MozeBaltyk/AnsiColt.git > /dev/null 2>&1
  printf "\e[1;32m[OK]\e[m AnsiColt collection was installed.\n"
  ansible-galaxy collection list MozeBaltyk.AnsiColt
}


# Add Aliases in .config/aliases directory and in your zshrc or bashrc
install_aliases() {
  printf "\e[1;33m[CHANGE]\e[m Installing ansiColt aliases...\n"
  mkdir -p ~/.config/aliases

  echo "$aliases" > $HOME/.config/aliases/AnsiColt

  if [[ "$SHELL" == *"/zsh" ]]; then
    grep -wq '~/.config/aliases' $HOME/.zshrc || echo "[ -d ~/.config/aliases ] && source ~/.config/aliases/*" >> $HOME/.zshrc && true
    source ~/.config/aliases/*
  elif [[ "$SHELL" == *"/bash" ]]; then
    grep -wq '~/.config/aliases' $HOME/.bashrc || echo "[ -d ~/.config/aliases ] && source ~/.config/aliases/*" >> $HOME/.bashrc && true
    source ~/.config/aliases/*
  fi

  printf "\e[1;32m[OK]\e[m AnsiColt aliases were installed.\n"
}


# Succes Message
print_success() {
  printf '%s    ___  %s         %s        %s    _ %s   ______%s        %s    __%s   __  %s\n' $FMT_RAINBOW $FMT_RESET
  printf '%s   /   | %s   ____  %s   _____%s   (_)%s  / ____/%s  ____  %s   / /%s  / /_ %s\n' $FMT_RAINBOW $FMT_RESET
  printf '%s  / /| | %s  / __ \ %s  / ___/%s  / / %s / /     %s / __ \\ %s  / / %s / __/ %s\n' $FMT_RAINBOW $FMT_RESET
  printf '%s / ___ | %s / / / / %s (__  ) %s / /  %s/ /___   %s/ /_/ / %s / /  %s/ /_   %s\n' $FMT_RAINBOW $FMT_RESET
  printf '%s/_/  |_| %s/_/ /_/  %s/____/  %s/_/   %s\\____/   %s\\____/  %s/_/   %s\\__/  %s\n' $FMT_RAINBOW $FMT_RESET
  printf '%s         %s         %s        %s      %s         %s        %s      %s..... is now installed!%s\n' $FMT_RAINBOW $FMT_RESET
  printf '\n'
  printf '\n'
  printf "%s %s %s\n" "Before you start using ${FMT_BOLD}${FMT_YELLOW}AnsiColt${FMT_RESET} take a look over the" \
    "$(fmt_code "$(fmt_link "README" "file://$HOME/.ansible/collections/ansible_collections/MozeBaltyk/AnsiColt/README.md" --text)")" \
    "."
  printf '\n'
  printf '%s\n' "• Reload your profile with command $(fmt_code "source ~/.zshrc")"
  printf '%s\n' "• Do not hesite to contribute to the project: $(fmt_link @AnsiColt https://github.com/MozeBaltyk/AnsiColt/)"
  printf '%s\n' $FMT_RESET
}


setup_color
install_arkade
install_just
install_ansible
install_glab
install_gh
install_ansicolt
install_aliases
print_success
