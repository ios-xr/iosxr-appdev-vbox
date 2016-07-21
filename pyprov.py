#!/usr/bin/env python

''' This runs a sequence of commands on a remote host using SSH. It runs a simple set 
of commands on the remote host. 

./pyprov.py [-s server_hostname] [-p port] [-U username] [-P password]
    -s : hostname of the remote server to login to.
    -p : port number of SSH on the remote server to login to.
    -U : username to user for login.
    -P : Password to user for login.

Example:
        ./pyprov.py -s localhost -p 3230 -U <uid> -P <password>

'''

from __future__ import print_function
from __future__ import absolute_import

__author__        = "Sudhir Rustogi"
__maintainer__    = "Sudhir Rustogi"


import os, sys, re, getopt, getpass
import pexpect
import pexpect.pxssh

try:
    raw_input
except NameError:
    raw_input = input


def exit_with_usage():

    print(globals()['__doc__'])
    os._exit(1)

#
# Main routine that parses the parameters and runs expect SSH session
#
def main():

    ######################################################################
    ## Parse the options, arguments, get ready, etc.
    ######################################################################
    try:
        optlist, args = getopt.getopt(sys.argv[1:], 'h?s:p:U:P:', ['help','h','?'])
    except Exception as e:
        print(str(e))
        exit_with_usage()
    options = dict(optlist)
    if len(args) > 1:
        exit_with_usage()

    if [elem for elem in options if elem in ['-h','--h','-?','--?','--help']]:
        print("Help:")
        exit_with_usage()

    if '-s' in options:
        host = options['-s']
    else:
        host = raw_input('hostname: ')
    if '-p' in options:
        port = options['-p']
    else:
        port = 22
    if '-U' in options:
        user = options['-U']
    else:
        user = raw_input('username: ')
    if '-P' in options:
        password = options['-P']
    else:
        password = getpass.getpass('password: ')


    #
    # Push commands using pxssh
    #
    try:
        #
        # First login via SSH
        #
        s = pexpect.pxssh.pxssh()
        terminal_type='ansi'
        original_prompt=r"[#$]"
        login_timeout=10
        s.login(host, user, password, terminal_type, original_prompt, login_timeout, port)

        #
        # First cleanup vagrant user
        #
        s.sendline('userdel vagrant')   # run a command
        s.prompt()             # match the prompt
        print(s.before)        # print everything before the prompt.

        s.sendline('rm -rf /home/vagrant')   # run a command
        s.prompt()             # match the prompt
        print(s.before)        # print everything before the prompt.

        s.sendline('rm -rf /etc/profile.d')   # run a command
        s.prompt()             # match the prompt
        print(s.before)        # print everything before the prompt.

        #
        # Create vagrant user and their environment
        #
        s.sendline('useradd -s /bin/bash -G sudo vagrant')   # run a command
        s.prompt()             # match the prompt
        print(s.before)        # print everything before the prompt.

        s.sendline('echo vagrant:vagrant | chpasswd')   # run a command
        s.prompt()             # match the prompt
        print(s.before)        # print everything before the prompt.

        s.sendline('mkdir -p /etc/profile.d')   # run a command
        s.prompt()             # match the prompt
        print(s.before)        # print everything before the prompt.

        s.sendline('cat >/etc/profile.d/appdev.profile <<\'EOF\' \nBASE_PATH="/usr/local/bin:/usr/bin:/bin"\nif [ "$USER" = "vagrant" ]; then\n    export PATH="${BASE_PATH}:/usr/local/sbin:/usr/sbin:/sbin"\nfi\nEOF')   # run a command 
        s.prompt()             # match the prompt
        print(s.before)        # print everything before the prompt.

        s.sendline('echo \'vagrant ALL=(ALL) NOPASSWD: ALL\' >> /etc/sudoers')   # run a command
        s.prompt()             # match the prompt
        print(s.before)        # print everything before the prompt.

#        s.sendline('cat >>visudo <<EOF \nvagrant ALL=(ALL) NOPASSWD: ALL\nEOF')   # run a command
#        s.prompt()             # match the prompt
#        print(s.before)        # print everything before the prompt.

        # Add public (rather than private key), so users can ssh without a password
        #https://github.com/purpleidea/vagrant-builder/blob/master/v6/files/ssh.sh
        s.sendline('mkdir -p /home/vagrant/.ssh')
        s.prompt()             # match the prompt
        print(s.before)        # print everything before the prompt.

        s.sendline('chmod 700 /home/vagrant/.ssh')
        s.prompt()             # match the prompt
        print(s.before)        # print everything before the prompt.

        s.sendline('echo \'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key\' > /home/vagrant/.ssh/authorized_keys')
        s.prompt()             # match the prompt
        print(s.before)        # print everything before the prompt.

        s.sendline('chmod 600 /home/vagrant/.ssh/authorized_keys')
        s.prompt()             # match the prompt
        print(s.before)        # print everything before the prompt.

        s.sendline('chown -R vagrant:vagrant /home/vagrant/.ssh')
        s.prompt()             # match the prompt
        print(s.before)        # print everything before the prompt.

        #
        # Setup XR repository in the VM
        #
        s.sendline('cat >/etc/yum/repos.d/IOSXR.repo <<\'EOF\' \n[IOSXR.repo]\nname=IOS XR Repository\nbaseurl=https://devhub.cisco.com/artifactory/xr600/3rdparty/x86_64/\nenabled=1\ngpgcheck=0\nEOF')      # run a command 
        s.prompt()             # match the prompt
        print(s.before)        # print everything before the prompt.

        s.sendline('yum list installed')      # run a command 
        s.prompt()             # match the prompt
        print(s.before)        # print everything before the prompt.

        #
        # Logout. We are done.
        #
        s.logout()
    except pexpect.pxssh.ExceptionPxssh as e:
        print(str(e))
        exit_with_usage()


if __name__ == "__main__":
    main()
