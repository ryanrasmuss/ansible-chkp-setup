#!/bin/bash

# Authored by Ryan Rasmuss github.com/ryanrasmuss

# Ansible library location
config_file=/etc/ansible/ansible.cfg

# Modules directory; defined by line in ansible.cfg
module_dir=/usr/share/my_modules

# python interpreter
python_int=/usr/bin/python2.7

# python library
python_lib=/usr/lib/python2.7/

# ansible inventory file
ansible_inventory=/etc/ansible/hosts
#ansible_inventory=test.txt

# Ansible Test Playbook
test_file=3-cp-ansible-test.yml

OS=$(``cat /etc/os-release | grep ^ID= | cut -c 4-``)

banner()
{
    echo "--------------------------------- Hi -------------------------------------"
    echo "Detected OS: $OS"
    echo "Here are some reminders before running this script!"
    echo "Edit API Settings on Smart Console via Manage & Settings -> Blades"
    echo "Run \"api restart\" on the management server"
    echo "If you have not yet setup ssh-keys for localhost & Management Server.."
    echo ".. then run 1-setup-keys.sh (not as root / no sudo) first."
    echo "--------------------------------------------------------------------------"
}

usage()
{
    echo ""
    printf "\e[1;41mUsage: $0 [Ansible Server User] [Mgmt Server User] [Mgmt Server Hostname] [Mgmt Server IP Address]\n"
    printf "Example: $0 ansible-user admin CA-Mgmt-Server-1 192.168.26.254\e[0m\n"
    echo ""
}

check_root()
{
    if [ $(id -u) != 0 ]; then
        printf "\e[1;41mPlease run as root!\e[0m\n"
        exit 1
    fi
}

check_internet()
{
    echo "Checking for internet connection.."

    if ping -c 1 google.com &> /dev/null; then
        echo "Internet connectivity found"
    else
        echo "No internet connection. Please fix."
        exit 1
    fi
}

check_connection()
{
    echo "Checking communication with Management Server: $1"
    if ping -c 1 $1 &> /dev/null; then
        echo "Connectivity okay"
    else
        echo "No connection to management server. Quitting."
        exit 1
    fi
}

updates()
{
    apt-get update -y
    apt-get upgrade -y
}

install_reqs()
{
    apt-get install git -y
    apt-get install python2.7 -y
    apt-get install openssh-server -y
    apt install python-pip
}

install_ansible()
{
    
    OS_Version=$(``cat /etc/os-release | grep VERSION_ID | cut -c 12-``)
    
    # For Ubuntu 16.04
    if [ $OS_Version == "\"16.04\"" ]; then
        echo "Detected OS_Version: $OS_Version"
        echo "Getting software-properties-common.."
        apt-get install software-properties-common -y &> /dev/null
        echo "Adding ppa:ansible repo.."
        apt-add-repository ppa:ansible/ansible -y &> /dev/null
    # For Everything else (Including 18.01)
    else
        echo "Detected OS_Version: $OS_Version"
        echo "Adding universe repo.."
        add-apt-repository universe &> /dev/null
    fi

    echo "Updating.."
    apt-get update -y &> /dev/null
    echo "Installing ansible.."
    apt-get install ansible -y
}

install_sdk_and_api()
{
    # uncomment the library line
    sed -i 's/#library/library/g' $config_file
    # silence dict to type string warnings
    sed -i '/\[defaults\]/a string_conversion_action\ \=\ ignore' $config_file
    # clone check point rep
    git clone --recursive https://github.com/CheckPoint-APIs-Team/cpAnsible
    # clone the sdk
    git clone https://github.com/CheckPointSW/cp_mgmt_api_python_sdk
    # install the sdk
    echo "Installing Check Point SDK for Ansible"
    pip install cp_mgmt_api_python_sdk/

}

migrate_files()
{
    mkdir -v /usr/share/my_modules
    mv -v cpAnsible/check_point_mgmt/check_point_mgmt.py $module_dir
    mv -v cpAnsible/check_point_mgmt/cp_mgmt_api_python_sdk $python_lib
}

# fill invetory file
# requires $1 := user of ansible server
# requires $2 := user of management server
# requires $3 := name of management server (hostname)
# requires $4 := ip address of management server
# requires $5 := management server's password
init_inventory()
{
    echo "[$3]" >> $ansible_inventory
    echo "127.0.0.1" >> $ansible_inventory
    echo "[$3:vars]" >> $ansible_inventory
    echo "ansible_user=$1" >> $ansible_inventory
    echo "mgmt_server=$4" >> $ansible_inventory
    echo "appliance_name=$3" >> $ansible_inventory
    echo "ansible_python_interpreter=$python_int" >> $ansible_inventory
    echo "mgmt_user=$2" >> $ansible_inventory
    echo "mgmt_password=$5" >> $ansible_inventory
    echo "Wrote password to $ansible_inventory (needed for API calls)"
}

get_fingerprint()
{
    # Find identity file
    id="/home/$1/.ssh/id_rsa"
    finger_file=fingerprint.txt
    inventory_file=/etc/ansible/hosts
    payload_temp=fingerpaint.sh
    payload="finger_file=fingerprint.txt\napi fingerprint | grep SHA1 | cut -c 7- > \$finger_file\necho -e \"fingerprint=\$(cat \$finger_file)\" > \$finger_file"

    # make a payload file
    echo -e $payload > $payload_temp

    # Run payload on mgmt server
    cat $payload_temp | ssh -i $id $2@$3 "bash -"

    # get fingerprint 
    scp -i $id $2@$3:$finger_file .
    # delete payload file
    rm $payload_temp
    # remove generate finger file on server side
    ssh -i $id -t $2@$3 "rm $finger_file"

    # move contents to inventory file
    cat -v $finger_file >> $inventory_file
}

prepare_test_file()
{
    sed -i "s/hosts:/hosts: $1/g" $test_file
}

# $1 is user of ansible server (will be doing API calls)
# $2 is user of management server (defined in API settings)
# $3 is management server name
# $4 is ip address of management server

# check root
banner
check_root

if [ $# != 4 ]; then
    usage
    exit 1
fi

check_internet
check_connection $4

stty -echo
printf "Management Server's user \"$2\" password: " password
read password
stty echo
printf "\n"

updates
install_reqs
install_ansible
install_sdk_and_api
migrate_files
init_inventory $1 $2 $3 $4 $password
get_fingerprint $1 $2 $4 
prepare_test_file $3

echo "------------------------------👌  Done 👌 ----------------------------------"
