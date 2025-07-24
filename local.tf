resource "local_file" "ssh_config" {
  filename = "../../.ssh/config"

  content = templatefile(
    "templates/ssh/config",
    {
      devices = local.devices
      servers = local.servers
    }
  )
}
