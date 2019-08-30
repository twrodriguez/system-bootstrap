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
  if [[ -d "$2" ]]; then
    cd "$2"
    git pull
    cd -
  else
    git clone "$1" "$2"
  fi
}

vim_git_clone_or_update() {
  dir="$HOME/.vim/bundle/$(basename -s .git "$1")"
  if [[ -n "$2" ]]; then
    dir="$HOME/.vim/bundle/$2"
  fi

  git_clone_or_update "$1" "$dir"
}

install_asdf() {
  if [[ -z `which asdf 2> /dev/null` ]]; then
    export ASDF_HOME="$HOME/.asdf"
    git_clone_or_update "https://github.com/asdf-vm/asdf.git" "$ASDF_HOME"
    cd "$ASDF_HOME"
    git checkout "$(git describe --abbrev=0 --tags)"
    . asdf.sh
    cd -
  fi
}

install_latest_asdf_lang() {
  version=$(asdf list-all "$1" | grep -o "^[0-9.]\+$" | sort -V | tail -1)
  asdf install "$1" "$version"
  asdf global "$1" "$version"
}

install_all_asdf_plugins() {
  all_plugins=(helm kubectl minikube elixir julia kotlin python ruby rust scala)
  for lang in "${all_plugins[@]}"; do
    asdf plugin-add "$lang"
    install_latest_asdf_lang "$lang"
  done

  # Nodejs has to bootstrap trust
  asdf plugin-add nodejs
  bash "$ASDF_HOME/plugins/nodejs/bin/import-release-team-keyring"
  install_latest_asdf_lang nodejs
}

install_arrow_ubuntu18() {
  sudo apt update
  sudo apt install -y -V apt-transport-https gnupg lsb-release wget
  sudo wget -O /usr/share/keyrings/apache-arrow-keyring.gpg https://dl.bintray.com/apache/arrow/$(lsb_release --id --short | tr 'A-Z' 'a-z')/apache-arrow-keyring.gpg
  sudo tee /etc/apt/sources.list.d/apache-arrow.list <<APT_LINE
  deb [arch=amd64 signed-by=/usr/share/keyrings/apache-arrow-keyring.gpg] https://dl.bintray.com/apache/arrow/$(lsb_release --id --short | tr 'A-Z' 'a-z')/ $(lsb_release --codename --short) main
  deb-src [signed-by=/usr/share/keyrings/apache-arrow-keyring.gpg] https://dl.bintray.com/apache/arrow/$(lsb_release --id --short | tr 'A-Z' 'a-z')/ $(lsb_release --codename --short) main
APT_LINE

  sudo apt update
  sudo apt install -y -V libarrow-dev libarrow-glib-dev libplasma-dev libplasma-glib-dev libgandiva-dev libgandiva-glib-dev libparquet-dev libparquet-glib-dev
}

tmpdir="$HOME/bootstrap_tmp"

mkdir -p $tmpdir
mkdir -p "$HOME/bin" "$HOME/.ssh" "$HOME/.vim/autoload/airline/themes" "$HOME/.vim/bundle" "$HOME/.vim/syntax"

