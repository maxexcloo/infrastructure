locals {
  cloud_init_mac = { for k, v in local.servers : k => templatefile(
    "./templates/cloud_config.tftpl",
    merge(
      v,
      {
        tailscale_key = tailscale_tailnet_key.config[k].key
        config = merge(
          try(v.config, {}),
          {
            packages = []
            timezone = var.default.timezone
          }
        )
        user = merge(
          try(v.user, {}),
          {
            password = htpasswd_password.server[k].sha512
          }
        )
      }
    )
    )
  if v.parent_type == "mac" }

  cloud_init_oci = {
    for k, v in local.servers : k => templatefile(
      "./templates/cloud_config.tftpl",
      merge(
        v,
        {
          tailscale_key = tailscale_tailnet_key.config[k].key
          config = merge(
            try(v.config, {}),
            {
              packages = []
              timezone = var.default.timezone
            }
          )
          user = merge(
            try(v.user, {}),
            {
              password = htpasswd_password.server[k].sha512
            }
          )
        }
      )
    )
    if v.parent_name == "oci"
  }

  cloud_init_proxmox = {
    for k, v in local.servers : k => templatefile(
      "./templates/cloud_config.tftpl",
      merge(
        v,
        {
          tailscale_key = tailscale_tailnet_key.config[k].key
          config = merge(
            try(v.config, {}),
            {
              packages = ["qemu-guest-agent"]
              timezone = var.default.timezone
            }
          )
          user = merge(
            try(v.user, {}),
            {
              password = htpasswd_password.server[k].sha512
            }
          )
        }
      )
    )
    if v.parent_type == "proxmox"
  }

  cloudflare_websites_merged = {
    for k, v in merge(
      cloudflare_record.router,
      cloudflare_record.server,
      cloudflare_record.server_oci_ipv4,
      cloudflare_record.server_oci_ipv6,
      cloudflare_record.website
    ) : k => v
    if v.type == "A" || v.type == "AAAA" || v.type == "CNAME"
  }

  mac_servers_merged = merge([
    for i, parent in local.servers : {
      for k, server in local.servers : k => merge(
        server,
        {
          config = merge(
            try(parent.config, {}),
            try(server.config, {}),
            {
              parent_host = parent.host
              parent_user = parent.user.username
              parent_path = "${parent.config.parallels_path}/${server.name}"
            }
          )
          network = merge(
            try(server.network, {}),
            {
              mac_address = try(macaddress.config[k].address, "")
            }
          )
        }
      )
      if server.parent_name == parent.name
    }
    if parent.type == "mac"
  ]...)

  openwrt_websites_merged = merge([
    for i, website in local.cloudflare_websites_merged : {
      for k, server in local.servers : i => {
        fqdn     = website.hostname
        host     = server.host
        location = server.location
      }
      if(server.fqdn == website.hostname || server.fqdn == website.value) && server.parent_type != "cloud" && server.tag != "router"
    }
  ]...)

  servers = merge(
    merge(
      {
        for i, server in var.servers : "${server.location}.${var.default.domain}" => merge(
          server,
          {
            fqdn        = "${server.location}.${var.default.domain}"
            host        = server.location
            parent_name = ""
            parent_type = ""
            network = merge(
              try(server.network, {}),
              {
                ssh_port = try(server.network.ssh_port, 21)
              }
            )
            provider = merge(
              {
                password = var.terraform.openwrt[server.name].password
                port     = try(var.terraform.openwrt[server.name].port, 81)
              },
              try(server.provider, {})
            )
            user = merge(
              {
                fullname            = "root"
                ssh_keys            = data.github_user.config.ssh_keys
                username            = "root"
                username_automation = "root"
              },
              try(server.user, {})
            )
          }
        )
        if server.tag == "router"
      },
      [
        for i, server in var.servers : {
          for i, parent in var.servers : "${server.name}.${try(parent.location, parent.parent)}.${var.default.domain}" => merge(
            server,
            {
              fqdn        = "${server.name}.${try(parent.location, parent.parent)}.${var.default.domain}"
              host        = "${try(parent.location, parent.parent)}-${server.name}"
              location    = try(parent.location, parent.parent)
              parent_name = parent.name
              parent_type = parent.type
              network = merge(
                try(server.network, {}),
                {
                  ssh_port = try(server.network.ssh_port, 21)
                }
              )
              user = merge(
                {
                  fullname            = "root"
                  ssh_keys            = data.github_user.config.ssh_keys
                  username            = "root"
                  username_automation = server.type == "mac" ? try(server.user.username, "root") : try(server.user.username, "root") == "root" ? "root" : "automation"
                },
                try(server.user, {})
              )
            },
            server.type == "proxmox" ? {
              provider = merge(
                {
                  api_token = var.terraform.proxmox[server.name].api_token
                  insecure  = try(var.terraform.proxmox[server.name].insecure, true)
                  port      = try(var.terraform.proxmox[server.name].port, 8006)
                },
                try(server.provider, {})
              )
            } : {}
          )
          if try(parent.name, "") == server.parent
        }
        if server.tag != "router"
    ]...),
    {
      for i, server in var.servers : "${server.name}.${var.terraform.oci.location}.${var.default.domain}" => merge(
        server,
        {
          fqdn        = "${server.name}.${var.terraform.oci.location}.${var.default.domain}"
          host        = "${var.terraform.oci.location}-${server.name}"
          location    = var.terraform.oci.location
          parent_name = "oci"
          parent_type = "cloud"
          network = merge(
            try(server.network, {}),
            {
              ssh_port = try(server.network.ssh_port, 21)
            }
          )
          user = merge(
            try(server.user, {}),
            {
              fullname            = try(server.user.fullname, "root")
              ssh_keys            = data.github_user.config.ssh_keys
              username            = try(server.user.username, "root")
              username_automation = try(server.user.username_automation, "automation")
            }
          )
        }
      )
      if try(server.parent, "") == "oci"
    }
  )

  tags = distinct([
    for i, server in var.servers : server.tag
  ])

  websites = merge([
    for zone, records in var.websites : {
      for i, record in records : "${record.name == "@" ? "" : "${record.name}."}${zone}-${lower(record.type)}-${i}" => merge(
        record,
        {
          zone = zone
        }
      )
    }
  ]...)
}
