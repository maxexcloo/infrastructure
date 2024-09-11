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
    cloudflare_record.vm_oci_ipv4,
    cloudflare_record.vm_oci_ipv6
  )

  filtered_servers_all = merge(
    local.merged_routers,
    local.merged_servers,
    local.merged_servers_proxmox,
    local.merged_vms_oci,
    local.merged_vms_proxmox
  )

  filtered_servers_docker = {
    for k, server in local.filtered_servers_all : k => server
    if contains(server.flags, "docker")
  }

  filtered_servers_openwrt = {
    for k, server in local.filtered_servers_all : k => server
    if server.parent_type == "proxmox" || try(server.network.mac_address, "") != ""
  }

  filtered_servers_noncloud = {
    for k, server in local.filtered_servers_all : k => server
    if server.parent_type != "cloud" && server.tag != "router"
  }

  filtered_tags_tailscale_servers = [
    for k, tag in local.merged_tags_tailscale : tag.tailscale_tag
    if tag.server
  ]

  filtered_tags_tailscale_vpn = [
    for k, tag in local.merged_tags_tailscale : tag.tailscale_tag
    if tag.vpn
  ]

  filtered_tailscale_devices = {
    for k, server in local.filtered_servers_all : k => {
      fqdn_external = server.fqdn_external
      fqdn_internal = server.fqdn_internal
      ipv4 = [for device in data.tailscale_devices.default.devices :
        [for address in device.addresses : address if can(cidrhost("${address}/32", 0))][0]
        if element(split(".", device.name), 0) == k
      ][0]
      ipv6 = [for device in data.tailscale_devices.default.devices :
        [for address in device.addresses : address if can(cidrhost("${address}/128", 0))][0]
        if element(split(".", device.name), 0) == k
      ][0]
    }
    if length([for device in data.tailscale_devices.default.devices : device if element(split(".", device.name), 0) == k]) > 0
  }

  merged_devices = {
    for i, device in var.devices : device.name => merge(
      {
        host     = device.name
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
        record,
        {
          zone = zone
        }
      )
    }
  ]...)

  merged_routers = merge({
    for i, router in var.routers : router.location => merge(
      router,
      {
        flags         = try(router.flags, [])
        fqdn_external = "${router.location}.${var.default.domain_external}"
        fqdn_internal = "${router.location}.${var.default.domain_internal}"
        host          = router.location
        name          = router.location
        parent_name   = ""
        parent_type   = ""
        tag           = "router"
        network = merge(
          {
            mac_address     = ""
            private_address = ""
            public_address  = ""
            ssh_port        = 22
            web_port        = 80
            web_ssl         = false
          },
          try(router.network, {})
        )
        provider = merge(
          {
            port = 81
          },
          var.terraform.openwrt[router.location]
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
          flags         = try(server.flags, [])
          fqdn_external = "${server.name}.${var.default.domain_external}"
          fqdn_internal = "${server.name}.${var.default.domain_internal}"
          host          = "${router.location}-${server.name}"
          location      = router.location
          parent_name   = router.name
          parent_type   = router.type
          tag           = "server"
          network = merge(
            {
              mac_address     = ""
              private_address = ""
              public_address  = cloudflare_record.router[router.location].name
              ssh_port        = 22
            },
            try(server.network, {})
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

  merged_servers_proxmox = merge([
    for k, router in local.merged_routers : {
      for i, server in var.servers_proxmox : "${router.location}-${server.name}" => merge(
        server,
        {
          flags         = try(server.flags, [])
          fqdn_external = "${server.name}.${var.default.domain_external}"
          fqdn_internal = "${server.name}.${var.default.domain_internal}"
          host          = "${router.location}-${server.name}"
          location      = router.location
          parent_name   = router.name
          parent_type   = router.type
          tag           = "server"
          type          = "proxmox"
          network = merge(
            {
              mac_address     = ""
              private_address = ""
              public_address  = cloudflare_record.router[router.location].name
              ssh_port        = 22
              web_port        = 8006
              web_ssl         = true
            },
            try(server.network, {})
          )
          provider = merge(
            {
              username = var.terraform.proxmox[server.name].username
              password = var.terraform.proxmox[server.name].password
              insecure = try(var.terraform.proxmox[server.name].insecure, true)
              port     = try(var.terraform.proxmox[server.name].port, 8006)
            },
            try(server.provider, {})
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

  merged_vms_oci = merge({
    for i, vm in var.vms_oci : "${vm.location}-${vm.name}" => merge(
      vm,
      {
        flags         = try(vm.flags, [])
        fqdn_external = "${vm.name}.${var.default.domain_external}"
        fqdn_internal = "${vm.name}.${var.default.domain_internal}"
        host          = "${vm.location}-${vm.name}"
        parent_name   = "oci"
        parent_type   = "cloud"
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
    for k, server in local.merged_servers_proxmox : {
      for i, vm in var.vms_proxmox : "${server.location}-${server.name}-${vm.name}" => merge(
        vm,
        {
          flags         = try(vm.flags, [])
          fqdn_external = "${server.name}-${vm.name}.${var.default.domain_external}"
          fqdn_internal = "${server.name}-${vm.name}.${var.default.domain_internal}"
          host          = "${server.location}-${server.name}-${vm.name}"
          location      = server.location
          name          = "${server.name}-${vm.name}"
          parent_name   = server.name
          parent_type   = server.type
          tag           = "vm"
          config = merge(
            {
              boot_disk_image_url = ""
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
          network = merge(
            {
              mac_address     = ""
              private_address = ""
              public_address  = cloudflare_record.router[server.location].name
              ssh_port        = 22
            },
            try(vm.network, {})
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
