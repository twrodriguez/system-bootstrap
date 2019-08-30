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

launch_browser() {
  # Launch Browser
  if [[ "$my_platform" == "linux" ]]; then
    xdg-open "$2"
  elif [[ "$my_platform" == "darwin" ]]; then
    open -a "$(/usr/local/bin/DefaultApplication -url 'http:')" "$2"
  else
    echo "Please visit '$2'$3"
  fi
  echo "Press Enter to continue"
  read
}

launch_browser_to_download() {
  launch_browser "$1" "$2" "and install $1 for your platform"
}

install_kubernetes_linux() {
  # Minikube
  if test ! -e "$HOME/minikube"; then
    curl -Lo "$HOME/minikube" "https://storage.googleapis.com/minikube/releases/v0.28.0/minikube-linux-amd64"
    chmod +x "$HOME/minikube"
  fi

  # Kubectl
  snap install kubectl --classic

  # Helm
  if ! command -v helm; then
    mkdir -p "$HOME/.helm"
    curl -Lo "$HOME/.helm/helm_install" "https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get"
    chmod +x "$HOME/.helm/helm_install"
    "$HOME/.helm/helm_install" --version 'latest'
  fi

  # Set up kubernetes
  minikube config set disk-size 60g
  minikube config set memory 4096
  minikube config set cpus 2
  minikube config set vm-driver virtualbox
  minikube addons enable heapster
  minikube addons enable ingress
  minikube addons enable metrics-server
  minikube start
  helm init
}

install_latest_asdf_lang() {
  version=$(asdf list-all "$1" | grep -o "^[0-9.]\+$" | sort -V | tail -1)
  asdf install "$1" "$version"
  asdf global "$1" "$version"
}

