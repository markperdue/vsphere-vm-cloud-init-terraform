# Example building an Ubuntu virtual machine.
vsphere_user       = "administrator@vsphere.local"
vsphere_password   = "changethisP455word!"
vsphere_server     = "vcsa-01.lab"
vsphere_datacenter = "Datacenter"
vsphere_cluster    = "Cluster"
vsphere_datastore  = "datastore1"
vsphere_network    = "VM Network"

# Global template to apply to all virtual machines
vm_template_name    = "ubuntu-jammy-22.04-cloudimg-20221201"
vm_user             = "appuser"
vm_group            = "appowner"
vm_timezone         = "America/Los_Angeles"
vm_disk_size        = 20
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
