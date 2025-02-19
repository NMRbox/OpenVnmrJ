#! /bin/bash
#
# Copyright (C) 2018  University of Oregon
# 
# You may distribute under the terms of either the GNU General Public
# License or the Apache License, as specified in the LICENSE file.
# 
# For more information, see the LICENSE file.
# 
#
# set -x

userId=$(/usr/bin/id | awk 'BEGIN { FS = " " } { print $1 }')
if [ $userId != "uid=0(root)" ]; then
  echo
  if [ -x /usr/bin/dpkg ]; then
     echo "Installing OpenVnmrJ for Ubuntu."
  else
     echo "Installing OpenVnmrJ for RHEL / CentOS."
  fi
  echo "Or type cntrl-C to exit."
  echo
  s=1
  t=3
  while [[ $s = 1 ]] && [[ ! $t = 0 ]]; do
    if [ -x /usr/bin/dpkg ]; then
      echo "If requested, enter the admin (sudo) password"
      sudo $0 $* ;
    else
      echo "Please enter this system's root user password"
      su root -c "$0 $*";
    fi
    s=$?
    t=$((t-1))
    echo " "
  done
  if [ $t = 0 ]; then
    echo "Access denied. Type cntrl-C to exit this window."
    echo "Type $0 to start the installation program again"
    echo ""
  fi
  exit
fi


turboRepo() {
  cat >/etc/yum.repos.d/TurboVNC.repo  <<EOF

[TurboVNC]
name=TurboVNC official RPMs
baseurl=https://sourceforge.net/projects/turbovnc/files
gpgcheck=1
gpgkey=http://pgp.mit.edu/pks/lookup?op=get&search=0x6BBEFA1972FEB9CE
enabled=1
exclude=turbovnc-*.*.9[0-9]-*
EOF
}

if [[ -f /etc/yum.repos.d/openvnmrj.repo ]]; then
  ovjRepo=1
else
  ovjRepo=0
fi

repoGet=0
if [[ "x$(basename $0)" = "xovjGetRepo" ]]; then
  if [ ! -f /etc/centos-release ]; then
    if [ ! -f /etc/redhat-release ]; then
      echo "$0 can only be used for CentOS or RedHat systems"
      exit 1
    fi
  fi
  repoGet=1
  if [[ $ovjRepo -eq 1 ]]; then
    rm -f /etc/yum.repos.d/openvnmrj.repo
    ovjRepo=0
  fi
  repoPath=$(dirname $(dirname $(readlink -f $0)))
  repoPath=$(dirname $repoPath)/openvnmrj.repo
  repoArg="--download_path=$repoPath"
  repoArg="--downloadonly --downloaddir=$repoPath"
fi

noPing=0
for arg in "$@"
do
  if [[ "x$arg" = "xnoPing" ]]; then
    noPing=1
  fi
done

if [[ $ovjRepo -eq 0 ]] && [[ $noPing -eq 0 ]]
then
  ping -W 1 -c 1 google.com > /dev/null 2>&1
  if [ $? -ne 0 ]
  then
    echo "Must be connected to the internet for $0 to function"
    echo "This is tested by doing \"ping google.com\". The ping"
    echo "command may also fail due to a firewall blocking it."
    echo "If you are sure the system is connected to the internet"
    echo "and want to bypass this \"ping\" test, use"
    echo "./load.nmr noPing"
    echo "or"
    echo "$0 noPing"
    echo ""
    exit 2
  fi
fi

postfix=$(date +"%F_%H_%M_%S")
if [ -d /tmp/ovj_preinstall ]; then
  logfile="/tmp/ovj_preinstall/pkgInstall.log_$postfix"
else
  logfile="/tmp/pkgInstall.log_$postfix"
fi

if [ ! -x /usr/bin/dpkg ]; then
  if [ -f /etc/centos-release ]; then
    rel=centos-release
  elif [ -f /etc/redhat-release ]; then
    rel=redhat-release
  else
    echo "$0 can only be used for CentOS or RedHat systems"
    exit 1
  fi
# remove all characters up to the first digit
  version=$(cat /etc/$rel | sed -E 's/[^0-9]+//')
# remove all characters from end including first dot
  version=${version%%.*}

# Determine if some packages are already installed.
# If they are, do not remove them.

