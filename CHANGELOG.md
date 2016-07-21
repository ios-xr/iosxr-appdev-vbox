# Changelog

1.0 (2016-07-21)

# Vagrantfile Generator

* Introduce new script to auto-generate Vagrantfile to be used with AppDev WRL7 VM. The user downloads this file together with the AppDev WRL7 VBox image.
* The auto-generated Vagrantfile includes basic configuration options. Options such as rsync based host folder share are commented out but tested to work.



# wrl7vbox.sh Automation tool to create VBox images from AppDev WRL7 ISO

* wrl7vbox.sh Automation tool (bash-based) to script a simplified workflow for creating AppDev WRL7 VBox image, given an ISO image.
* wrl7vbox.sh tool creates a VBox VM using VBoxManage tool with primary disk as ISO and secondary VDI disk.
* wrl7vbox.sh tool starts the VBox VM which automatically installs ISO image to the VDI disk image using Anaconda installer packaged in the AppDev WRL7 ISO.
* wrl7vbox.sh tool automatically ejects the ISO disk and changes boot order, then restarts the VBox VM using just the VDI disk image
* Integrated with pyprov.py tool for pre-provisioning the AppDev WRL7 VBox VM.
* Package a Vagrantfile as part of AppDev-WRL7 VBox image using vagrant package tool to allow standard Vagrant bringup without requiring download of a Vagrantfile.
* wrl7vbox.sh tool packages the VBox VM as AppDev WRL7 VBox image.


# pyprov.py Provisioning tool to pre-provision AppDev WRL7 VBox VM

* New Python-based tool pyprov.py created to pre-provision AppDev WRL7 VBox VM. The tool uses pexpect's pxssh package.
* Provision vagrant user credentials in the VM and add sudo support for vagrant user.
* Set PATH in the VM to match that of root user using bash profile for vagrant user.
* Setup SSH in the VM with public key. This provides password-less vagrant workflows.
* Setup XR yum repository in the VM. This allows a user to be able to install RPM packages in the VM from the XR yum repository.


# Create README.md

* Added README.md sections for users wanting to use AppDev WRL7 VBox VM for building applications including just using the Atlas box.
* Added README.md sections for users wanting to build AppDev WRL7 VBox VM using wrl7vbox.sh tool.


# Create CHANGELOG.md

* Created CHANGELOG.md with version 1.0 changes.











