locals {
  filtered_cloudflare_records_wildcard = merge(
    {
      for k, cloudflare_record in cloudflare_record.dns : k => cloudflare_record
      if local.merged_dns[k].wildcard
    },
    {
      for k, cloudflare_record in cloudflare_record.internal_ipv4 : "${k}-internal" => cloudflare_record
    },
    cloudflare_record.noncloud,
    cloudflare_record.vm_ipv4,
    cloudflare_record.vm_oci_ipv4
  )

  filtered_servers_all = merge(
    local.merged_routers,
    local.merged_servers,
    local.merged_vms,
    local.merged_vms_oci,
    local.merged_vms_proxmox
  )

  filtered_servers_noncloud = merge(
    local.merged_servers,
    local.merged_vms_proxmox
  )

  filtered_tailscale_devices = {
    for k, server in local.filtered_servers_all : k => {
      fqdn_external = server.fqdn_external
      fqdn_internal = server.fqdn_internal
      private_ipv4  = element([for device in data.tailscale_devices.default.devices : element([for address in device.addresses : address if can(cidrhost("${address}/32", 0))], 0) if element(split(".", device.name), 0) == k], 0)
      private_ipv6  = element([for device in data.tailscale_devices.default.devices : element([for address in device.addresses : address if can(cidrhost("${address}/128", 0))], 0) if element(split(".", device.name), 0) == k], 0)
    }
    if length([for device in data.tailscale_devices.default.devices : device if element(split(".", device.name), 0) == k]) > 0
  }

  merged_devices = {
    for device in var.devices : device.name => merge(
      {
        port     = 22
        username = "root"
      },
      device,
      {
        sftp_paths = concat(var.default.user_config.sftp_paths, try(device.sftp_paths, []))
      }
    )
  }

  merged_dns = merge([
    for zone, records in var.dns : {
      for i, record in records : "${record.name == "@" ? "" : "${record.name}."}${zone}-${lower(record.type)}-${i}" => merge(
        {
          priority = null
          wildcard = false
          zone     = zone
        },
        record
      )
    }
  ]...)

  merged_routers = {
    for router in var.routers : router.location => merge(
      {
        flags        = []
        parent_flags = []
        parent_name  = ""
        services     = []
        tag          = "router"
      },
      router,
      {
        fqdn_external = "${router.location}.${var.default.domain_external}"
        fqdn_internal = "${router.location}.${var.default.domain_internal}"
        name          = router.location
        title         = try(router.title, upper(router.name), upper(router.location))
        config = merge(
          var.default.server_config,
          try(router.config, {})
        )
        networks = [
          for network in try(router.networks, [{}]) : merge(
            {
              public_address = ""
            },
            network
          )
        ]
        user = merge(
          var.default.user_config,
          try(router.user, {}),
          {
            sftp_paths = concat(var.default.user_config.sftp_paths, try(router.user.sftp_paths, []))
          }
        )
      }
    )
  }

  merged_servers = merge([
    for router in local.merged_routers : {
      for server in var.servers : "${router.location}-${server.name}" => merge(
        {
          flags    = []
          services = []
          tag      = "server"
        },
        server,
        {
          fqdn_external = "${server.name}.${router.location}.${var.default.domain_external}"
          fqdn_internal = "${server.name}.${router.location}.${var.default.domain_internal}"
          location      = router.location
          parent_flags  = router.flags
          parent_name   = router.name
          title         = try(server.title, title(server.name))
          config = merge(
            var.default.server_config,
            try(server.config, {})
          )
          networks = [
            for network in try(server.networks, [{}]) : merge(
              {
                public_address = cloudflare_record.router[router.location].name
              },
              network
            )
          ]
          user = merge(
            var.default.user_config,
            try(server.user, {}),
            {
              sftp_paths = concat(var.default.user_config.sftp_paths, try(server.user.sftp_paths, []))
            }
          )
        },
      )
      if server.parent == router.name
    }
  ]...)

  merged_tags_tailscale = [
    for tag in var.tags : "tag:${tag}"
  ]

  merged_vms = merge({
    for vm in var.vms : "${vm.location}-${vm.name}" => merge(
      {
        flags        = []
        location     = "cloud"
        parent_flags = ["cloud"]
        parent_name  = "cloud"
        services     = []
        tag          = "vm"
      },
      vm,
      {
        fqdn_external = "${vm.name}.${vm.location}.${var.default.domain_external}"
        fqdn_internal = "${vm.name}.${vm.location}.${var.default.domain_internal}"
        title         = try(vm.title, title(vm.name))
        config = merge(
          var.default.server_config,
          try(vm.config, {})
        )
        networks = [
          for network in try(vm.networks, [{}]) : merge(
            {
              public_ipv4 = ""
              public_ipv6 = ""
            },
            network
          )
        ]
        user = merge(
          var.default.user_config,
          try(vm.user, {}),
          {
            sftp_paths = concat(var.default.user_config.sftp_paths, try(vm.user.sftp_paths, []))
          }
        )
      }
    )
  })

  merged_vms_oci = merge({
    for vm in var.vms_oci : "${vm.location}-${vm.name}" => merge(
      {
        flags        = []
        location     = "cloud"
        parent_flags = ["cloud"]
        parent_name  = "oci"
        services     = []
        tag          = "vm"
      },
      vm,
      {
        fqdn_external = "${vm.name}.${vm.location}.${var.default.domain_external}"
        fqdn_internal = "${vm.name}.${vm.location}.${var.default.domain_internal}"
        title         = try(vm.title, title(vm.name))
        config = merge(
          var.default.server_config,
          {
            boot_disk_image_id = ""
            boot_disk_size     = 128
            cpus               = 4
            memory             = 8
            shape              = "VM.Standard.A1.Flex"
          },
          try(vm.config, {})
        )
        networks = [
          for network in try(vm.networks, [{}]) : network
        ]
        user = merge(
          var.default.user_config,
          try(vm.user, {}),
          {
            sftp_paths = concat(var.default.user_config.sftp_paths, try(vm.user.sftp_paths, []))
          }
        )
      }
    )
  })

  merged_vms_proxmox = merge([
    for server in local.merged_servers : {
      for vm in var.vms_proxmox : "${server.location}-${server.name}-${vm.name}" => merge(
        {
          flags    = []
          services = []
          tag      = "vm"
        },
        vm,
        {
          fqdn_external = "${vm.name}.${server.name}.${server.location}.${var.default.domain_external}"
          fqdn_internal = "${vm.name}.${server.name}.${server.location}.${var.default.domain_internal}"
          location      = server.location
          name          = "${server.name}-${vm.name}"
          parent_flags  = server.flags
          parent_name   = server.name
          title         = "${server.title} ${try(vm.title, title(vm.name))}"
          config = merge(
            var.default.server_config,
            {
              boot_disk_image_compression_algorithm = null
              boot_disk_image_url                   = ""
              boot_disk_size                        = 128
              cpus                                  = 4
              enable_serial                         = false
              memory                                = 8
              operating_system                      = "l26"
            },
            try(vm.config, {}),
            {
              packages = concat(["qemu-guest-agent"], try(vm.config.packages, []), var.default.server_config.packages)
            }
          )
          hostpci = [
            for hostpci in try(vm.hostpci, {}) : merge(
              {
                pcie = true
                xvga = false
              },
              hostpci
            )
          ]
          networks = [
            for network in try(vm.networks, [{}]) : merge(
              {
                firewall       = true
                public_address = cloudflare_record.router[server.location].name
                vlan_id        = null
              },
              network
            )
          ]
          usb = [
            for usb in try(vm.usb, {}) : merge(
              {
                usb3 = true
              },
              usb
            )
          ]
          user = merge(
            var.default.user_config,
            try(vm.user, {}),
            {
              sftp_paths = concat(var.default.user_config.sftp_paths, try(vm.user.sftp_paths, []))
            }
          )
        },
      )
      if vm.parent == server.name
    }
  ]...)

  output_b2 = {
    for k, b2_bucket in b2_bucket.server : k => {
      application_key_id = b2_application_key.server[k].application_key_id
      application_key    = b2_application_key.server[k].application_key
      bucket_name        = b2_bucket.bucket_name
      endpoint           = replace(data.b2_account_info.default.s3_api_url, "https://", "")
    }
  }

  output_cloud_config = {
    for k, server in local.filtered_servers_all : k => templatefile(
      "templates/cloud_config/cloud_config.yaml",
      {
        init_commands = local.output_init_commands[k]
        password_hash = htpasswd_password.server[k].sha512
        server        = server
        ssh_keys      = data.github_user.default.ssh_keys
      }
    )
    if server.config.enable_cloud_config
  }

  output_cloudflare_api_tokens = {
    for k, cloudflare_api_token in cloudflare_api_token.server : k => cloudflare_api_token.value
  }

  output_cloudflare_tunnels = {
    for k, cloudflare_zero_trust_tunnel_cloudflared in cloudflare_zero_trust_tunnel_cloudflared.server : k => {
      cname = cloudflare_zero_trust_tunnel_cloudflared.cname
      id    = cloudflare_zero_trust_tunnel_cloudflared.id
      token = cloudflare_zero_trust_tunnel_cloudflared.tunnel_token
    }
  }

  output_init_commands = {
    for k, server in local.filtered_servers_all : k => concat(
      [
        "sysctl --system"
      ],
      contains(server.config.packages, "qemu-guest-agent") ? [
        "systemctl enable --now qemu-guest-agent"
      ] : [],
      contains(server.flags, "docker") ? concat(
        [
          "curl -fsLS https://get.docker.com | sh",
          "docker network create ${var.default.organisation}",
          "docker run --name portainer-agent --restart unless-stopped -d -p 9001:9001 -v /:/host -v ${contains(server.flags, "truenas") ? "/mnt/.ix-apps/docker/volumes:/mnt/.ix-apps/docker/volumes" : "/var/lib/docker/volumes:/var/lib/docker/volumes"} -v /var/run/docker.sock:/var/run/docker.sock portainer/agent",
        ],
        contains(server.flags, "portainer") ? [
          "docker run --name portainer --network ${var.default.organisation} --restart unless-stopped -d -l \"caddy.reverse_proxy={{upstreams 9000}}\" -l \"caddy.import=internal\" -l \"caddy=portainer.${var.default.domain_internal}\" -p 8000:8000 -p 9000:9000 -p 9443:9443 -v portainer_data:/data portainer/portainer-ce"
        ] : [],
      ) : [],
      [
        "curl -fsLS https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$(dpkg --print-architecture).deb -o /tmp/cloudflared.deb && dpkg -i /tmp/cloudflared.deb && rm /tmp/cloudflared.deb",
        "curl -fsLS https://tailscale.com/install.sh | sh",
        "cloudflared service install ${local.output_cloudflare_tunnels[k].token}",
        "tailscale up --advertise-exit-node --authkey ${local.output_tailscale_tailnet_keys[k]} --hostname ${k}"
      ]
    )
  }

  output_resend_api_keys = {
    for k, restapi_object in restapi_object.resend_api_key_server : k => jsondecode(restapi_object.create_response).token
  }

  output_secret_hashes = {
    for k, random_password in random_password.secret_hash : k => random_password.result
  }

  output_tailscale_tailnet_keys = {
    for k, tailscale_tailnet_key in tailscale_tailnet_key.server : k => tailscale_tailnet_key.key
  }
}
