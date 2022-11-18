## Table of Contents
  - [Docker Swarm Terraform](#docker-swarm-terraform)
  - [Features](#features)
  - [Preparation](#preparation)
  - [Running the Module](#running-the-module)
    - [Network Config](#network-config)
    - [Generate Ansible Inventory](#generate-ansible-inventory)

# Docker Swarm Terraform

Deploy a docker swarm in Proxmox.

## Features

- Creates VMs for Both Docker Manager and Workers using template
- Initialises the swarm manager and registers additional managers and worker VMs
- Scale the swarm vertically or horizontally as required
- Shared Storage in all Nodes

Note: It can be run on any machine with access to Proxmox and Terraform Installed.

## Preparation

Note: This method requires an ubuntu vm template with docker installed and accessible to the user ubuntu as non-root command.
To create a compatible vm programtically refer to [proxmox-ubuntu-vm-template](https://github.com/prashantsolanki3/proxmox-ubuntu-vm-template)
- Create env.tfvars (in the same directory as main.tf)

```
nano env.tfvars
```

- Check variables.tf, read the descriptions and add the required variables to env.tfvars. The env.tfvars file should look something like this:

```
PROXMOX_IP                     = "PROXMOX_IP"
PM_API_TOKEN_ID                = "proxmox-token-id"
PM_API_TOKEN_SECRET            = "proxmox-token-secret"
docker_manager_count=3
docker_worker_count=4
.
.
.
# Other Variables
```

## Running the Module

- (First Run) Initialise the Project: Installs the required dependencies.

```
terraform init
```

- Plan the deployment

```
terraform plan -var-file="env.tfvars"
```

- Apply the changes

WARNING: This would actually update the resources on Proxmox.

```
terraform apply -var-file="env.tfvars"
```
- Destroy the VMs

```
terraform destroy -var-file="env.tfvars"
```

### Network Config

Note: Make sure the IP addresses do not overlap.
The current config of IP addresses restrict the number of VM to

- Max allowed Managers: 5
- Max allowed Workers: 5

Network Configuration

```
docker_manager_ipv4_range=10.2.21.12
docker_worker_ipv4_range=10.2.21.12
docker_manager_range_offset=0
docker_worker_range_offset=5
```

### Generate Ansible Inventory

Ansible inventory is created in `ansible/inventory` upon completion of the terraform deployment is complete.

You can manually configure and run any Ansible playbooks.
<!-- ## Ansible

Run Playboon on the specified inventory

Note: The comma (,) at the end is required.
```
ansible all -i <ip>,
``` -->