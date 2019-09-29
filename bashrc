# .bashrc

# Source global definitions
if [[ `uname -s` != "Darwin" ]]; then
  if [ -f /etc/bashrc ]; then
    . /etc/bashrc
  fi
fi

if [[ `uname -s` == "Darwin" ]]; then
  PATH=$PATH:/usr/local/opt/ruby/bin:/usr/local/share/npm/bin # Add Homebrew Ruby & Node Bin to PATH
  PATH=/usr/local/opt/libxml2/lib/pkgconfig:$PATH
  export HISTSIZE=
  export HISTFILESIZE=
fi

# Linux running under a Windows host
if test -f "$HOME/.windows_user.sh"; then
  . "$HOME/.windows_user.sh"
fi

WIN_HOME="/mnt/c/Users/$WIN_USER"
if [[ -d "$WIN_HOME" ]]; then
  sys32="/mnt/c/Windows/System32"
  mkdir -p "$WIN_HOME/bin"
  PATH="$WIN_HOME/bin:$PATH"
  PATH="$sys32/WindowsPowerShell/v1.0:$sys32:/mnt/c/Windows:$PATH"
  export WIN_HOME
  PATH=$WIN_HOME/bin:$PATH
fi
PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/local/heroku/bin:$PATH
PKG_CONFIG_PATH=$PATH
EDITOR=vim

# Linuxbrew
if [[ -d "/home/linuxbrew/.linuxbrew" ]]; then
  eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
fi

# ASDF language version manager
if [[ -n `which asdf 2> /dev/null` ]]; then
  export ASDF_HOME=`realpath "$(which asdf | xargs dirname)/.."`
  if [[ -d "$ASDF_HOME" ]];then
    . $ASDF_HOME/asdf.sh
    . $ASDF_HOME/completions/asdf.bash
  fi
fi

# Kubernetes Completions
programs=(helm kubectl minikube)
for prgm in "${programs[@]}"; do
  if [[ -n `which ${prgm} 2> /dev/null` ]]; then
    completion_file="${HOME}/.completions/${prgm}.bash"
    if test ! -f "$HOME/.completions/${prgm}.bash"; then
      mkdir -p "$(dirname ${completion_file})"
      ${prgm} completion bash > "${completion_file}"
    fi
    . ${completion_file}
  fi
done

# SSH-Agent for not needing to input passwords every time
if which ssh-agent > /dev/null; then
  if test -f "$HOME/.ssh/id_rsa"; then
    if [[ -n "$SSH_AGENT_PID" ]]; then
      ssh_agent_pid=`ps x | awk '{ print $1 }' | grep "^${SSH_AGENT_PID}$"`
      if [[ "$ssh_agent_pid" != "$SSH_AGENT_PID" ]]; then
        unset SSH_AGENT_PID
        unset SSH_AUTH_SOCK
      fi
    fi

    if [[ -z "$SSH_AGENT_PID" ]]; then
      eval "$(ssh-agent -s)"
      ssh-add "$HOME/.ssh/id_rsa"
    fi
  fi
fi

if test -f "$HOME/.github_api_token"; then
  export HOMEBREW_GITHUB_API_TOKEN=`cat "$HOME/.github_api_token"`
fi

if test -d "$HOME/depot_tools"; then
  PATH=$PATH:$HOME/depot_tools
fi

if [[ `uname -s` =~ "MINGW" ]]; then
  if test ! -d "$HOME/GitHub"; then
    mkdir -p "$HOME/GitHub"
  fi
  if [[ -z `mount | grep "GitHub"` ]]; then
    mount "$HOME/GitHub"
  fi

  # Put python in the PATH
  PATH=$PATH:/c/Python27
fi

# Unsafe Forking
if [[ `uname -s` == "Darwin" ]]; then
  export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
fi

export PATH
export PKG_CONFIG_PATH
export EDITOR
if [[ `uname -s` != "Darwin" ]]; then
  if [[ "$TERM" == "xterm" ]]; then
    export TERM="xterm-256color"
  fi
fi

# Clipboard integration
if [[ `uname -s` == "Linux" ]]; then
  alias pbcopy='xclip -selection c'
fi

# Concessions for WSL
if grep -q "Microsoft" "/proc/version"; then
  export DOCKER_HOST="tcp://0.0.0.0:2375"
  export DISPLAY=:0
fi

