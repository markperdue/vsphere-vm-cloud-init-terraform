# Example building an Ubuntu virtual machine.
vsphere_user       = "administrator@vsphere.local"
vsphere_password   = "password_here"
vsphere_server     = "server_here"
vsphere_datacenter = "Datacenter"
vsphere_cluster    = "Cluster"
vsphere_datastore  = "nvme"
vsphere_network    = "VM Network"

# Global template to apply to all virtual machines
vm_template_name    = "template-ubuntu-20.04-20211207"
vm_user             = "my_user"
vm_group            = "my_group"
vm_timezone         = "America/Los_Angeles"
ssh_authorized_keys = ["my_ssh_authorized_key"]
userdata_file       = "examples/ubuntu/userdata.tftpl"

virtual_machines = [
  {
    fqdn         = "ubuntu.lab",
    cpu          = 2,
    memory       = 1024,
    ip           = "192.168.2.26/24",
    gateway      = "192.168.2.1",
    nameservers = ["192.168.2.1", "1.1.1.1"]
  }
]
