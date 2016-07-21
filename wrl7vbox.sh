#!/bin/bash

#title         :wrl7vbox.sh
#description   :Automation Script for converting Wind River Linux 7 (WRL7) based AppDev VM ISO to VirtualBox Image 
#author        :Sudhir Rustogi
#maintainer    :Sudhir Rustogi
#

#
# Requires VBoxManage tool - Version 5.*
#
VBM_VER_PREF="5.0"
PY_VER_MIN="2.7.11"

SSH_HOST_PORT="3230"      # Need mechanism to find available port on host dynamically
SSH_GUEST_PORT="22"
MIN_DISK_SIZE=12
VM_MEM="1024"
VM_VRAM="12"
VM_DISK="8192"
VBOX_DIR="$HOME/VirtualBox\ VMs"
VARIANT="Standard"

function check_host ()
{
    vbox_ver=$(VBoxManage -v)
    if [[ $vbox_ver != $VBM_VER_PREF* ]]
    then
	echo ""
	echo "VBoxManage Version: $vbox_ver, need $VBM_VER_PREF.0 or greater"
	echo ""
	exit 1
    fi

    py_ver=$(python --version 2>&1 | awk '{print $2;}')
    echo ""
    echo "Detected Python Version: $py_ver, Preferred Python Version $PY_VER_MIN or greater"
    echo ""
}
check_host

# wrl7iso.sh tool usage
function usage ()
{
    "Usage: wrl7vbox.sh -name <vm-name> -iso <wrl7-iso>"
    exit 1
}

# First check if mandatory inputs are supplied
if [ "$#" -lt 2 ]
then
    usage
fi

# Parse user inputs
while [ "$#" -ne 0 ];
do
    case $1 in
        -name )
            VMNAME=$2
            shift
            ;;

        -iso )
            ISO=$2
            shift
            ;;

        -* )
            usage
            ;;
    esac
    shift
done

# Check that ISO file exists
if [ ! -f $ISO ]
then
    echo ""
    echo "File $ISO does not exist"
    echo ""
    exit 1
fi

# Parsed inputs
echo "##########################################################################"
echo ""
echo "Virtual Box VM : $VMNAME"
echo "WRL7 ISO       : $ISO"
echo ""
echo "##########################################################################"

