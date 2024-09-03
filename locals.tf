locals {
  filtered_defaults_portainer = {
    for k, v in var.default : k => v
    if k == "domain_external" || k == "domain_internal" || k == "email" || k == "timezone"
  }

  filtered_servers_all = merge(
    local.merged_routers,
    local.merged_servers,
    local.merged_servers_proxmox,
    local.merged_vms_oci,
    local.merged_vms_proxmox
  )

  filtered_servers_noncloud = {
    for k, server in local.filtered_servers_all : k => server
    if server.parent_type != "cloud" && server.tag != "router"
  }

  filtered_servers_portainer = {
    for k, server in local.filtered_servers_all : k => {
      b2_bucket_application_key    = local.output_b2_buckets[k].application_key
      b2_bucket_application_key_id = local.output_b2_buckets[k].application_key_id
      b2_bucket_bucket_name        = local.output_b2_buckets[k].bucket_name
      b2_bucket_endpoint           = local.output_b2_buckets[k].endpoint
      cloudflare_api_token         = local.output_cloudflare_api_tokens[k].api_token
      fqdn_external                = server.fqdn_external
      fqdn_internal                = server.fqdn_internal
      host                         = server.host
      name                         = server.name
      resend_api_key               = local.output_resend_api_keys[k].api_key
    }
  }

  filtered_servers_ssh = {
    for k, server in local.filtered_servers_all : k => server
    if server.tag == "server"
  }

  filtered_websites_noncloud = merge([
    for k, server in local.filtered_servers_noncloud : {
      for i, website in local.output_cloudflare_records : i => {
        fqdn_external = website.hostname
        host          = server.host
        location      = server.location
      }
      if server.fqdn_external == website.hostname || server.fqdn_external == website.value
    }
  ]...)

  filtered_websites_portainer = merge([
    for k, server in local.filtered_servers_all : {
      for k, website in local.merged_websites : k => {
        app_name                     = website.app_name
        app_type                     = website.app_type
        b2_bucket_application_key    = website.enable_b2_bucket ? local.output_b2_buckets[k].application_key : ""
        b2_bucket_application_key_id = website.enable_b2_bucket ? local.output_b2_buckets[k].application_key_id : ""
        b2_bucket_bucket_name        = website.enable_b2_bucket ? local.output_b2_buckets[k].bucket_name : ""
        b2_bucket_endpoint           = website.enable_b2_bucket ? local.output_b2_buckets[k].endpoint : ""
        database_password            = website.enable_database_password ? local.output_database_passwords[k].database_password : ""
        database_username            = website.enable_database_password ? website.app_type : ""
        description                  = website.description
        fqdn                         = website.fqdn
        group                        = website.group
        host                         = server.host
        resend_api_key               = website.enable_resend_api_key ? local.output_resend_api_keys[k].api_key : ""
        secret_hash                  = website.enable_secret_hash ? local.output_secret_hashes[k].secret_hash : ""
        tailscale_tailnet_key        = website.enable_tailscale_key ? local.output_tailscale_tailnet_keys[k].tailnet_key : ""
        url                          = website.url
      }
      if server.fqdn_external == website.content || server.fqdn_internal == website.content
    }
  ]...)

  filtered_zones = merge(
    var.dns,
    var.websites
  )

  merged_devices = {
    for i, device in var.devices : device.name => merge(
      {
        host       = device.name
        port       = 22
        sftp_paths = concat(var.default.sftp_paths, try(device.sftp_paths, []))
        username   = "root"
      },
      device
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

  merged_tags = {
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
            private_address = ""
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

  merged_websites = merge([
    for zone, websites in var.websites : {
      for k, website in websites : "${website.name}.${zone}${try(website.port, 0) != 0 ? ":${website.port}" : ""}" => merge(
        {
          app_name                 = website.name
          app_type                 = "default"
          content                  = ""
          description              = ""
          enable_b2_bucket         = false
          enable_cloudflare_record = true
          enable_database_password = false
          enable_password          = false
          enable_resend_api_key    = false
          enable_secret_hash       = false
          enable_ssl               = true
          enable_tailscale_key     = false
          fqdn                     = "${website.name}.${zone}"
          group                    = "Websites (${zone})"
          onepassword_url          = "${try(website.enable_ssl, true) ? "${try(website.port, 0) != 0 ? "https://" : ""}" : "http://"}${website.name}.${zone}${try(website.port, 0) != 0 ? ":${website.port}" : ""}"
          port                     = 0
          url                      = "${try(website.enable_ssl, true) ? "https://" : "http://"}${website.name}.${zone}${try(website.port, 0) != 0 ? ":${website.port}" : ""}"
          username                 = ""
          zone                     = zone
        },
        website
      )
    }
  ]...)

  output_b2_buckets = merge(
    {
      for k, server in local.filtered_servers_all : k => {
        application_key    = b2_application_key.server[k].application_key
        application_key_id = b2_application_key.server[k].application_key_id
        bucket_name        = b2_bucket.server[k].bucket_name
        endpoint           = replace(data.b2_account_info.default.s3_api_url, "https://", "")
      }
    },
    {
      for k, website in local.merged_websites : k => {
        application_key    = b2_application_key.website[k].application_key
        application_key_id = b2_application_key.website[k].application_key_id
        bucket_name        = b2_bucket.website[k].bucket_name
        endpoint           = replace(data.b2_account_info.default.s3_api_url, "https://", "")
      }
      if website.enable_b2_bucket
    }
  )

  output_cloudflare_api_tokens = {
    for k, cloudflare_api_token in cloudflare_api_token.server : k => {
      api_token = cloudflare_api_token.value
    }
  }

  output_cloudflare_records = merge(
    {
      for k, cloudflare_record in cloudflare_record.internal : "${k}-internal" => cloudflare_record
    },
    {
      for k, cloudflare_record in merge(
        cloudflare_record.dns,
        cloudflare_record.router,
        cloudflare_record.server,
        cloudflare_record.vm_oci_ipv4,
        cloudflare_record.vm_oci_ipv6,
        cloudflare_record.website
      ) : k => cloudflare_record
      if cloudflare_record.type == "A" || cloudflare_record.type == "AAAA" || cloudflare_record.type == "CNAME"
    }
  )

  output_cloudflare_tunnel_tokens = {
    for k, cloudflare_tunnel in cloudflare_zero_trust_tunnel_cloudflared.server : k => {
      tunnel_token = cloudflare_tunnel.tunnel_token
    }
  }

  output_database_passwords = {
    for k, random_password in random_password.database_password : k => {
      database_password = random_password.result
    }
  }

  output_resend_api_keys = {
    for k, restapi_object in merge(restapi_object.server_resend_api_key, restapi_object.website_resend_api_key) : k => {
      api_key = jsondecode(restapi_object.create_response).token
    }
  }

  output_secret_hashes = {
    for k, random_password in random_password.secret_hash : k => {
      secret_hash = random_password.result
    }
  }

  output_ssh_keys = {
    for k, tls_private_key in tls_private_key.server_ssh_key : k => {
      private_key = trimspace(tls_private_key.private_key_openssh)
      public_key  = trimspace(tls_private_key.public_key_openssh)
    }
  }

  output_tailscale_tailnet_keys = {
    for k, tailscale_tailnet_key in merge({ github = tailscale_tailnet_key.github }, tailscale_tailnet_key.server, tailscale_tailnet_key.website) : k => {
      tailnet_key = tailscale_tailnet_key.key
    }
  }
}
