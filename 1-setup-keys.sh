#!/bin/bash

install_ssh_server()
{
    sudo apt-get install openssh-server -y
}

generate_keys()
{
    ssh-keygen -b 4096 -t rsa
}

copy_keys()
{
    ssh-copy-id $(whoami)@127.0.0.1
    ssh-copy-id $1@$2
}

if [ $# != 2 ]; then
    echo "Usage: $0 [Mgmt Server User] [Mgmt Server IP]"
    echo "Example: $0 admin 192.168.1.254"
    exit 1
fi

install_ssh_server
generate_keys
copy_keys $1 $2
