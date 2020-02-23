#!/bin/bash -e

unknown_install_method() {
  echo "Not sure how to install the necessary packages"
  echo "INSTALL FAILED"
}

install_config_file() {
  echo "Installing $1..."
  # TODO - Append to existing file
  echo "Installed $1."
}

git_clone_or_update() {
  if test -d "$2"; then
    cd "$2"
    git pull
    cd -
  else
    git clone "$1" "$2"
  fi
}

defensive_wget() {
  if test -f "$2"; then
    rm -f "$2"
  fi

  if which curl &> /dev/null; then
    curl -sSfL "$1" -o "$2"
  elif which wget &> /dev/null; then
    wget "$1" "$2"
  else
    echo "Wow, no git, curl, or wget? You're boned."
    exit 1
  fi
}

defensive_curl() {
  if which curl &> /dev/null; then
    curl -sSfL "$1"
  elif which wget &> /dev/null; then
    wget -q -O - "$1"
  else
    echo "Wow, no curl or wget? You're boned."
    exit 1
  fi
}

install_all_asdf_plugins() {
  set +e
  # TODO: Imagemagick? groovy?
  asdf_install_latest elixir julia kotlin python ruby rust scala golang haskell R protoc crystal bazel

  # Nodejs has to bootstrap trust
  asdf plugin-add nodejs
  bash "$ASDF_HOME/plugins/nodejs/bin/import-release-team-keyring"
  asdf_upgrade nodejs

  asdf reshim
  set -e
}

install_linuxbrew() {
  # Linuxbrew
  if which git &> /dev/null; then
    mkdir -p "$HOME/.linuxbrew/bin"
    git_clone_or_update https://github.com/Homebrew/brew "$HOME/.linuxbrew/Homebrew"
    ln -s ~/.linuxbrew/Homebrew/bin/brew ~/.linuxbrew/bin
    eval $(~/.linuxbrew/bin/brew shellenv)
  else
    sh -c "$(defensive_curl 'https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh')"
  fi
}

install_asdf() {
  if [[ -z `which asdf 2> /dev/null` ]]; then
    export ASDF_HOME="$HOME/.asdf"
    local asdf_install_dir="$HOME/.asdf_install"
    if which git &> /dev/null; then
      git_clone_or_update "https://github.com/asdf-vm/asdf.git" "$ASDF_HOME"
      cd "$ASDF_HOME"
      git checkout "$(git describe --abbrev=0 --tags)"
      cd -
    else
      echo "Sadly, ASDF is useless without git."
      exit 1
    fi
    . "${ASDF_HOME}/asdf.sh"
  fi
}

tmpdir="$HOME/bootstrap_tmp"

# Get Windows Username
if grep -q "Microsoft" "/proc/version"; then
  if test -f "$HOME/.windows_user.sh"; then
    source "$HOME/.windows_user.sh"
  else
    read -p "Windows Username: " WIN_USER
    cat <<-EOF > "$HOME/.windows_user.sh"
export WIN_USER='$WIN_USER'
EOF
    export WIN_USER
  fi

  # TODO: Install scoop https://github.com/lukesampson/scoop
fi

mkdir -p $tmpdir
mkdir -p "$HOME/bin" "$HOME/.ssh"
mkdir -p "$HOME/.vim/autoload/airline/themes" "$HOME/.vim/bundle" "$HOME/.vim/syntax"

set -x
if test `pwd | xargs basename` == "system-bootstrap"; then
  cp -a * $tmpdir/
