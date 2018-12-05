# Ansible + Check Point Setup

By:   **Ryan Rasmuss**

### Requirements

A fresh install of one of the following (tested) Linux Distros:

- [ubuntu 16.04 LTS Server 64-bit](http://releases.ubuntu.com/16.04/)
- [ubuntu 16.04 LTS Desktop 64-bit](http://releases.ubuntu.com/16.04/)
- [ubuntu 18.04.1 LTS Server 64-bit](http://releases.ubuntu.com/18.04/)

A R80.xx Management Server with the following tasks completed:

- First Time Wizard Completed.
- In SmartConsole, edit your API settings via Manage & Settings -> Blades -> Management API -> Advanced Settings...
- Remember to run ``api restart`` on the management server after changing api settings.
- Connectivity between your soon-to-be Ansible server and Check Point Management Server (this script will do a ping test).
- The ability to establish SSH connections between soon-to-be Ansible server and Check Point Management Server.
- Internet access for the soon-to-be Ansible server.
- A user on Management server w/ ``/bin/bash`` as default shell (see Section "User with ``bin/bash``").


### Quick Start

1. Unless you already have SSH keys setup between this server and your Check Point Management server, run the script ``./1-setup-keys.sh`` **not** as root. This will generate a pair of keys between this server and the management server.

2. Run script ``sudo ./2-ansible-chkp-setup.sh`` (note the sudo!) and follow the prompts. This script will ask for user input. Be prepared to enter the linux server's password and the Check Point Management Server's password. Type 'y' or '[ENTER]' when in doubt.

3. Run script ``ansible-playbook 3-cp-ansible-test.yml`` to test Ansible. If you get no scary red text, you are good to go!

Example:

- I have a linux server with hostname ``ubuntu`` and user ``ansible``. This linux server has internet access and can ssh into the Check Point R80.10 Management Server.
- I have a R80.10 Management Server with hostname ``Mgmt-Server``, user ``admin`` with default shell as ``/bin/bash`` (not ``clish``), and ip-address ``192.168.1.254``. I already completed the first time wizard, changed the Management API Settings to ``All IP Addresses that can be used for GUI clients``, and ran ``api restart`` on the Management Server.
- I run ``./1-setup-keys.sh admin 192.168.1.254`` (**not** as root!)
- I run ``sudo ./2-ansible-chkp-setup.sh ansible admin Mgmt-Server 192.168.1.254`` and follow all of the prompts. Will ask password for local linux server and R80.10 Management server.
- Finally, I run ``ansible-playbook 3-cp-ansible-test.yml`` and i'm ready to build some playbooks.
- Done.

### 3. What I do

Overview of ``1-setup-keys.sh``

1. Generates rsa ssh keys with 2048 bytes
2. Copies keys to self (127.0.0.1). This is required for Ansible to properly communicate with Check Point. This allows public-key authentication to self.

Overview of ``2-ansible-chkp-setup.sh``:

1. Updates and upgrades linux server
2. Installs ansible, ssh server, git, and python2.7
3. Installs [Check Point's Python Management API SDK](https://github.com/CheckPointSW/cpAnsible)
4. Creates ``/usr/share/my_modules`` and adds ``check_point_mgmt.py`` to this directory
5. Moves ``cp_mgmt_api_python_sdk/`` to ``/usr/lib/python2.7/``
6. Adds several lines to the end of ``/etc/ansible/hosts`` (your Ansible inventory file)
7. Gets Management Server's fingerprint and adds a fingerprint line in ``/etc/ansible/hosts`` and leaves behind a ``fingerprint.txt`` file
8. Prepares the ``cp-ansible-test.yml``

Overview of ``3-cp-ansible-test.yml``

1. Login to Management Server
2. Registers session information
3. Adds host of name ``test-123abc`` with ip-address ``1.1.1.2``
4. Discards (no changes are made)
5. Log out


### 4. User with ``/bin/bash``

Change the default shell of the ``admin`` user on the Management Server to ``/bin/bash``. This can be completed via clish command: ``set user admin shell /bin/bash``. Run ``save config`` afterwards. Use ``admin`` for the "Mgmt Server User" parameter in the scripts.

After finishing this setup, you can change the shell back via ``set user admin shell /etc/cli.sh`` and ``save config``

### 5. Misc

[Check Point Playbook Examples](https://github.com/ryanrasmuss/ansible-checkpoint-playbooks)

[Check Point Management API Documentation](https://sc1.checkpoint.com/documents/latest/APIs/index.html#introduction~v1.2%20)

[Ansible Documentation](https://docs.ansible.com/)

[Check Point Github](https://github.com/CheckPointSW)

