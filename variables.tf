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

variable "vsphere_datacenter" {
  description = "The name of the vSphere Datacenter into which resources will be created."
  type        = string
}

variable "vsphere_cluster" {
  description = "The name of the vSphere Cluster into which resources will be created."
  type        = string
}

variable "vsphere_datastore" {
  description = "The name of the vSphere Datastore into which resources will be created."
  type        = string
}

variable "vsphere_network" {
  description = "The name of the vSphere Network into which resources will be created."
  type        = string
}

variable "vm_template_name" {
  description = "The name of the vSphere Template to use for vm creation."
  type        = string
}

variable "vm_user" {
  description = "The default user to create in the vm."
  type        = string
}

variable "vm_group" {
  description = "The default group for the user in the vm."
  type        = string
}

variable "vm_timezone" {
  description = "The default timezone for the vm."
  type        = string
}

variable "ssh_authorized_keys" {
  description = "List of ssh authorized key entry to add to the vm."
  type        = list(string)
}

variable "userdata_file" {
  description = "Relative path from root to the userdata template file to use."
  type        = string
}

variable "virtual_machines" {
  type = list(object({
    fqdn        = string,
    cpu         = number,
    memory      = number,
    ip          = string,
    gateway     = string,
    nameservers = list(string)
  }))
}

variable "addl_disks" {
  type = list(object({
    label            = string,
    size             = number,
    eagerly_scrub    = bool,
    thin_provisioned = bool,
    unit_number      = string
  }))
}
