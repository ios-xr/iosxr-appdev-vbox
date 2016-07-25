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

def run_command(s, line):
    """Send the given line to s, wait for prompt, and print the response."""
    s.sendline(line)   # run a command
    s.prompt()         # match the prompt
    print(s.before)    # print everything before the prompt.

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
        run_command(s, 'userdel vagrant')
        run_command(s, 'rm -rf /home/vagrant')
        run_command(s, 'rm -rf /etc/profile.d')

        #
        # Create vagrant user and their environment
        #
        run_command(s, 'useradd -s /bin/bash -G sudo vagrant')
        run_command(s, 'echo vagrant:vagrant | chpasswd')
        run_command(s, 'mkdir -p /etc/profile.d')
        run_command(s, 'cat >/etc/profile.d/appdev.profile <<\'EOF\' \n'
                       'BASE_PATH="/usr/local/bin:/usr/bin:/bin"\n'
                       'if [ "$USER" = "vagrant" ]; then\n'
                       'export PATH="${BASE_PATH}:/usr/local/sbin:/usr/sbin:/sbin"\n'
                       'fi\n'
                       'EOF')
        run_command(s, 'echo \'vagrant ALL=(ALL) NOPASSWD: ALL\' >> /etc/sudoers')
#       run_command(s, 'cat >>visudo <<EOF \nvagrant ALL=(ALL) NOPASSWD: ALL\nEOF')

        # Add public (rather than private key), so users can ssh without a password
        #https://github.com/purpleidea/vagrant-builder/blob/master/v6/files/ssh.sh
        run_command(s, 'mkdir -p /home/vagrant/.ssh')
        run_command(s, 'chmod 700 /home/vagrant/.ssh')
        run_command(s, 'echo \'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key\' > /home/vagrant/.ssh/authorized_keys')
        run_command(s, 'chmod 600 /home/vagrant/.ssh/authorized_keys')
        run_command(s, 'chown -R vagrant:vagrant /home/vagrant/.ssh')

        #
        # Setup XR repository in the VM
        #
        run_command(s, 'cat >/etc/yum/repos.d/IOSXR.repo <<\'EOF\' \n'
                       '[IOSXR.repo]\n'
                       'name=IOS XR Repository\n'
                       'baseurl=https://devhub.cisco.com/artifactory/xr600/3rdparty/x86_64/\n'
                       'enabled=1\n'
                       'gpgcheck=0\n'
                       'EOF')
        run_command(s, 'yum list installed')

        #
        # Logout. We are done.
        #
        s.logout()
    except pexpect.pxssh.ExceptionPxssh as e:
        print(str(e))
        exit_with_usage()


if __name__ == "__main__":
    main()
