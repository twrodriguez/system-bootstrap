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
    xdg-open "$1"
  elif [[ "$my_platform" == "darwin" ]]; then
    open "$1"
  else
    echo "Please visit '$1'"
  fi
  echo "Press Enter to continue"
  read
}

setup_kubernetes() {
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

install_kubernetes_linux() {
  # Minikube
  # if test ! -e "$HOME/minikube"; then
  #   curl -Lo "$HOME/minikube" "https://storage.googleapis.com/minikube/releases/v0.28.0/minikube-linux-amd64"
  #   chmod +x "$HOME/minikube"
  # fi

  # Kubectl
  # snap install kubectl --classic

  # Helm
  # if ! command -v helm; then
  #   mkdir -p "$HOME/.helm"
  #   curl -Lo "$HOME/.helm/helm_install" "https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get"
  #   chmod +x "$HOME/.helm/helm_install"
  #   "$HOME/.helm/helm_install" --version 'latest'
  # fi
  install_latest_asdf_lang "minikube"
  install_latest_asdf_lang "kubectl"
  install_latest_asdf_lang "helm"
}

install_latest_asdf_lang() {
  asdf plugin-add "$1"
  version=$(asdf list-all "$1" | grep -o "^[0-9.]\+$" | sort -V | tail -1)
  asdf install "$1" "$version"
  asdf global "$1" "$version"
}

install_all_asdf_plugins() {
  all_plugins=(postgres mysql elasticsearch spark redis mongodb)
  for lang in "${all_plugins[@]}"; do
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
      brew install minio

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

        if [[ -z `ls /etc/apt/sources.list.d/ 2> /dev/null | grep "oracle"` ]]; then
          # Virtualbox
          codename=`lsb_release -c -s`
          wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
          sudo add-apt-repository -y "deb https://download.virtualbox.org/virtualbox/debian ${codename} contrib"
        fi

        sudo apt-get update
      fi

      sudo apt-get upgrade -y

      sudo $my_install binutils ca-certificates cmake curl dnsmasq docker-compose docker.io eclipse \
                        exuberant-ctags f2c gcc gfortran ghostscript git graphviz htop wget xclip \
                        hunspell-dictionary-* imagemagick ipython-notebook kvm libgeos-dev \
                        libgs-dev libhunspell-dev liblapack-dev libmagic-dev libmagickcore-dev \
                        libmagickwand-dev libmysql++-dev libpoppler-dev libpq-dev libreadline-dev \
                        libsqlite-dev libssl-dev libvirt-bin libxml++-dev libxml2-dev libxslt-dev \
                        libyaml-dev lsb memcached mercurial mysql-server nmap openjdk-8-jdk p7zip-full \
                        pgadmin3 poppler-data poppler-utils postgresql-client postgresql-contrib \
                        python-dev python-pip snap sqlite3 tesseract-ocr-* tmux vim virtualbox-5.2

      if [[ -n `which snap 2> /dev/null` ]]; then
        snap install rg
        snap install slack --classic
      fi

      #install_kubernetes_linux
      setup_kubernetes

      sudo usermod -a -G libvirtd $(whoami)
      newgrp libvirtd

      set +x

    elif [[ "$my_pkg_fmt" == "rpm" ]]; then

      # TODO - Setup adobe flash repos? Dropbox? Chrome?

      if [[ -z `ls /etc/yum.repos.d/ 2> /dev/null | grep "virtualbox"` ]]; then
        sudo wget -q https://download.virtualbox.org/virtualbox/rpm/fedora/virtualbox.repo -O /etc/yum.repos.d/virtualbox.repo
      fi

      set -x

      sudo $my_pkg_mgr update -y
      sudo $my_install @development-tools ImageMagick-devel binutils* cmake couchdb ctags curl \
                        dnsmasq docker eclipse f2c file-libs gcc geos-devel ghostscript-devel \
                        git graphviz htop hunspell-* ipython-notebook kernel-devel lapack-devel \
                        libxml++-devel libxml-devel libxslt-devel libyaml-devel memcached \
                        mercurial mongodb mysql-devel nmap openssl openssl-devel p7zip \
                        poppler-devel postgresql-devel postgresql-server python python-devel \
                        python-pip qemu-kvm readline-devel redhat-lsb ripgrep scala snapd \
                        sqlite-devel tar tesseract-devel tesseract-langpack-* tmux vim \
                        virt-install virt-manager wget zlib-devel


      if [[ -n `which snap 2> /dev/null` ]]; then
        # sudo ln -s /var/lib/snapd/snap /snap
        snap install slack --classic
      fi

      #install_kubernetes_linux
      setup_kubernetes

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

rm -rf "$tmpdir"

# Source the newly-installed bashrc
source "$HOME/.bashrc"

# Setup Postgresql & Redis
# for ubuntu: https://www.digitalocean.com/community/tutorials/how-to-install-and-use-postgresql-on-ubuntu-16-04
# then: ALTER USER <user name> WITH PASSWORD '<your new password>';
# sudo -u postgres psql -c "CREATE USER root WITH SUPERUSER CREATEDB PASSWORD 'password'"
# https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-redis-on-ubuntu-16-04