# User specific aliases and functions
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias vi='vim'
alias ll='ls -lh --color'
alias bi='bundle install'
alias be='bundle exec'
alias tmux='tmux attach || tmux -2'
alias git-yolo='git commit -am "DEAL WITH IT #YOLO" && git push -f origin master'
alias json-curl='curl -H "Content-Type: application/json" -XPOST'
alias grep='grep --color'
alias strip-newline="perl -pe 'chomp if eof'"
alias csv="column -s, -t"
alias rg="rg --smart-case --colors 'match:fg:magenta' --colors 'line:fg:black' --colors 'column:fg:red' --colors 'path:fg:yellow' -M 1000"
alias TODO="rg '# (TODO|FIXME|XXX)'"

if [[ -n `which dropbox 2> /dev/null` && -n `which ifconfig 2> /dev/null` ]]; then
  dboxstat=`dropbox status`
  ip_list=`ifconfig | grep -o "inet \(addr:\)\?[0-9\.]*" | grep -o "[0-9\.]*$" | grep -v "127.0.0.1"`
  if [[ -n "$ip_list" ]]; then
    if [[ -z `grep "fs.inotify.max_user_watches" /etc/sysctl.conf` ]]; then
      echo 200000 | sudo tee /proc/sys/fs/inotify/max_user_watches
      sudo su -c 'echo "fs.inotify.max_user_watches=200000" >> "/etc/sysctl.conf"'
    fi
    if [[ $dboxstat =~ "isn't running" ]]; then
      dropbox start
    elif [[ $dboxstat =~ "Connecting" ]]; then
      dropbox stop
      dropbox start
    fi
  fi
fi

# Disable Mac Animations
if [[ `uname -s` == "Darwin" ]]; then
  defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
fi

# Enable Bash Colors in OSX
if [[ `uname -s` == "Darwin" ]]; then
  export CLICOLOR=1
  export LS_COLORS='rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=01;05;37;41:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.dz=01;31:*.gz=01;31:*.lz=01;31:*.xz=01;31:*.bz2=01;31:*.tbz=01;31:*.tbz2=01;31:*.bz=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.axv=01;35:*.anx=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=01;36:*.au=01;36:*.flac=01;36:*.mid=01;36:*.midi=01;36:*.mka=01;36:*.mp3=01;36:*.mpc=01;36:*.ogg=01;36:*.ra=01;36:*.wav=01;36:*.axa=01;36:*.oga=01;36:*.spx=01;36:*.xspf=01;36:'
fi

# Enable Bash Completion from Homebrew
if [[ -n `which brew 2> /dev/null` ]]; then
  if [ -f "$(brew --prefix)/etc/bash_completion" ]; then
    . "$(brew --prefix)/etc/bash_completion"
  fi
fi

# Set JAVA_HOME
if [[ -z "$JAVA_HOME" && -n `which java 2> /dev/null` ]]; then
  if [[ -z `which java_home 2> /dev/null` ]]; then
    if [[ `uname -s` == "Darwin" ]]; then
      java_home_path="/System/Library/Frameworks/JavaVM.framework/Versions/Current/Commands/java_home"
      if test -e "$java_home_path"; then
        mkdir -p "$HOME/bin"
        ln -s "$java_home_path" "$HOME/bin/java_home"
      fi
    fi
  fi
  export JAVA_HOME=`java_home`
fi