set -x
if [[ -d "$HOME/Dropbox/code/config" ]]; then
  cp -a $HOME/Dropbox/code/config/* $tmpdir/
elif [[ `pwd | xargs basename` == "system-bootstrap" ]]; then
  cp -a * $tmpdir/
else
  echo "System bootstrap files must be available. Exiting."
  exit 1
fi

if [[ `uname -s` == "Darwin" ]]; then
  echo -n ""
elif [[ `uname -s` =~ "MINGW" ]]; then
  echo -n ""
else
  chown "$SUDO_USER":"$SUDO_USER" $tmpdir/*
fi
set +x

# Find out information about a system
source "$tmpdir/env_vars.sh"

# TODO - install ~/.git_template (See http://stackoverflow.com/questions/2293498/git-commit-hooks-global-settings)
if [[ `uname -s` == "Darwin" ]]; then
  mv "$tmpdir/bashrc"  "$HOME/.bashrc"
  mv "$tmpdir/gitconfig"  "$HOME/.gitconfig"
  mv "$tmpdir/irbrc"  "$HOME/.irbrc"
  mv "$tmpdir/vimrc" "$HOME/.vimrc"
  mv "$tmpdir/eslintrc" "$HOME/.eslintrc"
  mv "$tmpdir/my.cnf" "$HOME/.my.cnf"
  mv "$tmpdir/sed_ri" "$HOME/bin/sed_ri"
  mv "$tmpdir/search" "$HOME/bin/search"
  mv "$tmpdir/pathogen.vim" "$HOME/.vim/autoload"
#  mv "$tmpdir/airline_theme.vim" "$HOME/.vim/autoload/airline/themes/airline_theme.vim"
  mv "$tmpdir/python.vim" "$HOME/.vim/syntax"
  mv "$tmpdir/pyrex.vim" "$HOME/.vim/syntax"
elif [[ `uname -s` =~ "MINGW" ]]; then
  mv "$tmpdir/bashrc"  "$HOME/.bashrc"
  mv "$tmpdir/irbrc"  "$HOME/.irbrc"
  mv "$tmpdir/vimrc" "$HOME/.vimrc"
  mv "$tmpdir/eslintrc" "$HOME/.eslintrc"
  mv "$tmpdir/pathogen.vim" "$HOME/.vim/autoload"
  mv "$tmpdir/python.vim" "$HOME/.vim/syntax"
  mv "$tmpdir/pyrex.vim" "$HOME/.vim/syntax"
else # Linux
  mv "$tmpdir/bashrc"  "$HOME/.bashrc"
  mv "$tmpdir/gitconfig"  "$HOME/.gitconfig"
  mv "$tmpdir/java_home"  "$HOME/bin/java_home"
  mv "$tmpdir/irbrc"  "$HOME/.irbrc"
  mv "$tmpdir/vimrc" "$HOME/.vimrc"
  mv "$tmpdir/eslintrc" "$HOME/.eslintrc"
  mv "$tmpdir/fstab"  "$HOME/fstab"
  mv "$tmpdir/my.cnf" "$HOME/.my.cnf"
  mv "$tmpdir/sed_ri" "$HOME/bin/sed_ri"
  mv "$tmpdir/search" "$HOME/bin/search"
  mv "$tmpdir/pathogen.vim" "$HOME/.vim/autoload"
  mv "$tmpdir/python.vim" "$HOME/.vim/syntax"
  mv "$tmpdir/pyrex.vim" "$HOME/.vim/syntax"
  echo "Be sure to edit /etc/fstab using ~/fstab as a template"
fi

# Install Homebrew if on Darwin
if [[ "$my_platform" == "darwin" && -n `which brew 2> /dev/null` ]]; then
  echo "Installing Xcode command line tools..."
  xcode-select --install

  echo "Installing Homebrew..."
  ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
fi

# Refresh information about underlying system
source "$tmpdir/env_vars.sh"

# Install necessary packages
source "$HOME/.bashrc"
if [[ "$my_method" == "install" ]]; then
  if [[ "$my_platform" == "darwin" ]]; then
    if [[ "$my_install" == "brew install" ]]; then

      brew doctor

      set -x
      brew install caskroom/cask/brew-cask
      brew install bash-completion ruby imagemagick p7zip python git gsl llvm@6 bison flex pipenv \
                   heroku-toolbelt gcc node vim tmux gs automake autoconf dnsmasq boost graphviz nmap \
                   libtool libmagic curl wget tesseract readline libxml++ libxml2 groovy ripgrep \
                   hunspell libyaml mercurial cmake htop-osx poppler gem-completion apache-arrow gpg \
                   pip-completion vagrant-completion ruby-completion rake-completion rails-completion \
                   bundler-completion haskell-platform the_silver_searcher ctags s3cmd asdf jq \
                   coreutils s3cmd docker

      set +x

      if [[ -e "/usr/local/lib/ImageMagick" ]]; then
        cd /usr/local/lib
        set -x
        libmagicks=$(ls libMagick*Q16.dylib)
        extension=".1.dylib"
        for FILE in $libmagicks; do
          BASENAME=$(basename "$FILE" .dylib)
          ln -s "$FILE" "$BASENAME$extension"
        done
        set +x
        cd -
      fi
    else
      echo "Couldn't find 'brew' command. It's highly recommended that you use 'http://brew.sh'"
      unknown_install_method && exit 1
    fi
  elif [[ "$my_platform" == "linux" ]]; then
    if [[ "$my_pkg_fmt" == "deb" ]]; then

      # TODO - Setup adobe flash repos? Dropbox? Chrome?

      set -x
      if [[ -n `which add-apt-repository 2> /dev/null` ]]; then
      #  sudo add-apt-repository ppa:openjdk-r/ppa

      #  if [[ -z `ls /etc/apt/sources.list.d/ 2> /dev/null | grep "elasticsearch"` ]]; then
      #    wget -qO - https://packages.elasticsearch.org/GPG-KEY-elasticsearch | apt-key add -
      #    add-apt-repository -y "deb http://packages.elasticsearch.org/elasticsearch/1.4/debian stable main"
      #  fi

        sudo apt-get update
      fi

      sudo apt-get upgrade -y

      sudo $my_install binutils gcc rbenv libxslt-dev python python-dev openjdk-8-jdk snap patchelf \
                        python-pip git imagemagick libmagickcore-dev libmagickwand-dev zlib1g-dev \
                        p7zip-full lsb gfortran dnsmasq nodejs libmagic-dev golang-go g++ ffmpeg \
                        vim curl wget ca-certificates f2c tmux eclipse libxml++-dev libhunspell-dev \
                        hunspell-dictionary-* libxml2-dev libyaml-dev libreadline-dev tesseract-ocr-* \
                        libssl-dev liblapack-dev libmysql++-dev libpq-dev libgsl-dev python3-dev \
                        postgresql-contrib sqlite3 libsqlite-dev postgresql-client mercurial zip gpg \
                        cmake htop poppler-utils poppler-data libpoppler-dev libgs-dev ghostscript \
                        scala haskell-platform silversearcher-ag exuberant-ctags python3-opengl dirmngr \
                        xclip libgeos-dev graphviz nmap groovy libboost-all-dev libosmesa6-dev llvm-8 \
                        pkg-config unzip libjpeg-dev swig python-pyglet libsdl2-dev xvfb dos2unix \
                        python3-pip llvm bison++ flex build-essential file unixodbc-dev jq clang-8

      if [[ -n `which snap 2> /dev/null` ]]; then
        snap install rg
      fi

      ubuntu_version=`lsb_release -r --short`
      if [[ "$ubuntu_version" == "18.04" ]]; then
        install_arrow_ubuntu18
      fi

      # Install ASDF language version manager
      install_asdf

      set +x

    elif [[ "$my_pkg_fmt" == "rpm" ]]; then

      # TODO - Setup adobe flash repos? Dropbox? Chrome?

      #if [[ -z `ls /etc/yum.repos.d/ 2> /dev/null | grep "elasticsearch"` ]]; then
        #rpm --import https://packages.elasticsearch.org/GPG-KEY-elasticsearch
        #cat > /etc/yum.repos.d/elasticsearch.repo << EOF
#[elasticsearch-1.4]
#name=Elasticsearch repository for 1.4.x packages
#baseurl=http://packages.elasticsearch.org/elasticsearch/1.4/centos
#gpgcheck=1
#gpgkey=http://packages.elasticsearch.org/GPG-KEY-elasticsearch
#enabled=1
#EOF
      #fi

      set -x

      sudo $my_pkg_mgr update -y
      sudo $my_install binutils* gcc rbenv libxslt-devel python python-devel python-pip \
                        git ImageMagick-devel p7zip @development-tools gsl-devel pipenv \
                        kernel-devel openssl nodejs npm dnsmasq file-libs redhat-lsb vim curl wget \
                        f2c tmux tar curl libxml++-devel hunspell-* tesseract-devel snapd \
                        libxml-devel zlib-devel libyaml-devel readline-devel openssl-devel lapack-devel \
                        tesseract-langpack-* postgresql-devel mysql-devel sqlite-devel llvm \
                        mercurial cmake htop poppler-devel ghostscript-devel scala haskell-platform \
                        the_silver_searcher ctags ripgrep geos-devel ipython-notebook graphviz nmap \
                        golang groovy unixODBC-devel jq

      # TODO - xclip, clang, llvm, gpg, dirmngr

      # Install ASDF language version manager
      install_asdf

      set +x

    else
      unknown_install_method && exit 1
    fi
  else
    echo "Don't know how to setup for this system"
  fi
fi

install_all_asdf_plugins

# Install pylint
pip install pylint git-lint pipenv

# Set up chef environment
gem install --no-ri --no-rdoc bundler flog reek ruby-lint rubocop sass

# Install JS command line tools
npm install -g uglify-js less coffee-script grunt-cli csslint jshint eslint babel-eslint eslint-plugin-react

# Install Vim plugins
vim_git_clone_or_update "https://github.com/scrooloose/nerdtree.git"
vim_git_clone_or_update "https://github.com/scrooloose/nerdcommenter.git"
vim_git_clone_or_update "https://github.com/scrooloose/syntastic.git"
vim_git_clone_or_update "https://github.com/ervandew/supertab.git"
vim_git_clone_or_update "https://github.com/tpope/vim-rails.git"
vim_git_clone_or_update "https://github.com/tpope/vim-bundler.git"
vim_git_clone_or_update "https://github.com/moll/vim-node.git"
vim_git_clone_or_update "https://github.com/docunext/closetag.vim.git" closetag
vim_git_clone_or_update "https://github.com/maksimr/vim-jsbeautify.git"
vim_git_clone_or_update "https://github.com/terryma/vim-multiple-cursors.git"
vim_git_clone_or_update "https://github.com/mbbill/undotree.git"
vim_git_clone_or_update "https://github.com/mhinz/vim-signify.git"
vim_git_clone_or_update "https://github.com/tpope/vim-fugitive.git"
vim_git_clone_or_update "https://github.com/bling/vim-airline.git"
vim_git_clone_or_update "https://github.com/dyng/ctrlsf.vim.git"
#vim_git_clone_or_update "https://github.com/myusuf3/numbers.vim.git" numbers
vim_git_clone_or_update "https://github.com/powerline/fonts.git" powerline-fonts
vim_git_clone_or_update "https://github.com/vim-airline/vim-airline-themes"
vim_git_clone_or_update "https://github.com/mxw/vim-jsx.git"
vim_git_clone_or_update "https://github.com/leafgarland/typescript-vim.git"
vim_git_clone_or_update "https://github.com/nathanaelkane/vim-indent-guides.git"
vim_git_clone_or_update "https://github.com/kien/rainbow_parentheses.vim.git" rainbow_parentheses
vim_git_clone_or_update "https://github.com/wincent/command-t.git"
vim_git_clone_or_update "https://github.com/derekwyatt/vim-scala"

cd "$HOME/.vim/bundle/vim-jsbeautify"
git submodule update --init --recursive
cd -

cd "$HOME/.vim/bundle/powerline-fonts"
./install.sh
cd -

cd "$HOME/.vim/bundle/command-t/ruby/command-t/ext/command-t"
rbenv exec ruby extconf.rb
make
cd -

rm -rf "$tmpdir"

# Source the newly-installed bashrc
source "$HOME/.bashrc"

# Setup Postgresql & Redis
# for ubuntu: https://www.digitalocean.com/community/tutorials/how-to-install-and-use-postgresql-on-ubuntu-16-04
# then: ALTER USER <user name> WITH PASSWORD '<your new password>';
# sudo -u postgres psql -c "CREATE USER root WITH SUPERUSER CREATEDB PASSWORD 'password'"
# https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-redis-on-ubuntu-16-04
