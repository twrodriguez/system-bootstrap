#!/bin/bash -e

#
# Determine Platform
#
uname_output=`uname -s`
if [[ "$uname_output" =~ "Linux" ]]; then
  my_platform="linux"
elif [[ "$uname_output" =~ "Darwin" ]]; then
  my_platform="darwin"
elif [[ "$uname_output" =~ "Solaris" || "$uname_output" =~ "SunOS" ]]; then
  my_platform="solaris"
elif [[ "$uname_output" =~ "BSD" || "$uname_output" =~ "DragonFly" ]]; then
  my_platform="bsd"
elif [[ "$uname_output" =~ "Haiku" ]]; then
  my_platform="beos"
elif [[ "$uname_output" =~ "MINGW" || "$uname_output" =~ "mingw" || "$uname_output" =~ "MinGW" ]]; then
  my_platform="mingw"
elif [[ "$uname_output" =~ "CYGWIN" || "$uname_output" =~ "cygwin" ]]; then
  my_platform="cygwin"
else
  echo "ERROR: Unknown Platform '$uname_output'"
  exit 1
fi

#
# Determine CPU info
#
if [[ -e "/proc/cpuinfo" ]]; then
  # Linux
  num_cpus=`cat /proc/cpuinfo | grep processor | wc -l`
  cpu_vendor=`cat /proc/cpuinfo | grep "Vendor ID:" | grep -o "\w\+$" | head -1`
elif [[ -n `which lscpu 2> /dev/null` ]]; then
  # Linux Alternative
  num_cpus=`lscpu | grep -i "CPU(s):" | awk '{print $2}'`
  cpu_vendor=`lscpu | grep "Vendor ID:" | grep -o "\w\+$" | head -1`
elif [[ -n `which psrinfo 2> /dev/null` ]]; then
  # Solaris
  num_cpus=`psrinfo | wc -l`
  # TODO: cpu_vendor
elif [[ -n `which sysinfo 2> /dev/null` ]]; then
  # Haiku/BeOS
  num_cpus=`sysinfo | grep -i "CPU #[0-9]*:" | wc -l`
  # TODO: cpu_vendor
elif [[ -n `which sysctl 2> /dev/null` ]]; then
  # BSD
  num_cpus=`sysctl -a 2> /dev/null | egrep -i 'hw.ncpu' | awk '{print $2}'`
  # TODO: cpu_vendor
fi

if [[ -n `which arch 2> /dev/null` ]]; then
  # Linux
  my_arch=`arch`
elif [[ -n `which lscpu 2> /dev/null` ]]; then
  # Linux Alternative
  my_arch=`lscpu | grep -i "Architecture" | awk '{print $2}'`
elif [[ -n `which sysinfo 2> /dev/null` ]]; then
  # Haiku/BeOS
  my_arch=`sysinfo | grep -o "kernel_\\w*"`
else
  # BSD/Solaris
  my_arch=`uname -p 2> /dev/null`
  [[ -n "$my_arch" ]] || my_arch=`uname -m 2> /dev/null`
fi

if [[ -n `echo $my_arch | grep -i "sparc\\|sun4u"` ]]; then
  my_arch_family="sparc"
elif [[ -n `echo $my_arch | grep -i "^ppc\\|powerpc"` ]]; then
  my_arch_family="powerpc"
elif [[ "$my_arch" =~ mips ]]; then
  my_arch_family="mips"
elif [[ "$my_arch" =~ s390 ]]; then
  my_arch_family="s390x"
elif [[ -n `echo $my_arch | grep -i "ia64\\|itanium"` ]]; then
  my_arch_family="itanium"
elif [[ "$my_arch" =~ arm64 ]]; then
  my_arch_family="arm64"
elif [[ "$my_arch" =~ arm ]]; then
  my_arch_family="arm"
elif [[ "$my_arch" =~ 64 ]]; then
  my_arch_family="x86_64"
elif [[ -n `echo $my_arch | grep -i "\\(i[3-6]\\?\\|x\\)86\\|ia32"` ]]; then
  my_arch_family="i386"
fi

