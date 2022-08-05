# Overview
A terraform plan that spins up virtual machines on an ESXi host using vCenter. This repo is organized for the use case of spinning up and down VMs within their own unique terraform workspace with the goal to simplify onboarding and offloading of virtual machines.

The main use case of this repo surrounds spinning up Kubernetes virtual machines to be later configured by Ansible playbooks.


# Features
- uses the new [VMWare datasource](https://cloudinit.readthedocs.io/en/latest/topics/datasources/vmware.html) built into cloud-init version 21.3 and later
- manage multiple virtual machines with separate state files using terraform workspaces


# Quickstart
1. From the root directroy run `terraform init`
2. Create a terraform workspace for the terraform run using `terraform workspace new <some name>`
    ```
    terraform workspace new ubuntu
    ```
3. Modify settings in `<path/to/terraform.tfvars>`
4. Run `terraform apply --var-file=<path/to/terraform.tfvars>`
    ```
    terraform apply --var-file=examples/ubuntu/terraform.tfvars
    ```


# Guide
1. Install ESXI
2. [Installing vCenter on ESXi (Arch linux cli)](#installing-vcenter-on-esxi-arch-linux-cli) or [Installing vCenter on ESXi](#installing-vcenter-on-esxi-abridged)
3. [Create DNS record for vCenter](#create-dns-record-for-vcenter)
4. [Create OVF template for vCenter](#create-ovf-template-for-vcenter)
5. [Run terraform plan](#quickstart)

# Write esxi iso to flash drive
- `sudo dd bs=4M if=VMware-VMvisor-Installer-7.0U3f-20036589.x86_64.iso of=/dev/sda`

# Installing vCenter on ESXi (Arch linux cli)
- Install ovftool from https://customerconnect.vmware.com/downloads/get-download?downloadGroup=OVFTOOL443&download=true&fileId=43493035a4d43d3306fdb7c6ee61df29&uuId=edea95e1-2486-4298-afe6-28099de84bd6
- Install libcrypt `yay -S libxcrypt-compat`
- Run config validators (with replacement of your config json file based off of examples/vsphere-cli.json)
    ```
    ./vcsa-deploy install --accept-eula --acknowledge-ceip --verify-template-only ./local/vsphere-cli.json
    ./vcsa-deploy install --accept-eula --acknowledge-ceip --precheck-only ./local/vsphere-cli.json
    ```
- Install (with replacement of your config json file based off of examples/vsphere-cli.json)
    ```
    ./vcsa-deploy install --accept-eula --acknowledge-ceip ./local/vsphere-cli.json
    ```


# Installing vCenter on ESXi (abridged)
There are many guides available for installing ESXi but fewer for installing vCenter afterwards. 

1. Download [VMware-VCSA-all-7.0.3-18778458](https://customerconnect.vmware.com/en/downloads/details?downloadGroup=VC70U3A&productId=974) or desired VCSA file
2. Double click to mount the image
3. Launch `vcsa-ui-installer/win32/installer.exe`
4. Click `Install`
5. Click `Next`
6. Click to accept the license agreement and click `Next`
7. Enter the values of your ESXi host and click `Next`
8. Accept the certificate warning if it is shown
9. Enter desired values for the new vCenter Server VM and click `Next`
10. Select the desired deployment size and storage size and click `Next`
11. Select the desired datastore (and enable Thing Disk Mode) and click `Next`
12. Configure network settings and click `Next`
```
Network: VM Network
IP version: IPv4
IP assignment: static
FQDN: vcsa-01.lab
IP address: 192.168.2.12
Subnet mask or prefix length: 255.255.255.0
Default gateway: 192.168.2.1
DNS servers: 192.168.2.1,1.1.1.1
```
13. Review settings and click `Finish`
14. Once stage 1 installation is complete, click `Continue`
15. Click `Next` to start stage 2 installation
16. Configure `vCenter Server Configuration` screen and and click `Next`
```
Time synchronization mode: Synchronize time with the NTP servers
NTP servers: time.cloudflare.com
SSH access: Disabled
```
17. Configure SSO Configuration screen and click `Next`
```
Create a new SSO domain
Single Sign-On domain name: vsphere.local
Single Sign-On username: administrator
Single Sing-On password: <enter password>
Confirm password: <re-enter password>
```
18. Uncheck `Join the VMWare's CEIP` and click `Next`
19. Review settings and click `Finish`
20. Click `OK` to warning message
21. Click `Close` when the installation is complete
22. Launch [vCenter UI](https://192.168.2.12)
23. Add a new `Datacenter`
24. Add a new `Cluster`
25. Add a new `Host` to the previously created `Datacenter`


# Create DNS record for vCenter
Create a DNS A record to resolve to vCenter. A basic example of doing this using EdgeOS for Ubiquiti routers is below.

## EdgeOS A record creation
1. SSH to router
2. Run the following commands:
    ```
    configure
    set system static-host-mapping host-name <hostname of vCenter> inet <ip of vCenter>
    commit
    save
    exit
    ```

Example:
```
# sshed into edgerouter
configure
set system static-host-mapping host-name vcsa-01.lab inet <192.168.2.2>
commit
save
exit

# on another machine
ping vcsa-01.lab
PING vcsa-01.lab (192.168.2.2) 56(84) bytes of data.
64 bytes from vcsa-01.lab (192.168.2.2): icmp_seq=1 ttl=62 time=0.598 ms
```


# Create OVF template for vCenter
Download the released Ubuntu OVA image from https://cloud-images.ubuntu.com/releases/focal/release ([direct link](https://cloud-images.ubuntu.com/releases/focal/release/ubuntu-20.04-server-cloudimg-amd64.ova))

Alternatively, daily builds are available at https://cloud-images.ubuntu.com/focal/current/

## Update VMWare Template to properly support virtual machine `extraConfig`
As of November 2021, there is an issue that leads to `guestinfo` not being properly passed to cloud-init during startup of the virtual machine for, at least, Ubuntu images. A workaround for this issue is below.

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

# Create kubernetes vms
```
terraform init
terraform workspace new kubernetes
terraform apply --var-file=examples/kubernetes/terraform.tfvars


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