elif which git &> /dev/null; then
  git_clone_or_update 'https://github.com/twrodriguez/system-bootstrap.git' "$HOME/.system-bootstrap"
  cp -a "$HOME/.system-bootstrap"/* $tmpdir/
else
  defensive_wget 'https://github.com/twrodriguez/system-bootstrap/archive/master.zip' "$tmpdir/master.zip"
  unzip -qq "$tmpdir/master.zip" -d "$tmpdir"
  cp -a "${tmpdir}"/system-bootstrap-master/* $tmpdir/
fi
set +x

# Find out information about a system
source "$tmpdir/env_vars.sh"

# TODO - install ~/.git_template (See http://stackoverflow.com/questions/2293498/git-commit-hooks-global-settings)
mv "$tmpdir/bashrc"  "$HOME/.bashrc"
mv "$tmpdir/irbrc"  "$HOME/.irbrc"
mv "$tmpdir/vimrc" "$HOME/.vimrc"
mv "$tmpdir/eslintrc" "$HOME/.eslintrc"
mv "$tmpdir/pylintrc" "$HOME/.pylintrc"
mv "$tmpdir/pathogen.vim" "$HOME/.vim/autoload"
mv "$tmpdir/python.vim" "$HOME/.vim/syntax"
mv "$tmpdir/pyrex.vim" "$HOME/.vim/syntax"
if test -f "$HOME/.bash_profile"; then
  if [[ -z `grep asdf_install_latest "$HOME/.bash_profile"` ]]; then
    cat "$tmpdir/profile_fns" >> "$HOME/.bash_profile"
  fi
else
  mv "$tmpdir/profile_fns" "$HOME/.bash_profile"
fi

if [[ `uname -s` == "Darwin" ]]; then
  mv "$tmpdir/gitconfig"  "$HOME/.gitconfig"
  mv "$tmpdir/sed_ri" "$HOME/bin/sed_ri"
elif [[ `uname -s` =~ "MINGW" ]]; then
  echo -n ""
else # Linux
  mv "$tmpdir/gitconfig"  "$HOME/.gitconfig"
  mv "$tmpdir/java_home"  "$HOME/bin/java_home"
  mv "$tmpdir/sed_ri" "$HOME/bin/sed_ri"
fi

# Add Profile Functions
source "$HOME/.bashrc"

# Install ASDF Manually
install_asdf

# Install Homebrew
if ! which ruby &> /dev/null; then
  asdf_install_latest ruby
fi

kernel=`uname`
if [[ "$kernel" == "darwin" ]]; then
  echo "Installing Xcode command line tools..."
  xcode-select --install

  echo "Installing Homebrew..."
  ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
else
  install_linuxbrew
fi

brew doctor

set -x
brew install bash-completion ruby python imagemagick p7zip git gsl llvm@6 bison flex pipenv \
             gcc vim tmux gs automake autoconf dnsmasq boost graphviz nmap capnp pkg-config \
             libtool libmagic curl wget tesseract readline libxml++ libxml2 ripgrep libffi \
             hunspell libyaml cmake htop-osx poppler gem-completion apache-arrow gpg openssl \
             pip-completion vagrant-completion ruby-completion rake-completion rails-completion \
             bundler-completion ctags s3cmd jq coreutils docker parquet-tools docker-compose

set +x

install_all_asdf_plugins

# Install basic python utilities
pip install --user pylint git-lint pipenv pipx poetry

# Install basic ruby utilities
gem install bundler rake flog reek ruby-lint rubocop sass

# Install JS command line tools
npm install -g csslint jshint eslint babel-eslint eslint-plugin-react

bash "$tempdir/vim_bootstrap.sh"

rm -rf "$tmpdir"

# Source the newly-installed bashrc
source "$HOME/.bashrc"

# Powerline font for PuTTY
if grep -q "Microsoft" "/proc/version"; then
  putty_font="https://github.com/powerline/fonts/blob/master/DroidSansMonoDotted/Droid%20Sans%20Mono%20Dotted%20for%20Powerline.ttf"
  launch_browser "${putty_font}"
fi

# Generte SSH Key
if test ! -f "$HOME/.ssh/id_rsa"; then
  ssh-keygen -t rsa -b 4096
  cat "$HOME/.ssh/id_rsa.pub" | pbcopy
  launch_browser "https://github.com/settings/keys"
fi