# Set Prompt
if [ "$PS1" ]; then
  export PS1="[\t \u@\h \W]\\$ "

  git_prompt_sh="";
  if [ -f "/etc/bash_completion.d/git-prompt" ]; then
    git_prompt_sh="/etc/bash_completion.d/git-prompt"
  else
    if   [ -d "/usr/local/Cellar/git" ]; then
      git_dir="/usr/local/Cellar/git"
    elif [ -d "/usr/local/git" ]; then
      git_dir="/usr/local/git"
    elif [ -d "/usr/lib/git-core" ]; then
      git_dir="/usr/lib/git-core"
    elif [ -d "/usr/share/git-core" ]; then
      git_dir="/usr/share/git-core"
    fi
    git_prompt_sh=`find "$git_dir" -type f | grep git-prompt | head -1`
  fi

  old_ps1="$PS1"

  if [ -f "$git_prompt_sh" ]; then
    GIT_PS1_SHOWUPSTREAM="auto"
    GIT_PS1_SHOWCOLORHINTS="yes"
    source "$git_prompt_sh"
  fi

  __switchable_git_ps1() {
    git status &> /dev/null
    if [ $? == 0 ]; then
      bname=$(basename $(git rev-parse --show-toplevel))
      origin_repo_name=$(git remote -v show | grep -m1 '^origin.*(fetch)$' | awk '{ print $2 }')
      if [[ -n "$origin_repo_name" ]]; then
        bname=$(basename "$origin_repo_name" .git)
      fi
      suffix_prefix=""
      if [[ "$bname" == $(basename `pwd`) ]]; then
        suffix_prefix=' .'
      else
        suffix_prefix=' \W'
      fi
      __git_ps1 "$1$bname" "$suffix_prefix$2"
    else
      export PS1="$old_ps1"
    fi
  }

  ### For working with the ChefDK (with rvm)
  function parent_dir() {
    path=$PWD

    if [ "$#" -eq 1 ]; then path=$1; fi

    regex='(.+)(/.+$)'
    [[ $path =~ $regex ]]

    if [ -z "${BASH_REMATCH[1]}" ]; then
      echo '/'
    else
      echo "${BASH_REMATCH[1]}"
    fi
  }

  function check_for_chefdk_marker() {
    cwd=$PWD

    while [ "$cwd" != '/' ]; do
      [ -f "${cwd}/.chefdk" ] && return 0
      cwd=$(parent_dir "$cwd")
    done

    return 1
  }

  function __autoload_chefdk() {
    if check_for_chefdk_marker; then
      load_chefdk
    elif [ "$CHEFDK_FORCE_LOADED" != "1" ]; then
      unload_chefdk
    fi
  }

  # Force load pass any value after it. You'll need to force unload if you want
  # unload the chefdk.
  function load_chefdk() {
    if [ "$CHEFDK" != "1" ]; then
      old_path=$PATH
      old_gem_home=$GEM_HOME
      old_gem_path=$GEM_PATH
      old_gem_root=$GEM_ROOT

      eval "$(chef shell-init bash)"
      if [ "$?" -eq 0 ]; then
        if [ "$#" -eq 1 ]; then export CHEFDK_FORCE_LOADED=1; fi

        export CHEFDK_OLD_PATH=$old_path
        export CHEFDK_OLD_GEM_HOME=$old_gem_home
        export CHEFDK_OLD_GEM_PATH=$old_gem_path
        export CHEFDK_OLD_GEM_ROOT=$old_gem_root
        export CHEFDK=1

        echo "ChefDK loaded."
      fi
    fi
  }

  # To fore unload, pass any argument to the function.
  function unload_chefdk() {
    if [ "$CHEFDK" == "1" ]; then
      if [ "$#" -eq 1 ]; then export CHEFDK_FORCE_LOADED=0; fi

      export PATH=$CHEFDK_OLD_PATH
      export GEM_HOME=$CHEFDK_OLD_GEM_HOME
      export GEM_PATH=$CHEFDK_OLD_GEM_PATH
      export GEM_ROOT=$CHEFDK_OLD_GEM_ROOT
      export CHEFDK=0

      unset CHEFDK_OLD_PATH
      unset CHEFDK_OLD_GEM_HOME
      unset CHEFDK_OLD_GEM_PATH
      unset CHEFDK_OLD_GEM_ROOT

      echo 'Unloaded ChefDK.'
    fi
  }

  function __prompt_command() {
    __autoload_chefdk
    if [ -f "$git_prompt_sh" ]; then
      __switchable_git_ps1 "[\t " "]\\\$ ";
    fi
  }

  export PROMPT_COMMAND=__prompt_command
fi

# Export SSL_CERT_FILE on Darwin
if [[ `uname -s` == "Darwin" && -z "$SSL_CERT_FILE" ]]; then
  cert_file="/usr/local/opt/curl-ca-bundle/share/ca-bundle.crt"
  if test -e "$cert_file"; then
    export SSL_CERT_FILE="$cert_file"
  fi
fi

venv() {
  if [[ -z "$VIRTUAL_ENV" ]]; then
    if [[ -f "venv/bin/activate" ]]; then
      . "venv/bin/activate"
      echo "Virtualenv activated!"
    elif [[ -f "ENV/bin/activate" ]]; then
      . "ENV/bin/activate"
      echo "Virtualenv activated!"
    else
      echo "Virtualenv not found"
    fi
  else
    deactivate
    echo "Virtualenv deactivated!"
  fi
}