#
# Setup Build Env
#
if [[ -z `echo "$PATH" | grep "/usr/local/bin"` ]]; then
  export PATH=/usr/local/sbin:/usr/local/bin:$PATH
fi
if [[ "$PATH" =~ "rvm/bin" ]]; then
  if [[ `whoami` == "root" ]]; then
    rvm_home=/usr/local/rvm
  else
    rvm_home=$HOME/.rvm
  fi
  export PATH=$PATH:$rvm_home/bin # Add RVM to PATH for scripting
fi

if [[ "$my_platform" == "linux" ]]; then

  # PLEASE tell me you have lsb_release installed.
  if [[ -z `which lsb_release 2> /dev/null` ]]; then
    if [[ -n `which apt-get 2> /dev/null` ]]; then    # Debian/Ubuntu/Linux Mint/PCLinuxOS
      sudo apt-get install -y lsb
    elif [[ -n `which up2date 2> /dev/null` ]]; then  # RHEL/Oracle
      sudo up2date -i lsb
    elif [[ -n `which dnf 2> /dev/null` ]]; then      # CentOS/Fedora/RHEL/Oracle
      sudo dnf install -y lsb
    elif [[ -n `which yum 2> /dev/null` ]]; then      # Old CentOS/Fedora/RHEL/Oracle
      sudo yum install -y lsb
    elif [[ -n `which zypper 2> /dev/null` ]]; then   # OpenSUSE/SLES
      sudo zypper --non-interactive install lsb
    elif [[ -n `which pacman 2> /dev/null` ]]; then   # ArchLinux
      sudo pacman -S --noconfirm lsb-release
    elif [[ -n `which urpmi 2> /dev/null` ]]; then    # Mandriva/Mageia
      sudo urpmi --auto lsb-release
    elif [[ -n `which emerge 2> /dev/null` ]]; then   # Gentoo
      sudo emerge lsb
    elif [[ -n `which slackpkg 2> /dev/null` ]]; then # Slackware
      echo "" > /dev/null # Slackware doesn't use LSB
    else
      echo "ERROR: Unknown Package manager in use (what ARE you using??)"
      exit 1
    fi
  fi

  my_method="install"
  my_major_release=`lsb_release -r 2> /dev/null | awk '{print $2}' | grep -o "[0-9]\+" | head -1`
  my_nickname=`lsb_release -c 2> /dev/null | awk '{print $2}'`
  my_pkg_arch="$my_arch_family"
  lsb_release_output=`lsb_release -a 2> /dev/null`
  if grep -q "Microsoft" "/proc/version"; then
    my_host_platform="windows"
  else
    my_host_platform="linux"
  fi
  if [[ -n `echo $lsb_release_output | grep -i "debian"` ]]; then
    my_distro="debian"
    my_pkg_fmt="deb"
    my_pkg_mgr="apt-get"
    my_install="apt-get install -y"
    my_local_install="dpkg -i"
    if [[ "$my_arch_family" == "x86_64" ]]; then my_pkg_arch="amd64"; fi
  elif [[ -n `echo $lsb_release_output | grep -i "ubuntu"` ]]; then
    my_distro="ubuntu"
    my_pkg_fmt="deb"
    my_pkg_mgr="apt-get"
    my_install="apt-get install -y"
    my_local_install="dpkg -i"
    if [[ "$my_arch_family" == "x86_64" ]]; then my_pkg_arch="amd64"; fi
  elif [[ -n `echo $lsb_release_output | grep -i "mint"` ]]; then
    my_distro="mint"
    my_pkg_fmt="deb"
    my_pkg_mgr="apt-get"
    my_install="apt-get install -y"
    my_local_install="dpkg -i"
    if [[ "$my_arch_family" == "x86_64" ]]; then my_pkg_arch="amd64"; fi
  elif [[ -n `echo $lsb_release_output | grep -i "centos"` ]]; then
    my_distro="centos"
    my_pkg_fmt="rpm"
    my_pkg_mgr="yum"
    my_install="yum install -y"
    my_local_install="yum localinstall -y"
  elif [[ -n `echo $lsb_release_output | grep -i "fedora"` ]]; then
    my_distro="fedora"
    my_pkg_fmt="rpm"
    if [ "$my_major_release" -ge "18"]; then
      my_pkg_mgr="dnf"
      my_install="dnf install -y"
      my_local_install="dnf localinstall -y"
    else
      my_pkg_mgr="yum"
      my_install="yum install -y"
      my_local_install="yum localinstall -y"
    fi
  elif [[ -n `echo $lsb_release_output | grep -i "redhat\|rhel"` ]]; then
    my_distro="rhel"
    my_pkg_fmt="rpm"
    my_pkg_mgr="up2date"
    my_install="up2date -i"
    my_local_install="rpm -Uvh"
  elif test -e "/etc/oracle-release" -o -e "/etc/enterprise-release"; then
    my_distro="oracle"
    if test -e "/etc/oracle-release"; then
      my_nickname=`cat /etc/oracle-release`
    else
      my_nickname=`cat /etc/enterprise-release`
    fi
    my_major_release=`echo $my_nickname | grep -o "[0-9]\+" | head -1`
    my_pkg_fmt="rpm"
    my_pkg_mgr="up2date"
    my_install="up2date -i"
    my_local_install="rpm -Uvh"
  elif [[ -n `echo $lsb_release_output | grep -i "open\s*suse"` ]]; then
    my_distro="opensuse"
    my_pkg_fmt="rpm"
    my_pkg_mgr="zypper"
    my_install="zypper --non-interactive install"
    my_local_install="rpm -Uvh"
  elif [[ -n `echo $lsb_release_output | grep -i "suse" | grep -i "enterprise"` ]]; then
    my_distro="sles"
    my_pkg_fmt="rpm"
    my_pkg_mgr="zypper"
    my_install="zypper --non-interactive install"
    my_local_install="rpm -Uvh"
  elif [[ -n `echo $lsb_release_output | grep -i "archlinux"` ]]; then
    my_distro="arch"
    my_pkg_fmt="pkg.tar.xz"
    my_pkg_mgr="pacman"
    my_install="pacman -S --noconfirm"
    my_local_install="pacman -U --noconfirm"
  elif test -e "/etc/slackware-version"; then
    my_distro="slackware"
    my_nickname=`cat /etc/slackware-version`
    my_major_release=`echo $my_nickname | grep -o "[0-9]\+" | head -1`
    if [[ "$my_major_release" -lt "13" ]]; then
      my_pkg_fmt="tgz"
    else
      my_pkg_fmt="txz"
    fi
    my_pkg_mgr="slackpkg"
    my_install="slackpkg -batch=on -default_answer=y install"
    my_local_install="installpkg"
  elif [[ -n `echo $lsb_release_output | grep -i "mandriva"` ]]; then
    my_distro="mandriva"
    my_pkg_fmt="rpm"
    my_pkg_mgr="urpmi"
    my_install="urpmi --auto "
    my_local_install="rpm -Uvh"
  elif [[ -n `echo $lsb_release_output | grep -i "mageia"` ]]; then
    my_distro="mageia"
    my_pkg_fmt="rpm"
    my_pkg_mgr="urpmi"
    my_install="urpmi --auto "
    my_local_install="rpm -Uvh"
  elif [[ -n `echo $lsb_release_output | grep -i "gentoo"` ]]; then
    my_distro="gentoo"
    my_pkg_fmt="tgz"
    my_pkg_mgr="emerge"
    my_install="emerge"
    my_local_install=""
  # TODO: Add Alpine Linux w/ pkg manager "apk" to the list
  else
    echo "Warning: Unsupported Linux Distribution, any packages will be compiled from source"
    my_method="build"
    my_distro=`lsb_release -d 2> /dev/null`
  fi

