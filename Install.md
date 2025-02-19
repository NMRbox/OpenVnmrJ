
OpenVnmrJ Version 2 Installation or Upgrade

For upgrade information, see the end of this document.

OpenVnmrJ Version 2 has been installed on RedHat/CentOS systems running
versions 6.8, 6.9, and 6.10, and versions 7.5, 7.6, 7.7, 8.1, and 8.2.
It has also been installed on Ubuntu Version 14, 16, 18, and 20 systems.
The MacOS version of OpenVnmrJ has been installed on versions Yosemite (10.10)
to Catalina (10.15). Installation on RHEL/CentOS systems can be used to
run a spectrometer. Installation on Ubuntu systems may function as a
spectrometer, but this has not been verified.  The MacOS version is for
data-processing only.

To install on CentOS 6.x systems, we recommend using the CentOS KickStart
DVD available from Agilent, available from
https://drive.google.com/drive/folders/10-pQ-HquslWJfWBkoOj7cM0yHST5RFbU 

For CentOS 7.x and 8.x systems, one can start by installing a standard
OS using the CentOS-7-x86_64-DVD-*.iso or CentOS-8-x86_64-DVD-*.iso images
available from https://www.centos.org/download/

For Ubuntu systems, one can start by downloading one of the images available
from https://ubuntu.com/download/desktop

If earlier versions of OS, for example, CentOS_6.9, Centos_7.6, or
Ubuntu_16, were chosen, then the system, if connected to network, will
prompt for OS updates at a later stage.  It is up to the user and/or
user's organization policies to opt for OS updates or not.

A typical CentOS 7.x or 8.x installation may involve selecting, in the
"SOFTWARE SELECTION" options, the GNOME Desktop as the base environment
and the GNOME applications, Legacy X Window System Compatibility,
Compatibility Libraries, and Development Tools as add-ons. One does
not need to set a hostname or connect to a network at this time.
After clicking "Begin Installation", set the root password and click
the "USER CREATION" button to make vnmr1, which will be the default
OpenVnmrJ administrator.

Following installation and a reboot, login in as root, accept the license,
turn on the network and click the "Finish configuration" button. After a
few more configuration items, it is ready for installation of OpenVnmrJ.

The OpenVnmrJ installer may be downloaded from
  https://github.com/OpenVnmrJ/OpenVnmrJ/releases
Move the zip file to /tmp and unzip it.  If you are logged in
as root, do not try to install it from root's home directory (/root). It will
not work. First unzip the file and cd into dvdimageOVJ (or dvdimageOVJMI).
If you are using CentOS 8, some modifications to the currently released
OpenVnmrJ 2.1 are required. Download the ver81.zip file from the github
releases page, copy it to the dvdimageOVJ directory, and run
  unzip -o ver81.zip
Note the -o argument. The contents of ver81.zip are also compatible with
installations on earlier CentOS versions. After unzipping the ver81.zip file,
run ./load.nmr.  The first thing it will do is install missing CentOS
packages. It uses yum and will require network access. Since it turns off
SELinux, a reboot is needed after the packages are installed.

After reboot, log in as root
again and cd to the dvdimageOVJ directory and run ./load.nmr again. It will
find that all required packages have been installed and start a normal
OpenVnmrJ installation. Following that, it will prompt you to set up
some standard accounts (walkup and service), install the latest version
of NMRPipe, install the VnmrJ 4.2 manual set, and setup the network for
console communications. If you make the walkup and service accounts, they
will be given passwords abcd1234.

Note that access to the network is tested by trying to "ping" google.com 
Some firewalls disable ping. If you are sure you have network access,
one can bypass the "ping" test by using
   ./load.nmr noPing

Note that the default OS package installation downloads them from the
network.  To support installation of OpenVnmrJ without network access, two
new scripts have been implemented. They are in the dvdimageOVJ directory
along with load.nmr. The ovjGetRepo command is a link to the installpkgs
script. Network access is required for this command. It will download
and save the required packages and their dependencies. It will also
install them. For this to work, a system with a minimum of packages is
needed, since if the package is already installed, the ovjGetRepo script
will not download it.  To create the repositories described below, a fresh
install of CentOS 7 with only the Gnome desktop and "Development tools"
selection was used. The ovjGetRepo script puts the packages in a directory
named openvnmrj.repo in the parent directory of the dvdimageOVJ direcory.
For the repositories described below, this was repeated for CentOS 7.5,
7.6, 7.7, 8.1, and 8.2 since each has different package dependencies.  The
openvnmrj.repo directories were zipped to files named ovjCentos75.repo.zip,
ovjCentos76.repo.zip, ovjCentos77.repo.zip, ovjCentos81.repo.zip, and
ovjCentos82.repo.zip.  They can be downloaded with these links:

   https://www.dropbox.com/s/1abfx71q7ppnz5k/ovjCentos75.repo.zip?dl=0

   https://www.dropbox.com/s/n95wnuyhmmccpby/ovjCentos76.repo.zip?dl=0

   https://www.dropbox.com/s/rx0fiprusehf78r/ovjCentos77.repo.zip?dl=0

   https://www.dropbox.com/s/fxzqxlltruss73r/ovjCentos78.repo.zip?dl=0

   https://www.dropbox.com/s/a98p04s0kiyn2sm/ovjCentos81.repo.zip?dl=0

   https://www.dropbox.com/s/e77kql65nsokmvt/ovjCentos82.repo.zip?dl=0

