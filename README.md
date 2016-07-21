# AppDev-WRL7 Native Build VirtualBox VM

This README file describes the process to use the AppDev-WRL7 Native Build VirtualBox VM and shows how to build a sample application using the Native toolchains bundled in the VM.


# Pre-Built (Ready-to-use) AppDev-WRL7 Native Build Artifacts

Pre-Built (Ready-to-use) Version 1.0 AppDev-WRL7 Native Build Artifacts are available at http://engci-maven-master.cisco.com/artifactory/simple/appdevci-release/AppDev-WRL7/1.0/.

We recommend that you use Version 1.0 artifacts as per instructions provided below.


# Building AppDev-WRL7 Native Build VM box image from WRL7 ISO

Note: Users of AppDev-WRL7 Native Build VM do not need to do this, as they can directly download an existing box. If that is what you want to do, just go to the Section "Using the AppDev-WRL7 Native Build VM, given the box file"

First download the ISO.

```
cd <path-to-iso\
curl -O http://engci-maven-master.cisco.com/artifactory/simple/appdevci-release/AppDev-WRL7/1.0/wrlinux-image-installer-intel-x86-64-20160411171331.iso
```

Now build an AppDev-WRL7 Native Build VM box image, using wrl7vbox tool. Please be patient as wrl7vbox tool will take about 10-15 minutes to generate the vbox image. 

The wrl7vbox.sh tool is available at https://github.com/ios-xr/iosxr-appdev-vbox and can be used as shown below.

```
git clone https://github.com/ios-xr/iosxr-appdev-vbox
cd iosxr-appdev-vbox
./wrl7vbox.sh -name AppDev-WRL7 -iso <path-to-iso>/wrlinux-image-installer-intel-x86-64-20160411171331.iso
```

# Using the AppDev-WRL7 Native Build VM, given the box image

Users of AppDev-WRL7 Native Build VM have multiple ways available to them. One can build the box as described in previous section and use that box. Or one can down the box from Cisco artifactory location -  http://engci-maven-master.cisco.com/artifactory/simple/appdevci-release/AppDev-WRL7/1.0/AppDev-WRL7.box. Or one can just use the box available at Atlas - https://atlas.hashicorp.com/ciscoxr/boxes/appdev-xr6.1.1

## Initialize a New Vagrant VM (If using your own box image)

The following will create a brand new Vagrantfile. This approach is recommended if you want to create your own Vagrantfile.

```
vagrant init "AppDev-WRL7"
```


## Create AppDev WRL7 Vagrant Box using the Box image built in Build section

```
vagrant box list             # first list existing boxes
vagrant box add --name "AppDev-WRL7" AppDev-WRL7.box
```

## Alternatively, create AppDev WRL7 Vagrant Box using the Box image hosted at Cisco repository

```
vagrant box list             # first list existing boxes
vagrant box add --name "AppDev-WRL7" http://engci-maven-master.cisco.com/artifactory/simple/appdevci-release/AppDev-WRL7/1.0/AppDev-WRL7.box
```

## Use Atlas AppDev-WRL7 Native Build VM vbox

Users can also use AppDev-WRL7 Native Build VM vbox as available on Atlas. In this case just do the following and the box is automatically downloaded

```
vagrant init ciscoxr/appdev-xr6.1.1
```

## Customize Vagrantfile such as sharing host directory into AppDev WRL7 Vagrant Box VM

A Vagrantfile is packaged as part of the box image. However the packaged Vagrantfile does not allow sharing a host directory as AppDev WRL7 Vagrant Box VM does not support native virtualbox sync folder functionality. Users can , however, share a host directory (e.g., ./share/ into the VM as /home/vagrant/host_share/ directory) by adding the following lines to a Vagrantfile that is created when they execute vagrant init command above. The lines below use an alternative method based on rsync.

```
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder "./share/", "/home/vagrant/host_share", type: "rsync",
    rsync__exclude: ".git/",
    rsync__args: ["--verbose", "--rsync-path='sudo rsync'", "--archive", "--delete", "-z"]
```

Make ./share/ directory in current directory before connecting to the VM. 

```
mkdir -p ./share
```


## Create and connect to AppDev WRL7 VBox VM

```
vagrant up
vagrant ssh
```

## Destroy AppDev WRL7 VBox VM

```
vagrant destroy
vagrant status
```

## Remove AppDev WRL7 Vagrant Box

User can remove the Box if they created one earlier as follows. You don't need to do this if you are using Atlas box.

```
vagrant box remove "AppDev-WRL7"
vagrant box list
```

## Build an Application inside the VM. As an example we build CollectD

```
# Build CollectD Application in AppDev VM
rm -rf /home/vagrant/collectd
rm -rf /home/vagrant/collectd-wrl7

# Download CollectD Application
git clone -b collectd-5.5 https://github.com/collectd/collectd.git

# Cisco CollectD changes
# E.g., change dependency package lex to flex in build.sh since AppDev VM
# does not contain lex, flex provides equivalent functionality
git clone https://github.com/ios-xr/iosxr-collectd.git

# Apply Cisco changes
cp collectd-wrl7/build.sh collectd/.

# Build CollectD
cd /home/vagrant/collectd
./build.sh
./configure
make
sudo make install

# Build CollectD RPM
cd /home/vagrant/collectd-wrl7/
sudo ./changes.sh
sudo rpmbuild --clean /usr/src//rpm/SPECS/collectd.spec
sudo rpmbuild -ba /usr/src/rpm/SPECS/collectd.spec

# CollectD RPM is at /usr/src/rpm/RPMS/noarch/collectd-5.5.0-211.noarch.rpm

```