# Check if there are any vagrant machines that contain VM name
function get_machines ()
{
    machines=$(echo "$(vagrant status $VMNAME)" | grep $VMNAME | awk '{print $1;}')
    machines_l=($(echo "$machines"))
    num_machines=${#machines_l[@]}
}

# Check if there are any vagrant boxes that contain VM name
function get_boxes ()
{
    boxes=$(echo "$(vagrant box list)" | grep $VMNAME | awk '{print $1;}')
    boxes_l=($(echo "$boxes"))
    num_boxes=${#boxes_l[@]}
}

# Check if there are any virtualbox vms that contain VM name
function get_vms ()
{
    vms=$(echo "$(VBoxManage list vms)" | grep $VMNAME | awk '{print $2;}' | sed 's/{//' | sed 's/}//')
    vms_l=($(echo "$vms"))
    num_vms=${#vms_l[@]}
}

# Remove vagrant machines with matching name
function remove_machines ()
{
    get_machines

    if [ $num_machines -eq 0 ] 
    then
	echo "No existing vagrant machines found, nothing to remove"
	return
    else
	echo "Removing $num_machines vagrant machines: " $machines
    fi

    for i in $(seq 1 $num_machines)
    do
    	echo "Destroying vagrant machine: " ${machines_l[$i - 1]}

	# Use vagrant to shut off and destroy VM
        # Destroy existing Vagrant machine VM
	vagrant destroy --force ${machines_l[$i - 1]}
    done
}

# Remove vagrant boxes with matching name
function remove_boxes ()
{
    get_boxes

    if [ $num_boxes -eq 0 ] 
    then
	echo "No existing vagrant boxes found, nothing to remove"
	return
    else
	echo "Removing $num_boxes vagrant boxes: " $boxes
    fi

    for i in $(seq 1 $num_boxes)
    do
    	echo "Removing vagrant box: " ${boxes_l[$i - 1]}

        # Remove existing Vagrant Box with matching name
	vagrant box remove ${boxes_l[$i - 1]}
    done
}

# Remove vbox vms with matching name
function remove_vms ()
{
    get_vms

    if [ $num_vms -eq 0 ] 
    then
	echo "No existing virtualbox vms found, nothing to remove"
	return
    else
	echo "Removing $num_vms virtualbox vms: " $vms
    fi

    for i in $(seq 1 $num_vms)
    do
    	echo "Destroying virtualbox vm: " ${vms_l[$i - 1]}

	# Use VBoxManage to shut off and destroy VM
        # Shutdown the existing VirtualBox VM
	running=$(vboxmanage showvminfo $VMNAME | grep -c "running (since")
	if [ $running -eq 1 ]
	then
	    VBoxManage controlvm ${vms_l[$i - 1]} poweroff
	fi

        # Cleanup and remove the VirtualBox VM
	#VBoxManage modifyvm ${vms_l[$i - 1]} --natpf1 delete "GuestSSH"
        VBoxManage unregistervm ${vms_l[$i - 1]} --delete
    done
}

# Cleanup SSH keys
function cleanup_ssh ()
{
    # Remove stale SSH entry
    ssh-keygen -R [127.0.0.1]:$SSH_HOST_PORT
    ssh-keygen -R [localhost]:$SSH_HOST_PORT
}

# Cleanup existing VMs and Boxes
function cleanup ()
{
    echo ""
    echo "Cleaning up existing VMs containing string $VMNAME"
    echo ""

    # Shut off and destroy existing Vagrant Machines 
    remove_machines

    # Remove any existing Vagrant boxes
    remove_boxes

    # Shut off and destroy existing VirtualBox VMs 
    remove_vms

    # Cleanup SSH entry
    cleanup_ssh

    echo ""
    echo "Cleanup done for existing VMs containing string $VMNAME"
    echo ""
}

# Check if the VM with the given name already exists
if [[ $(VBoxManage list vms | grep $VMNAME) == *$VMNAME* ]]
then
    echo ""
    echo "VM containing $VMNAME already exists, auto-removing existing VMs"
    echo ""
fi

cleanup          # For now we call this everytime so we start with a clean slate


# Check if enough disk space is available
function enough_disk_space ()
{
    avail_disk_space=$(df -k / | grep -v Available | awk '{print $4;}')
    min_disk_sz=$(($MIN_DISK_SIZE*1024*1024)) 

    if [ $avail_disk_space -lt ${min_disk_sz} ]
    then
	echo "Not enough disk space on host, available $avail_disk_space, needed ${min_disk_sz}"
	exit 1
    fi 
}
enough_disk_space

echo ""
echo "Ready to create $VMNAME VM"
echo ""

sleep 30

# Create VirtualBox VM
function create_vm ()
{
    # Create a new VirtualBox VM
    VBoxManage createvm --name $VMNAME --register

    # Setup memory, display etc
    VBoxManage modifyvm $VMNAME --memory $VM_MEM --acpi on --boot1 dvd
    VBoxManage modifyvm $VMNAME --vram $VM_VRAM
    VBoxManage modifyvm $VMNAME --ostype "Linux_64"

    # Setup networking - currently setting up all 8 nics to make sure Intel device driver is selected
    # setup nic1 - default vbox network
    VBoxManage modifyvm $VMNAME --nic1 nat --nictype1 82540EM
    VBoxManage modifyvm $VMNAME --natpf1 "GuestSSH,tcp,127.0.0.1,$SSH_HOST_PORT,,$SSH_GUEST_PORT"
    #VBoxManage modifyvm $VMNAME --nic1 bridged --bridgeadapter1 eth0
    #VBoxManage modifyvm $VMNAME --macaddress1 XXXXXXXXXXXX

    # setup nictype2 to nictype8 - may be used for other vbox networks
    VBoxManage modifyvm $VMNAME --nictype2 82540EM
    VBoxManage modifyvm $VMNAME --nictype3 82540EM
    VBoxManage modifyvm $VMNAME --nictype4 82540EM
    VBoxManage modifyvm $VMNAME --nictype5 82540EM
    VBoxManage modifyvm $VMNAME --nictype6 82540EM
    VBoxManage modifyvm $VMNAME --nictype7 82540EM
    VBoxManage modifyvm $VMNAME --nictype8 82540EM

    #VBoxManage modifyvm $VMNAME --nic2 intnet --nictype2 82540EM

    # Setup storage
    #VBoxManage createhd --filename "$VBOX_DIR/$VMNAME/$VMNAME.vdi" --size $VM_DISK
    VBoxManage createmedium disk  --filename "$VBOX_DIR/$VMNAME/$VMNAME.vdi" \
	--size $VM_DISK --format VDI --variant $VARIANT
    VBoxManage storagectl $VMNAME --name "IDE Controller" --add ide

    VBoxManage storageattach $VMNAME --storagectl "IDE Controller"  \
	--port 0 --device 0 --type hdd --medium "$VBOX_DIR/$VMNAME/$VMNAME.vdi"

    VBoxManage storageattach $VMNAME --storagectl "IDE Controller" \
	--port 1 --device 0 --type dvddrive --medium "$ISO"

    # Setup Guest Additions
}
create_vm

# Run VirtualBox VM in headless mode as we just want Anaconda autoinstaller 
# to do its magic
function run_headless ()
{
    # Start the VM for installation
    VBoxHeadless --startvm $VMNAME &

    # Sleep if you want to verify setting in VirtualBox Manager GUI
    sleep 240

    running=$(vboxmanage showvminfo $VMNAME | grep -c "running (since")
    if [ $running -eq 1 ]
    then
	echo "Successfully installed VM disk image"
    else
	echo "Failed to install VM disk image"
	cleanup
	exit 1
    fi
}
run_headless

function prep_image ()
{
    # Prep the disk image with vagrant user credentials
    python ./pyprov.py -s localhost -p ${SSH_HOST_PORT} -U root -P cisco123
}

# Remove DVD and create a VirtualBox image for distribution
function create_vbox ()
{
    echo "Removing dvd"

    # Shutdown the VM first
    VBoxManage controlvm $VMNAME poweroff

    # Remove the dvd disk
    VBoxManage modifyvm $VMNAME --dvd none

    # Start the VM again. VM is ready for use now
    VBoxHeadless --startvm $VMNAME &

    # Sleep if you want to verify setting in VirtualBox Manager GUI
    sleep 120

    running=$(vboxmanage showvminfo $VMNAME | grep -c "running (since")
    if [ $running -eq 1 ]
    then
	echo "Successfully restarted VM using disk image"
    else
	echo "Failed to start VM using disk image"
	exit 1
    fi

    # Prep the image with vagrant credentials and such ..
    prep_image

    # Create Vagrantfile to be packaged
    rm Vagrantfile
    ./prepVagrant.sh

    # Create Virtual Box
    rm $VMNAME.box
    vagrant package --base $VMNAME --vagrantfile ./Vagrantfile --output $VMNAME.box
    rm Vagrantfile

    # Shutdown the VM again
    #VBoxManage controlvm $VMNAME poweroff

    # Export it as OVF to run on another server. On that server, just import the OVF using
    # VBoxManage import $VMNAME.ovf
    #rm $VMNAME.ovf
    #rm $VMNAME*.vmdk
    #VBoxManage export $VMNAME --output $VMNAME.ovf

    # Now that we are done, lets go ahead and clean up 
    cleanup
}
create_vbox

