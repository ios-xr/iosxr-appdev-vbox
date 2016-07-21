#!/bin/bash

########################################################################
# 
# Creates a Vagrantfile for AppDev-WRL7 VM 
#
# Created and tested on Mac OS X. Assumes tools such as vagrant exist.
#
# TBD: Take Command line inputs, Check for vagrant install, Convert
#      to a more robust implementation, etc.
#
########################################################################

# Make sure current directory does not have an existing Vagrantfile since we
# would just overwrite it. So just bail out.

TDIR="tmp.$$"
TFILE="tmp_.$$"
VFILE="Vagrantfile"

VM="AppDev-WRL7"
USER="vagrant"

if [ -f $VFILE ]
then
    echo ERROR: "$VFILE already exists" 1>&2
    exit 1
fi

if [ -d $TDIR ]
then
    echo ERROR: "$TDIR temporary directory already exists" 1>&2
    exit 1
fi

mkdir -p $TDIR
#echo "Created $TDIR temporary directory"

cd ./$TDIR
vagrant init ${VM} > /dev/null 

# Simplified implementation. Eventually convert to support different
# VirtualBox network models
cat >${TFILE} <<EOF

  config.ssh.forward_agent = true
  config.vm.post_up_message = "Welcome to the IOS XR Application Development (AppDev) VM that provides a WRL7 based native environment to build applications for IOS XR (Release 6.1.1) platforms. "
  config.vm.synced_folder ".", "/vagrant", disabled: true

EOF
#cat >${TFILE} <<EOF
#
#  config.ssh.forward_agent = true
#  config.vm.post_up_message = "Welcome to the IOS XR Application Development (AppDev) VM that provides a WRL7 based native environment to build applications for IOS XR (Release 6.1.1) platforms. "
#  config.vm.synced_folder ".", "/vagrant", disabled: true
#  config.vm.network :private_network, virtualbox__intnet: "link1", ip: "11.1.1.20"
#  config.vm.synced_folder "./share/", "/home/${USER}/host_share", type: "rsync",
#    rsync__exclude: ".git/",
#    rsync__args: ["--verbose", "--rsync-path='sudo rsync'", "--archive", "--delete", "-z"]
#  config.vm.provider :virtualbox do |vb|
#    vb.name = "${VM}"
#  end
#
#EOF

MATCH="end"

mv $VFILE $VFILE.bak
sed '/end/d' $VFILE.bak > $VFILE
cat $TFILE >> $VFILE
echo $MATCH >> $VFILE

cp $VFILE ../.
cp $VFILE ../$VFILE.bak

# Clean up temp files and directory
cd ..
rm -rf ./$TDIR
