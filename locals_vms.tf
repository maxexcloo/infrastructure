locals {
  merged_vms = merge({
    for vm in var.vms : "${vm.location}-${vm.name}" => merge(
      {
        flags        = []
        location     = "cloud"
        parent_flags = ["cloud"]
        parent_name  = "cloud"
        services     = []
        tag          = "vm"
      },
      vm,
      {
        fqdn_external = "${vm.name}.${vm.location}.${var.default.domain_external}"
        fqdn_internal = "${vm.name}.${vm.location}.${var.default.domain_internal}"
        title         = try(vm.title, title(vm.name))
        config = merge(
          var.default.server_config,
          try(vm.config, {})
        )
        networks = [
          for network in try(vm.networks, [{}]) : merge(
            {
              public_ipv4 = ""
              public_ipv6 = ""
            },
            network
          )
        ]
        user = merge(
          var.default.user_config,
          try(vm.user, {})
        )
      }
    )
  })

  merged_vms_oci = merge({
    for vm in var.vms_oci : "${vm.location}-${vm.name}" => merge(
      {
        flags        = []
        location     = "cloud"
        parent_flags = ["cloud"]
        parent_name  = "oci"
        services     = []
        tag          = "vm"
      },
      vm,
      {
        fqdn_external = "${vm.name}.${vm.location}.${var.default.domain_external}"
        fqdn_internal = "${vm.name}.${vm.location}.${var.default.domain_internal}"
        title         = try(vm.title, title(vm.name))
        config = merge(
          var.default.server_config,
          {
            boot_disk_image_id = ""
            boot_disk_size     = 128
            cpus               = 4
            ingress_ports      = [22, 80, 443]
            memory             = 8
            shape              = "VM.Standard.A1.Flex"
          },
          try(vm.config, {})
        )
        networks = [
          for network in try(vm.networks, [{}]) : network
        ]
        user = merge(
          var.default.user_config,
          try(vm.user, {})
        )
      }
    )
  })

  merged_vms_proxmox = merge([
    for server in local.merged_servers : {
      for vm in var.vms_proxmox : "${server.location}-${server.name}-${vm.name}" => merge(
        {
          flags    = []
          services = []
          tag      = "vm"
        },
        vm,
        {
          fqdn_external = "${vm.name}.${server.name}.${server.location}.${var.default.domain_external}"
          fqdn_internal = "${vm.name}.${server.name}.${server.location}.${var.default.domain_internal}"
          location      = server.location
          name          = "${server.name}-${vm.name}"
          parent_flags  = server.flags
          parent_name   = server.name
          title         = "${server.title} ${try(vm.title, title(vm.name))}"
          config = merge(
            var.default.server_config,
            {
              boot_disk_image_compression_algorithm = null
              boot_disk_image_url                   = ""
              boot_disk_size                        = 128
              cpus                                  = 4
              enable_serial                         = false
              memory                                = 8
              operating_system                      = "l26"
            },
            try(vm.config, {}),
            {
              packages = concat(["qemu-guest-agent"], try(vm.config.packages, []), var.default.server_config.packages)
            }
          )
          hostpci = [
            for hostpci in try(vm.hostpci, {}) : merge(
              {
                pcie = true
                xvga = false
              },
              hostpci
            )
          ]
          networks = [
            for network in try(vm.networks, [{}]) : merge(
              {
                firewall       = true
                public_address = cloudflare_dns_record.router[server.location].name
                vlan_id        = null
              },
              network
            )
          ]
          usb = [
            for usb in try(vm.usb, {}) : merge(
              {
                usb3 = true
              },
              usb
            )
          ]
          user = merge(
            var.default.user_config,
            try(vm.user, {})
          )
        },
      )
      if vm.parent == server.name
    }
  ]...)
}