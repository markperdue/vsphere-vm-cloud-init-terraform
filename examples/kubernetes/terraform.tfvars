# Example building a Kubernetes cluster consisting of 4 virtual machines (1 control plane and 3 worker nodes).
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
userdata_file       = "examples/kubernetes/userdata.tftpl"

virtual_machines = [
  {
    fqdn         = "c1-cp1.lab",
    cpu          = 2,
    memory       = 4096,
    ip           = "192.168.2.21/24",
    gateway      = "192.168.2.1",
    nameservers = ["192.168.2.1", "1.1.1.1"]
  },
  # {
  #   fqdn         = "c1-node1.lab",
  #   cpu          = 2,
  #   memory       = 4096,
  #   ip           = "192.168.2.31/24",
  #   gateway      = "192.168.2.1",
  #   nameservers = ["192.168.2.1", "1.1.1.1"]
  # },
  # {
  #   fqdn         = "c1-node2.lab",
  #   cpu          = 2,
  #   memory       = 4096,
  #   ip           = "192.168.2.32/24",
  #   gateway      = "192.168.2.1",
  #   nameservers = ["192.168.2.1", "1.1.1.1"]
  # },
  # {
  #   fqdn         = "c1-node3.lab",
  #   cpu          = 2,
  #   memory       = 4096,
  #   ip           = "192.168.2.33/24",
  #   gateway      = "192.168.2.1",
  #   nameservers = ["192.168.2.1", "1.1.1.1"]
  # }
]

addl_disks = [
  {
    label            = "disk1",
    size             = 50,
    eagerly_scrub    = false,
    thin_provisioned = false,
    unit_number      = 1
  }
]
