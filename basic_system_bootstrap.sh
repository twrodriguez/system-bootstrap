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

setup_kubernetes() {
  set +e
  asdf_install_latest helm kubectl minikube stern kubeval golang terraform istioctl skaffold packer reckoner kops
  set -e

  # Set up kubernetes
  if [[ "${my_platform}" == "linux" ]]; then
    if [[ "${my_host_platform}" != "windows" ]]; then
      # Start k8s via minikube
      minikube config set disk-size 60g
      minikube config set memory 4096
      minikube config set cpus $(expr ${num_cpus} / 2)
      minikube config set vm-driver virtualbox
      minikube addons enable heapster
      minikube addons enable ingress
      minikube addons enable metrics-server
      minikube start
    else
      # Copy the .kube config from Docker Desktop for Windows
      if test ! -f "/mnt/c/Users/${WIN_USER}/.kube/config"; then
        echo "You need to install kubernetes into your Docker Desktop for Windows. Press <Enter> when you have."
        read
      fi
      mkdir -p "${HOME}/.kube"
      cp "/mnt/c/Users/${WIN_USER}/.kube/config" "${HOME}/.kube"
    fi
  fi

  asdf reshim
  helm init
}

install_all_asdf_plugins() {
  set +e
  # TODO: Imagemagick? groovy?
  asdf_install_latest elixir julia kotlin python ruby rust scala golang haskell R protoc crystal bazel ripgrep

  # Nodejs has to bootstrap trust
  asdf plugin-add nodejs
  bash "$ASDF_HOME/plugins/nodejs/bin/import-release-team-keyring"
  asdf_upgrade nodejs
  set -e
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

install_arrow_centos() {
  sudo tee /etc/yum.repos.d/Apache-Arrow.repo <<REPO
[apache-arrow]
name=Apache Arrow
baseurl=https://dl.bintray.com/apache/arrow/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://dl.bintray.com/apache/arrow/centos/RPM-GPG-KEY-apache-arrow
REPO
  sudo yum install -y epel-release
  sudo yum install -y --enablerepo=epel arrow-devel # For C++
  sudo yum install -y --enablerepo=epel arrow-glib-devel # For GLib (C)
  sudo yum install -y --enablerepo=epel parquet-devel # For Apache Parquet C++
  sudo yum install -y --enablerepo=epel parquet-glib-devel # For Parquet GLib (C)
}

install_fbec() {
  # https://github.com/chronoxor/CppSerialization#how-to-build
  pipx install gil
  asdf reshim
  mkdir -p "$HOME/software"
  fbe_lib="$HOME/software/FastBinaryEncoding"
  git_clone_or_update "https://github.com/chronoxor/FastBinaryEncoding.git" "$fbe_lib"
  cd "$fbe_lib"
  gil update
  cd -
  cd "$fbe_lib/build"
  ./unix.sh
  # TODO: Windows native
}

install_capnproto_centos() {
  echo ""
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
mv "$tmpdir/bashrc"  "$HOME/.bashrc"
mv "$tmpdir/irbrc"  "$HOME/.irbrc"
mv "$tmpdir/vimrc" "$HOME/.vimrc"
mv "$tmpdir/eslintrc" "$HOME/.eslintrc"
mv "$tmpdir/pylintrc" "$HOME/.pylintrc"
mv "$tmpdir/pathogen.vim" "$HOME/.vim/autoload"
mv "$tmpdir/python.vim" "$HOME/.vim/syntax"
mv "$tmpdir/pyrex.vim" "$HOME/.vim/syntax"
cat "$tmpdir/profile_fns" >> "$HOME/.profile"

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
  if which brew &> /dev/null; then

    brew doctor

    set -x
    brew install bash-completion ruby imagemagick p7zip python git gsl llvm@6 bison flex pipenv \
                 gcc node vim tmux gs automake autoconf dnsmasq boost graphviz nmap capnp \
                 libtool libmagic curl wget tesseract readline libxml++ libxml2 libffi \
                 hunspell libyaml cmake htop-osx poppler gem-completion apache-arrow gpg openssl \
                 pip-completion vagrant-completion ruby-completion rake-completion rails-completion \
                 bundler-completion ctags s3cmd asdf jq coreutils docker parquet-tools \
                 pkg-config docker-compose openjdk

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
  elif [[ "$my_platform" == "linux" ]]; then
    if [[ "$my_pkg_fmt" == "deb" ]]; then

      # TODO - Setup adobe flash repos? Dropbox? Chrome?

      set -x

      sudo apt-get update -y
      sudo apt-get upgrade -y

      if grep -q "Microsoft" "/proc/version"; then
        sudo apt-get remove openssh-server # Need to re-install from scratch
      fi

      sudo apt install binutils gcc libxslt-dev python python-dev openjdk-8-jdk snap patchelf \
                        python-pip git imagemagick libmagickcore-dev libmagickwand-dev zlib1g-dev \
                        p7zip-full lsb gfortran dnsmasq nodejs libmagic-dev g++ ffmpeg libcurl4-openssl-dev \
                        vim curl wget ca-certificates f2c tmux eclipse libxml++-dev libhunspell-dev \
                        hunspell-dictionary-* libxml2-dev libyaml-dev libreadline-dev tesseract-ocr-eng \
                        libssl-dev liblapack-dev libmysql++-dev libpq-dev libgsl-dev python3-dev \
                        postgresql-contrib sqlite3 libsqlite-dev postgresql-client zip gpg dirmngr \
                        cmake htop poppler-utils poppler-data libpoppler-dev libgs-dev ghostscript \
                        exuberant-ctags python3-opengl libffi-dev libsasl2-dev libldap2-dev clang-8 \
                        xclip libgeos-dev graphviz nmap libboost-all-dev libosmesa6-dev llvm-8 \
                        pkg-config unzip libjpeg-dev swig python-pyglet libsdl2-dev xvfb dos2unix \
                        python3-pip bison++ flex build-essential file unixodbc-dev jq python3.6-dev \
                        openssh-server ssh capnproto

      ubuntu_version=`lsb_release -r --short`
      if grep -q "Microsoft" "/proc/version"; then
        sudo sed -i "s/^\s*#\?\s*PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
        sudo service ssh --full-restart
      fi

      # Apache Arrow
      if [[ "$ubuntu_version" == "18.04" ]]; then
        install_arrow_ubuntu18
      fi


      # Install ASDF language version manager
      install_asdf

      set +x

    elif [[ "$my_pkg_fmt" == "rpm" ]]; then

      # TODO - Setup adobe flash repos? Dropbox? Chrome?
      set -x

      sudo $my_pkg_mgr update -y
      sudo $my_install binutils* gcc libxslt-devel python python-devel python-pip wget \
                        git ImageMagick-devel p7zip @development-tools gsl-devel pipenv nmap \
                        kernel-devel openssl nodejs npm dnsmasq file-libs redhat-lsb vim curl \
                        f2c tmux tar libcurl-devel libxml++-devel hunspell-* tesseract-devel snapd \
                        libxml-devel zlib-devel libyaml-devel readline-devel openssl-devel \
                        tesseract-langpack-eng postgresql-devel mysql-devel sqlite-devel xclip \
                        cmake htop poppler-devel ghostscript-devel scala haskell-platform \
                        the_silver_searcher ctags geos-devel ipython-notebook graphviz \
                        golang groovy unixODBC-devel jq lapack-devel gcc-c++ libffi-devel \
                        openldap-devel libsasl2-devel gnupg clang llvm-devel dirmngr

      install_arrow_centos

      # Install ASDF language version manager
      install_asdf

      # install_capnproto_centos

      set +x

    else
      unknown_install_method && exit 1
    fi
  else
    echo "Don't know how to setup for this system"
  fi
fi

install_all_asdf_plugins
setup_kubernetes

# Install basic python utilities
pip install --user pylint git-lint pipenv pipx poetry

# Install basic ruby utilities
gem install bundler rake flog reek ruby-lint rubocop sass

# Install JS command line tools
npm install -g csslint jshint eslint babel-eslint eslint-plugin-react

bash "$tempdir/vim_bootstrap.sh"

rm -rf "$tmpdir"

# Install FastBinaryEncoding
#install_fbec

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

# Setup Postgresql & Redis
# for ubuntu: https://www.digitalocean.com/community/tutorials/how-to-install-and-use-postgresql-on-ubuntu-16-04
# then: ALTER USER <user name> WITH PASSWORD '<your new password>';
# sudo -u postgres psql -c "CREATE USER root WITH SUPERUSER CREATEDB PASSWORD 'password'"
# https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-redis-on-ubuntu-16-04
