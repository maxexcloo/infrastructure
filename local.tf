resource "local_file" "ssh_config" {
  content = templatefile(
    "templates/ssh/config",
    {
      devices = local.servers_merged_devices
      servers = local.servers_filtered_all
    }
  )
  filename = "../../.ssh/config"
}