# perl-homedir creates a perl5 directory in every acct.
# Removing it fixes it so it does not do that.
  perlHomeInstalled=0
  if [ "$(rpm -q perl-homedir |
    grep 'not installed' > /dev/null;echo $?)" != "0" ]
  then
    perlHomeInstalled=1
  fi
  epelInstalled=0
  if [ "$(rpm -q epel-release |
    grep 'not installed' > /dev/null;echo $?)" != "0" ]
  then
    epelInstalled=1
  fi
  turbovncFileInstalled=0
  if [ -f /etc/yum.repos.d/TurboVNC.repo ]
  then
    turbovncFileInstalled=1
  fi

#for RHEL 7 and Centos 7
# remove gnome-power-manager tk tcl
# rename openmotif22 to motif.i686
# recompile fortran with gfortran and remove compat-libf2c-34 compat-gcc-34-g77 
#   and add libgfortran
# recompile Xrecon to remove libtiff dependence

# kernel-headers
# kernel-devel
# libidn
# sendmail-cf
# xinetd

  commonList='
  make
  gcc
  gcc-c++
  gdb
  libtool
  binutils
  automake
  strace
  autoconf
  expect
  tftp-server
  libgfortran
  mutt
  ghostscript
 '
  if [ $version -lt 8 ]; then
    commonList="$commonList rsh rsh-server"
  else
    commonList="$commonList csh libnsl compat-openssl10 compat-libgfortran-48"
  fi

# Must list 32-bit packages, since these are no longer
# installed along with the 64-bit versions
  bit32List='
  mesa-libGL-devel
  mesa-libGL
  mesa-libGLU
  mesa-libGLU-devel
 '

  pipeList='
  xorg-x11-fonts-100dpi
  xorg-x11-fonts-ISO8859-1-100dpi
  xorg-x11-fonts-75dpi
  xorg-x11-fonts-ISO8859-1-75dpi
  xorg-x11-fonts-misc
 '

# The following were removed from the CentOS 6.8 kickstart
# gnome-python2-desktop
# compat-gcc-34-g77
# openmotif22
# openmotif-devel.i686
# rpmforge-release
# tigervnc
# tigervnc-server
# @basic-desktop
# @desktop-platform all files present
# @desktop-platform-devel
# @eclipse
# @general-desktop
# sendmail-cf
# unix2dos
# @server-platform
# @server-platform-devel
# @server-policy
# @tex
# @virtualization
# @workstation-policy  installs gdm, already present
# @additional-devel
# @base
# @core
# @desktop-debugging
# @development
# @directory-client
# @emacs
# @fonts
# @graphical-admin-tools
# @input-methods
# @internet-browser
# @java-platform
# @legacy-x
# @network-file-system-client
# @performance
# @perl-runtime
# @print-client
# @remote-desktop-clients
# @technical-writing
# @virtualization-client
# @virtualization-platform
# @x11
# libgnomeui-devel
# libbonobo-devel
# kdegraphics
# @debugging
# @graphics

  package68List=' 
  libstdc++
  libstdc++-devel
  glibc
  glibc-devel
  libX11
 '

  offList=' 
  libgcrypt-devel
  libXinerama-devel
  xorg-x11-proto-devel
  startup-notification-devel
  junit
  libXau-devel
  libXrandr-devel
  popt-devel
  libdrm-devel
  libxslt-devel
  libglade2-devel
  gnutls-devel
  pax
  python-dmidecode
  oddjob
  wodim
  sgpio
  genisoimage
  device-mapper-persistent-data
  systemtap-client
  abrt-gui
  desktop-file-utils
  ant
  rpmdevtools
  javapackages-tools
  rpmlint
  samba
  samba-winbind
  certmonger
  pam_krb5
  krb5-workstation
  netpbm-progs
  libXmu
  libXp
  perl-DBD-SQLite
  libvirt-java
  python-psycopg2
  gsl-devel
  hplip-gui
  icedtea-web
  lm_sensors
  logwatch
  recode
  syslinux-extlinux
 '

  item68List='
  libXt
  motif
  mtools
  expect
  gpm
  minicom
  telnet
  tftp-server
  dos2unix
  gitk
  gnuplot
  gsl
  tftp
  xinetd
  xterm
  createrepo
  perl-Compress-Raw-Bzip2
 '
  if [ $version -lt 8 ]; then
    item68Listb='
    gimp
    ImageMagick
    k3b
    pexpect
    postgresql-docs
    postgresql-odbc
    postgresql-server
    PyGreSQL
    sharutils
    a2ps
    compat-libstdc++-33
    fuseiso
    gconf-editor
  '
    item68List="$item68List $item68Listb"
  fi
