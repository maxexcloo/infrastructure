locals {
  b2_buckets = {
    for k, b2_bucket in b2_bucket.website : k => {
      application_key    = nonsensitive(b2_application_key.website[k].application_key)
      application_key_id = b2_application_key.website[k].application_key_id
      bucket_name        = b2_bucket.bucket_name
      endpoint           = data.b2_account_info.default.s3_api_url
    }
  }

  cloudflare_api_tokens = {
    for k, cloudflare_api_token in cloudflare_api_token.server : k => {
      api_token = nonsensitive(cloudflare_api_token.value)
    }
  }

  cloudflare_records_merged = merge(
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

  cloudflare_tunnel_tokens = {
    for k, cloudflare_tunnel in cloudflare_tunnel.server : k => {
      tunnel_token = nonsensitive(cloudflare_tunnel.tunnel_token)
    }
  }

  database_passwords = {
    for k, random_password in random_password.database_password : k => {
      database_password = nonsensitive(random_password.result)
    }
  }

  defaults_portainer = {
    for k, v in var.default : k => v
    if k != "home" && k != "sftp_paths"
  }

  devices = {
    for i, device in var.devices : device.host => merge(
      {
        port       = 22
        sftp_paths = concat(var.default.sftp_paths, try(device.sftp_paths, []))
        username   = "root"
      },
      device
    )
  }

  dns = merge([
    for zone, records in var.dns : {
      for i, record in records : "${record.name == "@" ? "" : "${record.name}."}${zone}-${lower(record.type)}-${i}" => merge(
        record,
        {
          zone = zone
        }
      )
    }
  ]...)

  resend_api_keys_merged = {
    for k, restapi_object in merge(restapi_object.server_resend_api_key, restapi_object.website_resend_api_key) : k => {
      api_key = jsondecode(restapi_object.create_response).token
    }
  }

  routers = merge({
    for i, router in var.routers : router.location => merge(
      router,
      {
        fqdn_external = "${router.location}.${var.default.domain_external}"
        fqdn_internal = "${router.location}.${var.default.domain_internal}"
        host          = router.location
        name          = router.location
        parent_name   = ""
        parent_type   = ""
        tags          = concat(["router"], try(router.tags, []))
        type          = "openwrt"
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
            automation = "root"
            fullname   = ""
            sftp_paths = var.default.sftp_paths
            ssh_keys   = data.github_user.default.ssh_keys
            username   = "root"
          },
          try(router.user, {})
        )
      }
    )
  })

  secret_hashes = {
    for k, random_password in random_password.secret_hash : k => {
      secret_hash = nonsensitive(random_password.result)
    }
  }

  servers_mac = merge([
    for k, router in local.routers : {
      for i, server in var.servers_mac : "${router.location}-${server.name}" => merge(
        server,
        {
          fqdn_external = "${server.name}.${var.default.domain_external}"
          fqdn_internal = "${server.name}.${var.default.domain_internal}"
          host          = "${router.location}-${server.name}"
          location      = router.location
          parent_name   = router.name
          parent_type   = router.type
          tags          = concat(["server"], try(router.tags, []))
          type          = "mac"
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
              automation = "root"
              fullname   = ""
              sftp_paths = var.default.sftp_paths
              ssh_keys   = data.github_user.default.ssh_keys
              username   = "root"
            },
            try(server.user, {})
          )
        },
      )
      if server.parent == router.name
    }
  ]...)

  servers_merged = merge(
    local.routers,
    local.servers_mac,
    local.servers_proxmox,
    local.vms_oci,
    local.vms_proxmox
  )

  servers_merged_cloudflare = {
    for k, server in local.servers_merged : k => server
    if server.parent_type != "cloud" && server.tags[0] != "router"
  }

  servers_merged_portainer = {
    for k, server in local.servers_merged : k => {
      cloudflare_api_token = local.cloudflare_api_tokens[k].api_token
      fqdn_external        = server.fqdn_external
      fqdn_internal        = server.fqdn_internal
      host                 = server.host
      name                 = server.name
      resend_api_key       = local.resend_api_keys_merged[k].api_key
    }
  }

  servers_merged_ssh = {
    for k, server in local.servers_merged : k => server
    if server.tags[0] == "server"
  }

  servers_proxmox = merge([
    for k, router in local.routers : {
      for i, server in var.servers_proxmox : "${router.location}-${server.name}" => merge(
        server,
        {
          fqdn_external = "${server.name}.${var.default.domain_external}"
          fqdn_internal = "${server.name}.${var.default.domain_internal}"
          host          = "${router.location}-${server.name}"
          location      = router.location
          parent_name   = router.name
          parent_type   = router.type
          tags          = concat(["server"], try(server.tags, []))
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
              api_token = var.terraform.proxmox[server.name].api_token
              insecure  = try(var.terraform.proxmox[server.name].insecure, true)
              port      = try(var.terraform.proxmox[server.name].port, 8006)
            },
            try(server.provider, {})
          )
          user = merge(
            {
              automation = "root"
              fullname   = ""
              sftp_paths = var.default.sftp_paths
              ssh_keys   = data.github_user.default.ssh_keys
              username   = "root"
            },
            try(server.user, {})
          )
        },
      )
      if server.parent == router.name
    }
  ]...)

  ssh_keys = {
    for k, tls_private_key in tls_private_key.server_ssh_key : k => {
      private_key = trimspace(nonsensitive(tls_private_key.private_key_openssh))
      public_key  = trimspace(tls_private_key.public_key_openssh)
    }
  }

  tags = {
    for i, tag in var.tags : tag.name => merge(
      {
        tailscale_tag = "tag:${tag.name}"
      },
      tag
    )
  }

  tailscale_tailnet_keys_merged = {
    for k, tailscale_tailnet_key in merge(tailscale_tailnet_key.server, tailscale_tailnet_key.website) : k => {
      tailnet_key = nonsensitive(tailscale_tailnet_key.key)
    }
  }

  vms_oci = merge({
    for i, vm in var.vms_oci : "${vm.location}-${vm.name}" => merge(
      vm,
      {
        fqdn_external = "${vm.name}.${var.default.domain_external}"
        fqdn_internal = "${vm.name}.${var.default.domain_internal}"
        host          = "${vm.location}-${vm.name}"
        parent_name   = "oci"
        parent_type   = "cloud"
        tags          = concat(["vm"], try(vm.tags, []))
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
            automation = "root"
            fullname   = ""
            sftp_paths = var.default.sftp_paths
            ssh_keys   = data.github_user.default.ssh_keys
            username   = "root"
          },
          try(vm.user, {})
        )
      }
    )
  })

  vms_proxmox = merge([
    for k, server in local.servers_proxmox : {
      for i, vm in var.vms_proxmox : "${server.location}-${server.name}-${vm.name}" => merge(
        vm,
        {
          fqdn_external = "${server.name}-${vm.name}.${var.default.domain_external}"
          fqdn_internal = "${server.name}-${vm.name}.${var.default.domain_internal}"
          host          = "${server.location}-${server.name}-${vm.name}"
          location      = server.location
          name          = "${server.name}-${vm.name}"
          parent_name   = server.name
          parent_type   = server.type
          tags          = concat(["vm"], try(vm.tags, []))
          config = merge(
            {
              boot_image_url = ""
              timezone       = var.default.timezone
            },
            try(vm.config, {}),
            {
              packages = concat(["qemu-guest-agent"], try(vm.config.packages, []))
            },
          )
          network = merge(
            {
              private_address = ""
              public_address  = cloudflare_record.router[server.location].name
              ssh_port        = 22
            },
            try(vm.network, {})
          )
          user = merge(
            {
              automation = "root"
              fullname   = ""
              sftp_paths = var.default.sftp_paths
              ssh_keys   = data.github_user.default.ssh_keys
              username   = "root"
            },
            try(vm.user, {})
          )
        },
      )
      if vm.parent == server.name
    }
  ]...)

  websites = merge([
    for zone, websites in var.websites : {
      for k, website in websites : "${website.name}.${zone}${try(website.port, 0) != 0 ? ":${website.port}" : ""}" => merge(
        {
          app_name                 = website.name
          app_type                 = "default"
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
          username                 = null
          value                    = ""
          zone                     = zone
        },
        website
      )
    }
  ]...)

  websites_merged_openwrt = merge([
    for k, server in local.servers_merged_cloudflare : {
      for i, website in local.cloudflare_records_merged : i => {
        fqdn_external = website.hostname
        host          = server.host
        location      = server.location
      }
      if server.fqdn_external == website.hostname || server.fqdn_external == website.value
    }
  ]...)

  websites_merged_portainer = merge([
    for k, server in local.servers_merged : {
      for k, website in local.websites : k => {
        app_name              = website.app_name
        app_type              = website.app_type
        database_password     = website.enable_database_password ? local.database_passwords[k].database_password : ""
        database_username     = website.enable_database_password ? website.app_type : ""
        fqdn                  = website.fqdn
        host                  = server.host
        resend_api_key        = website.enable_resend_api_key ? local.resend_api_keys_merged[k].api_key : ""
        secret_hash           = website.enable_secret_hash ? local.secret_hashes[k].secret_hash : ""
        tailscale_tailnet_key = website.enable_tailscale_key ? local.tailscale_tailnet_keys_merged[k].tailnet_key : ""
        url                   = website.url
      }
      if server.fqdn_external == website.value
    }
  ]...)

  zones = merge(
    var.dns,
    var.websites
  )
}
