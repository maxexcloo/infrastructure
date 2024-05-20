resource "ssh_resource" "mac" {
  for_each = { for k, v in local.merged_servers : k => v if v.type == "mac" }

  agent = true
  host  = each.value.tailscale_name
  user  = each.value.user.username

  commands = [
    "sh -l ${each.value.config.parallels_path}/vagrant.sh"
  ]

  file {
    destination = "${each.value.config.parallels_path}/vagrant.sh"

    content = templatefile(
      "./templates/mac/vagrant.sh.tftpl",
      {
        parallels_path = each.value.config.parallels_path
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
          if v.parent_name == each.value.name
        }
      }
    )
  }

  file {
    destination = "${each.value.config.parallels_path}/Vagrantfile"

    content = templatefile(
      "./templates/mac/vagrantfile.tftpl",
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
          if v.parent_name == each.value.name
        }
      }
    )
  }

  dynamic "file" {
    for_each = { for k, v in local.merged_servers : k => v if v.parent_name == each.value.name }

    content {
      destination = "${each.value.config.parallels_path}/${file.value.name}.yaml"

      content = templatefile(
        "./templates/cloud_config.tftpl",
        merge(
          file.value,
          {
            tailscale_key = tailscale_tailnet_key.config[file.key].key
            config = merge(
              try(file.value.config, {}),
              {
                packages = []
                timezone = var.default.timezone
              }
            )
            user = merge(
              try(file.value.user, {}),
              {
                password = htpasswd_password.server[file.key].sha512
              }
            )
          }
        )
      )
    }
  }
}