#These do not need to be installed for running OpenVnmrJ
#Just if you intend to build it
  buildList='
  motif-devel
  libXmu-devel
  libXaw-devel.i686
  libXext-devel.i686
  libX11-devel.i686
  libXau.i686
  libX11.i686
  libXi.i686
  libXt.i686
  libXaw.i686
  libXpm.i686
  libXt-devel.i686
  libXtst-devel.i686
  ncurses-libs.i686
  ncurses-devel.i686
  libxml2.i686
  libxml2-devel.i686
  alsa-lib.i686
  atk-devel.i686
  glibc-devel.i686
  gtk2-devel.i686
  libidn-devel.i686
  libstdc++-devel.i686
  expat.i686
  expat-devel.i686
  kde-baseapps-libs
  atk.i686
  gtk2.i686
  libidn.i686
 '
# from epel-release
  epelList='
  ntfsprogs
  fuse-ntfs-3g
  kdiff3
 '
  if [ $version -lt 8 ]; then
    epelList="$epelList scons meld x11vnc"
  else
    epelList="$epelList kdiff3 k3b ImageMagick rsh rsh-server"
  fi
  if [ $version -lt 7 ]; then
#  Add older motif package
    packageList="openmotif $item68List $commonList $bit32List $pipeList"
  else
    packageList="$item68List $commonList $pipeList"
  fi


#  The PackageKit script often holds a yum lock.
#  This prevents this script from executing
#  On CentOS 7, the systemctl command should stop the PackageKit
  if [ $version -ge 7 ]; then
    systemctl --now --runtime mask packagekit > /dev/null 2>&1
  fi
  npids=$(ps -ef  | grep PackageKit | grep -v grep |
	   awk '{ printf("%d ",$2) }')
  for prog_pid in $npids
  do
    kill $prog_pid
    sleep 2
  done
#  Try a second time
  npids=$(ps -ef  | grep PackageKit | grep -v grep |
           awk '{ printf("%d ",$2) }')
  for prog_pid in $npids
  do
    kill $prog_pid
  done
#  If it will not die, exit
  npids=$(ps -ef  | grep PackageKit | grep -v grep |
	   awk '{ printf("%d ",$2) }')
  if [ ! -z $npids ]
  then
    echo "CentOS / RedHat PackageKit is preventing installation"
    echo "Please try again in 5-10 minutes,"
    echo "after this tool completes its task."
    exit 1
  fi

  echo "You can monitor the progress in a separate terminal window with the command"
  echo "tail -f $logfile"

  yum68List=''
  for xpack in $package68List
  do
    yum68List="$yum68List ${xpack}.i686"
  done
  yum68List="$yum68List ncurses-libs.i686"
  if [ $version -ge 8 ]; then
     yum68List="$yum68List libnsl.i686"
  fi
  if [[ $repoGet -eq 1 ]]; then
    echo "Downloading standard packages (1 of 3)"
    echo "Downloading standard packages (1 of 3)" > $logfile
    chmod 666 $logfile
    yum -y install $repoArg $package68List &>> $logfile
