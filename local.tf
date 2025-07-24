resource "local_file" "ssh_config" {
  content = templatefile(
    "templates/ssh/config",
    {
      devices = local.merged_devices
      servers = local.filtered_servers_all
    }
  )
  filename = "../../.ssh/config"
}