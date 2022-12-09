provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

resource "vsphere_virtual_machine" "vm" {
  count = length(var.virtual_machines)

  name                       = split(".", var.virtual_machines[count.index].fqdn)[0]
  resource_pool_id           = data.vsphere_compute_cluster.this.resource_pool_id
  datastore_id               = data.vsphere_datastore.this.id
  num_cpus                   = var.virtual_machines[count.index].cpu
  memory                     = var.virtual_machines[count.index].memory
  guest_id                   = data.vsphere_virtual_machine.template.guest_id
  scsi_type                  = data.vsphere_virtual_machine.template.scsi_type
  wait_for_guest_net_timeout = 0

  cdrom {
    client_device = true
  }

  network_interface {
    network_id   = data.vsphere_network.this.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = var.vm_disk_size
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  dynamic "disk" {
    for_each = var.addl_disks
    content {
      label            = disk.value.label
      size             = disk.value.size
      eagerly_scrub    = disk.value.eagerly_scrub
      thin_provisioned = disk.value.thin_provisioned
      unit_number      = disk.value.unit_number
    }
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }

  # uses vmware datasource which requires cloud-init >= 21.3
  # https://cloudinit.readthedocs.io/en/latest/topics/datasources/vmware.html
  extra_config = {
    "guestinfo.metadata" = base64encode(templatefile("${path.module}/examples/metadata.tftpl", {
      ip          = var.virtual_machines[count.index].ip,
      gateway     = var.virtual_machines[count.index].gateway,
      nameservers = var.virtual_machines[count.index].nameservers
    }))
    "guestinfo.metadata.encoding" = "base64"
    "guestinfo.userdata" = base64encode(templatefile("${path.module}/${var.userdata_file}", {
      fqdn                = var.virtual_machines[count.index].fqdn,
      user                = var.vm_user,
      group               = var.vm_group,
      timezone            = var.vm_timezone,
      ssh_authorized_keys = var.ssh_authorized_keys
    }))
    "guestinfo.userdata.encoding" = "base64"
  }
}
