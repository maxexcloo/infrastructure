locals {
  merged_routers = {
    for i, server in var.servers : "${server.location}.${var.root.domain}" => server
    if try(server.location, "") != ""
  }

  merged_servers = merge([
    for i, server in var.servers : {
      for i, parent in var.servers : "${server.hostname}.${try(parent.location, parent.parent)}.${var.root.domain}" => merge(
        server,
        {
          location = try(parent.location, parent.parent)
          parent   = try(server.parent, "")
        }
      )
      if try(parent.hostname, "") == server.parent
    }
    if try(server.parent, "") != ""
  ]...)

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