install_all_asdf_plugins() {
  all_plugins=(postgres mysql elasticsearch spark redis)
  for lang in "${all_plugins[@]}"; do
    asdf plugin-add "$lang"
    install_latest_asdf_lang "$lang"
  done
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
  mv "$tmpdir/airline_theme.vim" "$HOME/.vim/autoload/airline/themes/airline_theme.vim"
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
      brew cask install homebrew/cask-versions/adoptopenjdk8
      brew cask install virtualbox
      brew cask install vagrant
      brew install couchdb p7zip memcached minio

      install_all_asdf_plugins
      set +x

    else
      echo "Couldn't find 'brew' command. It's highly recommended that you use 'http://brew.sh'"
      unknown_install_method && exit 1
    fi
  elif [[ "$my_platform" == "linux" ]]; then
    if [[ "$my_pkg_fmt" == "deb" ]]; then

      # TODO - Setup adobe flash repos? Dropbox? Chrome?

      set -x
      if [[ -n `which add-apt-repository 2> /dev/null` ]]; then
        sudo add-apt-repository ppa:openjdk-r/ppa
      #  if [[ -z `ls /etc/apt/sources.list.d/ 2> /dev/null | grep "elasticsearch"` ]]; then
      #    wget -qO - https://packages.elasticsearch.org/GPG-KEY-elasticsearch | apt-key add -
      #    add-apt-repository -y "deb http://packages.elasticsearch.org/elasticsearch/1.4/debian stable main"
      #  fi

        if [[ -z `ls /etc/apt/sources.list.d/ 2> /dev/null | grep "oracle"` ]]; then
          # Virtualbox
          codename=`lsb_release -c -s`
          wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
          sudo add-apt-repository -y "deb https://download.virtualbox.org/virtualbox/debian ${codename} contrib"
        fi

        sudo apt-get update
      fi

      sudo apt-get upgrade -y

      sudo $my_install binutils gcc rbenv libxslt-dev python python-dev openjdk-8-jdk snap virtualbox-5.2 \
                        python-pip git imagemagick libmagickcore-dev libmagickwand-dev couchdb \
                        memcached redis-server p7zip-full lsb gfortran dnsmasq nodejs libmagic-dev golang-go \
                        vim curl wget ca-certificates f2c tmux eclipse libxml++-dev libhunspell-dev \
                        hunspell-dictionary-* libxml2-dev libyaml-dev libreadline-dev tesseract-ocr-* \
                        libssl-dev liblapack-dev postgresql mysql-server libmysql++-dev libpq-dev \
                        postgresql-contrib pgadmin3 sqlite3 libsqlite-dev postgresql-client mercurial \
                        cmake htop poppler-utils poppler-data libpoppler-dev libgs-dev ghostscript \
                        scala haskell-platform julia elasticsearch silversearcher-ag exuberant-ctags \
                        golang-go docker.io xclip libgeos-dev ipython-notebook graphviz nmap kvm libvirt-bin \
                        docker-compose groovy mongodb

      if [[ -n `which snap 2> /dev/null` ]]; then
        snap install rg
        snap install slack --classic
      fi

      install_kubernetes_linux

      sudo usermod -a -G libvirtd $(whoami)
      newgrp libvirtd

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

      if [[ -z `ls /etc/yum.repos.d/ 2> /dev/null | grep "virtualbox"` ]]; then
        sudo wget -q https://download.virtualbox.org/virtualbox/rpm/fedora/virtualbox.repo -O /etc/yum.repos.d/virtualbox.repo
      fi

      set -x

      sudo $my_pkg_mgr update -y
      sudo $my_install binutils* gcc rbenv elasticsearch libxslt-devel python python-devel python-pip \
                        git ImageMagick-devel couchdb memcached redis p7zip @development-tools \
                        kernel-devel openssl nodejs npm dnsmasq file-libs redhat-lsb vim curl wget \
                        f2c tmux eclipse tar curl libxml++-devel hunspell-* tesseract-devel snapd \
                        libxml-devel zlib-devel libyaml-devel readline-devel openssl-devel lapack-devel \
                        tesseract-langpack-* postgresql-devel postgresql-server mysql-devel sqlite-devel \
                        mercurial cmake htop poppler-devel ghostscript-devel scala haskell-platform \
                        the_silver_searcher ctags ripgrep geos-devel ipython-notebook graphviz nmap \
                        qemu-kvm virt-manager virt-install golang docker groovy mongodb
      # TODO - Julia Programming Language Install
      # TODO - Go lang install
      # TODO - Rust lang install
      # TODO - Docker
      # TODO - xclip

      if [[ -n `which snap 2> /dev/null` ]]; then
        # sudo ln -s /var/lib/snapd/snap /snap
        snap install kubectl --classic
        snap install slack --classic
      fi

      install_kubernetes_linux

      sudo usermod -a -G libvirt $(whoami)
      newgrp libvirtd

      set +x

    else
      unknown_install_method && exit 1
    fi
  else
    echo "Don't know how to setup for this system"
  fi
fi

# Install pylint
pip install pylint virtualenv git-lint

# Set up chef environment
if test ! -d "$HOME/.rbenv/plugins/ruby-build"; then
  git clone https://github.com/sstephenson/ruby-build.git "$HOME/.rbenv/plugins/ruby-build"
fi
if [[ -z `rbenv versions | grep "2\.4\.1"` ]]; then
  rbenv install 2.4.1
  rbenv rehash
fi
rbenv global 2.4.1
gem install --no-ri --no-rdoc chef multi_json knife-ec2 berkshelf bundler foodcritic flog reek ruby-lint rubocop sass


# Install NVM
git clone "https://github.com/creationix/nvm.git" "$HOME/.nvm"
cd "$HOME/.nvm"
git checkout v0.33.8
. nvm.sh
cd -

# Install JS command line tools
nvm install node
nvm use node
npm install -g uglify-js less coffee-script grunt-cli csslint jshint eslint babel-eslint eslint-plugin-react

# Install Google's Closure Linter
easy_install http://closure-linter.googlecode.com/files/closure_linter-latest.tar.gz

# Install Vim plugins

# Syntastic
cd "$HOME/.vim/bundle"
git clone "https://github.com/scrooloose/nerdtree.git"
git clone "https://github.com/scrooloose/nerdcommenter.git"
git clone "https://github.com/scrooloose/syntastic.git"
git clone "https://github.com/ervandew/supertab.git"
git clone "https://github.com/tpope/vim-rails.git"
git clone "https://github.com/tpope/vim-bundler.git"
git clone "https://github.com/moll/vim-node.git"
git clone "https://github.com/docunext/closetag.vim.git" closetag
git clone "https://github.com/maksimr/vim-jsbeautify.git"
git clone "https://github.com/terryma/vim-multiple-cursors.git"
git clone "https://github.com/mbbill/undotree.git"
git clone "https://github.com/mhinz/vim-signify.git"
git clone "https://github.com/tpope/vim-fugitive.git"
git clone "https://github.com/bling/vim-airline.git"
git clone "https://github.com/dyng/ctrlsf.vim.git"
#git clone "https://github.com/myusuf3/numbers.vim.git" numbers
git clone "https://github.com/powerline/fonts.git" powerline-fonts
git clone "https://github.com/vim-airline/vim-airline-themes"
git clone "https://github.com/mxw/vim-jsx.git"
git clone "https://github.com/leafgarland/typescript-vim.git"
git clone "https://github.com/nathanaelkane/vim-indent-guides.git"
git clone "https://github.com/kien/rainbow_parentheses.vim.git" rainbow_parentheses
git clone "https://github.com/wincent/command-t.git"
git clone "https://github.com/derekwyatt/vim-scala"
cd -
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