#   in CentOS 8, yum clears the downloaddir prior to the download
    if [ $version -eq 8 ]; then
      repoPathTmp=${repoPath}.tmp
      mkdir $repoPathTmp
      cp -f $repoPath/* $repoPathTmp > /dev/null 2>&1
    fi
    yum -y install $package68List &>> $logfile
    yum -y upgrade $repoArg $package68List &>> $logfile
    if [ $version -eq 8 ]; then
      cp -f $repoPath/* $repoPathTmp > /dev/null 2>&1
    fi
  fi
  echo "Installing standard packages (1 of 3)"
  echo "Installing standard packages (1 of 3)" &>> $logfile
  chmod 666 $logfile
  if [[ $ovjRepo -eq 1 ]]; then
    yum -y install --disablerepo="*" --enablerepo="openvnmrj" $package68List &>> $logfile
    yum -y upgrade --disablerepo="*" --enablerepo="openvnmrj" $package68List &>> $logfile
  else
    if [ $version -lt 8 ]; then
      yum -y install $package68List &>> $logfile
    fi
    yum -y upgrade $package68List &>> $logfile
  fi
  if [[ $repoGet -eq 1 ]]; then
    echo "Downloading required packages (2 of 3)"
    echo "Downloading required packages (2 of 3)" >> $logfile
    yum -y install $repoArg $packageList &>> $logfile
    if [ $version -eq 8 ]; then
      yum -y --enablerepo=PowerTools install $repoArg sharutils &>> $logfile
      if [ $version -eq 8 ]; then
        cp -f $repoPath/* $repoPathTmp > /dev/null 2>&1
      fi
    fi
    yum -y install $repoArg $yum68List &>> $logfile
    if [ $version -eq 8 ]; then
      cp -f $repoPath/* $repoPathTmp > /dev/null 2>&1
    fi
  fi
  echo "Installing required packages (2 of 3)"
  echo "Installing required packages (2 of 3)" >> $logfile
  yumList=''
  for xpack in $packageList
  do
    if [ "$(rpm -q $xpack | grep 'not installed' > /dev/null;echo $?)" == "0" ]
    then
      yumList="$yumList $xpack"
    fi
  done
  if [[ $ovjRepo -eq 1 ]]; then
    if [ $version -eq 8 ]; then
      if [ "$(rpm -q sharutils | grep 'not installed' > /dev/null;echo $?)" == "0" ]
      then
        yumList="$yumList sharutils"
      fi
    fi
    if [ "x$yumList" != "x" ]; then
      yum -y install --disablerepo="*" --enablerepo="openvnmrj" $yumList &>> $logfile
    fi
    yum -y install --disablerepo="*" --enablerepo="openvnmrj" $yum68List &>> $logfile
  else
    if [ "x$yumList" != "x" ]; then
      yum -y install $yumList &>> $logfile
    fi
    if [ $version -eq 8 ]; then
      if [ "$(rpm -q sharutils | grep 'not installed' > /dev/null;echo $?)" == "0" ]
      then
        yum -y --enablerepo=PowerTools install sharutils &>> $logfile
      fi
    fi
    yum -y install $yum68List &>> $logfile
  fi

# perl-homedir creates a perl5 directory in every acct. This fixes it so it does not do that.
  if [ $perlHomeInstalled -eq 0 ]
  then
    echo "Removing perl-home rpm" &>> $logfile
    yum -y erase perl-homedir &>> $logfile
  fi

 # No need to add repos if OVJ repo is being used
  if [[ $ovjRepo -eq 1 ]]; then
    epelInstalled=1
    turbovncFileInstalled=1
  fi
  if [ $epelInstalled -eq 0 ]
  then
    yum -y install epel-release &>> $logfile
  fi
  if [[ $repoGet -eq 1 ]]; then
    echo "Downloading additional packages (3 of 3)"
    echo "Downloading additional packages (3 of 3)" >> $logfile
    yum -y install $repoArg $epelList &>> $logfile
    if [ $version -eq 8 ]; then
      cp -f $repoPath/* $repoPathTmp > /dev/null 2>&1
    fi
  fi
  echo "Installing additional packages (3 of 3)"
  echo "Installing additional packages (3 of 3)" >> $logfile

  if [[ $ovjRepo -eq 1 ]]; then
    yum -y install --disablerepo="*" --enablerepo="openvnmrj" $epelList &>> $logfile
  else
    yum -y install $epelList &>> $logfile
  fi
  if [ $epelInstalled -eq 0 ]
  then
    yum -y erase epel-release &>> $logfile
  fi
  if [ "$(rpm -q turbovnc | grep 'not installed' > /dev/null;echo $?)" == "0" ]
  then
    if [ $turbovncFileInstalled -eq 0 ]
    then
      turboRepo
    fi
    if [[ $repoGet -eq 1 ]]; then
      yum -y install $repoArg turbovnc &>> $logfile
      if [ $version -eq 8 ]; then
        cp -f $repoPath/* $repoPathTmp > /dev/null 2>&1
      fi
    fi
    if [[ $ovjRepo -eq 1 ]]; then
      yum -y install --disablerepo="*" --enablerepo="openvnmrj" turbovnc &>> $logfile
    else
      yum -y install turbovnc &>> $logfile
    fi
    if [ $turbovncFileInstalled -eq 0 ]
    then
      rm -f /etc/yum.repos.d/TurboVNC.repo
    fi
  fi

  dir=$(dirname $0)
  if [ "$(rpm -q gftp | grep 'not installed' > /dev/null;echo $?)" == "0" ]
  then
    if [ -f $dir/linux/gftp-2.0.19-4.el6.rf.x86_64.rpm ]
    then
      yum -y install --disablerepo="*" $dir/linux/gftp-2.0.19-4.el6.rf.x86_64.rpm &>> $logfile
    fi
  fi
  if [ "$(rpm -q numlockx | grep 'not installed' > /dev/null;echo $?)" == "0" ]
  then
    if [ -f $dir/linux/numlockx-1.2-6.el7.nux.x86_64.rpm ]
    then
      yum -y install --disablerepo="*" $dir/linux/numlockx-1.2-6.el7.nux.x86_64.rpm &>> $logfile
    fi
  fi

  if [ $version -ge 7 ]; then
    systemctl unmask packagekit
  fi
  if [[ $ovjRepo -eq 1 ]]; then
     rm -f /etc/yum.repos.d/openvnmrj.repo
  fi
  chown $(stat -c "%U.%G" $0) $logfile
  if [[ $repoGet -eq 1 ]]; then
    if [ $version -eq 8 ]; then
      rm -rf $repoPath
      mv $repoPathTmp $repoPath
    fi
    chown -R $(stat -c "%U.%G" $0) $repoPath
    echo "CentOS / RedHat package download complete"
    echo "Packages stored in $repoPath"
  else
    echo "CentOS / RedHat package installation complete"
  fi
  echo " "
else
  . /etc/lsb-release
  distmajor=${DISTRIB_RELEASE:0:2}
  if [ $distmajor -lt 14 ] ; then
    echo "Only Ubuntu 14 or newer is supported"
    echo " "
    exit 1
  fi

  echo "You can monitor progress in a separate terminal window with the command"
  echo "tail -f $logfile"
  echo "Installing standard packages (1 of 2)"
  echo "Installing standard packages (1 of 2)" > $logfile
# The unattended-upgrade script often holds a yum lock.
# This prevents this script from executing
  if [[ -x /bin/systemctl ]]; then
    systemctl --now --runtime mask unattended-upgrades > /dev/null 2>&1
  fi
  npids=$(ps -ef  | grep unattended-upgrade | grep -v grep |
	  awk '{ printf("%d ",$2) }')
  for prog_pid in $npids
  do
    kill -s 2 $prog_pid
    sleep 2
  done
# Try a second time
  npids=$(ps -ef  | grep unattended-upgrade | grep -v grep |
	  awk '{ printf("%d ",$2) }')
  for prog_pid in $npids
  do
    kill -s 2 $prog_pid
  done
# If it will not die, exit
  npids=$(ps -ef  | grep unattended-upgrade | grep -v grep |
	  awk '{ printf("%d ",$2) }')
  if [ ! -z $npids ]
  then
    echo "Ubuntu unattended-update is preventing installation"
    echo "Please try again in 5-10 minutes, after this tool completes its task."
    exit 1
  fi
  dpkg --add-architecture i386
  apt-get -qq update
# apt-get -qq -y dist-upgrade
# Prevent packages from presenting an interactive popup
  export DEBIAN_FRONTEND=noninteractive
  apt-get install -y tcsh make expect bc git scons g++ gfortran \
      openssh-server mutt sharutils sendmail-cf gnome-power-manager \
      kdiff3 libcanberra-gtk-module ghostscript imagemagick vim xterm \
      gedit dos2unix zip cups gnuplot gnome-terminal enscript rpcbind &>> $logfile
  echo "Installing version specific packages (2 of 2)"
  echo "Installing version specific packages (2 of 2)" >> $logfile
  if [ $distmajor -gt 18 ] ; then
   # these are needed to build
    apt-get install -y gdm3 gnome-session openjdk-8-jre \
      lib32stdc++-8-dev libc6-dev libglu1-mesa-dev libgsl-dev &>> $logfile
  elif [ $distmajor -gt 16 ] ; then
   # these are needed to build
    apt-get install -y gdm3 gnome-session openjdk-8-jre \
      lib32stdc++-7-dev libc6-dev-i386 libglu1-mesa-dev libgsl-dev &>> $logfile
  elif [ $distmajor -gt 14 ] ; then
   # these are needed to build
    apt-get install -y postgresql gdm3 gnome-session openjdk-8-jre \
      lib32stdc++-5-dev libc6-dev-i386 libglu1-mesa-dev libgsl-dev &>> $logfile
  else
    # these are needed to build
    apt-get install -y postgresql openjdk-6-jre lib32stdc++-4.8-dev \
            libc6-dev-i386 libglu1-mesa-dev libgsl0-dev &>> $logfile
  fi
# apt-get uninstalls these if an amd64 version is installed for something else >:(
# so install them last...
  apt-get install -y libmotif-dev libx11-dev libxt-dev &>> $logfile
  unset DEBIAN_FRONTEND
  echo "dash dash/sh boolean false" | debconf-set-selections &>> $logfile
  dpkg-reconfigure -u dash &>> $logfile
  if [[ -x /bin/systemctl ]]; then
    systemctl unmask unattended-upgrades > /dev/null 2>&1
  fi
  echo "Ubuntu package installation complete"
  echo " "
fi
exit 0
