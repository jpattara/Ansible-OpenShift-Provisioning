#!/bin/bash

ansible-galaxy collection install community.general
ansible-galaxy collection install community.crypto
ansible-galaxy collection install ansible.posix
ansible-galaxy collection install community.libvirt
sudo brew install sshpass -y
sudo brew install openssh -y
sudo brew install ssh-copy-id -y