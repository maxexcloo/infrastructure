locals {
  merged_servers = merge(
    merge(
      {
        for i, server in var.servers : "${server.location}.${var.root.domain}" => merge(
          server,
          {
            fqdn           = "${server.location}.${var.root.domain}"
            parent         = ""
            tailscale_name = server.location
            tailscale_tag  = "tag:${server.tag}"
            user = {
              fullname = try(server.user.fullname, "root")
              username = try(server.user.username, "root")
            }
          }
        )
        if server.tag == "router"
      },
      [
        for i, server in var.servers : {
          for i, parent in var.servers : "${server.name}.${try(parent.location, parent.parent)}.${var.root.domain}" => merge(
            server,
            {
              fqdn           = "${server.name}.${try(parent.location, parent.parent)}.${var.root.domain}"
              location       = try(parent.location, parent.parent)
              tailscale_name = "${try(parent.location, parent.parent)}-${server.name}"
              tailscale_tag  = "tag:${server.tag}"
              user = {
                fullname = try(server.user.fullname, "root")
                username = try(server.user.username, "root")
              }
            }
          )
          if try(parent.name, "") == server.parent
        }
        if server.tag != "router"
    ]...),
    {
      for i, server in var.servers : "${server.name}.${var.terraform.oci.location}.${var.root.domain}" => merge(
        server,
        {
          fqdn           = "${server.name}.${var.terraform.oci.location}.${var.root.domain}"
          location       = var.terraform.oci.location
          tailscale_name = "${var.terraform.oci.location}-${server.name}"
          tailscale_tag  = "tag:${server.tag}"
          user = {
            fullname = try(server.user.fullname, "root")
            username = try(server.user.username, "root")
          }
        }
      )
      if server.tag == "server" && try(server.parent, "") == "oci"
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
