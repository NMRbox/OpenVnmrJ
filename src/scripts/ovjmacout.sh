#!/bin/bash
#
#
# Copyright (C) 2015  University of Oregon
# 
# You may distribute under the terms of either the GNU General Public
# License or the Apache License, as specified in the LICENSE file.
# 
# For more information, see the LICENSE file.
# 
# set -x

# Default Declarations
#

if [ "x${workspacedir}" = "x" ]
then
   workspacedir=$HOME
fi
if [ "x${dvdBuildName1}" = "x" ]
then
   dvdBuildName1=dvdimageOVJ
fi

gitdir="${workspacedir}/OpenVnmrJ"
vnmrdir="${gitdir}/../vnmr"
standardsdir="${gitdir}/../options/standard"
optddrdir="${gitdir}/../options/console/ddr"
ddrconsoledir="${gitdir}/../console/ddr"

VnmrRevId=$(grep RevID ${gitdir}/src/vnmr/revdate.c | cut -s -d\" -f2 | cut -d\  -f3)
ovjAppName=OpenVnmrJ_${VnmrRevId}.app

# TODO replace this with spiffy OS X app that does away with installer...
packagedir="${workspacedir}/${dvdBuildName1}/Package_contents"
resdir="${workspacedir}/${dvdBuildName1}/install_resources"
mkdir -p "${packagedir}"
mkdir "${resdir}"

cd "${gitdir}/src/macos"
cp -r VnmrJ.app "${packagedir}/$ovjAppName"
rm -f VJ
cc -Os -mmacosx-version-min=10.8 -arch x86_64 VJ.c -o VJ
mkdir -p "${packagedir}/$ovjAppName/Contents/MacOS"
cp VJ "${packagedir}/$ovjAppName/Contents/MacOS/."
rm -f "${vnmrdir}/bin/convert"
rm -f "${vnmrdir}/bin/Infostat"
tar jxf ImageMagick.tar.bz2 -C $vnmrdir
# rm -rf "${vnmrdir}/jre"
# cp $JAVA_HOME/jre $vnmrdir/

vjdir="${packagedir}/${ovjAppName}/Contents/Resources/OpenVnmrJ"

mkdir -p "${vjdir}"
mkdir "${vjdir}/tmp" "$vjdir/acqqueue"
chmod 777 "${vjdir}/tmp" "$vjdir/acqqueue"

cp "${gitdir}/src/macos/preinstall" $resdir/.
cp "${gitdir}/src/macos/postinstall" $resdir/.
chmod +x $resdir/p*

cd "$vnmrdir"; tar cf - --exclude .gitignore --exclude "._*" . | (cd "$vjdir"; tar xpf -)
cd "$ddrconsoledir"; tar cf - --exclude .gitignore --exclude "._*" . | (cd "$vjdir"; tar xpf -)
rm -rf $vjdir/Bayes3
mv -f $vjdir/maclib/mtune_ddr $vjdir/maclib/mtune
mv -f $vjdir/maclib/_sw_ddr $vjdir/maclib/_sw

optionslist=`ls $standardsdir`
for file in $optionslist
do
   if [ $file != "P11" ]
   then
      cd "${standardsdir}/${file}"
      tar cf - --exclude .gitignore --exclude "._*" . | (cd "${vjdir}"; tar xpf -)
   fi
done
optionslist=`ls $optddrdir`
for file in $optionslist
do
   if [ $file != "P11" ]
   then
      cd $optddrdir/$file
      tar cf - --exclude .gitignore --exclude "._*" . | (cd $vjdir; tar xpf -)
   fi
done

cd $gitdir/src/macos
rm -f $vjdir/bin/vnmrj
cp vnmrj.sh $vjdir/bin/vnmrj
chmod 755 $vjdir/bin/vnmrj
cp ovjFixMac.sh $vjdir/bin/ovjFixMac
chmod 755 $vjdir/bin/ovjFixMac

echo "vnmrs" >> $vjdir/vnmrrev 
cd $vjdir/adm/users
cat userDefaults | sed '/^home/c\
home    yes     no      /Users/$accname\
' > userDefaults.bak
rm -f userDefaults
mv userDefaults.bak userDefaults
mkdir profiles/system profiles/user

#Following need a certificate issued by Apple to developer
echo "Code signing requires a certificate issued by Apple. Check for any errors and fix for OS X El Capitan or macOS Sierra"
codesign -s "3rd Party Mac Developer Application:" --entitlements "${gitdir}/src/macos/entitlement.plist" "${packagedir}/${ovjAppName}"


if [[ -f /usr/local/bin/packagesbuild ]]
then
   echo "Making MacOS package of OpenVnmrJ"
   /usr/local/bin/packagesbuild -v -F "${workspacedir}" "${gitdir}/src/macos/ovjpkg.pkgproj"
else
   echo "MacOS Packages.app not installed"
   echo "Cannot build OpenVnmrJ pkg"
fi
