# data "ignition_user" "server" {
#   for_each = {
#     for k, server in local.filtered_servers_all : k => server
#     if server.config.enable_ignition
#   }

#   gecos               = ""
#   home_dir            = "/home/foo/"
#   name                = "foo"
#   password_hash       = ""
#   shell               = "/bin/bash"
#   ssh_authorized_keys = ""
# }