elif [[ "$my_platform" == "darwin" ]]; then

  my_distro="Mac OSX"
  my_install=""

  if [[ -n `which brew 2> /dev/null` ]]; then # Homebrew
    my_method="install"
    my_install="brew install"
  elif [[ -n `which port 2> /dev/null` ]]; then # MacPorts
    my_method="install"
    my_install="port install"
  else
    my_method="build"
  fi
  my_major_release=`sw_vers -productVersion | grep -o "[0-9]\+\.[0-9]\+" | head -1`
  case "$my_major_release" in
    "10.0") my_nickname="Cheetah";;
    "10.1") my_nickname="Puma";;
    "10.2") my_nickname="Jaguar";;
    "10.3") my_nickname="Panther";;
    "10.4") my_nickname="Tiger";;
    "10.5") my_nickname="Leopard";;
    "10.6") my_nickname="Snow Leopard";;
    "10.7") my_nickname="Lion";;
    "10.8") my_nickname="Mountain Lion";;
    "10.9") my_nickname="Mavericks";;
    "10.10") my_nickname="Yosemite";;
    "10.11") my_nickname="El Capitan";;
    "10.12") my_nickname="Sierra";;
    "10.13") my_nickname="High Sierra";;
    "10.14") my_nickname="Mojave";;
    *)
      echo "Unknown Version of OSX Detected: $my_major_release"
      my_nickname="Unknown"
      ;;
  esac

  my_pkg_fmt=""
  my_local_install=""

