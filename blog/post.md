Walkthrough for creating virtual machines for a Kubernetes cluster using the [vSphere](https://registry.terraform.io/providers/hashicorp/vsphere/latest/docs) terraform provider.

This is part 2 of a multi-part series. Part 1 is available at [Using VMWare ESXi 8 and vCenter 8 in your homelab for free](https://perdue.dev/using-vmware-esxi-8-and-vcenter-8-in-your-homelab-for-free/)

# The goal of this series
This series is for you if you are interested in making management of your homelab something more turn-key. It is also for you if you are looking for something to help get hands-on experience to move from hobby tinkering to tools used in the workplace for managing infrastructure like Kubernetes clusters.

The series is an end-to-end walkthrough from installing ESXi on bare metal up to having homelab tools (Jenkins, Kubernetes dashboard) running in a Kubernenetes cluster using infrastructure as code practices to allow you to spin up and manage this whole setup through terraform and ansible.

The end-state Kubernetes cluster we will be creating will have some developer-focused tools deployed which will be described in more detail in part 4. All tools are deployed from code.<br/>
![homelab_tools-1](https://perdue.dev/content/images/2022/12/homelab_tools-1.png)


## Series Notes
To keep this series managable, I will skip over basics of why and how to use tools like terraform and ansible - this series will jump right in using the tools. If you are coming without a basic understanding of those tools, I would suggest running through some tutorials. There are fantastic write ups for those elsewhere.

This is a walkthrough that is meant to be adapted to your network design and hardware. It is best suited for those that have a single homelab machine where ESXi will be installed directly on the hardware and a vCenter instance will be started up within the ESXi host. Also, it should go without needing to say it, but this is not production grade - things like valid tls certificates are not included.

# This guide
At the end of this guide, we will have 4 Ubuntu virtual machines created through the vSphere provider. To keep things defined as code, we will be using [cloud-init](https://cloudinit.readthedocs.io/en/latest/) in [Ubuntu cloud images](https://cloud-images.ubuntu.com/) to allow us to pass in configuration like our OS user accounts, hostname, ssh keys, and storage mount points. All this configuration will be managed through terraform templates. Let's get started.

For an overview of the hardware we are using, please see [Infrastrcture Overview](https://perdue.dev/using-vmware-esxi-8-and-vcenter-8-in-your-homelab-for-free/#infrastructure-overview) from part 1.


TODO ADD IMAGE HERE TO BREAK UP TEXT

# Guide
1. [Get companion code](#get-companion-code)
1. [Creating a template virtual machine](#creating-a-template-virtual-machine)
1. [Apply the Terraform Plan](#apply-the-terraform-plan)
1. [Wrap Up](#wrap-up)


# Get companion code
The code this guide uses is available at [https://github.com/markperdue/vsphere-vm-cloud-init-terraform](https://github.com/markperdue/vsphere-vm-cloud-init-terraform). Clone the companion code repo to have the best experience following along.


# Creating a template virtual machine
As of December 2022, there is an issue that leads to `guestinfo` not being properly passed to cloud-init during startup of the virtual machine for, at least, Ubuntu images. To work around this, we need to reconfigure cloud-init for our template image.

1. Download the OVA image of the desired Ubuntu release. As of writing, that is [22.04 jammy](https://cloud-images.ubuntu.com/releases/jammy/release/)
1. Verify the sha256 checksum of the downloaded image against the stated [checksum](https://cloud-images.ubuntu.com/releases/jammy/release/SHA256SUMS). As this image is regularly updated, the checksum you see will likely be different than the checksum below which is for the image published on 2022-12-01
    ```
    $ sha256sum ubuntu-22.04-server-cloudimg-amd64.ova
    2bacf5305c4a09ad16919ac794b5420a01154b4b957095582a96e5d6161089ee  ubuntu-22.04-server-cloudimg-amd64.ova
    ```
1. Launch the [vcsa-01](https://vcsa-01.lab) instance from part 1 and login with the same credentials used previously. If those were not changed for this lab, they are `administrator@vsphere.local` and `changethisP455word!`
1. Expand the `vcsa-01.lab` listing in the Datacenter tab to show the `esxi-01.lab` host item
1. Right click on `esxi-01.lab` and click `Deploy OVF Template`
    ![deploy-ovf](https://perdue.dev/content/images/2022/12/deploy-ovf.png)
1. Select `Local file` and use the file picker from clicking `Upload Files` to find the `ubuntu-22.04-server-cloudimg-amd64.ova` file and click `Next`
1. Enter a unique name for the `virtual machine name` field such as `ubuntu-jammy-22.04-cloudimg-20221201` which is based off of the release date of the ubuntu image I had downloaded and click `Next`
1. Click through the compute resource screen making sure your `esxi-01.lab` host is selected by clicking `Next`
1. On the review details page click `Next`
1. Select the storage you have available for this VM as well as the disk format. I keep it with the default of `Thick Provision Lazy Zeroed` and click `Next`
1. On the networks screen, click `Next`
1. For the customize templates screen, click `Next`
1. Click `Finish` on the final confirmation screen
1. After a few moments, the OVF template should be deployed into vSphere


## Rebuilding cloud-init in ubuntu images
As mentioned previously, there is a small issue preventing us from using cloud-init properly through terraform in the ubuntu images. This prevents the guestinfo we define in terraform from making it into the VM which breaks our configuration goals. To fix this we need to reconfigure cloud-init.

1. Right click on the `ubuntu-jammy-22.04-cloudimg-20221201` item and click `Edit Settings...`
    ![ovf-template-edit-settings-menu](https://perdue.dev/content/images/2022/12/ovf-template-edit-settings-menu.png)
1. Click the `VM Options` tab and expand `Boot Options`
1. Set the `Boot Delay` to `10000` milliseconds to give us enough time to get into a recovery session shortly
    ![edit-settings-boot-delay](https://perdue.dev/content/images/2022/12/edit-settings-boot-delay.png)
1. Click `OK` to save changes
1. Click on the `ubuntu-jammy-22.04-cloudimg-20221201` listing to display its properties in the main window
1. Click `Launch Remote Console` (if you do not have this tool installed see the tooltip for information on installing it)
1. Accept the security warning that shows up since we aren't using any certificates
    ![vmware-remote-console-security-warning](https://perdue.dev/content/images/2022/12/vmware-remote-console-security-warning.png)
1. In the VMWare Remote Console window, click the `Virtual Machine` menu item and click `Power` > `Power On`
    ![vmware-remote-console-power-on](https://perdue.dev/content/images/2022/12/vmware-remote-console-power-on.png)
1. Immediately click into the Remote Console window so your keystokes are captured by the VM and hold down the `Shift` key
    ![remote-boot](https://perdue.dev/content/images/2022/12/remote-boot.png)
1. The grub menu should be displayed and select `Advanced options for Ubuntu`
    ![advanced-options](https://perdue.dev/content/images/2022/12/advanced-options.png)
1. In the grub menu, select the option that lists `(recovery mode)` at the end
     ![recovery-mode](https://perdue.dev/content/images/2022/12/recovery-mode.png)
1. Select `root    Drop to root shell prompt` from the recovery menu
1. Press enter to enter maintenance mode as instructed
1.From the shell prompt, type `dpkg-reconfigure cloud-init`
    ```
    root@ubuntu:~# dkpg-reconfigure cloud-init
    ```
1. Unselect all the data sources except `VMware` and `None`, hit tab to select `<OK>` and hit enter to save changes
    ![cloud-init-data-sources](https://perdue.dev/content/images/2022/12/cloud-init-data-sources.png)
1. Type `cloud-init clean`
    ```
    root@ubuntu:~# cloud-init clean
    ```
1. Shutdown the VM with `shutdown -h now`
    ```
    root@ubuntu:~# shutdown -h now
    ```
1. Back in vCenter, right click on the `ubuntu-jammy-22.04-cloudimg-20221201` item and click `Edit Settings...`
1. Edit the `Boot Delay` back to `0` milliseconds in the `VM Options` > `Boot Options` page and click `OK`
1. Right click on `ubuntu-jammy-22.04-cloudimg-20221201` and click `Template` > `Convert to Template`
    ![convert-to-template](https://perdue.dev/content/images/2022/12/convert-to-template.png)
1. Click `Yes` to the screen about confirming conversion

Now everything is set for us to use this template as the basis for all our Kubernetes VMs in the terraform plan.


# About the terraform plan
I have created a [terraform plan](https://github.com/markperdue/vsphere-vm-cloud-init-terraform) that we can use to create the 4 VMs for our Kubernetes cluster. This plan is the companion code mentioned earlier so it should already be locally available. The main configuration for this plan is exposed as a [tfvars](https://github.com/markperdue/vsphere-vm-cloud-init-terraform) file with the defaults matching the infrastructure design of this walkthrough.

## Customizing the plan - terraform.tfvars
This config requires at lesat 1 change to get this all going before being applied - 

For security reasons, ssh logins require ssh authorized keys instead of username/password combos. What this means for you is that you will need to edit this file before applying it in the next step and change the value `my_ssh_authorized_key` in `examples/kubernetes/terraform.tfvars` with your public ssh key which is commonly at a location like `~/.ssh/id_ed25519.pub` or some other `.pub` extension. The terraform plan accepts multiple public keys so if you have more than one key you would like to allow for sshing into the VMs, add them in the format `ssh_authorized_keys = ["key1", "key2", ...]`

All the other values are fine left as they but they are customizable and should be (hopefully) self explanatory.

Reference terraform.tfvars file at [terraform.tfvars](https://github.com/markperdue/vsphere-vm-cloud-init-terraform/blob/master/examples/kubernetes/terraform.tfvars)

## Customizing the plan - userdata.tftpl
This config file is the payoff for all that `cloud-init reconfigure` stuff earlier and does not need any changes for our walkthrough. This template file gives us the entrypoint to control cloud-init in our VMs. This file is a bit harder to understand at a glance since it uses specific cloud-init options but cloud-init is [well documented](https://cloudinit.readthedocs.io/en/latest/) which might help.

At a high level, terraform is going to process this template file and resolve all the variables to some of the values from the `terraform.tfvars` file earlier. On the startup of each of the 4 VMs, cloud-init will run and:
- create OS user `appuser` with our ssh authorized keys
- set the VM's hostname to the expected value (e.g. `c1-cp1.lab`)
- creates an additional mount point at `/var/lib/longhorn` with ownership permissions for our `appuser:appowner` user which we will use in the final part of the series for our persistent storage class in Kubernetes using [Longhorn](https://longhorn.io/)

Reference userdata.tftpl file at [userdata.tftpl](https://github.com/markperdue/vsphere-vm-cloud-init-terraform/blob/master/examples/kubernetes/userdata.tftpl)

# Apply the plan
```
terraform init
terraform workspace new kubernetes
terraform apply --var-file=examples/kubernetes/terraform.tfvars
```


```
ssh-keyscan -H -t rsa 192.168.2.21 >> ~/.ssh/known_hosts
ssh-keyscan -H -t rsa 192.168.2.31 >> ~/.ssh/known_hosts
ssh-keyscan -H -t rsa 192.168.2.32 >> ~/.ssh/known_hosts
ssh-keyscan -H -t rsa 192.168.2.33 >> ~/.ssh/known_hosts
```

# (optional) Verify a few things
If you have not used cloud-init much, it is neat to just see that all the things we defined in config worked. You can ssh into one of the machines to do some spot verification of this.

1. ssh into `c1-cp1` using either the ip or fqdn (fqdn must be added to your dns server for that to work)
    ```
    ssh appuser@192.168.2.21
    ```
1. Enter `yes` to the trust warning of the node as we have not connected to this node before and hit enter
    ```
    The authenticity of host '192.168.2.21 (192.168.2.21)' can't be established.
    ED25519 key fingerprint is SHA256:some_unique_value_here_for_your_setup.
    This key is not known by any other names.
    Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
    Warning: Permanently added '192.168.2.21' (ED25519) to the list of known hosts.
    ```
1. We can verify some of what cloud-init setup by seeing our expected user is `appuser` and the group info is `appowner`
    ```
    appuser@c1-cp1:~$ id
    uid=1000(appuser) gid=1000(appowner) groups=1000(appowner),27(sudo),100(users),118(admin)
    ```
1. Verify the hostname is `c1-cp1.lab`
    ```
    appuser@c1-cp1:~$ hostname -f
    c1-cp1.lab
    ```
1. Verify the mount point was added
    ```
    appuser@c1-cp1:~$ cat /etc/fstab
    LABEL=cloudimg-rootfs   /        ext4   discard,errors=remount-ro       0 1
    LABEL=UEFI      /boot/efi       vfat    umask=0077      0 1
    /dev/sdb1       /var/lib/longhorn       ext4    defaults,nofail,comment=cloudconfig     0       0
    ```

Looking good!

# Wrap Up
<what you have now>

<next part details>
