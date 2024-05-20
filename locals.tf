locals {
  merged_servers = merge(
    merge(
      {
        for i, server in var.servers : "${server.location}.${var.default.domain}" => merge(
          server,
          {
            fqdn           = "${server.location}.${var.default.domain}"
            parent_name    = ""
            parent_type    = ""
            tailscale_name = server.location
            provider = merge(
              {
                password = var.terraform.openwrt[server.name].password
                port     = try(var.terraform.openwrt[server.name].port, 81)
              },
              try(server.provider, {})
            )
            user = merge(
              {
                fullname = "root"
                ssh_keys = data.github_user.config.ssh_keys
                username = "root"
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
              fqdn           = "${server.name}.${try(parent.location, parent.parent)}.${var.default.domain}"
              location       = try(parent.location, parent.parent)
              parent_name    = parent.name
              parent_type    = parent.type
              tailscale_name = "${try(parent.location, parent.parent)}-${server.name}"
              user = merge(
                {
                  fullname = "root"
                  ssh_keys = data.github_user.config.ssh_keys
                  username = "root"
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
          fqdn           = "${server.name}.${var.terraform.oci.location}.${var.default.domain}"
          location       = var.terraform.oci.location
          parent_name    = "oci"
          parent_type    = "oci"
          tailscale_name = "${var.terraform.oci.location}-${server.name}"
          user = merge(
            try(server.user, {}),
            {
              fullname = try(server.user.fullname, "root")
              ssh_keys = data.github_user.config.ssh_keys
              username = try(server.user.username, "root")
            }
          )
        }
      )
      if try(server.parent, "") == "oci"
    }
  )

  merged_tags = distinct([
    for i, server in var.servers : server.tag
  ])

  merged_websites = merge([
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
