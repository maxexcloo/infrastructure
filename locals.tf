locals {
  filtered_cloudflare_records = merge(
    {
      for k, cloudflare_record in cloudflare_record.dns : k => cloudflare_record
      if local.merged_dns[k].wildcard
    },
    {
      for k, cloudflare_record in cloudflare_record.internal : "${k}-internal" => cloudflare_record
    },
    cloudflare_record.noncloud,
    cloudflare_record.vm_ipv4,
    cloudflare_record.vm_ipv6,
    cloudflare_record.vm_oci_ipv4,
    cloudflare_record.vm_oci_ipv6
  )

  filtered_servers = {
    all = merge(
      local.merged_routers,
      local.merged_servers,
      local.merged_vms,
      local.merged_vms_oci,
      local.merged_vms_proxmox
    )

    noncloud = merge(
      local.merged_servers,
      local.merged_vms,
      local.merged_vms_proxmox
    )
  }

  merged_devices = {
    for device in var.devices : device.name => merge(
      {
        port     = 22
        username = "root"
      },
      device,
      {
        sftp_paths = concat(var.default.server_config.sftp_paths, try(device.sftp_paths, []))
      }
    )
  }

  merged_dns = merge([
    for zone, records in var.dns : {
      for i, record in records : "${record.name == "@" ? "" : "${record.name}."}${zone}-${lower(record.type)}-${i}" => merge(
        {
          priority = null
          wildcard = false
          zone     = zone
        },
        record
      )
    }
  ]...)

  merged_routers = {
    for router in var.routers : router.location => merge(
      {
        flags        = []
        parent_flags = []
        parent_name  = ""
        tag          = "router"
      },
      router,
      {
        fqdn_external = "${router.location}.${var.default.domain_external}"
        fqdn_internal = "${router.location}.${var.default.domain_internal}"
        name          = router.location
        title         = try(router.title, upper(router.name), upper(router.location))
        config = merge(
          var.default.server_config,
          try(router.config, {})
        )
        networks = [
          for network in try(router.networks, [{}]) : merge(
            {
              public_address = ""
            },
            network
          )
        ]
        services = [
          for service in try(router.services, []) : merge(
            var.default.service_config,
            service
          )
        ]
        users = [
          for user in try(router.users, [{}]) : merge(
            var.default.user_config,
            user,
            {
              sftp_paths = concat(var.default.server_config.sftp_paths, try(user.sftp_paths, []))
            }
          )
        ]
      }
    )
  }

  merged_servers = merge([
    for router in local.merged_routers : {
      for server in var.servers : "${router.location}-${server.name}" => merge(
        {
          flags = []
          tag   = "server"
        },
        server,
        {
          fqdn_external = "${server.name}.${router.location}.${var.default.domain_external}"
          fqdn_internal = "${server.name}.${router.location}.${var.default.domain_internal}"
          location      = router.location
          parent_flags  = router.flags
          parent_name   = router.name
          title         = try(server.title, title(server.name))
          config = merge(
            var.default.server_config,
            try(server.config, {})
          )
          networks = [
            for network in try(server.networks, [{}]) : merge(
              {
                public_address = cloudflare_record.router[router.location].name
              },
              network
            )
          ]
          services = [
            for service in try(server.services, []) : merge(
              var.default.service_config,
              service
            )
          ]
          users = [
            for user in try(server.users, [{}]) : merge(
              var.default.user_config,
              user,
              { sftp_paths = concat(var.default.server_config.sftp_paths, try(user.sftp_paths, []))
              }
            )
          ]
        },
      )
      if server.parent == router.name
    }
  ]...)

  merged_tags_tailscale = {
    for tag in var.tags : tag.name => merge(
      {
        tailscale_tag = "tag:${tag.name}"
      },
      tag
    )
  }

  merged_vms = merge({
    for vm in var.vms : "${vm.location}-${vm.name}" => merge(
      {
        flags        = []
        location     = "cloud"
        parent_flags = ["cloud"]
        parent_name  = "cloud"
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
        services = [
          for service in try(vm.services, []) : merge(
            var.default.service_config,
            service
          )
        ]
        users = [
          for user in try(vm.users, [{}]) : merge(
            var.default.user_config,
            user,
            {
              sftp_paths = concat(var.default.server_config.sftp_paths, try(user.sftp_paths, []))
            }
          )
        ]
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
          for network in try(vm.networks, [{}]) : network
        ]
        services = [
          for service in try(vm.services, []) : merge(
            var.default.service_config,
            service
          )
        ]
        users = [
          for user in try(vm.users, [{}]) : merge(
            var.default.user_config,
            user,
            {
              sftp_paths = concat(var.default.server_config.sftp_paths, try(user.sftp_paths, []))
            }
          )
        ]
      }
    )
  })

  merged_vms_proxmox = merge([
    for server in local.merged_servers : {
      for vm in var.vms_proxmox : "${server.location}-${server.name}-${vm.name}" => merge(
        {
          flags = []
          tag   = "vm"
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
              cpus                                  = 2
              memory                                = 4
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
                public_address = cloudflare_record.router[server.location].name
                vlan_id        = null
              },
              network
            )
          ]
          services = [
            for service in try(vm.services, []) : merge(
              var.default.service_config,
              service
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
          users = [
            for user in try(vm.users, [{}]) : merge(
              var.default.user_config,
              user,
              {
                sftp_paths = concat(var.default.server_config.sftp_paths, try(user.sftp_paths, []))
              }
            )
          ]
        },
      )
      if vm.parent == server.name
    }
  ]...)

  output_b2 = {
    for k, b2_bucket in b2_bucket.server : k => {
      application_key_id = b2_application_key.server[k].application_key_id
      application_key    = b2_application_key.server[k].application_key
      bucket_name        = b2_bucket.bucket_name
      endpoint           = replace(data.b2_account_info.default.s3_api_url, "https://", "")
    }
  }

  output_cloud_config = {
    for k, server in local.filtered_servers.all : k => templatefile(
      "templates/cloud_config/cloud_config",
      {
        cloudflare_tunnel_token = try(local.output_cloudflare_tunnels[k].token, "")
        default                 = var.default
        k                       = k
        password                = htpasswd_password.server[k].sha512
        server                  = server
        ssh_keys                = concat(data.github_user.default.ssh_keys, [local.output_ssh[k].public_key])
        tailscale_tailnet_key   = try(local.output_tailscale_tailnet_keys[k], "")
      }
    )
  }

  output_cloudflare_tunnels = {
    for k, cloudflare_zero_trust_tunnel_cloudflared in cloudflare_zero_trust_tunnel_cloudflared.server : k => {
      cname = cloudflare_zero_trust_tunnel_cloudflared.cname
      id    = cloudflare_zero_trust_tunnel_cloudflared.id
      token = cloudflare_zero_trust_tunnel_cloudflared.tunnel_token
    }
  }

  output_ignition = {
    for k, server in local.filtered_servers.all : k => ""
  }

  output_resend_api_keys = {
    for k, restapi_object in restapi_object.resend_api_key_server : k => jsondecode(restapi_object.create_response).token
  }

  output_secret_hashes = {
    for k, random_password in random_password.secret_hash : k => random_password.result
  }

  output_servers_all = {
    for k, server in local.filtered_servers.all : k => merge(
      {
        b2                    = local.output_b2[k]
        cloudflare_tunnel     = try(local.output_cloudflare_tunnels[k], "")
        name                  = k
        resend_api_key        = local.output_resend_api_keys[k]
        secret_hash           = local.output_secret_hashes[k]
        ssh                   = concat(data.github_user.default.ssh_keys, [local.output_ssh[k].public_key])
        tailscale_tailnet_key = try(local.output_tailscale_tailnet_keys[k], "")
      },
      server
    )
  }

  output_services_all = {
    for k, server in local.output_servers_all : k => [
      for service in server.services : merge(
        {
          server = k
          url    = "${service.enable_ssl ? "https://" : "http://"}${server.fqdn_internal}${service.port == 80 || service.port == 443 ? "" : ":${service.port}"}"
        },
        service,
        {
          widgets = [
            for widget in try(service.widgets, []) : merge(
              var.default.widget_config,
              {
                description       = try(service.description, var.default.widget_config.description)
                enable_monitoring = coalesce(service.enable_monitoring, var.default.widget_config.enable_monitoring)
                icon              = try(service.service, var.default.widget_config.icon)
                title             = try(service.title, var.default.widget_config.title)
              },
              widget
            )
          ]
        }
      )
    ]
  }

  output_ssh = {
    for k, tls_private_key in tls_private_key.ssh_key : k => {
      private_key = trimspace(tls_private_key.private_key_openssh)
      public_key  = trimspace(tls_private_key.public_key_openssh)
    }
  }

  output_tailscale_tailnet_keys = {
    for k, tailscale_tailnet_key in tailscale_tailnet_key.server : k => tailscale_tailnet_key.key
  }
}
