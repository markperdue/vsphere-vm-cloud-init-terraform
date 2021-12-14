variable "vsphere_user" {
  description = "The username for vSphere API operations."
  type        = string
}

variable "vsphere_password" {
  description = "The password for vSphere API operations."
  type        = string
}

variable "vsphere_server" {
  description = "The vCenter server name for vSphere API operations."
  type        = string
}

variable vsphere_datacenter {
  description = "The name of the vSphere Datacenter into which resources will be created."
  type        = string
}

variable vsphere_cluster {
  description = "The name of the vSphere Cluster into which resources will be created."
  type        = string
}

variable vsphere_datastore {
  description = "The name of the vSphere Datastore into which resources will be created."
  type        = string
}

variable vsphere_network {
  description = "The name of the vSphere Network into which resources will be created."
  type        = string
}

variable vm_template_name {
  description = "The name of the vSphere Template to use for vm creation."
  type        = string
}

variable "virtual_machines" {
  type = list(object({
    fqdn         = string,
    cpu          = number,
    memory       = number,
    ip           = string,
    gateway      = string,
    nameserver_1 = string
  }))
}
