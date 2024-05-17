resource "ssh_resource" "config" {
  for_each = {
    for k, v in local.merged_servers : k => v
    if v.type == "mac"
  }

  agent = true
  host  = each.value.tailscale_name
  user  = each.value.user.username

  commands = [
    "bash -l -c 'cd ${var.default.home}/Parallels; vagrant up'"
  ]

  file {
    destination = "${var.default.home}/Parallels/Vagrantfile"

    content = templatefile(
      "./templates/vagrantfile.tftpl",
      {
        servers = {
          for k, v in local.merged_servers : k => merge(
            v,
            {
              network = merge(
                try(v.network, {}),
                {
                  mac_address = macaddress.config[k].address
                }
              )
            }
          )
          if v.parent_type == "mac"
        }
      }
    )
  }

  dynamic "file" {
    for_each = {
      for k, v in local.merged_servers : k => v
      if v.parent_type == "mac"
    }

    content {
      destination = "${var.default.home}/Parallels/${file.value.name}.yaml"

      content = templatefile(
        "./templates/cloud_config.yaml.tftpl",
        merge(
          each.value,
          {
            tailscale_key = tailscale_tailnet_key.config[each.key].key
            config = merge(
              try(each.value.config, {}),
              {
                packages = []
                timezone = var.default.timezone
              }
            )
            user = merge(
              try(each.value.user, {}),
              {
                password = htpasswd_password.server[each.key].sha512
              }
            )
          }
        )
      )
    }
  }
}
