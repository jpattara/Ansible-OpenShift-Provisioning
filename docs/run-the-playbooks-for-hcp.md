# Run the Playbooks
## Prerequisites
* Running OCP Cluster ( Management Cluster ), with a storage class provisoned on it.
* KVM host with root user access or user with sudo privileges if compute nodes are KVM.
* zvm host ( bastion ) and nodes if compute nodes are zVM.

### Network Prerequisites
* Add HCP bastion IP as forwarder in management cluster nameserver , or add DNS entry to resolve api.${cluster}.${domain} , api-int.${cluster}.${domain} , *apps.${cluster}.${domain} to a load balancer deployed to redirect incoming traffic to the ingresses pod  ( Bastion ).

* If using dynamic IP for agents, make sure you have entries in DHCP Server for macaddresses you are using in installation to map to  IPv4 addresses and along with this DHCP server should make your IPs to use nameserver which you have configured.
## Note: 
Supported Confugurations: 
*  KVM Compute nodes 
    *  Network type: MacVTap ( Static IP / DHCP )
    *  Disk types: QCOW, DASD
*  z/VM Compute nodes
    *  Network types:  vSwitch, OSA , RoCE , Hipersockets 
    *  Disk types: FCP, DASD
*  LPAR Compute nodes ( Classical LPAR only )
    *   Network types:  OSA , RoCE 
    *   Disk types: FCP, DASD, NVMe

## Step-1: Setup Ansible Vault for Management Cluster Credentials
### Overview
* Creating an encrypted file for storing Management Cluster Credentials and other passwords.
### Steps:
* The ansible-vault create command is used to create the encrypted file.
* Create an encrypted file in playbooks directory and set the Vault password ( Below command will prompt for setting Vault password).
```
ansible-vault create playbooks/secrets.yaml
```

* Give the credentials of Management Cluster in the encrypted file (created above) in following format.
```
kvm_host_password: '<password for kvm host for the specified user>'
bastion_root_pw: '<password_you_want_to_keep_for_bastion>'

# Management cluster login credentials
api_server: '<api-server-url ot management cluster>:<port>' 
user_name: '<username >'
password: '<password >'

# HMC login Credentials ( Required only if compute_node_type is LPAR )
hmca_username: '<user>'
hmca_password: '<password>'
```

* You can edit the encrypted file using below command
```
ansible-vault edit playbooks/secrets.yaml
```
* Make sure you entered Manamegement cluster credenitails properly ,incorrect credentails will cause problem while logging in to the cluster in further steps.

## Step-2: Initial Setup for Hosted Control Plane
* Navigate to the [root folder of the cloned Git repository](https://github.com/IBM/Ansible-OpenShift-Provisioning) in your terminal (`ls` should show [ansible.cfg](https://github.com/IBM/Ansible-OpenShift-Provisioning/blob/main/ansible.cfg)).
* Update variables as per the compute node type (zKVM /zVM) in [hcp.yaml](https://github.com/IBM/Ansible-OpenShift-Provisioning/blob/main/inventories/default/group_vars/hcp.yaml.template) ( hcp.yaml.template )before running the playbooks.
* First playbook to be run is setup_for_hcp.yaml which will create inventory file for HCP and will add ssh key to the kvm host.

* Run this shell command:
```
ansible-playbook playbooks/setup_for_hcp.yaml --ask-vault-pass
```

## Step-3: Create Hosted Cluster 
* Run each part step-by-step by running one playbook at a time, or all at once using [hcp.yaml](https://github.com/IBM/Ansible-OpenShift-Provisioning/blob/main/playbooks/hcp.yaml).
    * If bastion is already available ( bastion_params.create = false ) , just give ip ,user, and nameserver under bastion_params section and remaining parameters under bastion_params can be ignored. 
    * For zVM with network type Hipersockets converged, give ip, user, nameserver, internal_ip, hipersockets, user_id under bastion_params section and remaining parameters under bastion_params can be ignored.
    
* Here's the full list of playbooks to be run in order, full descriptions of each can be found further down the page:
    * create_hosted_cluster.yaml ([code](https://github.com/IBM/Ansible-OpenShift-Provisioning/blob/main/playbooks/create_hosted_cluster.yaml))
    * create_agents_and_wait_for_install_complete.yaml ([code](https://github.com/IBM/Ansible-OpenShift-Provisioning/blob/main/playbooks/create_agents_and_wait_for_install_complete.yaml))

* Watch Ansible as it completes the installation, correcting errors if they arise.
* To look at what tasks are running in detail, open the playbook or roles/role-name/tasks/main.yaml
* Alternatively, to run all the playbooks at once, start the master playbook by running this shell command:
* After installation , you can find the details of cluster like kubeconfig and password in the installation directory ( $HOME/ansible_workdir/ ) 
```
ansible-playbook playbooks/hcp.yaml --ask-vault-pass
```

# Description for Playbooks

## setup_for_hcp Playbook
### Overview
* First-time setup of the Ansible Controller,the machine running Ansible.
### Outcomes
* Inventory file for hcp to be created.
* SSH key generated for Ansible passwordless authentication.
* Ansible SSH key is copied to kvm host.
### Notes
* You can use an existing SSH key as your Ansible key, or have Ansible create one for you.

## create_hosted_cluster Playbook
### Overview
* Creates and configures bastion
* Creating AgentServiceConfig, HostedControlPlane, InfraEnv Resources, Download Images
### Outcomes
* Install prerequisites on kvm_host
* Create bastion
* Configure bastion
* Log in to Management Cluster
* Creates AgentServiceConfig resource and required configmaps
* Deploys HostedControlPlane
* Creates InfraEnv resource and wait till ISO generation
* Download required Images to kvm_host (initrd.img and kernel.img)
* Download rootfs.img and configure httpd on bastion.

## create_agents_and_wait_for_install_complete Playbook
### Overview
* Boots the Agents 
* Scale and Nodepool and monitor all the resources required.
### Outcomes
* Boot Agents 
* Monitor the attachment of agents 
* Approves the agents
* Scale up the nodepool
* Monitor agentmachines and machines creation
* Monitor the worker nodes attachment 
* Configure HAProxy for Hosted workers
* Monitor the Cluster operators
* Display Login Credentials for Hosted Cluster



# Destroy the Hosted Cluser

### Overview
* Destroy the Hosted Control Plane and other resources created as part of installation

### Procedure
* Run the playbook [destroy_cluster_hcp.yaml](https://github.com/IBM/Ansible-OpenShift-Provisioning/blob/main/playbooks/destroy_cluster_hcp.yaml) to destroy all the resources created while installation
```
ansible-playbook playbooks/destroy_cluster_hcp.yaml --ask-vault-pass
```

## destroy_cluster_hcp Playbook
### Overview
* Delete all the resources on Hosted Cluster
* Destroy the Hosted Control Plane
### Outcomes
* Scale in the nodepool to 0 
* Monitors the deletion of workers, agent machines and machines.
* Deletes the agents 
* Deletes InfraEnv Resource
* Destroys the Hosted Control Plane
* Deletes AgentServiceConfig
* Deletes the images downloaded on kvm host
* Destroys VMs of Bastion and Agents

## Notes
#### Overriding OCP Release Image for HCP 
* If you want to use any other image as OCP release image for HCP , you can override it by environment variable.
```
export HCP_RELEASE_IMAGE="<image_url>"
```