elif [[ "$my_platform" == "solaris" ]]; then

  my_major_release=`uname -r | grep -o "[0-9]\+" | head -2 | tail -1`
  if [[ -n `uname -a | grep -i "open\s*solaris"` ]]; then
    my_distro="OpenSolaris"
    my_nickname="$my_distro `cat /etc/release | grep -o "OpenSolaris [a-zA-Z0-9.]\\+"`"
  else
    my_distro="Solaris"
    my_nickname="$my_distro $my_major_release"
  fi
  my_method="install"
  # NOTE - `pfexec pkg set-publisher -O http://pkg.openindiana.org/legacy opensolaris.org`
  # NOTE - SUNWruby18, SUNWgcc, SUNWgnome-common-devel
  my_install="pkg install"

  my_pkg_fmt=""
  my_local_install=""

elif [[ "$my_platform" == "bsd" ]]; then

  my_distro=`uname -s`
  my_pkg_fmt="tgz"
  my_nickname="$my_distro `uname -r`"
  my_major_release=`uname -r | grep -o "[0-9]\+" | head -1`
  my_method="install"
  # NOTE - `portsnap fetch extract` to update snapshot
  my_install="pkg_add -r"

  my_local_install=""

elif [[ "$my_platform" == "beos" ]]; then

  my_distro=`uname -s`
  my_major_release=`uname -r | grep -o "[0-9]\+" | head -1`
  my_method="build"
  my_nickname="$my_distro $my_major_release"

  my_pkg_fmt=""
  my_local_install=""
  my_install=""

elif [[ "$my_platform" == "mingw" || "$my_platform" == "cygwin" ]]; then

  my_distro="Windows"
  my_install=""
  my_host_platform="windows"

  if [[ "$my_platform" == "mingw" ]]; then # MinGW
#   NOTE - You can use install if you want, but you need to know to use
#          either the mingw- or msys- prefix. And this is still only
#          really useful for packages you KNOW they have. You're better
#          off just building everything.
#    my_method="install"
#    my_install="mingw-get.exe install"
    my_method="build"
    my_install=""
  elif [[ "$my_platform" == "cygwin" ]]; then # Cygwin
    my_method="install"
    my_install="setup.exe -q -D -P"
  else
    my_method="build"
  fi
  my_major_release=`uname -s | grep -o "NT-[0-9]\+\.[0-9]\+" | head -1`
  case "$my_major_release" in
    "NT-5.1") my_distro="Windows XP";;
    "NT-6.0") my_distro="Windows Vista";;
    "NT-6.1") my_distro="Windows 7";;
    "NT-6.2") my_distro="Windows 8";;
    "NT-6.3") my_distro="Windows 8.1";;
    *)
      echo "Unknown Version of Windows Detected: $my_major_release"
      my_distro="Unknown"
      ;;
  esac

  my_nickname=`reg query "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion" | grep ProductName | awk '{ print $3 " " $4 " " $5 " " $6 " " $7 " " $8 " " $9 }'`

  my_pkg_fmt=""
  my_local_install=""

fi
