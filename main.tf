provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

resource vsphere_virtual_machine "vm" {
  count                      = length(var.virtual_machines)

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
    size             = data.vsphere_virtual_machine.template.disks.0.size
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  disk {
    label            = "disk1"
    datastore_id     = data.vsphere_datastore.ssd.id
    size             = 20
    eagerly_scrub    = false
    thin_provisioned = false
    unit_number      = 1
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }

  # uses vmware datasource which requires cloud-init >= 21.3
  # https://cloudinit.readthedocs.io/en/latest/topics/datasources/vmware.html
  extra_config = {
    "guestinfo.metadata"          = base64encode(templatefile("${path.module}/assets/metadata.yaml", {
                                      ip           = var.virtual_machines[count.index].ip,
                                      gateway      = var.virtual_machines[count.index].gateway,
                                      nameserver_1 = var.virtual_machines[count.index].nameserver_1
                                    }))
    "guestinfo.metadata.encoding" = "base64"
    "guestinfo.userdata"          = base64encode(templatefile("${path.module}/assets/userdata.yaml", {
                                      fqdn = var.virtual_machines[count.index].fqdn
                                    }))
    "guestinfo.userdata.encoding" = "base64"
  }
}