The second script is ovjUseRepo. It takes an optional path name for the
openvnmrj.repo but defaults to the parent of the dvdimageOVJ directory.
This script makes a repository and adds it to the list of yum repos.
If the installpkgs script, called by load.nmr, detects openvnmrj.repo,
it will not do the ping test and it disables all other repositories.
Internet access is not required. A typical process would be to download
the OpenVnmrJ installer and one of the above CentOS repositories. Move
both files to /tmp and then do
   unzip <OpenVnmrJ installer>
   unzip <CentOS repository>
   cd dvdimageOVJ
   ./ovjUseRepo
   ./load.nmr

Installations on Ubuntu systems are similar to those for CentOS.
One difference is that the user account created during the installation
of Ubuntu will be given "admin" privileges. That is, by using sudo,
that account can do anything the root account on CentOS can do.
Some may prefer that the vnmr1 account does not have those privileges.
One could then create an initial account, such as ovjroot.  During the
installation of OpenVnmrJ, the vnmr1 account will be created with no
admin privileges. It will be given the initial password of abcd1234.

After the OpenVnmrJ installation is complete, log out and log in before using
the administrator (vnmr1) account.

Newer CentOS and Ubuntu systems use the Gnome 3 display manager.
The "Standard" display manager no longer has desktop icons. Rather, it has
an Activities button at the upper left corner. Clicking that button will
display a "Type to search..." entry field. If you enter vnmrj, the
OpenVnmrJ launch icon will appear. This can be dragged to the favorites
toolbar. If the OpenVnmrJ launch icon does not appear, re-run makeuser on
that account. You may also need to log out and log in again.

Gnome 3 also supports the "Classic" display manager, where desktop icons
are displayed. One can select the display manager from the CentOS login screen.
After selecting the user, but before entering the password, click the settings
icon next to the "Sign in" button. Select the "Classic (Wayland display server)"
and then log in. The OpenVnmrJ desktop launch icons will be displayed. Before
they can be used, they must be enabled by clicking the right mouse button on
them and selecting "Allow Launching".


The MacOS version needs java version 1.8 or newer to be installed.
Also, if installed on MacOS Catalina (10.15), the Mac must be rebooted
following installation of OpenVnmrJ. If one installs OpenVnmrJ Version 2
on a Mac running Yosemite to Mojave and subsequently upgrades to Catalina,
OpenVnmrJ will stop working. This is because Catalina has implemented a
"read-only" system directory and OpenVnmrJ will have been moved to a different
disk locations and the /vnmr link will have been removed. To re-enable
OpenVnmrJ, run the script

  ~/vnmrsys/vnmr/bin/ovjFixMac

A system reboot will then be necessary.

The open-source version of java for MacOS may be obtained from https://jdk.java.net.
Download, for example, the JDK 13.0.2 release. Unpack the java package with the commands

  gunzip openjdk-13.0.2_osx-x64_bin.tar.gz

  tar xvf openjdk-13.0.2_osx-x64_bin.tar

Then move the jdk-13.0.2.jdk directory with the command

  sudo mv jdk-13.0.2.jdk /Library/Java/JavaVirtualMachines


Upgrading an existing OpenVnmrJ installation.
=============================================

With releases of OpenVnmrJ newer than OpenVnmrJ 2.1A, an upgrade.nmr script
is also available in the dvdimage directory. Running ./load.nmr will
install the new release as described above. If one instead runs
  ./upgrade.nmr
then OpenVnmrJ will be upgraded in place. That is, a new directory to hold
the release will not be created. The current system and user configuration
files will be maintained, along with any gradient shimming, probe, or
other calibration files. All other files that have changed or been added
since the previous version will be installed. There is no graphical
interface when the upgrade is performed.
