locals {
  merged_hosts = {
    for k, v in merge(local.merged_routers, local.merged_servers) : k => {
      hostname = v.tag == "router" ? v.hostname : "${v.location}-${v.hostname}"
      tag      = v.tag
      type     = v.type
      username = v.user.username
    }
  }

  merged_routers = {
    for i, server in var.servers : "${server.location}.${var.root.domain}" => server
    if server.tag == "router"
  }

  merged_servers = merge(
    merge([
      for i, server in var.servers : {
        for i, parent in var.servers : "${server.hostname}.${try(parent.location, parent.parent)}.${var.root.domain}" => merge(
          server,
          {
            location = try(parent.location, parent.parent)
          }
        )
        if try(parent.hostname, "") == server.parent
      }
      if server.tag != "router"
    ]...),
    {
      for i, server in var.servers : "${server.hostname}.${var.terraform.oci.location}.${var.root.domain}" => merge(
        server,
        {
          location = var.terraform.oci.location
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
