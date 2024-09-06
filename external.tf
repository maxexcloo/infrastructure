data "external" "connectivity_check_servers" {
  for_each = local.filtered_servers_all

  program = ["sh", "-c", "nc -w 3 -z ${each.value.host} ${each.value.network.ssh_port} >/dev/null 2>&1 && echo '{\"reachable\": \"true\"}' || echo '{\"reachable\": \"false\"}'"]
}
