# Overview
A terraform plan that spins up virtual machines on an ESXi host using vCenter. This repo is organized for the use case of spinning up and down VMs within their own unique terraform workspace with the goal to simplify onboarding and offloading of virtual machines.

The main use case of this repo surrounds spinning up Kubernetes virtual machines to be later configured by Ansible playbooks.

A guide for using this repo to spin up a Kubernetes cluster is available at [Creating VMs for Kubernetes using Terraform and VMWare vSphere](https://perdue.dev/creating-vms-for-kubernetes-using-terraform-and-vmware-vsphere/)


# Features
- uses the new [VMWare datasource](https://cloudinit.readthedocs.io/en/latest/topics/datasources/vmware.html) built into cloud-init version 21.3 and later
- manage multiple virtual machines with separate state files using terraform workspaces


# Quickstart
1. From the root directroy run `terraform init`
1. Create a terraform workspace for the terraform run using `terraform workspace new <some name>`
    ```
    terraform workspace new ubuntu
    ```
1. Modify settings in `<path/to/terraform.tfvars>`
1. Run `terraform apply --var-file=<path/to/terraform.tfvars>`
    ```
    terraform apply --var-file=examples/ubuntu/terraform.tfvars
    ```


# Create kubernetes vms
```
terraform init
terraform workspace new kubernetes
terraform apply --var-file=examples/kubernetes/terraform.tfvars
```

# Destroy kubernetes vms
```
terraform workspace select kubernetes
terraform destroy --var-file=examples/kubernetes/terraform.tfvars
```

# Install single vm
```
terraform init
terraform workspace new ubuntu
terraform apply --var-file=examples/ubuntu/terraform.tfvars
```

# Destroy
```
terraform workspace select ubuntu
terraform destroy --var-file=examples/ubuntu/terraform.tfvars
```


## Update VMWare Template to properly support virtual machine `extraConfig`
As of December 2022, there is an issue that leads to `guestinfo` not being properly passed to cloud-init during startup of the virtual machine for, at least, Ubuntu images. A workaround for this issue is below.

Solution from https://askubuntu.com/a/1368625
```
The problem is that cloud-init has, by default, the OVF datasource provider invoked prior to the new VMware datasource (as of cloud-init 21.3). Terraform is providing data that the OVF datasource provider likes and therefore it processes the information. That explains why vApp Properties "user-data" accepts the cloud-config.

The solution is to remove the OVF datasource provider from cloud-init:

    [Web Browser[ Download OVA: https://cloud-images.ubuntu.com/releases/focal/release/ubuntu-20.04-server-cloudimg-amd64.ova
    [VC UI] Deploy from OVF, accept defaults (except disk provisioning, use Thin Provisioning).
    [VC UI] Edit Settings / VM Options / Boot Options / Boot Delay = 2000ms.
    [VC UI] Open VM Console.
    [VM Console] Power On VM.
    [VM Console] Hold Shift on BIOS screen (to force GRUB to display menu).
    [VM Console] Select Advanced Options for Ubuntu.
    [VM Console] Select latest kernel version with "(recovery mode)" at the end.
    [VM Console] Select "root / Drop to root shell prompt"
    [VM Console] Press Enter for maintenance
    [VM Console] # dpkg-reconfigure cloud-init
    [VM Console] Deselect everything except VMware and None
    [VM Console] # cloud-init clean
    [VM Console] # shutdown -h now
    [VC UI] Edit Settings / VM Options / Boot Options / Boot Delay = 0ms.
    [VC UI] Convert to template
```
