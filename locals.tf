locals {
  filtered_cloudflare_records = merge(
    {
      for k, cloudflare_record in cloudflare_record.dns : k => cloudflare_record
      if try(local.merged_dns[k].wildcard, false)
    },
    {
      for k, cloudflare_record in cloudflare_record.tailscale_ipv4 : "${k}-internal" => cloudflare_record
    },
    cloudflare_record.router,
    cloudflare_record.server,
    cloudflare_record.vm_ipv4,
    cloudflare_record.vm_ipv6,
    cloudflare_record.vm_oci_ipv4,
    cloudflare_record.vm_oci_ipv6
  )

  filtered_servers_all = merge(
    local.merged_routers,
    local.merged_servers,
    local.merged_vms,
    local.merged_vms_oci,
    local.merged_vms_proxmox
  )

  filtered_servers_openwrt = {
    for k, server in local.filtered_servers_all : k => server
    if contains(server.parent_flags, "proxmox") || try(server.network.mac_address, "") != ""
  }

  filtered_servers_noncloud = {
    for k, server in local.filtered_servers_all : k => server
    if try(local.filtered_servers_all[server.parent_name].tag, "") == "router"
  }

  filtered_tags_tailscale_servers = [
    for k, tag in local.merged_tags_tailscale : tag.tailscale_tag
  ]

  filtered_tailscale_devices = {
    for k, server in local.filtered_servers_all : k => {
      fqdn_external = server.fqdn_external
      fqdn_internal = server.fqdn_internal
      private_ipv4 = [for device in data.tailscale_devices.default.devices :
        [for address in device.addresses : address if can(cidrhost("${address}/32", 0))][0]
        if element(split(".", device.name), 0) == k
      ][0]
      private_ipv6 = [for device in data.tailscale_devices.default.devices :
        [for address in device.addresses : address if can(cidrhost("${address}/128", 0))][0]
        if element(split(".", device.name), 0) == k
      ][0]
    }
    if length([for device in data.tailscale_devices.default.devices : device if element(split(".", device.name), 0) == k]) > 0
  }

  merged_devices = {
    for i, device in var.devices : device.name => merge(
      {
        port     = 22
        username = "root"
      },
      device,
      {
        sftp_paths = concat(var.default.sftp_paths, try(device.sftp_paths, []))
      }
    )
  }

  merged_dns = merge([
    for zone, records in var.dns : {
      for i, record in records : "${record.name == "@" ? "" : "${record.name}."}${zone}-${lower(record.type)}-${i}" => merge(
        {
          priority = null
          zone     = zone
        },
        record
      )
    }
  ]...)

  merged_routers = merge({
    for i, router in var.routers : router.location => merge(
      router,
      {
        description   = try(router.description, upper(router.location))
        flags         = try(router.flags, [])
        fqdn_external = "${router.location}.${var.default.domain_external}"
        fqdn_internal = "${router.location}.${var.default.domain_internal}"
        name          = router.location
        parent_flags  = []
        parent_name   = ""
        tag           = "router"
        network = merge(
          {
            mac_address    = ""
            private_ipv4   = ""
            public_address = ""
            ssh_port       = 22
          },
          try(router.network, {})
        )
        service = merge(
          {
            description    = ""
            enable_service = false
            enable_ssl     = true
            port           = 443
          },
          try(router.service, {}),
        )
        user = merge(
          {
            fullname = ""
            username = "root"
          },
          try(router.user, {}),
          {
            sftp_paths = concat(var.default.sftp_paths, try(router.config.sftp_paths, []))
          }
        )
      }
    )
  })

  merged_servers = merge([
    for k, router in local.merged_routers : {
      for i, server in var.servers : "${router.location}-${server.name}" => merge(
        server,
        {
          description   = try(server.description, title(server.name))
          flags         = try(server.flags, [])
          fqdn_external = "${server.name}.${router.location}.${var.default.domain_external}"
          fqdn_internal = "${server.name}.${router.location}.${var.default.domain_internal}"
          location      = router.location
          parent_flags  = router.flags
          parent_name   = router.name
          tag           = "server"
          network = merge(
            {
              mac_address    = ""
              private_ipv4   = ""
              public_address = cloudflare_record.router[router.location].name
              ssh_port       = 22
            },
            try(server.network, {})
          )
          service = merge(
            {
              description    = ""
              enable_service = false
              enable_ssl     = true
              port           = 443
            },
            try(server.service, {}),
          )
          user = merge(
            {
              fullname = ""
              username = "root"
            },
            try(server.user, {}),
            {
              sftp_paths = concat(var.default.sftp_paths, try(server.config.sftp_paths, []))
            }
          )
        },
      )
      if server.parent == router.name
    }
  ]...)

  merged_tags_tailscale = {
    for i, tag in var.tags : tag.name => merge(
      {
        tailscale_tag = "tag:${tag.name}"
      },
      tag
    )
  }

  merged_vms = merge({
    for i, vm in var.vms : "${vm.location}-${vm.name}" => merge(
      vm,
      {
        description   = try(vm.description, title(vm.name))
        flags         = try(vm.flags, [])
        fqdn_external = "${vm.name}.${vm.location}.${var.default.domain_external}"
        fqdn_internal = "${vm.name}.${vm.location}.${var.default.domain_internal}"
        location      = try(vm.location, "cloud")
        parent_flags  = ["cloud"]
        parent_name   = "cloud"
        tag           = "vm"
        network = merge(
          {
            public_ipv4 = ""
            public_ipv6 = ""
            ssh_port    = 22
          },
          try(vm.network, {})
        )
        service = merge(
          {
            description    = ""
            enable_service = false
            enable_ssl     = true
            port           = 443
          },
          try(vm.service, {}),
        )
        user = merge(
          {
            fullname = ""
            username = "root"
          },
          try(vm.user, {}),
          {
            sftp_paths = concat(var.default.sftp_paths, try(vm.config.sftp_paths, []))
          }
        )
      }
    )
  })

  merged_vms_oci = merge({
    for i, vm in var.vms_oci : "${vm.location}-${vm.name}" => merge(
      vm,
      {
        description   = try(vm.description, title(vm.name))
        flags         = try(vm.flags, [])
        fqdn_external = "${vm.name}.${vm.location}.${var.default.domain_external}"
        fqdn_internal = "${vm.name}.${vm.location}.${var.default.domain_internal}"
        location      = try(vm.location, "cloud")
        parent_flags  = ["cloud"]
        parent_name   = "oci"
        tag           = "vm"
        config = merge(
          {
            packages = []
            timezone = var.default.timezone
          },
          try(vm.config, {})
        )
        network = merge(
          {
            ssh_port = 22
          },
          try(vm.network, {})
        )
        service = merge(
          {
            description    = ""
            enable_service = false
            enable_ssl     = true
            port           = 443
          },
          try(vm.service, {}),
        )
        user = merge(
          {
            fullname = ""
            username = "root"
          },
          try(vm.user, {}),
          {
            sftp_paths = concat(var.default.sftp_paths, try(vm.config.sftp_paths, []))
          }
        )
      }
    )
  })

  merged_vms_proxmox = merge([
    for k, server in local.merged_servers : {
      for i, vm in var.vms_proxmox : "${server.location}-${server.name}-${vm.name}" => merge(
        vm,
        {
          description   = "${server.description} ${try(vm.description, title(vm.name))}"
          flags         = try(vm.flags, [])
          fqdn_external = "${vm.name}.${server.name}.${server.location}.${var.default.domain_external}"
          fqdn_internal = "${vm.name}.${server.name}.${server.location}.${var.default.domain_internal}"
          location      = server.location
          name          = "${server.name}-${vm.name}"
          parent_flags  = server.flags
          parent_name   = server.name
          tag           = "vm"
          config = merge(
            {
              boot_disk_image_url = ""
              memory              = 4
              cpus                = 2
              boot_disk_size      = 128
              operating_system    = "l26"
              timezone            = var.default.timezone
            },
            try(vm.config, {}),
            {
              packages = concat(["qemu-guest-agent"], try(vm.config.packages, []))
            },
          )
          disks = [
            for i, disk in try(vm.disks, {}) : merge(
              {
                backup   = false
                discard  = "ignore"
                external = false
                path     = null
                serial   = null
              },
              try(disk, {})
            )
          ]
          hostpci = try(vm.hostpci, [])
          network = merge(
            {
              mac_address    = ""
              private_ipv4   = ""
              public_address = cloudflare_record.router[server.location].name
              ssh_port       = 22
            },
            try(vm.network, {})
          )
          service = merge(
            {
              description    = ""
              enable_service = false
              enable_ssl     = true
              port           = 443
            },
            try(vm.service, {}),
          )
          usb = try(vm.usb, [])
          user = merge(
            {
              fullname = ""
              username = "root"
            },
            try(vm.user, {}),
            {
              sftp_paths = concat(var.default.sftp_paths, try(vm.config.sftp_paths, []))
            }
          )
        },
      )
      if vm.parent == server.name
    }
  ]...)

  output_b2 = {
    for k, server in local.filtered_servers_all : k => {
      application_key    = b2_application_key.server[k].application_key_id
      application_secret = b2_application_key.server[k].application_key
      bucket_name        = b2_bucket.server[k].bucket_name
      endpoint           = replace(data.b2_account_info.default.s3_api_url, "https://", "")
    }
  }

  output_cloudflare_tunnel_tokens = {
    for k, cloudflare_tunnel in cloudflare_zero_trust_tunnel_cloudflared.server : k => cloudflare_tunnel.tunnel_token
  }

  output_resend_api_keys = {
    for k, restapi_object in restapi_object.resend_api_key_server : k => jsondecode(restapi_object.create_response).token
  }

  output_secret_hashes = {
    for k, server in local.filtered_servers_all : k => random_password.secret_hash_server[k].result
  }

  output_ssh = {
    for k, tls_private_key in tls_private_key.ssh_key_server : k => {
      private_key = trimspace(tls_private_key.private_key_openssh)
      public_key  = trimspace(tls_private_key.public_key_openssh)
    }
  }

  output_tailscale_tailnet_keys = {
    for k, tailscale_tailnet_key in tailscale_tailnet_key.server : k => tailscale_tailnet_key.key
  }
}
